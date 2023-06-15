(import-macros {: vec2-op} :geom-macros)
(local scene (require :scene))
(local geom (require :geom))
(local util (require :util))
(local draw (require :draw))
(local collide (require :collide))
(var vision (require :vision))
(var mapgen (require :mapgen))
(local lume (require :lib.lume))
(local pp util.pp)

(local dungeon {})

(fn dungeon.init []
  (let [state {:level 0
               :elapsed-time 0
               :delta-time 0
               :stats {:vanquished {}
                       :money 0}
               :log []}]
    (dungeon.next-level state)
    state))

(fn dungeon.viewport [s]
  (unpack (mapgen.polygon-bounding-box s.level-border)))

(fn dungeon.next-level [s]
  (set s.level (+ s.level 1))
  (set s.actors [])
  (dungeon.log s (lume.format "Welcome to dungeon level {level}" s))
  (set s.actors-to-spawn [])
  (set s.hurt-tallies {}) ; map of <actor,tally> to combine hp of hits
  (set s.hurt-timers {})  ; map of <actor,timestamp> to combine hp of hits
  (set s.will-delete {})  ; map of <actor,will-delete?> to delete actors
  (set s.actors-seen {})  ; map of <actor,place> where have been seen last
  (set s.time-til-game-over nil)
  (let [(polygon actors) (mapgen.generate-level s.level)]
    (set s.level-border polygon)
    (each [_ args (ipairs actors)]
      (dungeon.spawn-actor s (unpack args))))
  (set s.border-seen (vision.get-visible s.player.pos s.level-border)))

(fn dungeon.update [s dt]
  (match s.time-til-game-over
    (where ttm (< ttm s.elapsed-time))
    (do
      ;; Finalize stats data then show the game over screen.
      (set s.stats.elapsed-time s.elapsed-time)
      (set s.stats.level s.level)
      (set s.stats.log s.log)
      (scene.set :game-over s.stats))
    (where ttm)
    (set s.delta-time dt))

  ;; add actors
  (each [_ actor (ipairs s.actors-to-spawn)]
    (table.insert s.actors actor)
    (set s.actors-to-spawn []))

  ;; look at damage tallies, spawn particles
  (each [actor time (pairs s.hurt-timers)]
    (let [time (- time dt)
          time (if (< time 0) nil time)]
      (tset s.hurt-timers actor time)
      (when (not time)
        (dungeon.spawn-particles
         s
         :damage-number
         actor.pos
         actor.friendly?
         (. s.hurt-tallies actor))
        (tset s.hurt-tallies actor nil))))

  (if
   (or (> s.player.freeze-until s.elapsed-time) s.time-til-game-over)
   (do                                  ; realtime mode
      (set s.elapsed-time (+ dt s.elapsed-time))
      (dungeon.update-actors s dt))
   (do                                  ; normal (freezy) mode
      (dungeon.update-realtime-actors s dt)
    ;; add new actors
    (when (> s.delta-time 0)
      (set s.elapsed-time (+ s.delta-time s.elapsed-time))
      (dungeon.update-actors s s.delta-time)
      (set s.delta-time 0))))

  ;; delete actors
  (set s.actors
       (icollect [i actor (ipairs s.actors)]
         (if (. s.will-delete actor) nil actor)))
  (set s.will-delete {}))

(fn dungeon.draw [s]
  (love.graphics.setColor 1 1 1 0.7)
  (love.graphics.setLineWidth 2)
  (vision.draw-visible-border s.level-border s.border-seen)
  (dungeon.draw-actors s)
  (love.graphics.setColor [1 1 1 1])
  (love.graphics.print (lume.format "Level: {level} // Time: {time}"
                                    {:time (lume.round s.elapsed-time .001) :level s.level})
                       10 10)
  (love.graphics.setColor [.5 .5 .5 1])
  (love.graphics.print "Press F1, /, or ? for help" 500 10)
  (when (> (length s.log) 0)
    (love.graphics.print (lume.last s.log) 265 560)))

(fn dungeon.mousemoved [s x y]
  (s.player.mousemoved s s.player x y))

(fn dungeon.keypressed [s keycode scancode]
  (when (scene.global-keys.handle-keypressed keycode scancode)
    (lua "return"))

  (s.player.keypressed s s.player scancode)

  (match scancode
    (where (or :/ :? :f1))
    (scene.set :dungeon-help s)
    "\\"
    (scene.set :dungeon-messages s)
    ;; DEBUG
    :f5
    (do
      (tset package.loaded :mapgen nil)
      (let [(status err) (pcall
                          (lambda []
                            (set mapgen (require :mapgen))
                            (dungeon.next-level s)
                            (for [i 1 1000] (tset s.border-seen i true))))]
        (if (= status false)
            (print (.. "ERROR: failed to reload map. " err)))))
    :f6
    (pp s.level-border)
    :f7
    (do
      (tset package.loaded :vision nil)
      (let [(status err) (pcall
                          (lambda [] (set vision (require :vision))))]
        (if (= status false)
            (print (.. "ERROR: failed to reload vision. " err)))))))

(fn dungeon.mousepressed [s x y button]
  (s.player.mousepressed s s.player x y button))

;;; returns true if step was successful
(fn dungeon.actor-step-forward [actor dt ?level-border]
  (let [step [(geom.polar->rectangular
               actor.angle
               (* dt actor.speed))]
        next-pos [(vec2-op + actor.pos step)]
        in-bounds (or (not ?level-border)
                      (geom.point-in-polygon? next-pos ?level-border))]
    (when in-bounds
      (do
        (set actor.pos next-pos)
        true))))

(fn dungeon.actor-try-stamina-action [actor cost action ...]
  (when (> actor.stamina cost)
    (set actor.stamina (- actor.stamina cost))
    (action ...)))

(fn dungeon.actor-look-at-pos [actor x y]
  (set actor.angle
       (geom.angle (vec2-op - [x y] actor.pos))))

(fn dungeon.find-nearest-visible [s actor ?kind]
  (local visible-actors
         (icollect [i v (ipairs s.actors)]
           (if (and v.hitbox
                   (vision.see-between-points? actor.pos v.pos s.level-border)
                   (or (not ?kind) (= ?kind v.kind)))
               v
               nil)))
  (dungeon.find-nearest-from-list s actor visible-actors))

(fn dungeon.find-nearest [s actor ?kind]
  (local tangible-actors
         (icollect [i v (ipairs s.actors)]
           (if (and v.hitbox
                   (or (not ?kind) (= ?kind v.kind)))
               v
               nil)))
  (dungeon.find-nearest-from-list s actor tangible-actors))

(fn dungeon.find-nearest-from-list [s actor list]
  (local (actor _ distance)
         (util.max-by-score
          list
          #(- (geom.distance (vec2-op - actor.pos (. $1 :pos))))
          actor))
  (values actor (and distance (- distance))))

;; move a 'step' pixels towards b, return the result
(fn dungeon.step-vec-towards [a b step]
  (let [(dx dy) (vec2-op - a b)
        (angle distance) (geom.rectangular->polar dx dy)]
    (if (< distance step)
        ;; too close to goal -- just teleport to goal
        b
        (let [step-vec [(geom.polar->rectangular angle step)]]
          [(vec2-op - a step-vec)]))))

(fn dungeon.spawn-particles [s kind ...]
  (fn format-num [num]
    (if (< num 0.95) (.. "." (lume.round (* num 10)))
        (lume.round num)))

  (case kind
    :circle
    (let [(pos props) ...
          count (or props.count 20)
          color (or props.color [1 1 1 1])
          lifetime 3
          speed (or props.speed 500)]
      (for [i 1 count]
        (dungeon.spawn-actor s :particle pos i
                             {: color
                              : lifetime
                              :show-line {: color :len (/ speed 30)}
                              :speed (* speed (+ 1 (math.random)))})))
    :healing-number
    (let [(pos friendly? amt) ...]
      (dungeon.spawn-actor s :particle pos (/ math.pi -2)
                           {
                            :color (if friendly? [0.5 1 0.5 1] [0 1 0 1])
                            :lifetime 1
                            :speed 30
                            :char (format-num amt)
                            :char-scale 0.5}))
    :damage-number
    (let [(pos friendly? atk) ...
          random-offset (lambda [] (- (* (math.random) 20) 10))
          pos [(vec2-op + pos [(random-offset) (random-offset)])]]
      (dungeon.spawn-actor s :particle pos (/ math.pi -2)
                           {
                            :color (if friendly? [1 0.5 0.5 1] [1 0 0 1])
                            :lifetime 1
                            :speed 30
                            :char (format-num atk)
                            :char-scale 0.5}))))

(fn dungeon.spawn-actor [s kind ...]
  (local actor-class (require (.. "actors." kind)))
  (local actor (actor-class.spawn s ...))
  (match kind
   :player
   (if s.player
       (do
         (set s.player.pos actor.pos)
         (table.insert s.actors-to-spawn s.player)
         (lua "return"))
       (do
         (set s.player actor)))
   :stairs-down
   (set s.stairs-down actor))

  (dungeon.insert-actor s actor))

(fn dungeon.insert-actor [s actor]
  (table.insert s.actors-to-spawn actor))

(fn dungeon.collide-actors [s actor other dt]
  (when (not (collide.actors-collide? actor other))
    (lua "return"))
  (match [actor.collect other]
    (where [{:money value} s.player])
    (do
      (set s.stats.money (+ s.stats.money value))
      (dungeon.delete-actor s actor)
      (table.insert s.log
        (.. "You collected a " actor.name " worth $" value))
      (lua "return"))
    (where [{:hp value} s.player])
    (do
      (dungeon.heal-actor s s.player value)
      (dungeon.delete-actor s actor)
      (table.insert s.log
        (.. "You ate " actor.name " and felt a bit better."))
      (lua "return")))

  (when (and
         actor.atk
         (or
           (and actor.enemy? other.friendly?)
           (and actor.friendly? other.enemy?)))
    (local dmg (* actor.atk dt))
    (table.insert
     s.log
     (match [actor.kind other.kind]
       [:sword _]
       (.. "You slash at the " other.name ".")
       [:bullet _]
       (if other.enemy?
         (.. "Your bullet pierces the " other.name ".")
         (.. "The enemy " actor.name " bombards you."))
       [_ :player]
       (.. "The " actor.name " hurts you.")))
    (dungeon.damage-actor s other dmg)))

(fn dungeon.heal-actor [s actor amt]
  (set actor.hp (math.min actor.max-hp (+ actor.hp amt)))
  (dungeon.spawn-particles
   s
   :healing-number
   actor.pos
   actor.friendly?
   amt))

;;; damage-actor returns nil.
(fn dungeon.damage-actor [s actor atk]
  (var msg nil)
  (when actor.hp
    (set actor.hp (- actor.hp atk))
    (tset s.hurt-tallies actor (+ (or (. s.hurt-tallies actor) 0) atk))
    (tset s.hurt-timers actor (/ 1 20))
    (when (< actor.hp 0)
      (dungeon.spawn-particles s :circle actor.pos {:color actor.color :count 20})
      (when actor.enemy?
        (do
          (tset s.stats.vanquished actor.name (+ 1 (or (. s.stats.vanquished actor.name)
                                                       0)))
          (set msg (.. "The " actor.name " is destroyed."))))
      (match actor.kind
        :player
        (do
          (set s.time-til-game-over (+ s.elapsed-time 2))
          (set s.msg "You died!")))
      (dungeon.delete-actor s actor)))
  (when msg
    (dungeon.log s msg))
  nil)

(fn dungeon.delete-actor [s actor]
  (match actor.on-death
    (where callback) (callback s actor))
  (tset s.will-delete actor true))

(fn dungeon.update-realtime-actors [s dt]
  (each [i actor (ipairs s.actors)]
    (match actor.realtime-update
      (where update) (update s actor dt))))

(fn dungeon.update-actors [s dt]
  (each [i actor (ipairs s.actors)]
    ;; hitboxes
    (when actor.hitbox
      (each [_ other (ipairs s.actors)]
        (when (and
               (not= actor other)
               other.hitbox)
          (dungeon.collide-actors s actor other dt))))

    ;; automatic death
    (when actor.lifetime
      (set actor.lifetime (- actor.lifetime dt))
      (if (<= actor.lifetime 0)
        (dungeon.delete-actor s actor)))

    ;; moving forward
    (when actor.moving?
      (local did-move? (dungeon.actor-step-forward actor dt)))

    ;; ai
    (local ai actor.ai)
    (case (?. ai :kind)
      :random ; move to a random point, periodically
      (do
        (let [did-step (dungeon.actor-step-forward actor dt s.level-border)]
          (when (or (not did-step)
                    (not ai.target)
                    (> s.elapsed-time ai.next-target-time))
            (set ai.target [(mapgen.random-point-in-polygon s.level-border)])
            (set ai.next-target-time (+ s.elapsed-time (love.math.random)))
            (dungeon.actor-look-at-pos actor (unpack ai.target))))))

    (match actor.update
      (where update) (update s actor dt))))

(fn dungeon.draw-actors [s]
  (each [i actor (ipairs s.actors)]
    (if
     (or
      (vision.see-between-points? s.player.pos actor.pos s.level-border)
      actor.always-visible?)
     (do
       (dungeon.draw-actor s actor)
       (tset s.actors-seen actor actor.pos))
     (. s.actors-seen actor)
     (do
       (when (not= actor.kind :stairs-down)
           (love.graphics.setColorMask false false true true))
       (dungeon.draw-actor s actor (. s.actors-seen actor))
       (love.graphics.setColorMask true true true true)))))

(fn dungeon.draw-actor [s actor ?last-seen-at]
  (local [x y] (or ?last-seen-at actor.pos))

  (when actor.hitbox
    (match actor.hitbox.shape
      :circle
      (do
        (love.graphics.setColor (if (. s.hurt-tallies actor)
                                    [1 0 0 1]
                                    [1 1 1 0.2]))
        (love.graphics.setLineWidth 2)
        (love.graphics.circle :line x y (- actor.hitbox.size 1)))
      :line
      (do
        (draw.ray [x y] [actor.angle actor.hitbox.size] 1 [1 1 1 0.2]))
      (where other)
      (error (.. "Unknown hitbox shape: " other))))

  (when (and actor.hp (not actor.hide-hp?) (not (>= actor.hp actor.max-hp)))
    (draw.progress [[(vec2-op - [x y] [10 15])] [20 5]]
                   (/ actor.hp actor.max-hp)
                   [1 0 0 1]))

  (when actor.char
    (love.graphics.setColor actor.color)
    (local s (or actor.char-scale 1))
    (love.graphics.printf actor.char x y 51 :center 0 s s 25 11))

  (when actor.meters
    (each [_ meter (pairs actor.meters)]
      (let [value (. actor meter.value-field)
            max (. actor meter.max-field)
            pos (if (= meter.pos :follow)
                    [(vec2-op + [x y] [0 -10])]
                    meter.pos)]
        (draw.progress [pos meter.size] (/ value max) meter.color))))

  (match actor.show-line
    (where {: color : len &as line})
    (draw.ray [x y] [actor.angle len] (or line.thickness 1) color)
    some_other
    (do
      (print (.. "Warning: invalid line for " actor.kind ": "))
      (pp some_other)))

  (when actor.draw
    (actor.draw s actor)))

(fn dungeon.log [s msg]
  (table.insert s.log msg))

dungeon

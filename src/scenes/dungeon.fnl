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

(fn dungeon.size [s]
  (values 800 600))

(fn dungeon.next-level [s]
  (set s.level (+ s.level 1))
  (set s.actors [])
  (table.insert s.log
                (lume.format "Welcome to dungeon level {level}" s))
  (set s.actors-to-spawn [])
  (set s.hurt-tallies {}) ; map of <actor,tally> to combine hp of hits
  (set s.hurt-timers {})  ; map of <actor,timestamp> to combine hp of hits
  (set s.will-delete {})  ; map of <actor,will-delete?> to delete actors
  (set s.actors-seen {})  ; map of <actor,place> where have been seen last
  (set s.time-til-game-over nil)
  (set s.freeze-player-until -100000)
  (let [(polygon actors) (mapgen.generate-level s.level (dungeon.size s))]
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
   (or (> s.freeze-player-until s.elapsed-time) s.time-til-game-over)
   (do                                  ; realtime mode
      (set s.elapsed-time (+ dt s.elapsed-time))
      (dungeon.update-actors s dt))
   (do                                  ; normal (freezy) mode
    (dungeon.update-player s dt)
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
  (set s.player.angle (geom.angle (vec2-op - [x y] s.player.pos))))

(fn dungeon.keypressed [s keycode scancode]
  (when (scene.global-keys.handle-keypressed keycode scancode)
    (lua "return"))

  (match scancode
    (where (or :/ :? :f1))
    (scene.set :dungeon-help s)
    "\\"
    (scene.set :dungeon-messages s)
    (where "." (util.shift-down?))
    (do
      (local distance (geom.distance (vec2-op - s.player.pos s.stairs-down.pos)))
      (when (< distance 20) (dungeon.next-level s)))
    (where (or "." :tab))
    (set s.freeze-player-until (+ s.elapsed-time 0.5))
    :space
    (dungeon.swing-player-sword s)
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
  (match button
   1
     (dungeon.fire-player-bullet s)
   2
     (dungeon.swing-player-sword s)))

(fn dungeon.move-player-to [s newpos]
  (set s.delta-time (+ s.delta-time
                       (/ (geom.distance (vec2-op - newpos s.player.pos))
                          s.player.speed)))
  (dungeon.actor-look-at-pos s.player (scene.get-mouse-position))
  (vision.update-visible s.border-seen s.player.pos s.level-border)
  (set s.player.pos newpos))

(fn dungeon.freeze-player [s duration]
  (set s.freeze-player-until (+ s.elapsed-time duration)))

(fn dungeon.fire-player-bullet [s]
  (dungeon.actor-try-stamina-action
   s.player
   s.player.bullet-stamina-cost
   (lambda []
     (dungeon.spawn-actor s
                          :bullet
                          s.player.pos
                          s.player.angle
                          true
                          s.player.bullet-atk))))

(fn dungeon.swing-player-sword [s]
  (dungeon.actor-try-stamina-action
   s.player
   s.player.melee-stamina-cost
   (lambda []
     (dungeon.freeze-player s 0.2)
     (dungeon.spawn-actor
      s
      :sword
      s.player.pos
      s.player.angle
      true
      s.player.melee-atk
      {:duration 0.2}))))

(fn dungeon.actor-step-forward [actor dt ?level-boundary]
  (let [step [(geom.polar->rectangular
               actor.angle
               (* dt actor.speed))]
        next-pos [(vec2-op + actor.pos step)]
        in-bounds (or (not ?level-boundary)
                      (geom.point-in-polygon? next-pos ?level-boundary))]
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

(fn dungeon.nearest-actor [s actor]
  (local tangible-actors
         (icollect [i v (ipairs s.actors)]
           (and v.hitbox v)))
  (util.max-by-score
   tangible-actors
   #(- (geom.distance (vec2-op - actor.pos (. $1 :pos))))
   actor))

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
    :damage-number
    (let [(pos friendly? atk) ...
          random-offset (lambda [] (- (* (math.random) 20) 10))
          pos [(vec2-op + pos [(random-offset) (random-offset)])]
          num (if (< atk 1)
                  (.. "." (math.floor (* atk 10)))
                  (math.floor atk))]
      (dungeon.spawn-actor s :particle pos (/ math.pi -2)
                           {:color (if friendly? [1 0.5 0.5 1] [1 0 0 1])
                            :lifetime 1
                            :speed 30
                            :char num
                            :char-scale 0.5}))))

(fn dungeon.spawn-actor [s kind ...]
  (dungeon.insert-actor s
   (case kind
     :player
     (let [pos ...]
       {: kind
        :name "player"
        : pos
        :friendly? true
        :always-visible? true
        :vision? true
        :color [1 1 1]
        :char "@"
        :char-scale 1.3
        :angle 0
        :speed 120
        :hp 3
        :max-hp 4
        :hide-hp? true
        :stamina 5
        :max-stamina 10
        :stamina-regen-rate 5
        :bullet-stamina-cost 8
        :bullet-atk 5
        :melee-stamina-cost 3
        :melee-atk 10
        :hitbox {:size 8 :shape :circle}
        :show-line {:color [1 1 1 0.3]
                    :len 100}
        :meters {:health
                 {:pos [20 560]
                  :size [100 20]
                  :value-field :hp
                  :max-field :max-hp
                  :color [.9 0 0 1]}
                 :stamina
                 {:pos [140 560]
                  :size [100 20]
                  :follow false
                  :value-field :stamina
                  :max-field :max-stamina
                  :color [0 .7 0 1]}}})
     :bullet
     (let [(pos angle friendly? atk) ...]
        {: kind
         :name "bullet"
         : friendly?
         : pos
         : angle
         :color [1 0 0]
         :show-line {:color [1 0 0] :len 6}
         : atk
         :speed 300})
     :sword
     (let [(pos angle friendly? atk props) ...
           arc-len (or props.arc-len (/ math.pi 4))
           duration (or props.duration 0.2)
           angle (- angle (/ arc-len 2))
           len (or props.len 30)
           rotate-speed (/ arc-len duration)
           expiry (+ s.elapsed-time duration)]
       {: kind
        :name "sword"
        : pos
        : angle
        : friendly?
        : atk
        :enemy? (not friendly?)
        :hitbox {:shape :line :size len}
        :color [1 0 0 1]
        :always-visible? true
        : rotate-speed
        : expiry})
     :killer-tomato
     (let [(pos ?generation) ...]
       {: kind
        :name "killer tomato"
        : pos
        :enemy? true
        :color [1 0 0]
        :char "t"
        :hp 3
        :max-hp 3
        :atk 6
        :hitbox {:size 8 :shape :circle}
        :generation (or ?generation 1)
        :seed-timer nil
        :seed-count 0})

     :tomato-seed
     (let [(pos generation) ...
           seed {: kind
                 :name "tomato seed"
                 : pos
                 :char "•"
                 :color [0 1 0]
                 :expiry (+ s.elapsed-time (+ 1 (math.random)))
                 :on-expiry (fn [s actor]
                              (table.insert s.log "The tomato seed has grown into a killer tomato!")
                              (dungeon.spawn-actor s
                                                   :killer-tomato
                                                   actor.pos
                                                   generation))
                 :speed 50}]
       (dungeon.actor-look-at-pos seed (unpack s.player.pos))
       (dungeon.actor-step-forward seed 1 s.level-boundary)
       seed)
     :grid-bug
     (let [pos ...]
       {: kind
        :name "Gridbug"
        : pos
        :enemy? true
        :color [(lume.color "#811A74")]
        :char "x"
        :char-scale 0.8
        :hp 1
        :max-hp 1
        :atk 2
        :speed 50
        :angle 0
        :ai {:kind :random}
        :hitbox {:size 4 :shape :circle}})
     :gold-coin
     (let [pos ...]
       {: kind
        :name "gold coin"
        : pos
        :color [1 0.8 0 1]
        :char "o"
        :char-scale 1
        :hitbox {:size 5 :shape :circle}
        :collect {:money 1}})
     :stairs-down
     (let [pos ...]
       {: kind
        :name "downward staircase"
        : pos
        :color [1 0.7 0 1]
        :char ">"
        :hitbox {:size 8 :shape :circle}})
     :particle
     (let [(pos angle props) ...]
       {: kind
        :name "particle"
        : angle
        : pos
        :always-visible? true
        :color props.color
        :char props.char
        :char-scale props.char-scale
        :show-line props.show-line
        :expiry (+ s.elapsed-time props.lifetime)
        :speed props.speed})
     _
     (error (.. "Unknown Actor kind: " kind)))))

(fn dungeon.collide-actors [s actor other dt]
  (match [actor.collect other]
    (where [{:money value} s.player])
    (do
      (set s.stats.money (+ s.stats.money value))
      (table.insert
       s.log
       (.. "You collected a " actor.name " worth $" value))
      (dungeon.delete-actor s actor)
      (lua "return")))
  (when (and
         actor.atk
         (= actor.friendly? other.enemy?))
    (local dmg (* actor.atk dt))
    (table.insert
     s.log
     (match actor.kind
       :sword
       (.. "You slash at the " other.name ".")
       (where _ (not= other.kind :sword))
       (.. "The " actor.name " hurts you.")))
    (dungeon.damage-actor s other dmg)))
;;; damage-actor returns nil.
(fn dungeon.damage-actor [s actor atk]
  (var msg nil)
  (when actor.hp
    (set actor.hp (- actor.hp atk))
    (tset s.hurt-tallies actor (+ (or (. s.hurt-tallies actor) 0) atk))
    (tset s.hurt-timers actor (/ 1 20))
    (when (< actor.hp 0)
      (dungeon.spawn-particles s :circle actor.pos {:color actor.color :count 20})
      (match actor.kind
        :player
        (do
          (set s.time-til-game-over (+ s.elapsed-time 2))
          (set s.msg "You died!"))
        monster
        (do
          (tset s.stats.vanquished actor.name (+ 1 (or (. s.stats.vanquished actor.name)
                                                       0)))
          (set msg (.. "The " actor.name " is destroyed."))))
      (dungeon.delete-actor s actor)))
  (when msg
    (table.insert s.log msg))
  nil)

(fn dungeon.insert-actor [s {: kind &as props}]
  (table.insert s.actors-to-spawn props)
  (if
   (= kind :player) (set s.player props)
   (= kind :stairs-down) (set s.stairs-down props))
  props)

(fn dungeon.delete-actor [s actor]
  (tset s.will-delete actor true))

(fn dungeon.update-actors [s dt]
  (each [i {: kind &as actor} (ipairs s.actors)]
    ;; hitboxes
    (when actor.hitbox
      (each [_ other (ipairs s.actors)]
        (when (and
               (not= actor other)
               other.hitbox
               (collide.actors-collide? actor other))
          (dungeon.collide-actors s actor other dt))))

    ;; automatic death
    (when (and actor.expiry
               (< actor.expiry s.elapsed-time))
      (when actor.on-expiry (actor.on-expiry s actor))
      (dungeon.delete-actor s actor))

    ;; ai
    (local ai actor.ai)
    (case (?. ai :kind)
      :random
      (do
        (let [did-step (dungeon.actor-step-forward actor dt s.level-border)]
          (when (or (not did-step)
                    (not ai.target)
                    (> s.elapsed-time ai.next-target-time))
            (set ai.target [(mapgen.random-point-in-polygon s.level-border)])
            (set ai.next-target-time (+ s.elapsed-time (love.math.random)))
            (dungeon.actor-look-at-pos actor (unpack ai.target))))))

    ;; dedicated update code
    (case kind
      :player
      (do
        (set s.player.stamina
             (math.min
              s.player.max-stamina
              (+ s.player.stamina (* dt s.player.stamina-regen-rate)))))
      :killer-tomato
      (do
        (if (and (< actor.generation 3)
                 (< actor.hp actor.max-hp)
                 (< actor.seed-count 3))
            (if
             (not actor.seed-timer)
             (do
               (set actor.seed-timer (+ s.elapsed-time
                                        (/ (math.random 50 100) 128))))
             (< actor.seed-timer s.elapsed-time)
             (do
               (set actor.seed-timer nil)
               (set actor.seed-count (+ 1 actor.seed-count))
               (table.insert s.log "The killer tomato has propagated a tomato seed...")
               (dungeon.spawn-actor s :tomato-seed actor.pos (+ 1 actor.generation))))))
      :particle
      (do
        (dungeon.actor-step-forward actor dt))
      :sword
      (do
        (set actor.angle (+ actor.angle (* dt actor.rotate-speed))))
      :bullet
      (do
        (let [step [(geom.polar->rectangular
                     actor.angle
                     (* dt actor.speed))]
              next-pos [(vec2-op + actor.pos step)]
              movement-lineseg [actor.pos next-pos]
              collision-point [(geom.lineseg-polygon-intersection
                                movement-lineseg
                                s.level-border)]]
          (when (. collision-point 1)
              (dungeon.delete-actor s actor))
          (each [_ other (ipairs s.actors)]
            (when (and other.hitbox
                       (not= actor.friendly? other.friendly?)
                       (geom.lineseg-in-circle? movement-lineseg
                                                [other.pos other.hitbox.size]))
              (table.insert s.log (.. "You shot the " other.name))
              (dungeon.damage-actor s other actor.atk)
              (dungeon.delete-actor s actor)))
          (set actor.pos next-pos))))))

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

(fn dungeon.draw-actor [s {: kind &as actor} ?last-seen-at]
  (local [x y] (or ?last-seen-at actor.pos))
  (case (?. actor :hitbox :shape)
    :circle
    (do
      (love.graphics.setColor (if (. s.hurt-tallies actor)
                                  [1 0 0 1]
                                  [1 1 1 0.2]))
      (love.graphics.setLineWidth 2)
      (love.graphics.circle :line x y (- actor.hitbox.size 1)))
    :line
    (do
      (draw.ray [x y] [actor.angle actor.hitbox.size] 1 [1 1 1 0.2])))
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
    (where {: color : len})
    (draw.ray [x y] [actor.angle len] 1 color)
    some_other
    (do
      (print (.. "Warning: invalid line for " actor.kind ": "))
      (pp some_other)))
  (case kind
   :sword
   (do
    (love.graphics.setColor actor.color)
    (love.graphics.arc :fill
                       x y
                       (- actor.hitbox.size 3)
                       (- actor.angle (/ actor.rotate-speed 60))
                       (+ actor.angle (/ actor.rotate-speed 60))
                       20))))

(fn dungeon.update-player [s dt]
  ;; keyboard input
  (let [shift-down? (util.shift-down?)
        key-offsets {:a [-1 0] :h [-1 0] :left [-1 0]
                     :s [0 1] :j [0 1] :down [0 1]
                     :w [0 -1] :k [0 -1] :up [0 -1]
                     :d [1 0] :l [1 0] :right [1 0]}]
    ;; average all the angle inputs
    (let [offset
          (accumulate [pos [0 0]
                       key kpos (pairs key-offsets)]
            (if (love.keyboard.isScancodeDown key)
                [(vec2-op + pos kpos)]
                pos))
          (angle distance) (geom.rectangular->polar (unpack offset))]
      (when (> distance 0)
           (let [speed (* s.player.speed dt (if shift-down? 0.2 1))
                 offset [(geom.polar->rectangular
                          angle
                          speed)]
                 next-pos [(vec2-op + offset s.player.pos)]]
             (if (geom.point-in-polygon? next-pos s.level-border)
                 (dungeon.move-player-to s next-pos)))))))

dungeon

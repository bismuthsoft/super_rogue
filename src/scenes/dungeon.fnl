(import-macros {: vec2-op} :geom-macros)
(local scene (require :scene))
(local geom (require :geom))
(local util (require :util))
(local draw (require :draw))
(local collide (require :collide))
(var mapgen (require :mapgen))
(local lume (require :lib.lume))
(local pp util.pp)

(local dungeon {})

(fn dungeon.init []
  (let [state {:level 0}]
    (dungeon.next-level state)
    state))

(fn dungeon.next-level [s]
  (set s.level (+ s.level 1))
  (set s.actors [])
  (set s.actors-to-spawn [])
  (set s.will-delete {})
  (set s.elapsed-time 0)
  (set s.delta-time 0)
  (set s.time-til-menu nil)
  (set s.freeze-player-until -100000)
  (let [(polygon actors) (mapgen.generate-level s.level)]
    (set s.level-border polygon)
    (each [_ args (ipairs actors)]
      (dungeon.spawn-actor s (unpack args)))))

(fn dungeon.update [s dt]
  (match s.time-til-menu
    (where ttm (< ttm s.elapsed-time)) (scene.pop)
    (where ttm) (set s.delta-time (+ s.delta-time (* 10 dt))))

  ;; add actors
  (each [_ actor (ipairs s.actors-to-spawn)]
    (table.insert s.actors actor)
    (set s.actors-to-spawn []))

  (if
   (> s.freeze-player-until s.elapsed-time)
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
  (draw.polygon s.level-border)
  (dungeon.draw-actors s)

  (love.graphics.setColor [1 1 1 1])
  (love.graphics.print (lume.format "elapsed-time {elapsed-time}" s) 10 10))

(fn dungeon.mousemoved [s x y]
  (set s.player.angle (geom.angle (vec2-op - [x y] s.player.pos))))

(fn dungeon.keypressed [s keycode scancode]
  (when (= scancode :space)
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
  ;; DEBUG
  (when (= scancode :f5)
        (tset package.loaded :mapgen nil)
        (let [(status err) (pcall
                            (lambda []
                              (set mapgen (require :mapgen))
                              (dungeon.next-level s)))]
          (if (= status false)
              (print (.. "ERROR: failed to reload map. " err)))))
  (when (= scancode :f6)
    (pp s.level-border)))

(fn dungeon.mousepressed [s x y button]
  (dungeon.actor-try-stamina-action
   s.player
   s.player.bullet-stamina-cost
   (lambda []
     (dungeon.spawn-actor s :bullet s.player.pos s.player.angle true))))

(fn dungeon.move-player-to [s newpos]
  (set s.delta-time (+ s.delta-time
                       (/ (geom.distance (vec2-op - newpos s.player.pos))
                          s.player.speed)))
  (dungeon.actor-look-at-pos s.player (love.mouse.getPosition))
  (set s.player.pos newpos))

(fn dungeon.freeze-player [s duration]
  (set s.freeze-player-until (+ s.elapsed-time duration)))

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
          lifetime 100
          speed (or props.speed 500)]
      (tset color 4 0.5)
      (for [i 1 count]
        (dungeon.spawn-actor s :particle pos i
                             {: color
                              : lifetime
                              :speed (* speed (+ 1 (math.random)))})))))

(fn dungeon.spawn-actor [s kind ...]
  (dungeon.insert-actor s
   (case kind
     :player
     (let [pos ...]
       {: kind
        : pos
        :friendly? true
        :color [1 1 1]
        :char "@"
        :angle 0
        :speed 120
        :hp 3
        :max-hp 4
        :hide-hp? true
        :stamina 5
        :max-stamina 10
        :stamina-regen-rate 5
        :bullet-stamina-cost 8
        :melee-stamina-cost 3
        :melee-atk 10
        :hitbox {:size 8 :shape :circle}
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
     (let [(pos angle friendly?) ...]
        {: kind
         : friendly?
         : pos
         : angle
         :color [1 0 0]
         :atk 5
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
        : pos
        : angle
        : friendly?
        : atk
        :enemy? (not friendly?)
        :hitbox {:shape :line :size len}
        :color [1 0 0 1]
        : rotate-speed
        : expiry})
     :particle
     (let [(pos angle props) ...]
       {: kind
        : angle
        : pos
        :color props.color
        :expiry (+ s.elapsed-time props.lifetime)
        :speed props.speed})
     :killer-tomato
     (let [pos ...]
       {: kind
        : pos
        :enemy? true
        :color [1 0 0]
        :char "t"
        :hp 3
        :max-hp 3
        :atk 6
        :hitbox {:size 8 :shape :circle}})
     :grid-bug
     (let [pos ...]
       {: kind
        : pos
        :enemy? true
        :color [(lume.color "#811A74")]
        :char "x"
        :hp 1
        :max-hp 1
        :atk 2
        :speed 50
        :angle 0
        :ai {:kind :random}
        :hitbox {:size 4 :shape :circle}})
     _
     (error (.. "Unknown Actor kind" kind)))))

(fn dungeon.insert-actor [s {: kind &as props}]
  (table.insert s.actors-to-spawn props)
  (if
   (= kind :player)
   (set s.player props))
  props)

(fn dungeon.delete-actor [s actor]
  (if (= actor s.player)
      (scene.set :menu))
  (tset s.will-delete actor true))

(fn dungeon.update-actors [s dt]
  (each [i {: kind &as actor} (ipairs s.actors)]
    ;; hitboxes
    (when (and actor.hitbox actor.atk)
      (each [_ other (ipairs s.actors)]
        (when (and other.hitbox
                   (not= actor.friendly? other.friendly?)
                   (collide.actors-collide? actor other))
          (dungeon.damage-actor s other (* actor.atk dt)))))

    ;; automatic death
    (when (and actor.expiry
               (< actor.expiry s.elapsed-time))
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
                (dungeon.damage-actor s other actor.atk)
                (dungeon.delete-actor s actor)))
          (set actor.pos next-pos))))))

(fn dungeon.draw-actors [s]
  (each [i {: kind &as actor} (ipairs s.actors)]
    (local [x y] actor.pos)
    (case (?. actor :hitbox :shape)
      :circle
      (do
        (love.graphics.setColor [1 1 1 0.2])
        (love.graphics.circle :line x y actor.hitbox.size))
      :line
      (do
        (draw.ray actor.pos [actor.angle actor.hitbox.size] 1 [1 1 1 0.2])))
    (when (and actor.hp (not actor.hide-hp?) (not (>= actor.hp actor.max-hp)))
      (draw.progress [[(vec2-op - actor.pos [10 15])] [20 5]]
                     (/ actor.hp actor.max-hp)
                     [1 0 0 1]))
    (when actor.char
      (love.graphics.setColor actor.color)
      (love.graphics.printf actor.char x y 21 :center 0 1 1 10 11))
    (when actor.meters
      (each [_ meter (pairs actor.meters)]
        (let [value (. actor meter.value-field)
              max (. actor meter.max-field)
              pos (if (= meter.pos :follow)
                      [(vec2-op + actor.pos [0 -10])]
                      meter.pos)]
          (draw.progress [pos meter.size] (/ value max) meter.color))))
    (case kind
     :player
     (do
       (draw.ray actor.pos [actor.angle 100] 1 [1 1 1 0.3]))
     :bullet
     (do
       (draw.ray actor.pos [actor.angle (/ actor.speed -60)] 1 actor.color))
     :particle
     (do
       (draw.ray actor.pos [actor.angle (/ actor.speed 60)] 1 actor.color))
     :sword
     (do
       (love.graphics.setColor actor.color)
       (love.graphics.arc :fill
                          x y
                          actor.hitbox.size
                          (- actor.angle (/ actor.rotate-speed 30))
                          (+ actor.angle (/ actor.rotate-speed 30)))))))

(fn dungeon.update-player [s dt]
  ;; keyboard input
  (let [shifted? (or (love.keyboard.isDown :lshift) (love.keyboard.isDown :rshift))
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
           (let [speed (* s.player.speed dt (if shifted? 0.2 1))
                 offset [(geom.polar->rectangular
                          angle
                          speed)]
                 next-pos [(vec2-op + offset s.player.pos)]]
             (if (geom.point-in-polygon? next-pos s.level-border)
                 (dungeon.move-player-to s next-pos)))))))

(fn dungeon.damage-actor [s actor atk]
  (when actor.hp
    (set actor.hp (- actor.hp atk))
    (when (< actor.hp 0)
      (dungeon.spawn-particles s :circle actor.pos {:color actor.color :count 20})
      (match actor.kind
        :player (set s.time-til-menu (+ s.elapsed-time 50)))
      (dungeon.delete-actor s actor))))

dungeon

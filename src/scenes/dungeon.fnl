(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util (require :util))
(local draw (require :draw))
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
  (set s.will-delete {})
  (set s.elapsed-time 0)
  (set s.delta-time 0)
  (let [(polygon actors) (mapgen.generate-level s.level)]
    (set s.level-border polygon)
    (each [_ args (ipairs actors)]
      (dungeon.spawn-actor s (unpack args)))))

(fn dungeon.update [s dt]
  (dungeon.update-player s dt)
  (when (> s.delta-time 0)
    (set s.elapsed-time (+ s.delta-time s.elapsed-time))
    (dungeon.update-actors s s.delta-time)
    (set s.delta-time 0)))

(fn dungeon.draw [s]
  (love.graphics.setColor 1 1 1 1)
  (dungeon.draw-polygon s.level-border)
  (dungeon.draw-actors s)

  (love.graphics.setColor [1 1 1 1])
  (love.graphics.print (lume.format "elapsed-time {elapsed-time}" s) 10 10))

(fn dungeon.mousemoved [s x y]
  (set s.player.angle (geom.angle (vec2-op - [x y] s.player.pos))))

(fn dungeon.keypressed [s keycode scancode]
  ;; DEBUG
  (when (= scancode :f5)
      (tset package.loaded :mapgen nil)
      (set mapgen (require :mapgen))
      (dungeon.next-level s)))

(fn dungeon.mousepressed [s x y button]
  (when (> s.player.stamina s.player.bullet-stamina-cost)
    (set s.player.stamina (- s.player.stamina s.player.bullet-stamina-cost))
    (dungeon.spawn-actor s :bullet s.player.pos s.player.angle true)))

(fn dungeon.move-player-to [s newpos]
  (set s.delta-time (+ s.delta-time
                       (geom.distance (vec2-op - newpos s.player.pos))))
  (set s.player.pos newpos))

(fn dungeon.draw-polygon [polygon]
  (love.graphics.polygon "line" (unpack (util.flatten polygon))))

(fn dungeon.draw-ray [[x y] [angle len]]
  (love.graphics.line
   x y
   (vec2-op + [x y] [(geom.polar->rectangular angle len)])))

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
           speed (or props.speed 5)]
       (tset color 4 0.5)
       (for [i 1 count]
         (dungeon.spawn-actor s :particle pos i {: color
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
        :move-speed 120
        :turn-speed 10
        :hp 3
        :max-hp 4
        :stamina 5
        :max-stamina 10
        :stamina-regen-rate 0.05
        :bullet-stamina-cost 8
        :hitbox {:size 8}
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
         :speed 2})
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
        :atk 0.1
        :hitbox {:size 8}
        :meters {:health
                 {:pos :follow
                  :size [20 5]
                  :value-field :hp
                  :max-field :max-hp
                  :color [.9 0 0 1]}}})
     :grid-bug
     (let [pos ...]
       {: kind
        : pos
        :enemy? true
        :color [(lume.color "#811A74")]
        :char "x"
        :hp 1
        :max-hp 1
        :atk 0.05
        :hitbox {:size 4}})
     _
     (error (.. "Unknown Actor kind" kind)))))

(fn dungeon.insert-actor [s {: kind &as props}]
  (table.insert s.actors props)
  (if
   (= kind :player)
   (set s.player props))
  props)

(fn dungeon.delete-actor [s actor]
  (tset s.will-delete actor true))

(fn dungeon.update-actors [s dt]
  (each [i {: kind &as actor} (ipairs s.actors)]
    (case kind
      :player
      (do
        (set s.player.stamina
             (math.min
              s.player.max-stamina
              (+ s.player.stamina (* dt s.player.stamina-regen-rate)))))
      :particle
      (do
        (let [step [(geom.polar->rectangular
                     actor.angle
                     (* dt actor.speed))]
              next-pos [(vec2-op + actor.pos step)]]
          (set actor.pos next-pos)
          (when (< actor.expiry s.elapsed-time)
            (dungeon.delete-actor s actor))))
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
          (set actor.pos next-pos)))
      (where _ actor.enemy?)
      (do
        (each [_ other (ipairs s.actors)]
          (when (and other.hitbox
                     (not= actor.friendly? other.friendly?)
                     (geom.circle-in-circle? [actor.pos actor.hitbox.size]
                                             [other.pos other.hitbox.size]))
            (dungeon.damage-actor s other (* actor.atk dt)))))))
  (set s.actors
       (icollect [i actor (ipairs s.actors)]
         (if (. s.will-delete actor) nil actor)))
  (set s.will-delete {}))

(fn dungeon.draw-actors [s]
  (each [i {: kind &as actor} (ipairs s.actors)]
    (local [x y] actor.pos)
    (when actor.hitbox
      (love.graphics.setColor [1 1 1 0.2])
      (love.graphics.circle :line x y actor.hitbox.size))
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
       (love.graphics.setColor 1 1 1 0.3)
       (dungeon.draw-ray actor.pos [actor.angle 100]))
     :bullet
     (do
       (love.graphics.setColor actor.color)
       (dungeon.draw-ray actor.pos [actor.angle (* 10 actor.speed)]))
     :particle
     (do
       (love.graphics.setColor actor.color)
       (dungeon.draw-ray actor.pos [actor.angle (* 2 actor.speed)])))))

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
           (let [move-speed (* s.player.move-speed dt (if shifted? 0.2 1))
                 offset [(geom.polar->rectangular
                          angle
                          move-speed)]
                 next-pos [(vec2-op + offset s.player.pos)]]
             (set s.player.will-move-to next-pos)
             (if (geom.point-in-polygon? next-pos s.level-border)
                 (dungeon.move-player-to s next-pos)))))))

(fn dungeon.damage-actor [s actor atk]
  (when actor.hp
    (set actor.hp (- actor.hp atk))
    (when (< actor.hp 0)
      (dungeon.spawn-particles s :circle actor.pos {:color actor.color :count 20})
      (dungeon.delete-actor s actor))))

dungeon

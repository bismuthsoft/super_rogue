(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util (require :util))
(local draw (require :draw))
(local lume (require :lib.lume))
(local pp util.pp)

(local dungeon {})

(fn dungeon.init []
  (let [state
        {:level-border (dungeon.generate-map)
         :actors []
         :will-delete {}
         :delta-time 0
         :time-rate 10}]
   (dungeon.add-actor
    state
    {:kind :player
     :color [1 1 1]
     :char "@"
     :pos [300 300]
     :angle 0
     :moved-by 0
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
   (dungeon.add-actor
    state
    {:kind :turret
     :color [0 1 0]
     :char "t"
     :pos [300 500]
     :hp 3
     :max-hp 3
     :hitbox {:size 8}
     :meters {:health
              {:pos :follow
               :size [20 5]
               :value-field :hp
               :max-field :max-hp
               :color [.9 0 0 1]}}})
   state))

(fn dungeon.update [s dt]
  (dungeon.update-player s dt)
  (dungeon.update-actors s s.delta-time)
  (set s.delta-time 0))

(fn dungeon.draw [s]
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print s.player.moved-by 10 10)
  (dungeon.draw-polygon s.level-border)
  (dungeon.draw-actors s))

(fn dungeon.mousemoved [s x y]
  (set s.player.angle (geom.angle (vec2-op - [x y] s.player.pos))))

(fn dungeon.mousepressed [s x y button]
  (when (> s.player.stamina s.player.bullet-stamina-cost)
    (set s.player.stamina (- s.player.stamina s.player.bullet-stamina-cost))
    (dungeon.add-actor s {:kind :bullet
                          :friendly? true
                          :pos s.player.pos
                          :color [1 0 0]
                          :angle s.player.angle
                          :atk 5
                          :speed 2})))

(fn dungeon.generate-map []
  (geom.polygon {:sides 3 :origin [400 300] :size 300}))

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

(fn dungeon.add-actor [s {: kind &as props}]
  (table.insert s.actors props)
  (if
   (= kind :player)
   (do
    (when s.player
      (error "Attempt to add second player"))
    (set s.player props)))
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
                       (not= actor.friendly? (= other s.player))
                       (geom.lineseg-in-circle? movement-lineseg
                                                [other.pos other.hitbox.size]))
                (dungeon.damage-actor s other actor.atk)
                (dungeon.delete-actor s actor)))
          (set actor.pos next-pos)))))
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
       (love.graphics.setColor 1 1 1 0.5)
       (dungeon.draw-ray actor.pos [actor.angle 100]))
     :bullet
     (do
       (love.graphics.setColor actor.color)
       (dungeon.draw-ray actor.pos [actor.angle (* 10 actor.speed)])))))

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
           (let [move-speed (* s.player.move-speed dt (if shifted? 10 1))
                 offset [(geom.polar->rectangular
                          angle
                          (* s.player.move-speed dt))]
                 next-pos [(vec2-op + offset s.player.pos)]]
             (set s.player.will-move-to next-pos)
             (if (geom.point-in-polygon? next-pos s.level-border)
                 (dungeon.move-player-to s next-pos)))))))

(fn dungeon.damage-actor [s actor atk]
  (when actor.hp
    (set actor.hp (- actor.hp atk))
    (when (< actor.hp 0)
      (dungeon.delete-actor s actor))))

dungeon
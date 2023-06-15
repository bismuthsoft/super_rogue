(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local dungeon (require :scenes.dungeon))
(local scene (require :scene)) ; used for HACK to get mouse pos
(local vision (require :vision))
(local util (require :util))

(local player {})

(fn player.spawn [s pos]
  {
   :kind "player"
   :name "player"
   :update player.update
   :realtime-update player.realtime-update
   :keypressed player.keypressed
   :mousemoved player.mousemoved
   :mousepressed player.mousepressed
   : pos
   :friendly? true
   :always-visible? true
   :vision? true
   :color [1 1 1]
   :char "@"
   :char-scale 1.3
   :angle 0
   :speed 90
   :hp 3
   :max-hp 4
   :hide-hp? true
   :stamina 5
   :max-stamina 10
   :stamina-regen-rate 5
   :bullet-stamina-cost 6
   :bullet-atk 80
   :melee-stamina-cost 3
   :melee-atk 20
   :movement-cost 2
   :freeze-until 0
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

(fn player.update [s actor dt]
  (set actor.stamina
       (math.min
        actor.max-stamina
        (+ actor.stamina (* dt actor.stamina-regen-rate)))))

(fn player.realtime-update [s actor dt]
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
           (let [speed (* actor.speed dt (if shift-down? 0.2 1))
                 offset [(geom.polar->rectangular
                          angle
                          speed)]
                 next-pos [(vec2-op + offset actor.pos)]]
             (if (geom.point-in-polygon? next-pos s.level-border)
                 (player.move-to s actor next-pos)))))))

(fn player.keypressed [s actor scancode]
  (match scancode
    (where "." (util.shift-down?))
    (do
      (local distance (geom.distance (vec2-op - actor.pos s.stairs-down.pos)))
      (when (< distance 20) (dungeon.next-level s))
      true)
    (where (or "." :tab))
    (do
      (set actor.freeze-until (+ s.elapsed-time 0.5))
      true)
    :space
    (do
      (player.swing-sword s actor))
    _
    false))

(fn player.mousepressed [s actor x y button]
  (match button
   1
     (player.fire-bullet s actor)
   2
     (player.swing-sword s actor)))

(fn player.mousemoved [s actor x y]
  (set actor.angle (geom.angle (vec2-op - [x y] actor.pos))))

(fn player.move-to [s actor newpos]
  (set s.delta-time (+ s.delta-time
                       (/ (geom.distance (vec2-op - newpos actor.pos))
                          actor.speed)))
  (set actor.stamina (- actor.stamina (* actor.movement-cost
                                         s.delta-time)))
  (dungeon.actor-look-at-pos actor (scene.get-mouse-position))
  (vision.update-visible s.border-seen actor.pos s.level-border)
  (set actor.pos newpos))

(fn player.freeze [s actor duration]
  (set actor.freeze-until (+ s.elapsed-time duration)))

(fn player.swing-sword [s actor]
  (dungeon.actor-try-stamina-action
   actor
   actor.melee-stamina-cost
   (lambda []
     (player.freeze s actor 0.2)
     (dungeon.spawn-actor
      s
      :sword
      actor.pos
      actor.angle
      true
      actor.melee-atk
      {:duration 0.2}))))

(fn player.fire-bullet [s actor dt]
  (dungeon.actor-try-stamina-action
   actor
   actor.bullet-stamina-cost
   (lambda []
     (dungeon.spawn-actor s
                          :bullet
                          actor.pos
                          actor.angle
                          true
                          actor.bullet-atk
                          {}))))

player

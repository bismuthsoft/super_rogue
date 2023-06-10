(import-macros {: vec2-op} :geom-macros)
(local dungeon (require :scenes.dungeon))
(local vision (require :vision))
(local geom (require :geom))
(local leprechaun {})

(fn leprechaun.spawn [s pos]
  {
   :kind "leprechaun"
   :name "Leprechaun"
   :update leprechaun.update
   : pos
   :enemy? true
   :color [.2 1 .2 1]
   :char "l"
   :hp 5
   :max-hp 5
   :atk 5
   :hitbox {:size 8 :shape :circle}
   :speed 30
   :angle 0
   :target-timer s.elapsed-time
   :bullet-timer nil})

(fn leprechaun.update [s actor dt]
  (if
   (not actor.bullet-timer)
   (set actor.bullet-timer
        (+ s.elapsed-time
         (/ (math.random 50 100) 64)))
   (< actor.bullet-timer s.elapsed-time)
   (do
     (set actor.bullet-timer nil)
     (when (vision.see-between-points? actor.pos s.player.pos s.level-border)
           (dungeon.spawn-actor s
                                :bullet
                                actor.pos
                                (geom.angle (vec2-op - s.player.pos actor.pos))
                                false
                                10
                                {:speed 100
                                 :color [0.8 0.8 0.5 1]
                                 :name "Leprechaun Dagger"
                                 :expiry (+ s.elapsed-time 2)}))))
  (if
   (not actor.target-timer)
   (do
     (set actor.target-timer (+ s.elapsed-time
                                (/ (math.random 40 80) 64))))
   (< actor.target-timer s.elapsed-time)
   (do
     (set actor.target-timer nil)
     (let [coin
           (dungeon.find-nearest-visible s actor :gold-coin)
           stairs
           (dungeon.find-nearest-visible s actor :stairs-down)
           behind-player
           [(vec2-op +
                     s.player.pos
                     [(geom.polar->rectangular s.player.angle -300)])]]
       (set actor.speed (if (or coin stairs) 50 85))
       (dungeon.actor-look-at-pos actor (unpack
                                         (if
                                          stairs stairs.pos
                                          coin coin.pos
                                          behind-player)))
       (set actor.angle (+ actor.angle (* 0.4 (math.random))))))
   (do
     (when (not (dungeon.actor-step-forward actor dt s.level-border))
       (set actor.target-timer s.elapsed-time)))))

leprechaun

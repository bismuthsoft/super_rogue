(local geom (require :geom))
(local util (require :util))
(local lume (require :lib.lume))
(local pp util.pp)
(import-macros {: vec2-op} :geom-macros)
(local dungeon {})

(fn dungeon.init []
  (let [state
        {:level-border (dungeon.generate-map)
         :actors []}]
    (set state.player
         (dungeon.add-actor state
          {:type :player
           :pos [300 300]
           :facing 0
           :moved-by 0
           :move-speed 120
           :turn-speed 10}))
    state))

(fn dungeon.update [s dt]
  (dungeon.update-actors s dt))

(fn dungeon.draw [s]
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print s.player.moved-by 10 10)
  (dungeon.draw-polygon s.level-border)
  (dungeon.draw-ray s.player.pos [s.player.facing 100])

  (love.graphics.print (collectgarbage :count))
  (love.graphics.print "@" (vec2-op - s.player.pos [5 10])))

(fn dungeon.mousemoved [s x y]
  (set s.player.facing (geom.angle (vec2-op - [x y] s.player.pos))))

(fn dungeon.generate-map []
  (geom.polygon {:sides 3 :origin [400 300] :size 300}))

(fn dungeon.move-player-to [player newpos]
  (set player.moved-by (geom.distance (vec2-op - newpos player.pos)))
  (set player.pos newpos))

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

(fn dungeon.add-projectile [s {: pos : angle : speed &as props}]
  (dungeon.add-actor s (lume.merge {:type :player-bullet} props)))

(fn dungeon.add-actor [s {: type &as props}]
  (table.insert s.actors props)
  props)

(fn dungeon.update-actors [s dt]
  (each [i {: type &as actor} (ipairs s.actors)]
    (if (= type :player) (dungeon.update-player s actor dt))))

(fn dungeon.update-player [s player dt]
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
           (let [move-speed (* player.move-speed dt (if shifted? 10 1))
                 offset [(geom.polar->rectangular
                          angle
                          (* player.move-speed dt))]
                 next-pos [(vec2-op + offset player.pos)]]
             (set player.will-move-to next-pos)
             (if (geom.point-in-polygon? next-pos s.level-border)
                 (dungeon.move-player-to player next-pos)))))))

dungeon

(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util (require :util))
(local lume (require :lib.lume))
(local pp util.pp)

(local f {}) ;; game functions -- put into table so that hoisting is not needed

(fn f.initial-state []
  {:player-pos [300 300]
   :player-moved-by 0
   :level-border (f.generate-map)})

(fn f.generate-map []
  (geom.polygon {:sides 3 :origin [400 300] :size 300}))

(fn f.update [s dt]
  (let [mouse-pos [(love.mouse.getPosition)]]
    (if (love.mouse.isDown 1)
        (let [next-pos (f.step-towards s.player-pos mouse-pos (* dt 120))]
         (if (geom.point-in-polygon? next-pos s.level-border)
           (do
            (set s.player-moved-by (geom.distance (vec2-op - next-pos s.player-pos)))
            (set s.player-pos next-pos)))))))

(fn f.draw [s]
  (love.graphics.setColor 1 1 1 1)
  (love.graphics.print s.player-moved-by 10 10)
  (f.draw-polygon s.level-border)
  (f.draw-ray s.player-pos [0 100])

  (love.graphics.print (collectgarbage :count))
  (love.graphics.print "@" (vec2-op - s.player-pos [5 10])))

(fn f.fill-circle [[x y] size]
  (love.graphics.circle "fill" x y size size))

(fn f.draw-polygon [polygon]
  (love.graphics.polygon "line" (unpack (util.flatten polygon))))

(fn f.draw-ray [[x y] [angle len]]
  (love.graphics.line
   x y
   (vec2-op + [x y] [(geom.polar->rectangular angle len)])))

;; move a 'step' pixels towards b, return the result
(fn f.step-towards [a b step]
  (let [(dx dy) (vec2-op - a b)
        (angle distance) (geom.rectangular->polar dx dy)]
    (if (< distance step)
        ;; too close to goal -- just teleport to goal
        b
        (let [step-vec [(geom.polar->rectangular angle step)]]
          [(vec2-op - a step-vec)]))))

(var s {}) ;; game state all contained in here

(fn love.load []
  (table.remove arg 1)  ;; game directory or .love file
  (while (> (length arg) 0)
    (match (. arg 1)
      "--test"
      (let [tests (require :tests)]
        (table.remove arg 1)
        (tests.entrypoint))))
  (set s (f.initial-state)))

(fn love.update [dt] (f.update s dt))

(fn love.draw [] (f.draw s))

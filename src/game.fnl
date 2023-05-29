(local pp #((. (require :lib.fennel) :view) $1))
(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))

(local f {}) ;; game functions -- put into table so that hoisting is not needed
(var s nil) ;; game state all contained in here

(fn f.generate-map []
  {:player-pos [300 300]})

(fn love.load []
  (set s (f.generate-map)))

(fn love.update [dt]
  (let [mouse-pos [(love.mouse.getPosition)]]
    (if (love.mouse.isDown 1)
        (set s.player-pos
             (f.step-towards s.player-pos mouse-pos 2)))))

(fn love.draw []
  (love.graphics.print (collectgarbage :count))
  (love.graphics.print "@" (unpack s.player-pos)))

;; move a 'step' pixels towards b, return the result
(fn f.step-towards [a b step]
  (let [(dx dy) (vec2-op - a b)
        (angle distance) (geom.rectangular->polar dx dy)]
    (if (< distance step)
        ;; too close to goal -- just teleport to goal
        b
        (let [step-vec [(geom.polar->rectangular angle step)]]
          [(vec2-op - a step-vec)]))))

(local pp #((. (require :lib.fennel) :view) $1))
(local {: Vec2 : PolarVec2} (require :Vec))

(local f {}) ;; game functions -- put into table so that hoisting is not needed
(var s nil) ;; game state all contained in here

(fn f.generate-map []
  {:player-pos (Vec2 300 300)})

(fn love.load []
  (set s (f.generate-map)))

(fn love.update [dt]
  (let [mouse-pos (Vec2 (love.mouse.getPosition))]
    (if (love.mouse.isDown 1)
        (set s.player-pos
             (f.step-towards s.player-pos mouse-pos)))))

(fn love.draw []
  (love.graphics.print (collectgarbage :count))
  (love.graphics.print "@" (s.player-pos:unpack)))

(fn f.step-towards [p1 p2]
  (let [min-step 2
        difference (- p1 p2)
        {:r distance} (PolarVec2 difference)]
    (if (< distance min-step)
        p2
        (- p1 (/ (* difference min-step) distance)))))

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
             (f.step-towards s.player-pos mouse-pos)))))

(fn love.draw []
  (love.graphics.print (collectgarbage :count))
  (love.graphics.print "@" (unpack s.player-pos)))

(fn f.step-towards [p1 p2]
  (let [min-step 2
        [x1 y1] p1
        [x2 y2] p2
        (dx dy) (values (- x2 x1) (- y2 y1))
        (_ distance) (f.rectangular-to-polar dx dy)]
    (if (< distance min-step)
        p2
        [(+ x1 (/ (* dx min-step) distance))
         (+ y1 (/ (* dy min-step) distance))])))

(fn f.rectangular-to-polar [x y]
  (values (math.atan2 y x)              ;; angle
          (^ (+ (^ y 2) (^ x 2)) 0.5))) ;; distance

(fn f.polar-to-rectangular [angle distance]
  (values (* distance (math.cos angle))
          (* distance (math.sin angle))))

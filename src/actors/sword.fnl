(local sword {})

(fn sword.spawn [s pos angle friendly? atk props]
  (let [
        arc-len (or props.arc-len (/ math.pi 4))
        duration (or props.duration 0.2)
        angle (- angle (/ arc-len 2))
        len (or props.len 30)
        rotate-speed (/ arc-len duration)]
    {
     :kind "sword"
     :name "your sword"
     :update sword.update
     :draw sword.draw
     : pos
     : angle
     : friendly?
     : atk
     :enemy? (not friendly?)
     :hitbox {:shape :line :size len}
     :color [1 0 0 1]
     :always-visible? true
     : rotate-speed
     :lifetime duration}))

(fn sword.update [s actor dt]
  (set actor.angle (+ actor.angle (* dt actor.rotate-speed))))

(fn sword.draw [s actor]
  (love.graphics.setColor actor.color)
  (local [x y] actor.pos)
  (love.graphics.arc
   :fill
   x y
   (- actor.hitbox.size 3)
   (- actor.angle (/ actor.rotate-speed 60))
   (+ actor.angle (/ actor.rotate-speed 60))
   20))

sword

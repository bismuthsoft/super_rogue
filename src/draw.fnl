(local draw {})
(local FILL "fill")
(local LINE "line")

(macro with-graphics-context [body ...]
  '(do
     (love.graphics.push "all")
     (let [out# (do ,body ,...)]
       (love.graphics.pop)
       out#)))

(fn draw.progress [rectangle percent color]
  (with-graphics-context
    (love.graphics.setColor (unpack color))
    (love.graphics.rectangle LINE rectangle.x rectangle.y rectangle.width rectangle.height)
    (love.graphics.rectangle FILL rectangle.x rectangle.y (math.floor (* rectangle.width percent)) rectangle.height)))

draw

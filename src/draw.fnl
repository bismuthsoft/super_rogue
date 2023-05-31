(local draw {})

(macro with-graphics-context [body ...]
  '(do
     (love.graphics.push "all")
     (let [out# (do ,body ,...)]
       (love.graphics.pop)
       out#)))

(fn draw.progress [[[x y] [w h]] percent color]
  (with-graphics-context
    (love.graphics.setColor color)
    (love.graphics.rectangle :line x y w h)
    (love.graphics.rectangle :fill x y (* w percent) h)))

draw

(local draw {})
(local geom (require :geom))
(local util (require :util))
(import-macros {: vec2-op} :geom-macros)

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

(fn draw.ray [[x y] [angle len] thickness color]
  (let [(x2 y2) (vec2-op + [x y] [(geom.polar->rectangular angle len)])]
   (with-graphics-context
     (love.graphics.setColor color)
     (love.graphics.setLineWidth thickness)
     (love.graphics.line x y x2 y2))))

(fn draw.ray [[x y] [angle len] thickness color]
  (let [(x2 y2) (vec2-op + [x y] [(geom.polar->rectangular angle len)])]
   (with-graphics-context
     (love.graphics.setColor color)
     (love.graphics.setLineWidth thickness)
     (love.graphics.line x y x2 y2))))

(fn draw.polygon [polygon thickness color]
  (with-graphics-context
    (love.graphics.setColor color)
    (love.graphics.setLineWidth thickness)
    (love.graphics.polygon "line" (unpack (util.flatten polygon)))))

draw

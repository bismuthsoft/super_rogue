(local draw {})
(local geom (require :geom))
(local util (require :util))
(local lume (require :lib.lume))
(import-macros {: vec2-op} :geom-macros)

(macro with-graphics-context [body ...]
  '(do
     (love.graphics.push "all")
     (let [out# (do ,body ,...)]
       (love.graphics.pop)
       out#)))

(macro with-canvas [id args body ...]
  '(let [,id (love.graphics.newCanvas (unpack ,args))]
     (love.graphics.setCanvas ,id)
     (let [out# (do ,body ,...)]
       (love.graphics.setCanvas)
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

(local
 HELP-ENTRIES
 [["/, ?, or F1" "This help menu"]
  ["Spacebar" "Melee attack"]
  ["Left mouse button" "Fire projectile"]
  ["H or Left Arrow" "Move left"]
  ["J or Down Arrow" "Move down"]
  ["K or Up Arrow" "Move up"]
  ["L or Right Arrow" "Move right"]])


(fn draw.help [screen-w screen-h]
  (fn calc-y [index] (+ 50 (* index 25)))
  (local w 450)
  (local h (+ 50 (calc-y (length HELP-ENTRIES))))
  (love.graphics.translate
   (/ (- screen-w w) 2)
   (/ (- screen-h h) 2))

  (love.graphics.setColor .1 .1 .1 .9)
  (love.graphics.rectangle :fill 0 0 w h)
  (love.graphics.setColor [1 1 1 0.5])
  (love.graphics.print "Help (press any key to close)" 25 25)
  (each [i [input description] (ipairs HELP-ENTRIES)]
    (local y (calc-y i))
    (love.graphics.setColor (lume.color "#a020f0"))
    (love.graphics.print input 25 y)
    (love.graphics.setColor [.7 .7 .7 1])
    (love.graphics.print description 250 y)))

draw

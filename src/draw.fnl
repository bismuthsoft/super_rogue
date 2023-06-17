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

(fn draw.get-centered-viewport-transform [x1 y1 x2 y2]
  (let [transform (love.math.newTransform)
        screensize [(love.window.getMode)]
        (vw vh) (vec2-op - [x2 y2] [x1 y1])
        (scalex scaley) (vec2-op / screensize [vw vh])
        scale (math.min scalex scaley)
        realsize [(vec2-op * [scale scale] [vw vh])]
        (ox oy) (vec2-op /           ; offset to center it
                         [(vec2-op - screensize realsize)]
                         [2 2])]
    (transform:translate ox oy)
    (transform:scale scale)
    (transform:translate (- x1) (- y1))
    transform))

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

(fn draw.help [entries screen-w screen-h]
  (fn calc-y [index] (+ 50 (* index 25)))
  (local w 450)
  (local h (+ 50 (calc-y (length entries))))
  (love.graphics.translate
   (/ (- screen-w w) 2)
   (/ (- screen-h h) 2))

  (love.graphics.setColor .1 .1 .1 .9)
  (love.graphics.rectangle :fill 0 0 w h)
  (love.graphics.setColor [.8 .8 .8 1])
  (love.graphics.print "Help (press any key to close)" 25 25)
  (each [i [input description] (ipairs entries)]
    (local y (calc-y i))
    (love.graphics.setColor (lume.color "#a020f0"))
    (love.graphics.print input 25 y)
    (love.graphics.setColor [.7 .7 .7 1])
    (love.graphics.print description 250 y)))

(fn draw.log [log screen-w screen-h]
  (local last-messages (lume.last log 10))
  (fn calc-y [index] (+ 50 (* index 25)))
  (local w 450)
  (local h (+ 50 (calc-y (length last-messages))))
  (love.graphics.translate
   (/ (- screen-w w) 2)
   (/ (- screen-h h) 2))

  (love.graphics.setColor .1 .1 .1 .9)
  (love.graphics.rectangle :fill 0 0 w h)
  (love.graphics.setColor [.8 .8 .8 1])
  (love.graphics.print "Messages (press any key to close)" 25 25)
  (each [i message (ipairs last-messages)]
    (local y (calc-y i))
    (love.graphics.print message 25 y)))

draw

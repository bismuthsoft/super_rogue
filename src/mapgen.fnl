(import-macros {: vec2-op} :geom-macros)
(local lume (require :lib.lume))
(local geom (require :geom))
(local util (require :util))
(local pp util.pp)

(local mapgen {})

(fn mapgen.generate-level [level]
  (local enemy-list
         [[:player]
          [:killer-tomato]
          [:grid-bug]
          [:grid-bug]
          [:grid-bug]])
  (let [map (mapgen.join-polygons (unpack (mapgen.random-polygons)))
        map-rect (mapgen.polygon-bounding-box map)]
    (values
     map
     (icollect [_ [kind] (ipairs enemy-list)]
       [kind (mapgen.random-point-in-polygon map map-rect)]))))

(fn mapgen.random-polygons []
  (var polygons [])
  (for [i 1 100]
    (let [(ssx ssy) (love.window.getMode)
          margin 150
          next-poly (geom.polygon {:sides (love.math.random 3 12)
                                   :origin [(love.math.random margin (- ssx margin))
                                            (love.math.random margin (- ssy margin))]
                                   :size (love.math.random 50 200)
                                   :angle (* 2 math.pi (love.math.random))})
          collision?
          (accumulate [collision? false
                       _ poly (ipairs polygons)
                       &until collision?]
            (geom.rect-in-rect?
             (mapgen.polygon-bounding-box poly)
             (mapgen.polygon-bounding-box next-poly)))]
      (if (not collision?) (table.insert polygons next-poly))))
  polygons)

(fn mapgen.polygon-bounding-box [p]
  (accumulate [[min-x min-y max-x max-y]
               [math.huge math.huge (- math.huge) (- math.huge)]
               _ [x y] (ipairs p)]
    [
     (math.min min-x x)
     (math.min min-y y)
     (math.max max-x x)
     (math.max max-y y)]))

(fn mapgen.random-point-in-screen []
  (mapgen.random-point-in-rect 0 0 (love.graphics.getMode)))

(fn mapgen.random-point-in-rect [x y x2 y2]
  (let [[w h] [(- x2 x) (- y2 y)]]
    (values
     (+ x (* w (love.math.random)))
     (+ y (* h (love.math.random))))))

(fn mapgen.random-point-in-polygon [polygon ?rect]
  (let [rect (or ?rect (mapgen.polygon-bounding-box polygon))
        point [(mapgen.random-point-in-rect (unpack rect))]]
    (if (geom.point-in-polygon? point polygon)
        point
        (mapgen.random-point-in-polygon polygon rect))))

(fn mapgen.join-polygons [...]
  (var poly-out nil)
  (while (not poly-out)
    (let [polygon-list (lume.shuffle [...])]
      (set poly-out
        (faccumulate [poly-out (. polygon-list 1)
                      i 2 (length polygon-list)
                      &until (not poly-out)]
          (mapgen.try-join-2-polygons poly-out (. polygon-list i))))))
  poly-out)

(fn mapgen.try-join-2-polygons [poly1 poly2]
  (let [point1 (mapgen.random-point-in-polygon poly1)
        point2 (mapgen.random-point-in-polygon poly2)
        lineseg [point1 point2]
        (_ _ vindex1) (geom.lineseg-polygon-intersection lineseg poly1)
        (_ _ vindex2) (geom.lineseg-polygon-intersection lineseg poly2)
        polygon-out (lume.concat
                     (lume.slice poly1 1 vindex1)
                     (lume.slice poly2 (+ 1 vindex2))
                     (lume.slice poly2 1 vindex2)
                     (lume.slice poly1 (+ 1 vindex1)))
        min-angle (/ math.pi 36) ; no angles less than 5 degrees
        valid (geom.polygon-valid? polygon-out (/ math.pi 90))]
    (and valid polygon-out)))

mapgen

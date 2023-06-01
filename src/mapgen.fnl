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
  (let [map (mapgen.join-2-polygons
             (geom.polygon {:sides 8 :origin [100 200] :size 100 :angle 0})
             (geom.polygon {:sides 8 :origin [500 300] :size 100 :angle 0}))
        map-rect (mapgen.polygon-bounding-box map)]
    (values
     map
     (icollect [_ [kind] (ipairs enemy-list)]
       [kind (mapgen.random-point-in-polygon map map-rect)]))))

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

(fn mapgen.join-2-polygons [poly1 poly2]
  (let [point1 (mapgen.random-point-in-polygon poly1)
        point2 (mapgen.random-point-in-polygon poly2)
        lineseg [point1 point2]
        (_ _ vindex1) (geom.lineseg-polygon-intersection lineseg poly1)
        (_ _ vindex2) (geom.lineseg-polygon-intersection lineseg poly2)]
    (lume.concat
     (lume.slice poly1 1 vindex1)
     (lume.slice poly2 (+ 1 vindex2))
     (lume.slice poly2 1 vindex2)
     (lume.slice poly1 (+ 1 vindex1)))))

mapgen

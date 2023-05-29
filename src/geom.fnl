(local geom {})

(fn geom.angle [x y]
  ;; get the angle of point x,y from 0,0
  (math.atan2 y x))

(fn geom.distance [x y]
  ;; get the distance of point x,y from 0,0
  (^ (+ (^ y 2) (^ x 2)) 0.5))

(fn geom.rectangular->polar [x y]
  (values
   (geom.angle x y)
   (geom.distance x y)))

(fn geom.polygon-contains [pts point]) ;; TODO
(fn geom.polar->rectangular [theta r]
  (values
   (* r (math.cos theta))
   (* r (math.sin theta))))

(fn geom.within-rectangle? [point pos size]
  (and
   (> point.x pos.x) (< point.x (+ pos.x size.x))
   (> point.y pos.y) (< point.y (+ pos.y size.y))))

geom

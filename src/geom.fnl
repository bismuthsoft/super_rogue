(local pp #(print ((. (require :lib.fennel) :view) $1)))

(local geom {})
(import-macros {: vec2-op} :geom-macros)

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

(fn geom.polar->rectangular [theta r]
  (values
   (* r (math.cos theta))
   (* r (math.sin theta))))

(fn geom.within-rectangle? [point pos size]
  (and
   (> point.x pos.x) (< point.x (+ pos.x size.x))
   (> point.y pos.y) (< point.y (+ pos.y size.y))))

(fn geom.polygon-contains? [point polygon]) ;; TODO

(fn geom.line-from-points [a b]
  ;; Given two points, each [x y], give the slope and intercept of a line that
  ;; goes thru both a and b.
  (let [(dx dy) (vec2-op - b a)
        slope (/ dy dx)
        intercept (- (. a 2) (* slope (. a 1)))]
    (values slope intercept)))

(fn geom.line-intersection [a b]
  ;; Given two lines, each [slope intercept], return the x and y intersection
  ;; point.
  (let [x (/ (- (. b 2) (. a 2))
             (- (. a 1) (. b 1)))
        y (+ (. a 2) (* x (. a 1)))]
    (values x y)))

(fn geom.point-on-line-segment? [point seg]
  (let [[x y] point
        (slope intercept) (geom.line-from-points (unpack seg))
        distance (math.abs (+ (* slope x) intercept (- y)))]
    (geom.approx-eq distance 0)))

(fn geom.line-segment-intersection [seg1 seg2]
  (let [line1 [(geom.line-from-points (unpack seg1))]
        line2 [(geom.line-from-points (unpack seg2))]
        isect-point [(geom.line-intersection line1 line2)]]
    (if (and
         (geom.point-on-line-segment? isect-point seg1)
         (geom.point-on-line-segment? isect-point seg2))
        (unpack isect-point))))

;; return true if something is roughly equal
(fn geom.approx-eq [a b]
  (> 0.00001 (math.abs (- a b))))

(fn geom.vec-eq [a b]
  (and (geom.approx-eq (. a 1) (. b 1))
       (geom.approx-eq (. a 2) (. b 2))))

(assert (geom.point-on-line-segment? [0 0] [[0 0] [3 3]]))
(assert (geom.point-on-line-segment? [1.5 1.5] [[0 0] [3 3]]))
(assert (geom.point-on-line-segment? [-1.5 -1.5] [[0 0] [-3 -3]]))
(assert (geom.point-on-line-segment? [3 3] [[0 0] [3 3]]))
(assert (not (geom.point-on-line-segment? [3 4] [[0 0] [3 3]])))
(assert (geom.vec-eq [1 2] [1 2]))
(assert (not (geom.vec-eq [1 2] [1 1])))
(assert (geom.vec-eq [0 0] [(geom.line-intersection [0 0] [1 0])]))
(assert (geom.vec-eq [0 1] [(geom.line-intersection [-1 1] [1 1])]))
(assert (geom.vec-eq [0 0] [(geom.line-segment-intersection
                             [[-1 -1] [1 1]]
                             [[1 -1] [-1 1]])]))
(assert (not (geom.line-segment-intersection
              [[0 0] [1 1]]
              [[1 1] [2 2]])))

geom

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

(fn geom.line-intersection-vertical [x line]
  ;; Get the intersection of a line at x=N
  (let [y (+ (* (. line 1)) (. line 2))]
    (values x y)))

(fn geom.line-intersection [a b]
  ;; Given two non-vertical lines, each [slope intercept], return the x and y
  ;; intersection point, if it exists. Returns "parallel" if they are parallel
  ;; and intersect.
  (if
   ;; parellel
   (= (. a 1) (. b 1))
   (if (geom.approx-eq (. a 2) (. b 2))
       (error "Attempt to find intersection of equal lines")
       false)
   ;; vertical (can't detect based on slope-intercept ...)
   (= (. a 1) (/ 1 0))
   (error "Attempt to find intersection of vertical line")
   ;; standard
   (let [x (/ (- (. b 2) (. a 2))
              (- (. a 1) (. b 1)))
         y (+ (. a 2) (* x (. a 1)))]
     (values x y))))
(fn geom.point-on-line-segment? [point p1 p2]
  (let [[x y] point
        (slope intercept) (geom.line-from-points p1 p2)
        distance (math.abs (+ (* slope x) intercept (- y)))]
    (if (= slope (/ 1 0))
        ;; vertical
        (geom.approx-eq (. point 1) (. p1 1))
        ;; normal
        (geom.approx-eq distance 0))))

(fn geom.line-segment-intersection [p1 p2 q1 q2]
  (let [line1 [(geom.line-from-points p1 p2)]
        line2 [(geom.line-from-points q1 q2)]]
    (let [isect-point
           (if
            (= (. line1 1) (/ 1 0))
            [(geom.line-intersection-vertical (. p1 1) line2)]
            [(geom.line-intersection line1 line2)])]
       (if (and
            (. isect-point 1)
            (geom.point-on-line-segment? isect-point p1 p2)
            (geom.point-on-line-segment? isect-point q1 q2))
           (unpack isect-point)))))

;; return true if something is roughly equal
(fn geom.approx-eq [a b]
  (> 0.00001 (math.abs (- a b))))

(fn geom.nan? [x] (not= x x))

(fn geom.vec-eq [a b]
  (and (geom.approx-eq (. a 1) (. b 1))
       (geom.approx-eq (. a 2) (. b 2))))

;; basic tests
;; (assert (geom.vec-eq [0 0] [(geom.line-from-points [0 0] [1 0])]))
;; (assert (geom.vec-eq [0 1] [(geom.line-from-points [0 1] [1 1])]))
;; (assert (geom.vec-eq [1 0] [(geom.line-from-points [0 0] [1 1])]))
;; (assert (geom.vec-eq [1 1] [(geom.line-from-points [0 1] [1 2])]))
;; (assert (geom.vec-eq [1 2] [1 2]))
;; (assert (geom.vec-eq [1 2] [1 2.00000000001]))
;; (assert (not (geom.vec-eq [1 2] [1 1])))
;; (assert (geom.point-on-line-segment? [0 0] [0 0] [3 3]))
;; (assert (geom.point-on-line-segment? [1.5 1.5] [0 0] [3 3]))
;; (assert (geom.point-on-line-segment? [-1.5 -1.5] [0 0] [-3 -3]))
;; (assert (geom.point-on-line-segment? [3 3] [0 0] [3 3]))
;; (assert (geom.point-on-line-segment? [0 0.5] [0 0] [0 1])) ;; vertical
;; (assert (not (geom.point-on-line-segment? [3 4] [0 0] [3 3])))
;; (assert (geom.vec-eq [0 0] [(geom.line-intersection [0 0] [1 0])]))
;; (assert (geom.vec-eq [0 1] [(geom.line-intersection [-1 1] [1 1])]))
;; (assert (not (geom.line-intersection [0 0] [0 1]))) ;; parallel
;; ;; (assert (geom.vec-eq [0 0]
;; ;;                      [(geom.line-intersection-vertical [(/ 1 0) 0] [1 0])])) ;; vertical, expect error
;; (assert (geom.vec-eq [0 0] [(geom.line-segment-intersection ;; normal
;;                              [-1 -1] [1 1]
;;                              [1 -1] [-1 1])]))
;; (assert (not (geom.line-segment-intersection [0 0] [1 0] [1 1] [2 1]))) ;; parallel

(assert (geom.vec-eq [0 1] [(geom.line-segment-intersection)])) ;; vertical
;;                              [0 0] [0 2]
;;                              [-1 1] [1 1])]))

geom

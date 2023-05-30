(local pp #(print ((. (require :lib.fennel) :view) $1)))
(local geom {})
(import-macros {: vec2-op} :geom-macros)

;; /!\
;;
;; Unless otherwise specified, assume rectangular coordinates.

(set geom.FAR 99999999) ;; arbitrary big number which must be larger than
                        ;; the largest map size

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

(fn geom.points->ray [a b]
  (values a (geom.angle (vec2-op - b a))))

(fn geom.points->line [a b]
  ;; Given two points, each [x y], give the slope and intercept of a line that
  ;; goes thru both a and b.
  (let [[x1 y1] a
        (dx dy) (vec2-op - b a)
        slope (/ dy dx)
        intercept (- y1 (* slope x1))]
    (if (= slope math.huge) ;; vertical line
        (values math.huge y1)
        (values slope intercept))))

(fn geom.line-at-x [x line]
  ;; Evalute line at x=x
  (let [y (+ (* (. line 1)) (. line 2))]
    (values x y)))

;; Intersection functions:
;;  - A-B-intersection
;;  - arg 1 is of type A, arg 2 is of type B
;;  - returns x and y as two values if intersection exists, otherwise nil
;;  - type "point" is [x y]
;;  - type "line" is [slope intercept]
;;  - type "lineseg" is [[x y] [x y]]
;;  - type "polygon" is [[x y] [x y] ...]

(fn geom.line-line-intersection [[x1 y1] [x2 y2]]
  (if
   ;; parallel
   (= x1 x2)
   (if (geom.approx-eq y1 y2)
       (error "Attempt to find intersection of equal lines")
       false)
   ;; vertical (can't detect based on slope-intercept ...)
   (= x1 math.huge)
   (error "Attempt to find intersection of vertical line")
   ;; standard
   (let [x (/ (- y2 y1)
              (- x1 x2))
         y (+ y1 (* x x1))]
     (values x y))))

(fn geom.point-lineseg-intersection [point [p1 p2]]
  (if (geom.approx-eq
       (+ (geom.distance (vec2-op - point p1))
          (geom.distance (vec2-op - point p2)))
       (geom.distance (vec2-op - p2 p1)))
      point))

(local DEBUG_LINESEG false)
(fn geom.lineseg-lineseg-intersection [[p1 p2] [q1 q2]]
  (let [line1 [(geom.points->line p1 p2)]
        line2 [(geom.points->line q1 q2)]]
    (let [isect-point
           (if
            (= (. line1 1) (/ 1 0))
            [(geom.line-at-x (. p1 1) line2)]
            [(geom.line-line-intersection line1 line2)])]
      (if (and
           (. isect-point 1)
           (geom.point-lineseg-intersection isect-point [p1 p2])
           (geom.point-lineseg-intersection isect-point [q1 q2]))
          (unpack isect-point)))))

;; return the first face of the polygon that intersects
(fn geom.lineseg-polygon-intersection [[p1 p2] polygon]
  (unpack
   (faccumulate [intersection []
                 i 1 (length polygon)
                 &until (. intersection 1)]
    (let [q1 (. polygon i)
          q2 (. polygon (+ 1 (% i (length polygon))))]
      [(geom.lineseg-lineseg-intersection [p1 p2] [q1 q2])]))))

(fn geom.point-in-polygon? [point polygon]
 (let [cross-count
       (faccumulate [cross-count 0
                     i 1 (length polygon)]
        (let [q1 (. polygon i)
              q2 (. polygon (+ 1 (% i (length polygon))))
              ray [point [geom.FAR (. point 2)]]]
          (+ cross-count
           (if (geom.lineseg-lineseg-intersection [q1 q2] ray)
               1
               0))))]
   (= 1 (% cross-count 2))))

;; return true if something is roughly equal
(fn geom.approx-eq [a b]
  (> 0.00001 (math.abs (- a b))))

(fn geom.nan? [x] (not= x x))

(fn geom.vec-eq [[x1 y1] [x2 y2]]
  (and (geom.approx-eq x1 x2)
       (geom.approx-eq y1 y2)))

;; basic tests
(assert (geom.vec-eq [0 0] [(geom.points->line [0 0] [1 0])]))
(assert (geom.vec-eq [0 1] [(geom.points->line [0 1] [1 1])]))
(assert (geom.vec-eq [1 1] [(geom.points->line [0 1] [1 2])]))
(assert (geom.vec-eq [1 2] [1 2]))
(assert (geom.vec-eq [1 2] [1 2.00000000001]))
(assert (not (geom.vec-eq [1 2] [1 1])))
(assert (geom.point-lineseg-intersection [0 0] [[0 0] [3 3]]))
(assert (geom.point-lineseg-intersection [1.5 1.5] [[0 0] [3 3]]))
(assert (geom.point-lineseg-intersection [-1.5 -1.5] [[0 0] [-3 -3]]))
(assert (geom.point-lineseg-intersection [3 3] [[0 0] [3 3]]))
(assert (not (geom.point-lineseg-intersection [1 2] [[1 -1] [1 1]]))) ;; vertical (out of range)
(assert (geom.point-lineseg-intersection [0 0.5] [[0 0] [0 1]])) ;; vertical (in range)
(assert (not (geom.point-lineseg-intersection [3 4] [[0 0] [3 3]])))
(assert (geom.vec-eq [0 0] [(geom.line-line-intersection [0 0] [1 0])]))
(assert (geom.vec-eq [0 1] [(geom.line-line-intersection [-1 1] [1 1])]))
(assert (not (geom.line-line-intersection [0 0] [0 1]))) ;; parallel
;; (assert (geom.vec-eq [0 0]
;;                      [(geom.line-at-x [(/ 1 0) 0] [1 0])])) ;; vertical, expect error
(assert (geom.vec-eq [0 0] [(geom.lineseg-lineseg-intersection ;; standard
                             [[-1 -1] [1 1]]
                             [[1 -1] [-1 1]])]))
(assert (not (geom.lineseg-lineseg-intersection [[0 0] [1 0]] [[1 1] [2 1]]))) ;; parallel
(assert (not (geom.lineseg-lineseg-intersection [[1 -1] [1 1]] [[0 2] [geom.FAR 2]]))) ;; parallel
(assert (geom.vec-eq [0 1] [(geom.lineseg-lineseg-intersection ;; vertical
                             [[0 0] [0 2]]
                             [[-1 1] [1 1]])]))

(local test-square [[-1 -1] [1 -1] [1 1] [-1 1]])
(assert (not (geom.polygon-contains? [0 2] test-square)))
(assert (geom.polygon-contains? [0 0] test-square)) ;; in square
(assert (geom.polygon-contains? [-2 0] test-square)) ;; behind square
(assert (not (geom.lineseg-polygon-intersection [[3 3] [2 2]] test-square)))
(assert (geom.vec-eq [0 1] [(geom.lineseg-polygon-intersection [[0 0] [0 2]] test-square)]))

geom

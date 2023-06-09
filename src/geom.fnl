(local pp #(print ((. (require :lib.fennel) :view) $1)))
(local geom {})
(import-macros {: vec2-op} :geom-macros)

;; /!\
;;
;; Unless otherwise specified, assume rectangular coordinates.

(set geom.FAR 99999999) ;; arbitrary big number which must be larger than
                        ;; the largest map size

(local pi math.pi)
(local tau (* 2 pi))

(fn geom.angle [x y]
  ;; get the angle of point x,y from 0,0
  (math.atan2 y x))

(fn geom.angle-to-signed [angle]
  ;; given any angle, convert it to the range -pi to pi
  (let [angle (% angle tau)]
    (if (> angle pi)
        (- angle tau)
        angle)))

(fn geom.angle-of-vertex [p1 p2 p3]
  ;; test how far apart a given vertex is, defined by 3 points
  (let [a1 (geom.angle (vec2-op - p2 p1))
        a2 (geom.angle (vec2-op - p2 p3))]
    (geom.angle-to-signed (- a1 a2))))

(fn geom.distance [x y]
  ;; get the distance of point x,y from 0,0
  (^ (+ (^ y 2) (^ x 2)) 0.5))

(fn geom.rect-in-rect? [[x1 y1 x2 y2] [x3 y3 x4 y4]]
  (let [w (+ (- x2 x1) (- x4 x3))
        h (+ (- y2 y1) (- y4 y3))
        dx (math.abs (- (+ x1 x2) (+ x3 x4)))
        dy (math.abs (- (+ y1 y2) (+ y3 y4)))]
    (and (< dx w) (< dy h))))

(fn geom.rectangular->polar [x y]
  (values
   (geom.angle x y)
   (geom.distance x y)))

(fn geom.polar->rectangular [theta r]
  (values
   (* r (math.cos theta))
   (* r (math.sin theta))))

(fn geom.polygon [{: sides : origin : size : angle}]
  (let [angle (or angle 0)]
    (fcollect [i 1 sides]
      [(vec2-op +
                origin
                [(geom.polar->rectangular
                  (+ angle (* 2 pi (/ i sides)))
                  size)])])))

(fn geom.points->ray [a b]
  (values a (geom.angle (vec2-op - b a))))

(fn geom.points->line [a b]
  ;; Given two points, each [x y], give the slope and intercept of a line that
  ;; goes thru both a and b.
  (let [[x1 y1] a
        (dx dy) (vec2-op - b a)
        slope (/ dy dx)
        intercept (- y1 (* slope x1))]
    (if (geom.infinite? slope) ;; vertical line
        (values math.huge y1)
        (values slope intercept))))

(fn geom.line-at-x [[slope intercept] x]
  ;; Evalute line at x=x
  (let [y (+ (* x slope) intercept)]
    (values x y)))

;; Intersection functions:
;;  - A-B-intersection
;;  - arg 1 is of type A, arg 2 is of type B
;;  - arg 1 is always simpler than arg 2, if possible
;;  - complexity order: point, line, circle, lineseg, polygon
;;  - returns x and y as two values if intersection exists, otherwise nil
;;  - type "point" is [x y]
;;  - type "line" is [slope intercept]
;;  - type "lineseg" is [[x y] [x y]]
;;  - type "polygon" is [[x y] [x y] ...]

(fn geom.point-point-intersection [d1 d2]
  (if (geom.vec-eq d1 d2) d1))

(fn geom.line-line-intersection [[s1 y1] [s2 y2]]
  (if
   ;; parallel
   (= s1 s2)
   (if (geom.approx-eq y1 y2)
       (values (/ 0 0) (/ 0 0)) ; totally unknown, but they do intersect lmao
       false)
   ;; vertical (can't detect based on slope-intercept ...)
   (or (geom.infinite? s1) (geom.infinite? s2))
   (error "Attempt to find intersection of vertical line")
   ;; standard
   (let [x (/ (- y2 y1)
              (- s1 s2))
         y (+ y1 (* x s1))]
     (values x y))))

(fn geom.point-lineseg-intersection [point [p1 p2]]
  (if (geom.approx-eq
       (+ (geom.distance (vec2-op - point p1))
          (geom.distance (vec2-op - point p2)))
       (geom.distance (vec2-op - p2 p1)))
      point))

(fn geom.lineseg-lineseg-intersection [[p1 p2] [q1 q2]]
  (let [line1 [(geom.points->line p1 p2)]
        line2 [(geom.points->line q1 q2)]
        vertical2 (geom.infinite? (. line2 1))]
    (let [isect-point
           (if
            ;; vertical line1
            (geom.infinite? (. line1 1))
            [(geom.line-at-x line2 (. p1 1))]
            ;; vertical line2
            (geom.infinite? (. line2 1))
            [(geom.line-at-x line1 (. q1 1))]
            ;; normal
            [(geom.line-line-intersection line1 line2)])]
      (if (and
           (. isect-point 1)
           (geom.point-lineseg-intersection isect-point [p1 p2])
           (geom.point-lineseg-intersection isect-point [q1 q2]))
          (unpack isect-point)))))

(fn geom.lineseg-polygon-intersection [lineseg polygon]
  ; return the x, y, and index of the first face that intersects
  (unpack
     (faccumulate [intersection []
                   i 1 (length polygon)
                   &until (. intersection 1)]
      (let [q1 (. polygon i)
            q2 (. polygon (+ 1 (% i (length polygon))))
            isect-point [(geom.lineseg-lineseg-intersection lineseg [q1 q2])]]
        [(. isect-point 1) (. isect-point 2) i]))))

(fn geom.lineseg-polygon-intersection-map [lineseg polygon]
  ; returns a list of whether or not each edge intersects
  (fcollect [i 1 (length polygon)]
   (let [q1 (. polygon i)
         q2 (. polygon (+ 1 (% i (length polygon))))
         isect? (geom.lineseg-lineseg-intersection lineseg [q1 q2])]
     (if isect? true false))))

(fn geom.lineseg-polygon-intersection-count [lineseg polygon]
  (let [map (geom.lineseg-polygon-intersection-map lineseg polygon)]
    (faccumulate [sum 0
                  i 1 (length polygon)]
      (if (. map i) (+ sum 1) sum))))

(fn geom.point-circle-intersection [point [origin radius]]
  (if (< (geom.distance (vec2-op - point origin)) radius)
    point))

(fn geom.circle-at-x [[[ox oy] r] x]
  ;; given a circle origin ox, oy, radius r, evaluate it at x. Returns either
  ;; zero or two points.
  (let [discriminant (- (^ r 2) (^ (- x ox) 2))]
    (if
     (< discriminant 0)
     nil
     (let [sqrt-discriminant (^ discriminant 0.5)]
       (values [x (+ oy sqrt-discriminant)]
               [x (- oy sqrt-discriminant)])))))

(fn geom.line-circle-intersection [[slope icept] [[cx cy] r]]
  ;; given a circle origin ox, oy, radius r, evaluate it at a given line.
  ;; Returns either zero or two points.
  (if
     ;; vertical
     (geom.infinite? slope)
     (error "Attempt to find circle intersection with vertical line")
     ;; standard
     (let [icept (+ icept (- cy) (* slope cx)) ; translate circle to 0,0
           a (+ 1 (^ slope 2))             ; solve quadratic polynomial
           b (* 2 slope icept)
           c (- (^ icept 2) (^ r 2))
           discriminant (- (^ b 2) (* 4 a c))
           lhs (/ (- b) 2 a)]
       (if
        (< discriminant 0)
        nil
        (let [sqrt-discriminant (/ (^ discriminant 0.5) 2 a)
              x1 (+ lhs sqrt-discriminant)
              (_ y1) (geom.line-at-x [slope icept] x1)
              x2 (- lhs sqrt-discriminant)
              (_ y2) (geom.line-at-x [slope icept] x2)]
          (values [(vec2-op + [x1 y1] [cx cy])]
                  [(vec2-op + [x2 y2] [cx cy])]))))))

(fn geom.lineseg-in-circle? [lineseg circle]
  (let [(slope icept) (geom.points->line (unpack lineseg))
        secant-points
        (if (geom.infinite? slope)
            [(geom.circle-at-x circle (. lineseg 1 1))] ; vertical
            [(geom.line-circle-intersection [slope icept] circle)])]
    (and
     (. secant-points 1)
     (or
      (geom.point-lineseg-intersection (. secant-points 1) lineseg)
      (geom.point-lineseg-intersection (. secant-points 2) lineseg)))))

(fn geom.circle-in-circle? [circ1 circ2]
  (let [[o1 r1] circ1
        [o2 r2] circ2
        distance (geom.distance (vec2-op - o1 o2))]
    (> (+ r1 r2) distance)))

(fn geom.point-in-polygon? [point polygon]
  (let [cross-count
        (faccumulate [cross-count 0
                      i 1 (length polygon)]
         (let [q1 (. polygon i)
               q2 (. polygon (+ 1 (% i (length polygon))))
               ray [point [geom.FAR (. point 2)]]]
           (let [isect-point [(geom.lineseg-lineseg-intersection [q1 q2] ray)]]
             (+ cross-count
                (if (and (. isect-point 1)
                         (not (geom.vec-eq q1 isect-point)))
                   1
                   0)))))]
    (= 1 (% cross-count 2))))

(fn geom.polygon-valid? [polygon ?min-angle]
  ;; validate that a polygon has more than 2 points, no internal crossings, and
  ;; no angles less than min-angle.
  (and
   (> (length polygon) 2) ; polygon must have 3 or more points
   (accumulate [valid true
                _ [x y] (ipairs polygon)
                &until (not valid)]
     (and (geom.real? x)
          (geom.real? y)))
   (faccumulate [valid true
                 i 1 (length polygon)
                 &until (not valid)]
     ;; ... which can't intersect with any non-adjacent segments
     (let [min-angle (or ?min-angle (/ tau 360)) ; default 1 degree
           i0 (if (= i 1) (length polygon) (- i 1))
           i1 i
           i2 (+ 1 (% i (length polygon)))
           q0 (. polygon i0)
           q1 (. polygon i1)
           q2 (. polygon i2)
           map (geom.lineseg-polygon-intersection-map [q1 q2] polygon)]
       (faccumulate [valid true
                     j (+ i 1) (length polygon)
                     &until (not valid)]
         (and
          (<= min-angle (math.abs (geom.angle-of-vertex q0 q1 q2)))
          (not (geom.vec-eq q1 (. polygon j))) ; same point can't exist twice
          (or (= j i0) (= j i1) (= j i2) (= (. map j) false))))))))

(fn geom.approx-eq [a b]
  (>= (^ 2 -26) (math.abs (- a b))))

(fn geom.vec-eq [[x1 y1] [x2 y2]]
  (and (geom.approx-eq x1 x2)
       (geom.approx-eq y1 y2)))

(fn geom.nan? [x] (not= x x))

(fn geom.infinite? [x]
  (or (>= x geom.FAR) (<= x (- geom.FAR))))

(fn geom.real? [x]
  (not (or (geom.nan? x) (geom.infinite? x))))

geom

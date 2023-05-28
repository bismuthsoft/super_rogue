(local class (require :src.class))

(macro generate-operators! [Class fields]
  (var out [])
  (local math-ops
         [[:__unm `#(- $1) false]
          [:__pow `^ false]
          [:__mod `% false]
          [:__add `+ true]
          [:__sub `- true]
          [:__mul `* true]
          [:__div `/ true]])

  ;; generate math operations
  (each [i# [op-name op variadic] (ipairs math-ops)]
    (table.insert
     out
     `(tset (. ,Class :mt) ,op-name
       (fn [...]
         ;; Turn all args into vectors, if possible
         (let [vals# (icollect [_# arg# (ipairs [...])]
                       (if (= (type arg#) :table) arg# (,Class arg#)))]
           ;; Check if more than 2 operands for variadic ops (less common)
           (if (. vals# 3)
            ;; loop to apply operation
            (faccumulate [acc# (. vals# 1) i# 2 (length vals#)]
              (,Class
                ,(unpack (icollect [_ field (ipairs fields)]
                          ;; perform operation on 2 items at a time
                          `(,op (. acc# ,field) (. (. vals# i#) ,field))))))
            ;; Just apply operation on 2 operands (no loop)
            (let [[a# b#] vals#]
              (,Class
                ,(unpack (icollect [_ field (ipairs fields)]
                           `(,op (. a# ,field) (. b# ,field))))))))))))

  ;; generate compare operations
  (table.insert
   out
   `(tset (. ,Class :mt) :__eq
      (fn [self# other#]
        (and
         ,(unpack (icollect [_i field (ipairs fields)]
                   `(= (. self# ,field) (. other# ,field))))))))

  `(do (unpack ,out)))


(fn generate-operators [Class fields]
  (fn Class.map [self f ...]
      (let [index-list (fn [l index] (icollect [_i v (ipairs l)] (. v index)))
            as-vec (fn [t] (if (= (type t) :table) t (Class t)))
            self (as-vec self)
            rest (icollect [_i v (ipairs [...])] (as-vec v))]
        (Class (unpack (icollect [_i v (ipairs fields)]
                        (f (. self v) (unpack (index-list rest v)))))))))

(var Vec2 (class.class))
(fn Vec2.constructor [x y]
  (if (= (type x) :table) (Vec2.from-polar x.r x.t)
    {: x :y (if y y x)}))
(generate-operators Vec2 [:x :y])
(generate-operators! Vec2 [:x :y])
(fn Vec2.within-rectangle [self pos size]
  (and
   (> self.x pos.x) (< self.x (+ pos.x size.x))
   (> self.y pos.y) (< self.y (+ pos.y size.y))))
(fn Vec2.from-polar [{: r : t}]
  (Vec2 (* r (math.cos t))
        (* r (math.sin t))))

(fn Vec2.unpack [self]
  (values self.x self.y))

(var PolarVec2 (class.class))
(fn PolarVec2.constructor [r t]
  (if (= (type r) :table) (PolarVec2.from-rectangular r)
    {: r : t}))
(generate-operators PolarVec2 [:r :t])
(generate-operators! PolarVec2 [:r :t])
(fn PolarVec2.from-rectangular [{: x : y}]
  (PolarVec2
   (^ (+ (^ y 2) (^ x 2)) 0.5)     ;; distance
   (math.atan2 y x)))              ;; angle

{: Vec2 : PolarVec2}

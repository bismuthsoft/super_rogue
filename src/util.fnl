(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util {})

(set util.pp #(print ((. (require :lib.fennel) :view) $1)))

(fn util.zero? [v]
  (= 0 v))

(fn util.flatten [array]
  (let [out []
        flatten (fn flatten [value]
                  (if (= (type value) :table)
                      (each [_ v (ipairs value)] (flatten v))
                      (table.insert out value)))]
    (flatten array)
    out))

(fn util.shift-down? []
  (or (love.keyboard.isDown :lshift) (love.keyboard.isDown :rshift)))


;; Using a function that takes a list entry and a function, return the index and
;; value with the highest score.
(fn util.max-by-score [list f ?self]
  (unpack
   (accumulate [top []
                i v (ipairs list)]
     (let [score (f v i)
           skip (and ?self (= ?self v))]
       (if (and (not skip)
                (or (not (. top 1)) (> score (. top 3))))
           [v i score]
           top)))))

(fn util.furthest [pos positions]
  (util.max-by-score
   positions
   (lambda [v]
     (geom.distance (vec2-op - pos v)))
   pos))

(fn util.nearest [pos positions]
  (util.max-by-score
   positions
   (lambda [v]
     (geom.distance (vec2-op - pos v)))
   pos))

util

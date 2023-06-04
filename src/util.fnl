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

util

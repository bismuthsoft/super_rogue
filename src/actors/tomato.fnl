(local tomato {})

(fn tomato.spawn [s pos]
  {:kind "tomato"
   :name "tomato"
   : pos
   :color [1 0 0]
   :char "ó"
   :hitbox {:size 5 :shape :circle}
   :collect {:hp 1}})

tomato

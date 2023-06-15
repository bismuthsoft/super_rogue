(local coin {})

(fn coin.spawn [s pos]
  {:kind "gold-coin"
   :name "gold coin"
   : pos
   :color [1 0.8 0 1]
   :char "$"
   :char-scale 1
   :hitbox {:size 5 :shape :circle}
   :collect {:money 1}})

coin

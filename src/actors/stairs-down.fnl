(local stairs {})

(fn stairs.spawn [s pos]
  {
   :kind "stairs-down"
   :name "downward staircase"
   : pos
   :color [1 0.7 0 1]
   :char ">"
   :hitbox {:size 8 :shape :circle}})

stairs

(local lume (require :lib.lume))

(local grid-bug {})

(fn grid-bug.spawn [s pos]
  {
   :kind "grid-bug"
   :name "Gridbug"
   : pos
   :enemy? true
   :color [(lume.color "#811A74")]
   :char "x"
   :char-scale 0.8
   :hp 1
   :max-hp 1
   :atk 2
   :speed 50
   :angle 0
   :ai {:kind :random}
   :hitbox {:size 4 :shape :circle}})

grid-bug

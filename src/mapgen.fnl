(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))

(local mapgen {})

(fn mapgen.generate-level [level]
  (values
   (geom.polygon {:sides 3 :origin [400 300] :size 300})
   [[:player [260 300]]
    [:killer-tomato [500 300]]
    [:grid-bug [400 400]]
    [:grid-bug [400 350]]
    [:grid-bug [400 250]]]))

mapgen

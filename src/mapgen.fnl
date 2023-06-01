(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))

(local mapgen {})

(fn mapgen.generate-level [level]
  (values
   (geom.polygon {:sides 3 :origin [400 300] :size 300})
   [
    [:player [250 300]]
    [:killer-tomato [300 300]]]))

mapgen

(local vision {})
(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))

(fn vision.see-between-points? [p1 p2 map]
  (not (geom.lineseg-polygon-intersection [p1 p2] map)))

vision

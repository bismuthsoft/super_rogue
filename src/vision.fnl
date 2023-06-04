(local vision {})
(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util (require :util))
(local lume (require :lib.lume))
(local pp util.pp)

(fn vision.see-between-points? [p1 p2 border]
  (not (geom.lineseg-polygon-intersection [p1 p2] border)))

(fn vision.get-visible-faces [pos border]
  (var visible [])
  (each [i vertex (ipairs border)]
    (let [count (geom.lineseg-polygon-intersection-count [pos vertex] border)]
      (if (<= count 2)
          (tset visible i true))))
  visible)

(fn vision.update-visible [seen pos border]
  (local visible (vision.get-visible-faces pos border))
  (for [i 1 (length border)]
    (when (. visible i)
      (tset seen i true)))
  seen)

(fn vision.draw-visible-border [border seen]
  (each [i vertex (ipairs border)]
    (if (. seen i)
      (let [i2 (+ 1 (% i (length border)))]
        (love.graphics.line
         (unpack (lume.concat
                  (. border i)
                  (. border i2))))))))

vision

(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util (require :util))
(local draw (require :draw))
(var mapgen (require :mapgen))
(local lume (require :lib.lume))
(local scene (require :scene))
(local pp util.pp)

(local game-over {})

(fn game-over.init [stats]
  stats)

(fn game-over.update [s dt]
  (do))

(fn game-over.size [s]
  (values 800 600))

(fn game-over.draw [s]
  (var line 1)
  (fn print-line [?text-or-justified-pair ?color]
    (match ?color
      color (love.graphics.setColor color)
      _ (love.graphics.setColor [1 1 1 1]))
    (local y (* line 25))
    (match ?text-or-justified-pair
      ;; Left/right justified text pair.
      [left right]
      (do
        (love.graphics.print left 200 y)
        (love.graphics.print right 500 y))
      (where str (= (type str) "string"))
      (love.graphics.print str 200 y)
      ;; Skip this line.
      nil
      (do)
      ;; Barf if input is invalid.
      idk
      (error (.."Not sure how to print " (pp idk))))
    (set line (+ 1 line)))
  (print-line "GAME OVER" [.9 0 0 1])
  (print-line)
  (print-line (lume.format "You survived for {elapsed} seconds."
                           {:elapsed (lume.round s.elapsed-time .01)}))
  (print-line (lume.format "You descended to dungeon level {level}" s))
  (print-line)
  (local GRAY [.7 .7 .7 1])
  (print-line "-------- Enemies vanquished --------" GRAY)
  (each [monster count (pairs s.vanquished)]
    (print-line [monster (tostring count)] GRAY))
  (print-line)
  (print-line "------- Last 10 log messages -------" GRAY)
  (each [_ message (ipairs (lume.last s.log 10))]
    (print-line message GRAY)))

(fn game-over.keypressed [s keycode scancode]
  (when (scene.global-keys.handle-keypressed keycode scancode)
    (lua "return"))
  (scene.set :menu))

game-over

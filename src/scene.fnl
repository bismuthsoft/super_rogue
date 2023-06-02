(local lume (require :lib.lume))
(local scene {:stack []})

(fn do-bind []
  (local entry (lume.last scene.stack))
  (local fns entry.fns)
  (local state entry.state)
  (fn bind-love [name]
    (tset love name
          (fn [...]
            (match (. fns name)
              (where callback) (callback state ...)))))
  (bind-love :update)
  (bind-love :draw)
  (bind-love :mousemoved)
  (bind-love :mousepressed)
  (bind-love :mousereleased)
  (bind-love :keypressed)
  (bind-love :keyreleased))

(fn scene.push [name ...]
  (local fns (require (.. "scenes." name)))
  (local state (fns.init ...))
  (lume.push scene.stack {: fns : state})
  (do-bind))

(fn scene.pop []
  (match (table.remove scene.stack)
    (where entry)
    (match (?. entry.fns :deinit)
      (where deinit)
      (deinit entry.state)))
  (match (lume.last scene.stack)
    (where entry)
    (do-bind)))

scene

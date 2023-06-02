(local lume (require :lib.lume))

(local scene {})
(var fns {})
(var state nil)

(fn scene.set [name ...]
  (match fns.deinit
    (where deinit) (deinit state ...))
  (set fns (require (.. "scenes." name)))
  (set state (fns.init ...))

  ;; bind love2d functions to scene
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

scene

(var scene-fns {}) ;; scene functions
(var scene-state {}) ;; scene state

(fn set-scene [scene-name ...]
  (when (?. scene-fns :deinit) (scene-fns.deinit scene-state))
  (set scene-fns (require scene-name))
  (set scene-state (scene-fns.init ...)))

(fn love.load []
  (table.remove arg 1)  ;; game directory or .love file
  (while (> (length arg) 0)
    (match (. arg 1)
      "--test"
      (let [tests (require :tests)]
        (table.remove arg 1)
        (tests.entrypoint))))
  (set-scene :dungeon))

(fn bind-love [name] (tset love name
                           (fn [...]
                             (when (. scene-fns name)
                               ((. scene-fns name) scene-state ...)))))

(bind-love :update)
(bind-love :draw)
(bind-love :mousemoved)
(bind-love :mousepressed)
(bind-love :mousereleased)
(bind-love :keypressed)
(bind-love :keyreleased)

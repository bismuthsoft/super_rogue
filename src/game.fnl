(var scene-fns {})                      ; scene functions
(var scene-state {})                    ; scene state

(love.graphics.setFont (love.graphics.newFont "lib/CourierPrime-Bold.ttf" 18))

(fn set-scene [scene-name ...]
  (match (?. scene-fns :deinit)
    (where deinit) (deinit scene-state))
  (set scene-fns (require (.. "scenes." scene-name)))
  (set scene-state (scene-fns.init ...)))

(fn love.load []
  (table.remove arg 1)                  ; game directory or .love file
  (while (> (length arg) 0)
    (match (. arg 1)
      "--test"
      (let [tests (require :tests)]
        (table.remove arg 1)
        (tests.entrypoint))
      unknown
      (do
        (print (.. "Unknown argument: \"" unknown "\".  Ignoring."))
        (table.remove arg 1))))
  (set-scene :dungeon))

(set-scene :dungeon)

(fn bind-love [name]
  (tset love name
        (fn [...]
          (match (. scene-fns name)
            (where callback) (callback scene-state ...)))))
(bind-love :update)
(bind-love :draw)
(bind-love :mousemoved)
(bind-love :mousepressed)
(bind-love :mousereleased)
(bind-love :keypressed)
(bind-love :keyreleased)

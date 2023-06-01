(var scene-fns {})                      ; scene functions
(var scene-state {})                    ; scene state

(fn set-scene [scene-name ...]
  (match (?. scene-fns :deinit)
    (where deinit) (deinit scene-state))
  (set scene-fns (require (.. "scenes." scene-name)))
  (set scene-state (scene-fns.init ...)))

(fn love.load []
  ;; Command line parsing
  (var mode :game)
  (table.remove arg 1)                  ; game directory or .love file
  (while (> (length arg) 0)
    (match (. arg 1)
      "--test"
      (do
        (set mode :test)
        (table.remove arg 1)
        (lua "break"))
      unknown
      (do
        (print (.. "Unknown argument: \"" unknown "\".  Ignoring."))
        (table.remove arg 1))))

  (match mode
    :game
    (do
      (when (or (not love.graphics) (not love.window))
        (error "super_rogue cannot run with --headless.  Please remove this flag and try again."))
      (love.graphics.setFont (love.graphics.newFont "lib/CourierPrime-Bold.ttf" 18))
      (love.graphics.setLineStyle :rough)
      (set-scene :dungeon))
    :test
    ((. (require :tests) :entrypoint)))) ; Get the tests entrypoint and call
                                         ; it.

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

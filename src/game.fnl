(local scene (require :scene))

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
      (scene.set :menu))
    :test
    ((. (require :tests) :entrypoint)))) ; Get the tests entrypoint and call
                                         ; it.

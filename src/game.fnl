(local scene (require :scene))
(local ent (require :lib.ent))
(local version (require :version))

(fn love.load []
  (love.filesystem.setIdentity "super_rogue")
  ;; Logging init.
  (ent.init
   {:useHTML false})
  (ent.info "Welcome to %s (%s - %s)"
            (love.filesystem.getIdentity) version.version version.name)

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
      (love.graphics.setFont (love.graphics.newFont "assets/CourierPrime-Bold.ttf" 18))
      (scene.set :menu))
    :test
    ((. (require :tests) :entrypoint)))) ; Get the tests entrypoint and call it.

;; TODO grabbing the default error handler then calling it at the end seems to
;; have a different effect.  The game simply exits instead of printing out the
;; error to the game screen and hanging.  Fix this!
(local default-errorhandler love.errorhandler)
(fn love.errorhandler [msg]
 (ent.error "%s" msg)
 (ent.close)
 (default-errorhandler msg))

(fn love.quit []
  (ent.close))

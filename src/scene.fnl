(import-macros {: vec2-op} :geom-macros)
(local lume (require :lib.lume))
(local draw (require :draw))

(local scene {})
(var fns {})
(var state nil)
(var transform (love.math.newTransform))
(local min-framerate 30)

(fn scene.get-mouse-position [x y]
  (transform:inverseTransformPoint
   (love.mouse.getPosition)))

(fn scene.set [name ...]
  (match fns.deinit
    (where deinit) (deinit state ...))
  (set fns (require (.. "scenes." name)))
  (set state (fns.init ...))
  (scene.bind fns state))

(fn scene.bind [new-fns new-state]
  (set fns new-fns)
  (set state new-state)

  ;; bind love2d functions to scene
  (fn bind-love [name]
    (tset love name
          (fn [...]
            (match (. fns name)
              (where callback) (callback state ...)))))

  ;; bind mouse functions to scene with scaling
  (fn bind-love-mouse [name x y]
    (tset love name
          (fn [x y ...]
            (let [(x y) (scene.get-mouse-position x y)]
             (match (. fns name)
               (where callback) (callback state x y ...))))))

  (bind-love :keypressed)
  (bind-love :keyreleased)
  (bind-love-mouse :mousemoved)
  (bind-love-mouse :mousepressed)
  (bind-love-mouse :mousereleased)

  (fn love.update [dt]
    (fns.update state (math.min dt (/ 1 min-framerate))))

  (fn love.draw []
    ;; center the screen and preserve aspect. The viewport function on each
    ;; scene gives the upper left and lower right corner of the current scene.
    (love.graphics.push)
    (set transform (draw.get-centered-viewport-transform (fns.viewport state)))
    (love.graphics.applyTransform transform)
    (fns.draw state)
    (love.graphics.pop)
    (when fns.draw-no-transform
      (fns.draw-no-transform state))))

(set scene.global-keys {})

;; Returns true if event should not propagate into current scene's handler
(fn scene.global-keys.handle-keypressed [keycode scancode]
  (match scancode                       ; Match returns nil if no match.
    (where :return (or (love.keyboard.isDown :lalt) (love.keyboard.isDown :ralt)))
    (do
      (love.window.setFullscreen (not (love.window.getFullscreen)))
      true)
    (where (or :lalt :ralt))
    true))

scene

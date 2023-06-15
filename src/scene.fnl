(import-macros {: vec2-op} :geom-macros)
(local lume (require :lib.lume))

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
    (let [screensize [(love.window.getMode)]
          (vx1 vy1 vx2 vy2) (fns.viewport state)
          (vw vh) (vec2-op - [vx2 vy2] [vx1 vy1])
          (scalex scaley) (vec2-op / screensize [vw vh])
          scale (math.min scalex scaley)
          realsize [(vec2-op * [scale scale] [vw vh])]
          (ox oy) (vec2-op /           ; offset to center it
                           [(vec2-op - screensize realsize)]
                           [2 2])]
      (transform:reset)
      (transform:translate ox oy)
      (transform:scale scale)
      (transform:translate (- vx1) (- vy1)))
    (love.graphics.applyTransform transform)
    (fns.draw state)))

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

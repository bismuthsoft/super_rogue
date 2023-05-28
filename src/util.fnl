(local Vec2 (require :Vec2))

(fn util.with-scroll [args f]
  (util.with-transform-list [:translate (unpack args)] f))

;; pass in a list of graphical transforms to apply when calling f
;; for example:
;; (util.with-transform-list [[:translate 10 20]] #(draw-carrot 100))
(fn util.with-transform-list [tforms f]
  (util.with-transform (util.transform-from tforms) f))

;; pass in a transform object and it will apply the transform when calling a
;; function
(fn util.with-transform [tform f]
  (love.graphics.push)
  (love.graphics.applyTransform tform)
  (f)
  (love.graphics.pop))

;; pass in a list of graphical transforms to convert into a transform object
;; for example:
;; (util.transform-from-list [[:translate 10 20]])
(fn util.transform-from-list [...]
  (let [out (love.math.newTransform)]
    (each [_i [tform a b c d] (ipairs [...])]
      ((. out tform) out
       (if (= (type a) :table) (values a.x a.y)
           (values a b c d))))
    out))

(fn util.with-color-rgba [r g b a f]
  (let [(oldr oldg oldb olda) (love.graphics.getColor)]
    (love.graphics.setColor r g b a)
    (f)
    (love.graphics.setColor oldr oldg oldb olda)))

(fn util.screen-size [] (Vec2 (love.window.getMode)))

(local class {})

;; Make an object a prototype of another
(fn class.prototype [class object]
  (let [object (or object {})]
   (setmetatable object {:__index class})))

;; Create a table which is a class X. When called as (X ...), it will construct
;; an object Y by calling X.constructor(...). The optional method
;; X.instantiate(...) will be called afterwards if it exists, for extra work
;; that requires methods to be bound.
(fn class.class [class]
  (let [class (if class class {})]
    (set class.mt {:__index class :__class class})
    (setmetatable
     class
     {:__call (fn [_class ...]
                (let [instance (setmetatable (class.constructor ...) class.mt)]
                 (when class.instantiate (instance:instantiate ...))
                 instance))})))

(fn class.get-class [object]
  (?. (getmetatable object) :__class))


(fn class.copy-instance [obj]
  (case (type obj)
    :table (let [copy (collect [k v (pairs obj)]
                        (values k (class.copy-instance v)))]
             (if (class.get-class obj)
                 (setmetatable copy (getmetatable obj))
                 copy))
    _ obj))

class

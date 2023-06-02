(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util (require :util))
(local collide {})
(local pp util.pp)

(fn collide.get-lineseg [actor]
  (let [step [(geom.polar->rectangular actor.angle actor.hitbox.size)]
        p2 [(vec2-op + actor.pos step)]]
    [actor.pos p2]))

(fn collide.actors-collide? [a1 a2]
  (match [(?. a1 :hitbox :shape) (?. a2 :hitbox :shape)]
    [:circle :circle]
    (geom.circle-in-circle? [a1.pos a1.hitbox.size]
                            [a2.pos a2.hitbox.size])
    [:circle :line]
    (geom.lineseg-in-circle? (collide.get-lineseg a2)
                             [a1.pos a1.hitbox.size])
    [:line :circle]
    (geom.lineseg-in-circle? (collide.get-lineseg a1)
                             [a2.pos a2.hitbox.size])
    [:line :line]
    (geom.lineseg-lineseg-intersection (collide.get-lineseg a1)
                                      (collide.get-lineseg a2))))

collide

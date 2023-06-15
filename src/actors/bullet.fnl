(local geom (require :geom))
(local dungeon (require :scenes.dungeon))
(local bullet {})

(fn bullet.spawn [s pos angle friendly? atk props]
  (let [color (or props.color [1 0 0 1])
        speed (or props.speed 300)
        name (or props.name "bullet")]
    {
     :kind "bullet"
     : name
     :color (or props.color [1 0 0 1]
                speed (or props.speed 300)
                name (or props.name "bullet")
                {: kind})
     : friendly?
     :enemy? (not friendly?)
     : pos
     : angle
     : color
     :hitbox {:shape :line :size 6}
     :show-line {: color :len 6 :thickness 2}
     :expiry props.expiry
     : atk
     : speed
     :moving? true}))

(fn bullet.update [s actor dt]
  (when (not (geom.point-in-polygon? actor.pos s.level-border))
    (dungeon.delete-actor s actor)))

bullet

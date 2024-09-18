(local dungeon (require :scenes.dungeon))
(local kt {})

(fn kt.spawn [s pos ?generation ...]
  {:kind "killer-tomato"
   :name "killer tomato"
   : pos
   :generation (or ?generation 1)
   :update kt.update
   :on-death kt.on-death
   :enemy? true
   :color [1 0 0]
   :char "t"
   :hp 3
   :max-hp 3
   :atk 6
   :hitbox {:size 8 :shape :circle}
   :seed-timer nil
   :seed-count 0})

(fn kt.update [s actor]
  (if (and (< actor.generation 3)
           (< actor.hp actor.max-hp)
           (< actor.seed-count 3))
      (if
       (not actor.seed-timer)
       (do
         (set actor.seed-timer (+ s.elapsed-time
                                  (/ (math.random 50 100) 128))))
       (< actor.seed-timer s.elapsed-time)
       (do
         (set actor.seed-timer nil)
         (set actor.seed-count (+ 1 actor.seed-count))
         (table.insert s.log "The killer tomato has propagated a tomato seed...")
         (dungeon.spawn-actor s :tomato-seed actor.pos (+ 1 actor.generation))))))

(fn kt.on-death [s actor]
  (when (< (love.math.random) 0.2)
    (dungeon.spawn-actor s :tomato actor.pos))
  (dungeon.log (.. "The Killer Tomato became docile!")))

kt

(local dungeon (require :scenes.dungeon))
(local seed {})

(fn seed.spawn [s pos generation]
  (local seed {:kind "tomato-seed"
               :name "tomato seed"
               : pos
               : generation
               :char "•"
               :color [0 1 0]
               :lifetime (+ 1 (math.random))
               :on-death seed.on-death
               :speed 25})

  (dungeon.actor-look-at-pos seed (unpack s.player.pos))
  (set (seed.angle) (+ seed.angle (math.random) -0.5))
  (dungeon.actor-step-forward seed (+ 1 (math.random)) s.level-border)
  seed)

(fn seed.on-death [s actor]
  (table.insert s.log "The tomato seed has grown into a killer tomato!")
  (dungeon.spawn-actor
   s
   :killer-tomato
   actor.pos
   actor.generation))

seed

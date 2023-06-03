(local dungeon (require :scenes.dungeon))
(local draw (require :draw))
(local scene (require :scene))
(local help {})

(fn help.init [dungeon-state]
  {: dungeon-state})

(fn help.keypressed [s]
  (scene.bind dungeon s.dungeon-state))

(fn help.size [s ...]
  (dungeon.size s.dungeon-state))

(fn help.draw [s]
  (love.graphics.push)
  (dungeon.draw s.dungeon-state)
  (love.graphics.pop)
  (draw.help (help.size s)))

help

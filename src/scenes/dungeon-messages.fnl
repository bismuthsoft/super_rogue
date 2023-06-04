(local dungeon (require :scenes.dungeon))
(local draw (require :draw))
(local scene (require :scene))
(local messages {})

(fn messages.init [dungeon-state]
  {: dungeon-state})

(fn messages.keypressed [s keycode scancode]
  (when (scene.global-keys.handle-keypressed keycode scancode)
    (lua "return"))
  (scene.bind dungeon s.dungeon-state))

(fn messages.size [s ...]
  (dungeon.size s.dungeon-state))

(fn messages.draw [s]
  (dungeon.draw s.dungeon-state)
  (draw.log s.dungeon-state.log (messages.size s)))

messages

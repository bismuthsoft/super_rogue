(local dungeon (require :scenes.dungeon))
(local draw (require :draw))
(local scene (require :scene))
(local help {})

(fn help.init [dungeon-state]
  {: dungeon-state})

(fn help.keypressed [s keycode scancode]
  (when (scene.global-keys.handle-keypressed keycode scancode)
    (lua "return"))
  (scene.bind dungeon s.dungeon-state))

(fn help.viewport [s ...]
  (dungeon.viewport s.dungeon-state))

(local
 HELP-ENTRIES
 [["/, ?, or F1" "This help menu"]
  ["Alt+Return" "Toggle fullscreen"]
  ["" ""]
  ["Spacebar" "Melee attack"]
  ["Right Mouse button" "Melee attack"]
  ["Left mouse button" "Fire projectile"]
  ["K, W, or Up" "Move up"]
  ["H, A, or Left" "Move left"]
  ["J, S, or Down" "Move down"]
  ["L, D, or Right" "Move right"]
  ["Shift + <Move>" "Move Slow"]
  ["Tab or ." "Rest"]
  [">" "Take Stairs"]
  ["\\" "View game log "]])

(fn help.draw [s]
  (dungeon.draw s.dungeon-state)
  (draw.help HELP-ENTRIES (help.size s)))

help

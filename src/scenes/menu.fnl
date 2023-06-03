(import-macros {: vec2-op} :geom-macros)
(local geom (require :geom))
(local util (require :util))
(local draw (require :draw))
(var mapgen (require :mapgen))
(local lume (require :lib.lume))
(local scene (require :scene))
(local pp util.pp)

(local menu {})

(fn menu.init []
  {})

(fn menu.update [s dt]
  (do))

(fn menu.size [s]
  (values 800 600))

(fn menu.draw [s]
  (love.graphics.print "Super Rogue" 300 100)
  (love.graphics.print "Press any key to play" 300 300))

(fn menu.keypressed [s keycode scancode]
  (print (lume.format "Pressed {keycode}" {: keycode}))
  (scene.set :dungeon))

menu

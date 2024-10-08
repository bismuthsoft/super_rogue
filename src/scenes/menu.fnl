(import-macros {: vec2-op} :geom-macros)
(local version (require :version))
(local geom (require :geom))
(local util (require :util))
(local draw (require :draw))
(var mapgen (require :mapgen))
(local lume (require :lib.lume))
(local scene (require :scene))
(local pp util.pp)

(local menu {})

(fn menu.init []
  {:time 0})

(fn menu.update [s dt]
  (set s.time (+ s.time dt)))

(fn menu.size [s]
  (values 800 600))

(fn menu.draw [s]
  (love.graphics.setColor [1 1 1 1])
  (love.graphics.print (string.format "Super Rogue %s - %s" version.version version.name) 300 100)
  (love.graphics.setColor [.7 .7 .7 1])
  (love.graphics.print "By 44100hz & winny" 300 150)
  (when (not= 0 (% (lume.round s.time) 5))
    (love.graphics.setColor [1 1 1 1])
    (love.graphics.print "*** Press any key to play ***" 300 300)))

(fn menu.keypressed [s keycode scancode]
  (when (scene.global-keys.handle-keypressed keycode scancode)
    (lua "return"))
  (scene.set :dungeon))

menu

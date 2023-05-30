(local lu (require :lib.luaunit))
(local fennel (require :lib.fennel))

{:entrypoint
 (lambda []
   (require :tests.sanity)
   (require :tests.geom)
   (set debug.traceback fennel.traceback)
   (local runner (lu.LuaUnit.new))
   (love.event.quit (runner:runSuite)))
 }

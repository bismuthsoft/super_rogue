function love.conf(t)
  -- Based on https://gitlab.com/technomancy/bussard/-/blob/master/conf.lua
  for index, a in pairs(arg) do
    if a == "--headless" then
      t.window, t.modules.window, t.modules.graphics = false, false, false
      table.remove(arg, index)
      -- This code isn't safe to run the same loop body twice because of the
      -- table.remove.
      break
    end
  end
  if t.window then
    t.window.title = "Super Rogue"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = true
  end
end

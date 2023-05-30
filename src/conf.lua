love.conf = function(t)
  -- Based on https://gitlab.com/technomancy/bussard/-/blob/master/conf.lua
  for index, a in pairs(arg) do
    if a == "--headless" then
      t.window, t.modules.window, t.modules.graphics = false, false, false
      table.remove(arg, index)
      break -- This code isn't safe to run the same loop body twice because of
            -- the table.remove.
    end
  end
end

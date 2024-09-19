-- bootstrap the compiler

local fennel = require("lib.fennel")
local make_love_searcher = function(env)
  return function(module_name)
    for _, filename in ipairs({".fnl", "/init.fnl"}) do
      local path = module_name:gsub("%.", "/") .. filename
      if love.filesystem.getInfo(path) then
        return function(...)
          local code = love.filesystem.read(path)
          return fennel.eval(code, {env=env, filename=path}, ...)
        end
      end
    end
  end
end

table.insert(package.loaders, make_love_searcher(_G))
table.insert(fennel["macro-searchers"], make_love_searcher("_COMPILER"))
debug.traceback = fennel.traceback

require("game")

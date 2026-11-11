-- Prints whether a file has unsaved changes in the Neovim the MCP server's
-- tool calls on it run in, `modified`, or is loaded there, `loaded`, or
-- nothing. Run with `nvim --clean -l state.lua <path>`.

-- The modules are next to this script.
local source = assert(debug.getinfo(1, "S")).source:sub(2)
local lua_dir = vim.fs.dirname(vim.fs.dirname(vim.fs.dirname(source)))
package.path = ("%s/?.lua;%s/?/init.lua;%s"):format(lua_dir, lua_dir, package.path)

local route = require("nvim_agents.mcp.route")

local path = _G.arg[1]
if not path or path == "" then return end
local done = false
route.find(path, function(_, state)
  if state then io.stdout:write(state, "\n") end
  done = true
end)
vim.wait(route.timeout_ms * 10, function() return done end, 5)

local h = require("nvim_agents_tests")
local route = require("nvim_agents.mcp.route")

local dir = h.tmpdir()
local run = h.tmpdir()
vim.env.XDG_RUNTIME_DIR = run
vim.env.NVIM = ""

local path = vim.fs.joinpath(dir, "shared.txt")
h.write(path, "text\n")

-- The peers answer slower while the other tests run.
route.timeout_ms = 1000

--- Starts a Neovim listening in the runtime directory with the plugin, and
--- returns its address and a function stopping it.
---@param lua string Code run at its start.
---@return string address
---@return fun() stop
local start_peer = function(lua)
  local address = vim.fs.joinpath(run, ("nvim.%d.0"):format(math.random(100000, 999999)))
  -- The peer writes it once it ran the code, after it started listening.
  local ready = address .. ".ready"
  -- The plugin's root is above `lua/nvim_agents/mcp/route.lua`.
  local plugin = assert(
    vim.api.nvim_get_runtime_file("lua/nvim_agents/mcp/route.lua", false)[1]
  )
  for _ = 1, 4 do
    plugin = vim.fs.dirname(plugin)
  end
  local process = vim.system({
    vim.v.progpath, "--headless", "--clean", "--listen", address,
    "--cmd", "set rtp^=" .. plugin,
    "-c", "lua " .. lua,
    "-c", ("lua io.open(%q, 'w'):close()"):format(ready),
  })
  h.wait(function() return vim.uv.fs_stat(ready) ~= nil end, "the peer is ready")
  return address, function() process:kill("sigterm") end
end

--- Returns the address route.find picks for the file, and the file's state
--- there.
---@return string? address
---@return string? state
local find = function()
  ---@type { address?: string, state?: string }?
  local result
  route.find(path, function(address, state) result = { address = address, state = state } end)
  h.wait(function() return result ~= nil end, "the route is found")
  local found = assert(result)
  return found.address, found.state
end

test("the Neovim with unsaved changes to the file wins over one with it loaded", function()
  local loaded, stop_loaded = start_peer(("vim.cmd.edit(%q)"):format(path))
  local modified, stop_modified = start_peer(
    ("vim.cmd.edit(%q); vim.api.nvim_buf_set_lines(0, 0, -1, false, { 'changed' })"):format(path)
  )
  local address, state = find()
  h.eq(address, modified)
  h.eq(state, "modified")
  stop_modified()
  h.wait(function() return vim.uv.fs_stat(modified) == nil end, "the peer stops")
  address, state = find()
  h.eq(address, loaded)
  h.eq(state, "loaded")
  stop_loaded()
end)

test("a Neovim that doesn't answer is skipped after the timeout", function()
  route.timeout_ms = 50
  -- A socket that accepts connections but never answers.
  local silent = vim.fs.joinpath(run, "nvim.1.0")
  local server = assert(vim.uv.new_pipe(false))
  server:bind(silent)
  local clients = {}
  server:listen(8, function()
    local client = assert(vim.uv.new_pipe(false))
    server:accept(client)
    clients[#clients + 1] = client
  end)
  local loaded, stop = start_peer(("vim.cmd.edit(%q)"):format(path))

  local started = vim.uv.hrtime()
  local address = find()
  local elapsed_ms = (vim.uv.hrtime() - started) / 1e6
  h.eq(address, loaded)
  h.eq(elapsed_ms < route.timeout_ms * 3, true, ("it took %dms"):format(elapsed_ms))
  stop()
  for _, client in ipairs(clients) do
    client:close()
  end
  server:close()
end)

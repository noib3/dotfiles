local agents = require("nvim_agents")
local h = require("nvim_agents_tests")

local dir = h.tmpdir()
agents.setup({ agents = {}, state_dir = dir })

test("queued texts are files of their own in the session's inbox", function()
  local session = { agent = "claude", id = "main" }
  h.eq(agents.queue(session, "first"), nil)
  h.eq(agents.queue(session, "second"), nil)
  local inbox = vim.fs.joinpath(dir, "inbox", "claude", "main")
  local names = {}
  for name in vim.fs.dir(inbox) do
    names[#names + 1] = name
  end
  table.sort(names)
  h.eq(#names, 2)
  h.eq(
    vim.tbl_map(
      function(name) return h.read(vim.fs.joinpath(inbox, name)) end,
      names
    ),
    { "first", "second" }
  )
end)

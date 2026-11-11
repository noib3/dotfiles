local agents = require("nvim_agents")
local h = require("nvim_agents_tests")
local registry = require("nvim_agents.registry")

---@param dir string
---@param agent string
---@param id string
---@param events table[]
local log_events = function(dir, agent, id, events)
  local lines = vim.tbl_map(
    function(event) return vim.json.encode(event) .. "\n" end,
    events
  )
  h.append(vim.fs.joinpath(dir, agent, id .. ".jsonl"), table.concat(lines))
end

---@param matches nvim_agents.Match[]
---@return string[]
local ids = function(matches)
  return vim.tbl_map(function(match) return match.session.id end, matches)
end

test("sessions are folded from their events", function()
  local dir = h.tmpdir()
  log_events(dir, "claude", "a", {
    { event = "start", time = 10, cwd = "/repo", nvim = "/tmp/nvim.sock" },
    { event = "read", time = 11, path = "/repo/x.lua" },
    { event = "edit", time = 12, path = "/repo/x.lua" },
    { event = "edit", time = 13, path = "/repo/y.lua" },
  })
  local sessions = registry.load(dir, math.huge)
  h.eq(#sessions, 1)
  local session = assert(sessions[1])
  h.eq(session.agent, "claude")
  h.eq(session.id, "a")
  h.eq(session.cwd, "/repo")
  h.eq(session.nvim, "/tmp/nvim.sock")
  h.eq(session.running, true)
  h.eq(session.time, 13)
  h.eq(session.read, { ["/repo/x.lua"] = 11 })
  h.eq(session.edited, { ["/repo/x.lua"] = 12, ["/repo/y.lua"] = 13 })

  log_events(dir, "claude", "a", { { event = "end", time = 20 } })
  session = assert(registry.load(dir, math.huge)[1])
  h.eq(session.running, false)
  h.eq(session.time, 20)
  h.eq(session.edited["/repo/y.lua"], 13)
end)

test("a line is folded once it's complete", function()
  local dir = h.tmpdir()
  local path = vim.fs.joinpath(dir, "claude", "a.jsonl")
  h.append(path, '{"event":"start","time":1,"cwd":"/repo"}\n{"event":"edit",')
  local session = assert(registry.load(dir, math.huge)[1])
  h.eq(session.edited, {})
  h.append(path, '"time":2,"path":"/repo/x.lua"}\n')
  session = assert(registry.load(dir, math.huge)[1])
  h.eq(session.edited, { ["/repo/x.lua"] = 2 })
end)

test("old sessions are left out", function()
  local dir = h.tmpdir()
  local now = os.time()
  log_events(
    dir,
    "claude",
    "old",
    { { event = "start", time = now - 100, cwd = "/repo" } }
  )
  log_events(
    dir,
    "claude",
    "new",
    { { event = "start", time = now, cwd = "/repo" } }
  )
  h.eq(ids(registry.rank(registry.load(dir, 50), { "/repo/x.lua" })), { "new" })
end)

test(
  "sessions are ranked by edits, then reads, then directory, then activity",
  function()
    local dir = h.tmpdir()
    log_events(dir, "claude", "contains", {
      { event = "start", time = 50, cwd = "/repo" },
    })
    log_events(dir, "claude", "contains-later", {
      { event = "start", time = 60, cwd = "/repo" },
    })
    log_events(dir, "claude", "read", {
      { event = "start", time = 1, cwd = "/elsewhere" },
      { event = "read", time = 2, path = "/repo/x.lua" },
    })
    log_events(dir, "claude", "edited-one", {
      { event = "start", time = 1, cwd = "/elsewhere" },
      { event = "edit", time = 2, path = "/repo/x.lua" },
    })
    log_events(dir, "claude", "edited-both", {
      { event = "start", time = 1, cwd = "/elsewhere" },
      { event = "edit", time = 2, path = "/repo/x.lua" },
      { event = "edit", time = 3, path = "/repo/y.lua" },
    })
    log_events(dir, "claude", "unrelated", {
      { event = "start", time = 100, cwd = "/elsewhere" },
      { event = "edit", time = 101, path = "/elsewhere/z.lua" },
    })
    local sessions = registry.load(dir, math.huge)
    h.eq(ids(registry.rank(sessions, { "/repo/x.lua", "/repo/y.lua" })), {
      "edited-both",
      "edited-one",
      "read",
      "contains-later",
      "contains",
    })
  end
)

test(
  "a directory doesn't contain the paths of a sibling with its prefix",
  function()
    local dir = h.tmpdir()
    log_events(
      dir,
      "claude",
      "a",
      { { event = "start", time = 1, cwd = "/repo" } }
    )
    h.eq(
      ids(registry.rank(registry.load(dir, math.huge), { "/repo-2/x.lua" })),
      {}
    )
  end
)

test("sessions() matches symlinked paths and filters by agent", function()
  local state = h.tmpdir()
  local repo = h.tmpdir()
  local link = repo .. "-link"
  assert(vim.uv.fs_symlink(repo, link))
  h.write(vim.fs.joinpath(repo, "x.lua"), "")
  local dir = vim.fs.joinpath(state, "sessions")
  log_events(dir, "claude", "a", {
    { event = "start", time = os.time(), cwd = "/elsewhere" },
    { event = "edit", time = os.time(), path = vim.fs.joinpath(link, "x.lua") },
  })
  log_events(dir, "codex", "b", {
    { event = "start", time = os.time(), cwd = repo },
  })
  agents.setup({ state_dir = state })
  h.eq(
    ids(agents.sessions({ paths = { vim.fs.joinpath(repo, "x.lua") } })),
    { "a", "b" }
  )
  h.eq(
    ids(
      agents.sessions({
        paths = { vim.fs.joinpath(repo, "x.lua") },
        agent = "codex",
      })
    ),
    { "b" }
  )
end)

test("a session's title is its latest", function()
  local dir = h.tmpdir()
  log_events(dir, "claude", "titled", {
    { event = "start", time = 10, cwd = "/repo" },
    { event = "title", time = 11, title = "First title" },
    { event = "title", time = 12, title = "Second title" },
  })
  local session = assert(registry.load(dir, math.huge)[1])
  h.eq(session.title, "Second title")
end)

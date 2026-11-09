local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

--- Pushes the changes between two subjects' lines, and returns the messages
--- notified meanwhile.
---@param bufnr integer
---@param first string
---@param last? string
---@return string[]
local push = function(bufnr, first, last)
  local messages = #h.messages
  local done = false
  nvim_jj.push(
    bufnr,
    h.row(bufnr, first),
    h.row(bufnr, last or first),
    function() done = true end
  )
  h.wait(function() return done end, "the push is done")
  return vim.list_slice(h.messages, messages + 1)
end

--- Returns the subjects on a branch of the remote, newest first.
---@param root string
---@param branch? string The branch, by default `main`.
---@return string[]
local remote_main = function(root, branch)
  local stdout = h.run(root, {
    "git",
    "--git-dir",
    "../remote.git",
    "log",
    "--format=%s",
    branch or "main",
  })
  return vim.split(vim.trim(stdout), "\n")
end

---@param messages string[]
---@return string[]
local without_ids = function(messages)
  return vim.tbl_map(
    function(message)
      return (message:gsub("%f[%w]" .. ("[k-z]"):rep(8) .. "%f[%W]", "<id>"))
    end,
    messages
  )
end

test("pushing a change moves the bookmark it's on top of", function()
  local root = h.repo({ "one", "two", "three" }, 1)
  local bufnr = h.open(root)

  h.eq(without_ids(push(bufnr, "two")), {
    "info: Pushing <id> two to main@origin",
    "info: Pushed <id> two to main@origin",
  })
  h.eq(remote_main(root), { "two", "one" })
end)

test("pushing a change whose parent isn't pushed is an error", function()
  local root = h.repo({ "one", "two", "three" }, 1)
  local bufnr = h.open(root)

  h.eq(without_ids(push(bufnr, "three")), {
    "error: These ancestors aren't pushed:\n<id> two",
  })
  h.eq(remote_main(root), { "one" })
end)

test("pushing several changes moves the bookmark to the topmost", function()
  local root = h.repo({ "one", "two", "three" }, 1)
  local bufnr = h.open(root)

  h.eq(without_ids(push(bufnr, "three", "two")), {
    "info: Pushing <id> three to main@origin",
    "info: Pushed <id> three to main@origin",
  })
  h.eq(remote_main(root), { "three", "two", "one" })
end)

test("pushing a pushed change is a warning", function()
  local root = h.repo({ "one", "two" }, 2)
  local bufnr = h.open(root)

  h.eq(without_ids(push(bufnr, "two")), {
    "warn: <id> two is already pushed",
  })
end)

test("the pushed changes among the selected ones are skipped", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)

  h.eq(without_ids(push(bufnr, "two", "one")), {
    "warn: <id> one is already pushed",
    "info: Pushing <id> two to main@origin",
    "info: Pushed <id> two to main@origin",
  })
  h.eq(remote_main(root), { "two", "one" })
end)

test("pushing a change off a remote bookmark is an error", function()
  local root = h.repo({ "one", "two" }, 2)
  h.run(root, { "jj", "new", "--quiet", "@--", "-m", "three" })
  local bufnr = h.open(root)

  h.eq(without_ids(push(bufnr, "three")), {
    "error: <id> three isn't on top of a bookmark of origin",
  })
end)

test("pushing a change with a bookmark pushes the bookmark", function()
  local root = h.repo({ "one", "two" }, 1)
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  local bufnr = h.open(root)

  h.eq(without_ids(push(bufnr, "two")), {
    "info: Pushing <id> two to feature@origin",
    "info: Pushed <id> two to feature@origin",
  })
  h.eq(remote_main(root, "feature"), { "two", "one" })
  h.eq(remote_main(root), { "one" })
end)

test("a bookmark's change is pushed again once it's rewritten", function()
  local root = h.repo({ "one", "two" }, 1)
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  local bufnr = h.open(root)
  push(bufnr, "two")

  h.run(root, { "jj", "describe", "--quiet", "-r", "@-", "-m", "dos" })
  h.settle()
  push(bufnr, "dos")

  h.eq(remote_main(root, "feature"), { "dos", "one" })
end)

local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

--- The default of the last bookmark prompt.
---@type string?
local prompted

--- Pushes the changes between two subjects' lines, and returns the messages
--- notified meanwhile. The bookmark prompt is answered with the given name,
--- or else its default.
---@param bufnr integer
---@param first string
---@param last? string
---@param push_opts? { branch?: boolean, name?: string }
---@return string[]
local push = function(bufnr, first, last, push_opts)
  push_opts = push_opts or {}
  local messages = #h.messages
  local done = false
  local input = vim.ui.input
  prompted = nil
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.input = function(opts, on_confirm)
    opts = opts or {}
    prompted = opts.default
    on_confirm(push_opts.name or opts.default)
  end
  nvim_jj.push(
    bufnr,
    h.row(bufnr, first),
    h.row(bufnr, last or first),
    push_opts.branch == true,
    function() done = true end
  )
  h.wait(function() return done end, "the push is done")
  vim.ui.input = input
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
  h.eq(prompted, nil)
  h.eq(remote_main(root), { "two", "one" })
end)

test("pushing a change on a new branch names it after the change", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)

  local id = h.query(root, "@-", "change_id.short()")[1]
  local branch = "push-" .. id
  h.eq(without_ids(push(bufnr, "two", nil, { branch = true })), {
    ("info: Pushing <id> two to %s@origin"):format(branch),
    ("info: Pushed <id> two to %s@origin"):format(branch),
  })
  h.eq(prompted, branch)
  h.eq(remote_main(root, branch), { "two", "one" })
  h.eq(remote_main(root), { "one" })
end)

--- Answers the next select with the item that's the given choice, and
--- returns its prompt once it's answered.
---@param choice string
---@return fun(): string?
local answer_select = function(choice)
  local select = vim.ui.select
  ---@type string?
  local prompt
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.select = function(items, opts, on_choice)
    vim.ui.select = select
    prompt = (opts or {}).prompt
    on_choice(vim.list_contains(items, choice) and choice or nil)
  end
  return function() return prompt end
end

test("naming an existing bookmark on a new branch asks before moving it", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)

  local prompt = answer_select("Cancel")
  h.eq(push(bufnr, "two", nil, { branch = true, name = "main" }), {})
  h.eq(without_ids({ assert(prompt()) }), { "main is already on <id> one" })
  h.eq(remote_main(root), { "one" })

  answer_select("Move it")
  push(bufnr, "two", nil, { branch = true, name = "main" })
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

test("pushing a change off a remote bookmark prompts for a new branch", function()
  local root = h.repo({ "one", "two" }, 2)
  h.run(root, { "jj", "new", "--quiet", "@--", "-m", "three" })
  local bufnr = h.open(root)

  local branch = "push-" .. h.query(root, "@", "change_id.short()")[1]
  push(bufnr, "three")
  h.eq(prompted, branch)
  h.eq(remote_main(root, branch), { "three", "one" })
end)

test("a confirmed bookmark moves off its descendants", function()
  local root = h.repo({ "one", "two" }, 2)
  h.run(root, { "jj", "new", "--quiet", "@--", "-m", "three" })
  local bufnr = h.open(root)

  answer_select("Move it")
  push(bufnr, "three", nil, { branch = true, name = "main" })
  h.eq(remote_main(root), { "three", "one" })
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

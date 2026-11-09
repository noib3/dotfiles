local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

--- The default of the last bookmark prompt.
---@type string?
local prompted

--- Pushes the changes between two subjects' lines, and waits until it's
--- done. The bookmark prompt is answered with the given name, or else its
--- default.
---@param bufnr integer
---@param first string
---@param last? string
---@param push_opts? { branch?: boolean, name?: string }
local push = function(bufnr, first, last, push_opts)
  push_opts = push_opts or {}
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
end

--- Answers the next select with the item that's the given choice, and
--- returns a function returning its prompt once it's answered.
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

---@param text? string
---@return string?
local without_ids = function(text)
  return text and (text:gsub("%f[%w]" .. ("[k-z]"):rep(8) .. "%f[%W]", "<id>"))
end

test("pushing a change moves the bookmark it's on top of", function()
  local root = h.repo({ "one", "two", "three" }, 1)
  local bufnr = h.open(root)

  push(bufnr, "two")
  h.eq(h.status(bufnr, "two"), "done: Pushed to main@origin")
  h.eq(prompted, nil)
  h.eq(remote_main(root), { "two", "one" })
end)

test("pushing a change on a new branch names it after the change", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)

  local branch = "push-" .. h.query(root, "@-", "change_id.short()")[1]
  push(bufnr, "two", nil, { branch = true })
  h.eq(prompted, branch)
  h.eq(h.status(bufnr, "two"), ("done: Pushed to %s@origin"):format(branch))
  h.eq(remote_main(root, branch), { "two", "one" })
  h.eq(remote_main(root), { "one" })
end)

test("naming an existing bookmark on a new branch asks before moving it", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)

  local prompt = answer_select("Cancel")
  push(bufnr, "two", nil, { branch = true, name = "main" })
  h.eq(without_ids(prompt()), "main is already on <id> one")
  h.eq(h.status(bufnr, "two"), nil)
  h.eq(remote_main(root), { "one" })

  answer_select("Move it")
  push(bufnr, "two", nil, { branch = true, name = "main" })
  h.eq(remote_main(root), { "two", "one" })
end)

test("pushing a change whose parent isn't pushed is an error", function()
  local root = h.repo({ "one", "two", "three" }, 1)
  local bufnr = h.open(root)

  push(bufnr, "three")
  h.eq(
    without_ids(h.status(bufnr, "three")),
    "failed: These ancestors aren't pushed: <id> two"
  )
  h.eq(remote_main(root), { "one" })
end)

test("pushing several changes moves the bookmark to the topmost", function()
  local root = h.repo({ "one", "two", "three" }, 1)
  local bufnr = h.open(root)

  push(bufnr, "three", "two")
  h.eq(h.status(bufnr, "three"), "done: Pushed to main@origin")
  h.eq(remote_main(root), { "three", "two", "one" })
end)

test("pushing a pushed change is a warning", function()
  local root = h.repo({ "one", "two" }, 2)
  local bufnr = h.open(root)

  push(bufnr, "two")
  h.eq(h.status(bufnr, "two"), "warning: Already pushed")
end)

test("the pushed changes among the selected ones are skipped", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)

  push(bufnr, "two", "one")
  h.eq(h.status(bufnr, "one"), "warning: Already pushed")
  h.eq(h.status(bufnr, "two"), "done: Pushed to main@origin")
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

  push(bufnr, "two")
  h.eq(h.status(bufnr, "two"), "done: Pushed to feature@origin")
  h.eq(remote_main(root, "feature"), { "two", "one" })
  h.eq(remote_main(root), { "one" })
end)

test("pushing a rewritten change asks before overwriting its bookmark", function()
  local root = h.repo({ "one", "two" }, 1)
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  local bufnr = h.open(root)
  push(bufnr, "two")

  h.run(root, { "jj", "describe", "--quiet", "-r", "@-", "-m", "dos" })
  h.settle()
  local prompt = answer_select("Cancel")
  push(bufnr, "dos")
  h.eq(
    prompt(),
    "feature@origin has changed since it was pushed, and pushing overwrites it"
  )
  h.eq(remote_main(root, "feature"), { "two", "one" })

  answer_select("Overwrite it")
  push(bufnr, "dos")
  h.eq(remote_main(root, "feature"), { "dos", "one" })
end)

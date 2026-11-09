local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

--- A stand-in for the GitHub CLI. Listing pull requests prints the JSON in
--- the file next to it, if any, and anything else saves its arguments next to
--- it and prints a pull request's URL.
local gh = vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "nvim-jj-gh")
local gh_args = gh .. ".args"
local gh_list = gh .. ".list"
local file = assert(io.open(gh, "w"))
file:write(table.concat({
  "#!/bin/sh",
  ('if [ "$1 $2" = "pr list" ]; then cat %q 2>/dev/null || echo "[]"; exit 0; fi'):format(gh_list),
  ('printf "%%s\\n" "$@" > %q'):format(gh_args),
  "echo https://github.com/o/r/pull/1",
  "",
}, "\n"))
file:close()
vim.uv.fs_chmod(gh, 493)

h.setup({ gh = gh })

---@param fn fun(on_done: fun(...))
local wait_for = function(fn)
  local done = false
  fn(function() done = true end)
  h.wait(function() return done end, "the operation is done")
  h.settle()
end

test("fetching offers to move the working copy onto the new trunk", function()
  local root = h.repo({ "one" }, 1)
  h.run(root, { "jj", "describe", "--quiet", "-m", "mine" })

  local other = vim.fs.joinpath(vim.fs.dirname(root), "other")
  h.run(vim.fs.dirname(root), { "jj", "git", "clone", "--quiet", "remote.git", other })
  local theirs = assert(io.open(vim.fs.joinpath(other, "theirs"), "w"))
  theirs:write("theirs\n")
  theirs:close()
  h.run(other, { "jj", "commit", "--quiet", "-m", "theirs" })
  h.run(other, { "jj", "bookmark", "set", "--quiet", "main", "-r", "@-" })
  h.run(other, { "jj", "git", "push", "--quiet", "--bookmark", "main" })

  local bufnr = h.open(root)
  local select = vim.ui.select
  ---@type string?
  local prompt
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.select = function(items, opts, on_choice)
    prompt = opts.prompt
    on_choice(items[1])
  end
  wait_for(function(on_done) nvim_jj.fetch(bufnr, on_done) end)
  vim.ui.select = select

  h.eq(prompt, "main moved, and 1 change aren't on top of it")
  h.eq(h.query(root, "@-", "description.first_line()"), { "theirs" })
end)

--- Creates a repo whose `feature` bookmark is pushed on top of `main`, with
--- a remote on GitHub, and opens its log.
---@param descriptions string[]
---@return string root
---@return integer bufnr
local github_repo = function(descriptions)
  local root = h.repo(descriptions, 1)
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  h.run(root, { "jj", "git", "push", "--quiet", "--bookmark", "feature" })
  h.run(root, {
    "jj",
    "git",
    "remote",
    "set-url",
    "origin",
    "https://github.com/o/r.git",
  })
  return root, h.open(root)
end

--- Starts opening a pull request of the change on a subject's line, and
--- returns the editor's lines once it's shown, and a function waiting until
--- the pull request is opened or abandoned.
---@param bufnr integer
---@param subject string
---@return string[] lines
---@return fun() wait
local start_pull_request = function(bufnr, subject)
  local done = false
  nvim_jj.open_pull_request(bufnr, h.row(bufnr, subject), function() done = true end)
  h.wait(
    function() return vim.startswith(vim.api.nvim_buf_get_name(0), "jj-pr://") end,
    "the editor is shown"
  )
  local wait = function()
    h.wait(function() return done end, "the pull request is done")
    h.settle()
  end
  return vim.api.nvim_buf_get_lines(0, 0, -1, false), wait
end

---@return string[]
local gh_arguments = function()
  local args = io.open(gh_args)
  if not args then return {} end
  local text = args:read("*a")
  args:close()
  return vim.split(text, "\n", { trimempty = true })
end

test("a pull request is opened once its editor is written and quit", function()
  os.remove(gh_args)
  local _, bufnr = github_repo({ "one", "two" })
  local windows = #vim.api.nvim_tabpage_list_wins(0)

  local lines, wait = start_pull_request(bufnr, "two")
  h.eq(lines, { "two", "" })
  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "A title", "", "A description" })
  vim.cmd.write()
  vim.cmd.quit()
  wait()

  h.eq(gh_arguments(), {
    "pr",
    "create",
    "--repo",
    "o/r",
    "--head",
    "feature",
    "--base",
    "main",
    "--title",
    "A title",
    "--body",
    "A description",
  })
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.eq(#vim.api.nvim_tabpage_list_wins(0), windows)
  h.eq(h.status(bufnr, "two"), "done: Opened pull request #1")
  local drawn = vim.iter(h.screen(bufnr)):any(
    function(line) return vim.startswith(line, "○  <id> two feature \239\144\136 #1 ") end
  )
  h.eq(drawn, true)
end)

test("quitting the pull request's editor without writing it abandons it", function()
  os.remove(gh_args)
  local _, bufnr = github_repo({ "one", "two" })

  local _, wait = start_pull_request(bufnr, "two")
  vim.cmd("quit!")
  wait()

  h.eq(gh_arguments(), {})
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.eq(h.status(bufnr, "two"), "warning: Didn't open a pull request")
end)

test("a pull request of several changes starts from the template", function()
  local root = h.repo({ "one", "two", "three" }, 1)
  h.run(root, { "jj", "bookmark", "create", "--quiet", "my-feature", "-r", "@-" })
  h.run(root, { "jj", "git", "push", "--quiet", "--bookmark", "my-feature" })
  h.run(root, {
    "jj",
    "git",
    "remote",
    "set-url",
    "origin",
    "https://github.com/o/r.git",
  })
  vim.fn.mkdir(vim.fs.joinpath(root, ".github"), "p")
  local template = assert(io.open(vim.fs.joinpath(root, ".github", "PULL_REQUEST_TEMPLATE.md"), "w"))
  template:write("## Summary\n")
  template:close()
  local bufnr = h.open(root)

  local lines, wait = start_pull_request(bufnr, "three")
  h.eq(lines, { "My feature", "", "## Summary" })
  vim.cmd("quit!")
  wait()
end)

test("a pull request of a bookmark that isn't pushed is an error", function()
  local root = h.repo({ "one", "two" }, 1)
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  h.run(root, {
    "jj",
    "git",
    "remote",
    "set-url",
    "origin",
    "https://github.com/o/r.git",
  })
  local bufnr = h.open(root)

  wait_for(function(on_done) nvim_jj.open_pull_request(bufnr, h.row(bufnr, "two"), on_done) end)
  h.eq(h.status(bufnr, "two"), "failed: Push feature to origin first")
end)

--- Returns the code actions on a line of a log buffer.
---@param bufnr integer
---@param line integer
---@return lsp.CodeAction[]
local code_actions = function(bufnr, line)
  local client = assert(vim.lsp.get_clients({ bufnr = bufnr, name = "nvim-jj" })[1])
  local response = client:request_sync("textDocument/codeAction", {
    textDocument = { uri = vim.uri.from_buf(bufnr) },
    range = {
      start = { line = line - 1, character = 0 },
      ["end"] = { line = line - 1, character = 0 },
    },
    context = { diagnostics = {} },
  }, 2000, bufnr)
  return response and response.result or {}
end

---@param actions lsp.CodeAction[]
---@return string[]
local titles = function(actions)
  return vim.tbl_map(function(action) return action.title end, actions)
end

test("opening a pull request is a code action of a change with a bookmark", function()
  os.remove(gh_list)
  local _, bufnr = github_repo({ "one", "two" })
  h.wait(function() return #code_actions(bufnr, h.row(bufnr, "two")) > 0 end, "the repo is found")

  h.eq(code_actions(bufnr, 1), {})
  h.eq(titles(code_actions(bufnr, h.row(bufnr, "two"))), { "\239\144\136 Open a PR on GitHub" })
end)

test("an open pull request is drawn after its bookmark, and can be browsed", function()
  local list = assert(io.open(gh_list, "w"))
  list:write(vim.json.encode({
    { number = 7, headRefName = "feature", url = "https://github.com/o/r/pull/7", isCrossRepository = false },
    { number = 8, headRefName = "main", url = "https://github.com/x/r/pull/8", isCrossRepository = true },
  }))
  list:close()
  local _, bufnr = github_repo({ "one", "two" })
  h.wait(
    function() return vim.tbl_contains(h.screen(bufnr), "○  <id> two feature \239\144\136 #7") end,
    "the pull request is drawn"
  )
  os.remove(gh_list)

  local actions = code_actions(bufnr, h.row(bufnr, "two"))
  h.eq(titles(actions), { "\239\144\136 Open PR #7 in the browser" })
  local opened
  local open = vim.ui.open
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.open = function(url) opened = url end
  local client = assert(vim.lsp.get_clients({ bufnr = bufnr, name = "nvim-jj" })[1])
  client:exec_cmd(assert(assert(actions[1]).command), { bufnr = bufnr })
  h.wait(function() return opened ~= nil end, "the pull request is browsed")
  vim.ui.open = open
  h.eq(opened, "https://github.com/o/r/pull/7")
end)

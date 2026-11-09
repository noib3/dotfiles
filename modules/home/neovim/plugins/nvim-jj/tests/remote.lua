local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

--- A stand-in for the GitHub CLI, which saves its arguments next to itself
--- and prints a pull request's URL.
local gh = vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "nvim-jj-gh")
local gh_args = gh .. ".args"
local file = assert(io.open(gh, "w"))
file:write(
  ('#!/bin/sh\nprintf "%%s\\n" "$@" > %q\necho https://github.com/o/r/pull/1\n'):format(
    gh_args
  )
)
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

test("a pull request goes from the change's bookmark into the one below it", function()
  local root = h.repo({ "one", "two" }, 1)
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
  local bufnr = h.open(root)

  ---@type string?
  local url
  wait_for(function(on_done)
    nvim_jj.open_pull_request(bufnr, h.row(bufnr, "two"), function(_, opened)
      url = opened
      on_done()
    end)
  end)
  h.eq(url, "https://github.com/o/r/pull/1")
  local args = assert(io.open(gh_args)):read("*a")
  h.eq(
    vim.split(args, "\n", { trimempty = true }),
    { "pr", "create", "--repo", "o/r", "--head", "feature", "--base", "main", "--title", "two", "--body" }
  )
end)

test("a pull request of a bookmark that isn't pushed is an error", function()
  local root = h.repo({ "one", "two" }, 1)
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  local bufnr = h.open(root)

  h.messages = {}
  wait_for(function(on_done) nvim_jj.open_pull_request(bufnr, h.row(bufnr, "two"), on_done) end)
  h.eq(h.messages, { "error: Push feature to origin first" })
end)

local context = require("nvim_threads.context")
local h = require("nvim_threads_tests")
local render = require("nvim_threads.render")
local threads = require("nvim_threads")

h.setup(80, 24)

test("the hunks overlapping the selection are picked", function()
  local diff = table.concat({
    "diff --git a/f.txt b/f.txt",
    "--- a/f.txt",
    "+++ b/f.txt",
    "@@ -1,3 +1,3 @@",
    " a",
    "-b",
    "+B",
    " c",
    "@@ -10,2 +10,3 @@",
    " j",
    "+k",
    " l",
  }, "\n")
  h.eq(context.overlapping_hunks(diff, 2, 2), {
    "@@ -1,3 +1,3 @@\n a\n-b\n+B\n c",
  })
  h.eq(#context.overlapping_hunks(diff, 4, 9), 0)
  h.eq(#context.overlapping_hunks(diff, 1, 12), 2)
end)

test("the scopes around the selection are named", function()
  local lines = {
    "local M = {}",
    "",
    "function M.outer()",
    "  local inner = function(x)",
    "    return x + 1",
    "  end",
    "end",
  }
  local scopes = context.scopes({
    root = "/",
    path = "f.lua",
    lines = lines,
    filetype = "lua",
  }, { start_row = 4, start_col = 4, end_row = 4, end_col = 16 })
  h.eq(scopes, { "function M.outer()", "local inner = function(x)" })
end)

test("the context has the selection and the hunks it overlaps", function()
  local root = h.repo({
    ["f.lua"] = h.text({ "local a = 1", "local b = 2", "return a" }),
  }, {
    ["f.lua"] = h.text({ "local a = 1", "local b = 3", "return a" }),
  })

  ---@type string?
  local built
  context.build(
    {
      root = root,
      path = "f.lua",
      lines = { "local a = 1", "local b = 3", "return a" },
      filetype = "lua",
    },
    { start_row = 1, start_col = 6, end_row = 1, end_col = 7 },
    function(text) built = text end
  )
  h.wait(function() return built ~= nil end, "the context is built")
  local text = assert(built)

  h.eq(
    text:find("```lua " .. root .. "/f.lua:2\nb\n```", 1, true) ~= nil,
    true,
    text
  )
  h.eq(
    text:find("starts at column 7 of line 2 and ends at column 7", 1, true)
      ~= nil,
    true,
    text
  )
  h.eq(text:find("-local b = 2\n+local b = 3", 1, true) ~= nil, true, text)
end)

test("lines wrap after spaces where possible", function()
  h.eq(render.wrap("aaa bbb ccc", 8), { { 0, 8 }, { 8, 11 } })
  h.eq(render.wrap("abcdefghij", 4), { { 0, 4 }, { 4, 8 }, { 8, 10 } })
  h.eq(render.wrap("", 4), { { 0, 0 } })
end)

test("the composer completes the participants after `@`", function()
  threads.register({ name = "claude", send = function() end })
  threads.register({
    name = "hidden",
    attaches = function() return false end,
    send = function() end,
  })

  local root = h.repo({ ["f.txt"] = "a\n" }, {})
  h.open(root, "f.txt")
  h.eq(threads.create(), true)
  vim.cmd.stopinsert()
  h.type({ "hey @cl" })

  local client = vim.lsp.get_clients({ bufnr = 0, name = "nvim-threads" })[1]
  h.eq(client ~= nil, true, "the language server is attached")
  ---@cast client -nil
  local response = client:request_sync("textDocument/completion", {
    textDocument = { uri = vim.uri.from_buf(vim.api.nvim_get_current_buf()) },
    position = { line = vim.api.nvim_buf_line_count(0) - 1, character = 7 },
  }, 1000, 0)
  local items = assert(response and response.result).items
  h.eq(vim.tbl_map(function(item) return item.label end, items), { "claude" })
  h.eq(items[1].textEdit.range.start.character, 5)
end)

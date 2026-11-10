local h = require("nvim_threads_tests")
local threads = require("nvim_threads")

h.setup(60, 20)
vim.o.termguicolors = true

local root = h.repo({ ["f.txt"] = h.text({ "one", "two", "three" }) }, {
  ["f.txt"] = h.text({ "one", "TWO", "three" }),
})

test("a thread's virtual lines don't take the gutter of their line", function()
  local bufnr = h.open(root, "f.txt")
  vim.wo.number = true
  vim.api.nvim_set_hl(0, "TestNr", { bg = 0xff0000 })
  -- Like nvim-hunks' highlight of a changed line's number.
  local namespace = vim.api.nvim_create_namespace("nvim-threads-tests")
  vim.api.nvim_buf_set_extmark(bufnr, namespace, 1, 0, {
    number_hl_group = "TestNr",
  })

  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  h.eq(threads.create(), true)
  vim.cmd.stopinsert()
  h.type({ "why?" })
  h.eq(threads.submit(), true)
  h.leave()
  vim.cmd.redraw()

  -- Rows 1 to 3 are the first two lines and the thread's collapsed line.
  h.eq(vim.fn.screenstring(3, 8), "▸", "the thread follows the second line")
  local changed = vim.fn.screenattr(2, 1)
  local plain = vim.fn.screenattr(1, 1)
  h.eq(changed ~= plain, true, "the changed line's number is highlighted")
  h.eq(vim.fn.screenattr(3, 1), plain)
end)

test("a thread's virtual lines have their own background", function()
  vim.api.nvim_set_hl(0, "ThreadsNormal", { bg = 0x00ff00 })
  vim.cmd.redraw()
  local text = vim.fn.screenattr(1, vim.o.columns)
  local thread = vim.fn.screenattr(3, vim.o.columns)
  h.eq(thread ~= text, true, "the background reaches the window's edge")
end)

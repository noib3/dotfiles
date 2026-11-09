local h = require("nvim_jj_tests")

h.setup({ lookahead = 20 })

local count = 3000

---@param bufnr integer
---@return integer
local line_count = function(bufnr) return vim.api.nvim_buf_line_count(bufnr) end

test("only the changes close to the view are loaded", function()
  local root = h.long_repo(count)
  local bufnr = h.open(root)

  h.eq(vim.api.nvim_buf_get_lines(bufnr, 0, 3, false), {
    " ",
    ("commit %d"):format(count),
    ("commit %d"):format(count - 1),
  })
  h.eq(line_count(bufnr) < count, true, "the whole log is loaded")
end)

test("scrolling to the end loads more changes", function()
  local root = h.long_repo(count)
  local bufnr = h.open(root)

  local loaded = line_count(bufnr)
  for _ = 1, 100 do
    if line_count(bufnr) == count + 2 then break end
    vim.cmd.normal({ "G", bang = true })
    vim.api.nvim_exec_autocmds("WinScrolled", {})
    vim.wait(20)
  end

  h.eq(loaded < line_count(bufnr), true, "no more changes are loaded")
  h.eq(vim.api.nvim_buf_get_lines(bufnr, -4, -1, false), {
    "commit 2",
    "commit 1",
    " ",
  })
end)

test("a redraw keeps the changes loaded so far", function()
  local root = h.long_repo(count)
  local bufnr = h.open(root)
  for _ = 1, 10 do
    vim.cmd.normal({ "G", bang = true })
    vim.api.nvim_exec_autocmds("WinScrolled", {})
    vim.wait(20)
  end
  local loaded = line_count(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)[1]
  local subject = vim.api.nvim_get_current_line()

  h.run(root, { "jj", "describe", "--quiet", "-m", "wip" })
  h.wait(
    function() return vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == "wip" end,
    "the log is redrawn"
  )

  h.eq(line_count(bufnr) >= loaded, true, "the loaded changes are dropped")
  h.eq(vim.api.nvim_win_get_cursor(0)[1], cursor)
  h.eq(vim.api.nvim_get_current_line(), subject)
end)

test("a scroll before jj's first output doesn't empty the log", function()
  local root = h.long_repo(count)
  require("nvim_jj").toggle(root)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_exec_autocmds("WinScrolled", {})
  h.wait(function() return line_count(bufnr) > 1 end, "the log is drawn")
end)

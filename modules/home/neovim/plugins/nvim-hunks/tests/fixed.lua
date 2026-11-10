local h = require("nvim_hunks_tests")
local hunks = require("nvim_hunks")

h.setup(80, 24)

---@param lines string[]
---@return string
local text = function(lines) return table.concat(lines, "\n") .. "\n" end

test("a buffer is diffed against a fixed text", function()
  local buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "a", "B", "c", "d" })
  vim.api.nvim_set_current_buf(buf)
  hunks.attach_base(buf, { "a", "b", "c" })
  h.wait(function() return hunks.hunks(buf) ~= nil end, "the buffer is diffed")
  h.eq(#assert(hunks.hunks(buf)), 2)
end)

test(
  "moving a hunk of a buffer diffed against a fixed text reverts it",
  function()
    local buf = vim.api.nvim_get_current_buf()
    vim.api.nvim_win_set_cursor(0, { 2, 0 })
    h.eq(hunks.move("@-"), true)
    h.eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "a", "b", "c", "d" })
    h.wait(
      function() return #(hunks.hunks(buf) or {}) == 1 end,
      "the hunk is gone"
    )
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    h.eq(hunks.move("@-"), true)
    h.eq(vim.api.nvim_buf_get_lines(buf, 0, -1, false), { "a", "b", "c" })
  end
)

test("a buffer diffed against a fixed text keeps its diff", function()
  local buf = vim.api.nvim_get_current_buf()
  hunks.show_all(true)
  hunks.show_all(false)
  h.eq(hunks.is_shown(buf), true)
end)

test("moving lines out of the working copy announces them", function()
  local root = h.repo({ ["f.txt"] = text({ "1", "2", "3" }) }, {
    ["f.txt"] = text({ "1", "TWO", "3" }),
  })
  local parent = vim.trim(
    h.run(root, { "jj", "log", "--no-graph", "-r", "@-", "-T", "change_id" })
  )

  ---@type table?
  local moved
  vim.api.nvim_create_autocmd("User", {
    pattern = "NvimHunksMoved",
    once = true,
    callback = function(ev) moved = ev.data end,
  })

  ---@type nvim_hunks.File?
  local file
  hunks.files({ root }, function(files) file = files[1] end)
  h.wait(function() return file ~= nil end, "the files are listed")
  ---@cast file -nil
  hunks.move_hunk(file, assert(file.hunks[1]), "@-")
  h.wait(function() return moved ~= nil end, "the move is announced")
  h.eq(moved, { root = root, path = "f.txt", into = parent, lines = { 2 } })
end)

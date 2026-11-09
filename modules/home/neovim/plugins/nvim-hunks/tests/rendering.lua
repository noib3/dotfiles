local h = require("nvim_hunks_tests")
local hunks = require("nvim_hunks")

h.setup(40, 16)

---@param root string
---@param path string
local show_diff = function(root, path)
  vim.cmd.edit(vim.fs.joinpath(root, path))
  vim.wo.number = true
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.wrap = true
  vim.wo.list = true
  vim.wo.listchars = "eol:¬"
  vim.wo.showbreak = "↪ "
  vim.wo.colorcolumn = "12"
  hunks.toggle()
  h.wait(function() return #(hunks.hunks() or {}) > 0 end, "the diff is drawn")
end

local root = h.repo({
  ["f.txt"] = table.concat({
    "keep 1",
    "old value here",
    "drop a",
    "drop longer line",
    "keep 2",
    "",
  }, "\n"),
}, {
  ["f.txt"] = table.concat({
    "keep 1",
    "new value here",
    "keep 2",
    "this added line is long enough to wrap around",
    "",
    "keep 3",
    "",
  }, "\n"),
})

test("hunks are drawn as boxes across the text area", function()
  show_diff(root, "f.txt")
  h.eq(
    h.screen(1, 10),
    table.concat({
      "  1 keep 1¬",
      "...............c........................",
      "    old value here¬",
      "hhhhDDDddddddddcdddddddddddddddddddddddd",
      "    drop a¬",
      "hhhhdddddddddddcdddddddddddddddddddddddd",
      "    drop longer line¬",
      "hhhhdddddddddddcdddddddddddddddddddddddd",
      "  2 new value here¬",
      "ggggAAAaaaaaaaacaaaaaaaaaaaaaaaaaaaaaaaa",
      "  3 keep 2¬",
      "...............c........................",
      "  4 this added line is long enough to wr",
      "ggggaaaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaaaa",
      "    ↪ ap around¬",
      "ggggaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
      "  5 ¬",
      "ggggaaaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaaaa",
      "  6 keep 3¬",
      "ggggaaaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaaaa",
    }, "\n")
  )
end)

test("stepping into deleted lines enters a float of them", function()
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  hunks.step(-1, "k")
  hunks.step(-1, "k")
  local win = vim.api.nvim_get_current_win()
  h.eq(vim.api.nvim_win_get_config(win).relative, "win")
  h.eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), {
    "old value here",
    "drop a",
    "drop longer line",
  })
end)

test("the floats close when the window is resized", function()
  vim.cmd.edit(vim.fs.joinpath(root, "f.txt"))
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  h.eq(#hunks.open_floats(vim.api.nvim_get_current_win()), 1)
  vim.cmd.vsplit()
  vim.cmd.only()
  h.eq(
    vim.tbl_filter(
      function(win) return vim.api.nvim_win_get_config(win).relative ~= "" end,
      vim.api.nvim_list_wins()
    ),
    {}
  )
end)

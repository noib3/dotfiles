local h = require("nvim_hunks_tests")
local hunks = require("nvim_hunks")

h.setup(40, 16)

---@param root string
---@param path string
---@param options? table<string, any> The window options other than the defaults.
local show_diff = function(root, path, options)
  vim.cmd.edit(vim.fs.joinpath(root, path))
  vim.wo.number = true
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.wrap = true
  vim.wo.list = true
  vim.wo.listchars = "eol:¬"
  vim.wo.showbreak = "↪ "
  vim.wo.colorcolumn = "12"
  -- OptionSet doesn't fire during startup, which runs the tests.
  for name, value in pairs(options or {}) do
    vim.wo[name] = value
  end
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

-- The kept line shows where Neovim draws the colorcolumns of the added one.
local wide = ("a"):rep(35) .. "漢字\tbbbbbbb"
local wide_root = h.repo(
  { ["w.txt"] = wide .. "\n" },
  { ["w.txt"] = wide .. "\n" .. wide .. "\n" }
)

test("wide characters move to the next row of wrapped lines", function()
  show_diff(
    wide_root,
    "w.txt",
    { listchars = "eol:¬,tab:  ", colorcolumn = "12,45,47" }
  )
  h.eq(
    h.screen(1, 4),
    table.concat({
      "  1 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa>",
      "ggggaaaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaaaa",
      "    ↪ 漢字      bbbbbbb¬",
      "ggggaaaaaaaacacaaaaaaaaaaaaaaaaaaaaaaaaa",
      "  2 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa>",
      "...............c........................",
      "    ↪ 漢字      bbbbbbb¬",
      "............c.c.........................",
    }, "\n")
  )
end)

test("lines scrolled sideways keep their boxes and colorcolumns", function()
  local repo = h.repo(
    { ["s.txt"] = "keep\nold\tline 漢字 that is gone\nkeep\n" },
    { ["s.txt"] = "keep\nnew\tline\nkeep\n" .. ("x"):rep(60) .. "\n" }
  )
  show_diff(
    repo,
    "s.txt",
    { wrap = false, listchars = "eol:¬,tab:  ", colorcolumn = "6,16" }
  )
  vim.api.nvim_win_set_cursor(0, { 4, 0 })

  -- The main loop reports the scrolls, which headless tests don't run.
  vim.cmd("normal! 5zl")
  vim.api.nvim_exec_autocmds("WinScrolled", {})
  h.eq(
    h.screen(2, 3),
    table.concat({
      "       line 漢字 that is gone¬",
      "hhhhcddddddDDDccDDDDDDDDDDDDDddddddddddd",
      "  2    line¬",
      "ggggcaaaaaaaaacaaaaaaaaaaaaaaaaaaaaaaaaa",
    }, "\n")
  )

  vim.cmd("normal! 9zl")
  vim.api.nvim_exec_autocmds("WinScrolled", {})
  h.eq(
    h.screen(2, 3),
    table.concat({
      "     字 that is gone¬",
      "hhhhDccDDDDDDDDDDDDDdddddddddddddddddddd",
      "  2",
      "ggggacaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
    }, "\n"),
    "a line's end scrolled out of view keeps its box"
  )
end)

test("deleted lines above the first line show at the top", function()
  local rest = ("x\n"):rep(40)
  local repo = h.repo(
    { ["top.txt"] = "gone 1\ngone 2\nkeep\n" .. rest },
    { ["top.txt"] = "keep\n" .. rest }
  )
  show_diff(repo, "top.txt")
  local expected = table.concat({
    "    gone 1¬",
    "hhhhdddddddddddcdddddddddddddddddddddddd",
    "    gone 2¬",
    "hhhhdddddddddddcdddddddddddddddddddddddd",
    "  1 keep¬",
    "...............c........................",
  }, "\n")
  h.eq(h.screen(1, 3), expected)

  -- The main loop reports the scrolls, which headless tests don't run.
  vim.cmd("normal! G")
  vim.api.nvim_exec_autocmds("WinScrolled", {})
  vim.cmd("normal! gg")
  vim.api.nvim_exec_autocmds("WinScrolled", {})
  h.eq(h.screen(1, 3), expected, "scrolling back to the top shows them again")
end)

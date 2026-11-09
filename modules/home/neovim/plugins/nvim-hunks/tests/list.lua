local h = require("nvim_hunks_tests")
local hunks = require("nvim_hunks")

h.setup(60, 30)
-- trouble's module forwards to `trouble.api`, which EmmyLua can't see through.
---@diagnostic disable-next-line: undefined-field
require("trouble").setup({})

local lines = function(from, to)
  local result = {}
  for line = from, to do
    result[#result + 1] = ("line %d"):format(line)
  end
  return result
end

local x = lines(1, 40)
local x_new = vim.deepcopy(x)
x_new[2] = "LINE 2"
x_new[30] = "LINE 30"

local root = h.repo({
  ["modules/a/x.txt"] = table.concat(x, "\n") .. "\n",
  ["old.txt"] = "gone\nfor good\n",
  ["ren.txt"] = "moved\n",
  ["root.txt"] = "before\n",
}, {
  ["modules/a/x.txt"] = table.concat(x_new, "\n") .. "\n",
  ["docs/new.md"] = "new\n",
  ["src/ren.txt"] = "moved\n",
  ["root.txt"] = "after\n",
})

--- Returns the window of the list of hunks.
---@return integer?
local list_win = function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local trouble = vim.w[win].trouble
    if trouble and trouble.mode == "hunks" then return win end
  end
end

--- Returns the window of trouble's preview.
---@return integer?
local preview_win = function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.w[win].trouble_preview then return win end
  end
end

--- Returns the lines of the recap at the list's top-right corner.
---@return string[]?
local recap = function()
  local list = list_win()
  if not list then return end
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.win == list and not vim.w[win].trouble_preview then
      local text =
        vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
      return vim.tbl_map(vim.trim, text)
    end
  end
end

--- Moves the cursor of the list to a row, as if the user did.
---@param row integer
local move_to = function(row)
  local win = assert(list_win())
  vim.api.nvim_win_set_cursor(win, { row, 0 })
  vim.api.nvim_exec_autocmds(
    "CursorMoved",
    { buffer = vim.api.nvim_win_get_buf(win) }
  )
end

-- The list's workspaces come from its `cwd` option, not from where Neovim is.
vim.cmd.cd("/")
vim.cmd.edit(vim.fs.joinpath(root, "modules/a/x.txt"))
local file_win = vim.api.nvim_get_current_win()
local file_buf = vim.api.nvim_get_current_buf()
vim.api.nvim_win_set_cursor(file_win, { 30, 0 })

-- A float on the file's window, like incline.nvim's.
local label =
  vim.api.nvim_open_win(vim.api.nvim_create_buf(false, true), false, {
    relative = "win",
    win = file_win,
    anchor = "NE",
    row = 0,
    col = vim.api.nvim_win_get_width(file_win),
    width = 5,
    height = 1,
    focusable = false,
  })

test("the list opens on the hunk the cursor is in", function()
  ---@diagnostic disable-next-line: undefined-field
  require("trouble").open({
    mode = "hunks",
    focus = true,
    cwd = root,
    center = true,
  })
  -- The buffers show their diffs without waiting for the list.
  h.eq(hunks.is_shown(file_buf), true)

  h.wait(function()
    local win = list_win()
    if not win then return false end
    local row = vim.api.nvim_win_get_cursor(win)[1]
    local buf = vim.api.nvim_win_get_buf(win)
    local line = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1]
    return line ~= nil and line:find("L30") ~= nil
  end, "the list's cursor is on the hunk")
  local list = assert(list_win())
  -- The file icons, in Unicode's private use areas, are replaced by `#`.
  local rows = vim.tbl_map(
    function(row)
      return (
        row
          :gsub("[\238\239][\128-\191][\128-\191]", "#")
          :gsub("\243[\128-\191][\128-\191][\128-\191]", "#")
          :gsub("%s+$", "")
      )
    end,
    vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(list), 0, -1, false)
  )
  h.eq(rows, {
    " # #  docs/ 1a (+1)",
    "   └╴#  new.md +1 (new file)",
    " # #  modules/a/ 1m (+2 -2)",
    "   └╴#  x.txt +2 -2",
    "     ├╴L2 +1 -1",
    "     └╴L30 +1 -1",
    " # #  src/ 1r",
    "   └╴#  ren.txt → ren.txt",
    "   #  old.txt -2 (deleted)",
    " # #  root.txt +1 -1",
  })

  -- Opening the list doesn't preview the hunk, which would scroll the file.
  h.eq(preview_win(), nil)
  -- The deleted lines drawn above the cursor after it's centered can push
  -- it down by as many rows.
  local height = vim.api.nvim_win_get_height(file_win)
  local winline = vim.api.nvim_win_call(file_win, vim.fn.winline)
  h.eq(
    math.abs(winline - math.ceil(height / 2)) <= 2,
    true,
    ("the cursor line is centered (row %d of %d)"):format(winline, height)
  )

  h.wait(function() return recap() and #recap() == 3 end, "the recap is drawn")
  local text = assert(recap())
  h.eq({ text[2], text[3] }, { "2m 1a 1d 1r (+4 -5)", "(no description set)" })
end)

test("moving the cursor previews below the file's floats", function()
  -- The main loop reports the move placing the list's cursor, which headless
  -- tests don't run.
  vim.api.nvim_exec_autocmds(
    "CursorMoved",
    { buffer = vim.api.nvim_win_get_buf(assert(list_win())) }
  )
  move_to(5)
  h.wait(preview_win, "the hunk is previewed")
  local preview = assert(preview_win())
  h.eq(vim.api.nvim_win_get_cursor(preview)[1], 2)
  -- Floats with the default z-index, like incline.nvim's, stay visible.
  local zindex = vim.api.nvim_win_get_config(preview).zindex
  h.eq(
    zindex < vim.api.nvim_win_get_config(label).zindex,
    true,
    "the preview is below the label"
  )

  -- A deleted file's preview spans the preview's width.
  move_to(9)
  h.wait(function()
    local win = preview_win()
    local name = win
      and vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    return name ~= nil and name:find("old.txt") ~= nil
  end, "the deleted file is previewed")
  local buf = vim.api.nvim_win_get_buf(assert(preview_win()))
  local padded = vim.tbl_filter(
    function(mark) return (mark[4] or {}).virt_text ~= nil end,
    vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })
  )
  h.eq(#padded, 2, "both deleted lines are padded")
end)

test("the list follows the cursor of other windows", function()
  local list = assert(list_win())
  vim.api.nvim_set_current_win(file_win)
  ---@param line integer
  ---@return string
  local row_after_moving_to = function(line)
    vim.api.nvim_win_set_cursor(file_win, { line, 0 })
    -- The main loop reports the move, which headless tests don't run.
    vim.api.nvim_exec_autocmds(
      "CursorMoved",
      { buffer = vim.api.nvim_win_get_buf(file_win) }
    )
    local row = vim.api.nvim_win_get_cursor(list)[1]
    local buf = vim.api.nvim_win_get_buf(list)
    return vim.trim(
      assert(vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1])
    )
  end

  h.eq(row_after_moving_to(2), "├╴L2 +1 -1")
  h.eq(row_after_moving_to(10):match("x%.txt") ~= nil, true, "on the file")
  h.eq(row_after_moving_to(30), "└╴L30 +1 -1")
  vim.cmd.edit(vim.fs.joinpath(root, "root.txt"))
  h.eq(
    row_after_moving_to(1):match("root%.txt") ~= nil,
    true,
    "on the collapsed file of the hunk"
  )
  vim.cmd.edit(vim.fs.joinpath(root, "modules/a/x.txt"))
  h.eq(preview_win(), nil, "nothing is previewed")
  vim.api.nvim_set_current_win(list)
end)

test("the list refreshes after jj operations", function()
  h.run(root, { "jj", "describe", "--message", "listed" })
  h.wait(function()
    local text = recap()
    return text and text[3] == "listed"
  end, "the recap shows the new description")
end)

test("closing the list hides the diffs it showed", function()
  vim.api.nvim_win_close(assert(list_win()), true)
  h.wait(
    function() return not hunks.is_shown(file_buf) end,
    "the diff is hidden"
  )
  h.wait(function() return recap() == nil end, "the recap is closed")
end)

--- Returns the rows of the list, without their icons and trailing spaces.
---@return string[]
local rows = function()
  local list = assert(list_win())
  return vim.tbl_map(
    function(row)
      return (
        row
          :gsub("[\238\239][\128-\191][\128-\191]", "#")
          :gsub("\243[\128-\191][\128-\191][\128-\191]", "#")
          :gsub("%s+$", "")
      )
    end,
    vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(list), 0, -1, false)
  )
end

test("folded directories stay folded when the list opens again", function()
  ---@diagnostic disable-next-line: undefined-field
  require("trouble").open({ mode = "hunks", focus = true, cwd = root })
  h.wait(function() return list_win() ~= nil and #rows() > 1 end, "the list opens")

  local view = assert(require("trouble.view").get({ mode = "hunks" })[1]).view
  ---@type integer?
  local src
  for index, row in ipairs(rows()) do
    if row:find("src/") then src = index end
  end
  view:fold(assert(view.renderer:at(assert(src)).node), { action = "close" })
  h.wait(
    function() return not vim.tbl_contains(rows(), "   └╴#  ren.txt → ren.txt") end,
    "src/ is folded"
  )

  vim.api.nvim_win_close(assert(list_win()), true)
  h.wait(function() return not hunks.is_showing_all() end, "the list is closed")
  ---@diagnostic disable-next-line: undefined-field
  require("trouble").open({ mode = "hunks", focus = true, cwd = root })
  h.wait(function() return list_win() ~= nil and #rows() > 1 end, "the list opens again")
  h.eq(vim.tbl_contains(rows(), " # #  src/ 1r"), true, vim.inspect(rows()))
  h.eq(vim.tbl_contains(rows(), "   └╴#  ren.txt → ren.txt"), false, vim.inspect(rows()))
  vim.api.nvim_win_close(assert(list_win()), true)
  h.wait(function() return not hunks.is_showing_all() end, "the list is closed")
end)

test("the list doesn't open without changes", function()
  local unchanged = h.repo({ ["a.txt"] = "a\n" }, { ["a.txt"] = "a\n" })
  local messages = {}
  local notify = vim.notify
  vim.notify = function(message) messages[#messages + 1] = message end
  ---@diagnostic disable-next-line: undefined-field
  require("trouble").open({ mode = "hunks", focus = true, cwd = unchanged })
  h.wait(function() return #messages > 0 end, "trouble says there's nothing")
  vim.notify = notify
  h.eq(
    messages[1]:match("^No results for %*%*hunks%*%*") ~= nil,
    true,
    messages[1]
  )
  h.eq(list_win(), nil)
  h.eq(hunks.is_showing_all(), false, "the diffs aren't all shown")
end)

test("a listing slower than trouble waits for still opens the list", function()
  local files = hunks.files
  ---@diagnostic disable-next-line: duplicate-set-field
  hunks.files = function(listed_roots, on_done)
    files(listed_roots, function(listed)
      vim.defer_fn(function() on_done(listed) end, 2500)
    end)
  end
  ---@diagnostic disable-next-line: undefined-field
  require("trouble").open({ mode = "hunks", focus = true, cwd = root })
  h.wait(function() return list_win() ~= nil end, "the list opens", 5000)
  hunks.files = files
  h.wait(
    function() return vim.api.nvim_get_current_win() == list_win() end,
    "the list is focused"
  )
  vim.api.nvim_win_close(assert(list_win()), true)
end)

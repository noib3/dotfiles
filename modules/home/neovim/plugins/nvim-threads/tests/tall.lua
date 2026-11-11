local h = require("nvim_threads_tests")
local threads = require("nvim_threads")

local lines = {}
for index = 1, 40 do
  lines[#lines + 1] = ("line %d"):format(index)
end
local body = {}
for index = 1, 12 do
  body[#body + 1] = ("reply line %d"):format(index)
end
threads.register(h.participant("editor", { table.concat(body, "\n") }, {
  edits = {
    { path = "f.txt", old_text = "line 10\n", new_text = "LINE 10\n" },
    { path = "f.txt", old_text = "line 30\n", new_text = "LINE 30\n" },
  },
}))

h.setup(80, 16)
local root = h.repo({ ["f.txt"] = h.text(lines) }, {})
vim.keymap.set({ "n", "x" }, "<F2>", function() threads.create() end)

---@param float_buf integer
---@param text string
---@return integer?
local line_of = function(float_buf, text)
  for index, line in ipairs(vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)) do
    if line == text then return index end
  end
end

--- Opens a thread whose reply and diffs are taller than the window, with
--- the cursor on its second edit's title in its float.
---@return integer bufnr
---@return integer float_win
---@return integer float_buf
local open_tall_thread = function()
  local bufnr = h.open(root, "f.txt")
  vim.api.nvim_feedkeys(vim.keycode("3G<F2>"), "x", false)
  vim.cmd.stopinsert()
  h.type({ "@editor fix" })
  h.eq(threads.submit(), true)
  local float_buf = vim.api.nvim_get_current_buf()
  h.wait(
    function() return line_of(float_buf, "▾ Edit at line 30") ~= nil end,
    "the participant replies"
  )
  local float_win = vim.api.nvim_get_current_win()
  h.eq(
    vim.api.nvim_buf_line_count(float_buf) > vim.o.lines,
    true,
    "the thread is taller than the screen"
  )
  vim.api.nvim_win_set_cursor(
    float_win,
    { assert(line_of(float_buf, "▾ Edit at line 30")), 0 }
  )
  return bufnr, float_win, float_buf
end

test(
  "collapsing an edit far down a tall thread keeps its float open and filled",
  function()
    local _, float_win, float_buf = open_tall_thread()
    local before = assert(vim.fn.getwininfo(float_win)[1])
    h.eq(before.topline > 1, true, "the float is scrolled down")

    h.eq(threads.activate(), true, "the edit collapses")
    vim.cmd.redraw()
    h.eq(vim.api.nvim_win_is_valid(float_win), true, "the float stays open")
    h.eq(
      line_of(float_buf, "▸ Edit at line 30") ~= nil,
      true,
      "only the edit is collapsed"
    )
    local info = assert(vim.fn.getwininfo(float_win)[1])
    local line_count = vim.api.nvim_buf_line_count(float_buf)
    h.eq(
      info.botline >= line_count
        and info.botline - info.topline + 1 < info.height,
      false,
      ("no blank rows below the buffer's end: topline %d, botline %d, height %d, lines %d"):format(
        info.topline,
        info.botline,
        info.height,
        line_count
      )
    )
    h.eq(threads.collapse(), true)
    h.eq(threads.delete(), true)
  end
)

test(
  "collapsing an edit while the thread's title is scrolled above the window",
  function()
    local bufnr, float_win, float_buf = open_tall_thread()
    -- The window shows the thread's last virtual lines at its top, with the
    -- thread's line above it, like after 'scrolloff' kept the cursor's next
    -- line visible.
    local source_win = assert(vim.fn.win_findbuf(bufnr)[1])
    vim.api.nvim_win_call(
      source_win,
      function() vim.fn.winrestview({ topline = 4, topfill = 8 }) end
    )
    local view = vim.api.nvim_win_call(source_win, vim.fn.winsaveview)
    h.eq({ view.topline, view.topfill }, { 4, 8 })
    local shown = assert(require("nvim_threads.float").get(float_win))
    shown.source_scroll = { view.topline, view.topfill, view.leftcol }
    vim.cmd.redraw()

    h.eq(threads.activate(), true, "the edit collapses")
    vim.cmd.redraw()
    h.eq(vim.api.nvim_win_is_valid(float_win), true, "the float stays open")
    h.eq(
      line_of(float_buf, "▸ Edit at line 30") ~= nil,
      true,
      "the thread stays expanded"
    )
    h.eq(threads.collapse(), true)
    h.eq(threads.delete(), true)
  end
)

local h = require("nvim_threads_tests")
local threads = require("nvim_threads")

threads.register(h.participant("bot", { "Sure." }))

h.setup(80, 30)

local root = h.repo({ ["f.txt"] = h.text({ "one", "two", "three" }) }, {})

vim.keymap.set({ "n", "x" }, "<F2>", function() threads.create() end)

test("the comments' ages are redrawn as they change", function()
  local bufnr = h.open(root, "f.txt")
  vim.api.nvim_feedkeys(vim.keycode("2G<F2>"), "x", false)
  vim.cmd.stopinsert()
  h.type({ "@bot hi" })
  h.eq(threads.submit(), true)
  ---@type nvim_threads.Thread?
  local thread
  threads.list(
    root,
    function(entries) thread = entries[1] and entries[1].thread end
  )
  h.wait(
    function() return thread ~= nil and #thread.comments == 2 end,
    "the participant replies"
  )
  ---@cast thread -nil

  -- The comments were made 59 seconds ago, so they're a minute old in one.
  for _, comment in ipairs(thread.comments) do
    comment.time = os.time() - 59
  end
  -- Leaving the float redraws the thread, with the comments' new times.
  h.leave()
  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  h.eq(threads.step(1, "j"), true)
  if not vim.api.nvim_get_current_line():find("▾", 1, true) then
    h.eq(threads.activate(), true, "the thread expands")
  end
  local float_buf = vim.api.nvim_get_current_buf()
  local ages = function()
    return vim.tbl_filter(
      function(line)
        return line:match("^me ") ~= nil or line:match("^bot ") ~= nil
      end,
      vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)
    )
  end
  h.eq(ages(), { "me  now", "bot  now" })
  h.wait(
    function() return vim.deep_equal(ages(), { "me  1m", "bot  1m" }) end,
    "the ages are redrawn",
    3000
  )
  local virt = h.virt_lines(bufnr)[2]
  h.eq(
    vim.tbl_contains(virt, "▎ bot  1m"),
    true,
    "the virtual lines are redrawn too: " .. vim.inspect(virt)
  )
end)

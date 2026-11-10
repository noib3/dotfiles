local h = require("nvim_threads_tests")
local threads = require("nvim_threads")

local bot, bot_requests = h.participant("bot", { "Because ", "of `x`." }, {
  title = "Why THREE",
})
threads.register(bot)

h.setup(80, 30)

local root = h.repo({
  ["f.txt"] = h.text({ "one", "two", "three", "four", "five" }),
}, {
  ["f.txt"] = h.text({ "one", "two", "THREE", "four", "five" }),
})

vim.keymap.set({ "n", "x" }, "<F2>", function() threads.create() end)

--- Opens a thread on the lines between two 1-based ones, writes a comment in
--- its composer and sends it.
---@param first integer
---@param last integer
---@param body string[]
local comment_on = function(first, last, body)
  local keys = ("%dGV%s<F2>"):format(
    first,
    last > first and (last - first) .. "j" or ""
  )
  vim.api.nvim_feedkeys(vim.keycode(keys), "x", false)
  vim.cmd.stopinsert()
  h.eq(vim.bo.filetype, "nvim-threads", "the cursor is in the thread's float")
  h.type(body)
  h.eq(threads.submit(), true)
  h.leave()
end

---@return nvim_threads.Thread[]
local listed = function()
  ---@type nvim_threads.Thread[]?
  local result
  threads.list(root, function(found)
    result = vim.tbl_map(function(entry) return entry.thread end, found)
  end)
  h.wait(function() return result ~= nil end, "the threads are listed")
  return assert(result)
end

local working_copy = h.change_id(root, "@")
local parent = h.change_id(root, "@-")

test("a remark is saved under the working-copy change", function()
  local bufnr = h.open(root, "f.txt")
  comment_on(2, 3, { "check this" })

  h.eq(vim.api.nvim_get_current_buf(), bufnr, "the cursor is back in the file")
  local lines = h.virt_lines(bufnr)[3]
  h.eq(
    lines,
    { "  ▸ check this (1 message)" },
    "the collapsed thread follows the selection"
  )
  h.wait(
    function() return h.saved(root, working_copy)["f.txt"] ~= nil end,
    "the thread is saved"
  )
  local saved = assert(assert(h.saved(root, working_copy)["f.txt"]).threads[1])
  h.eq(saved.anchor, { start_row = 1, start_col = 0, end_row = 2, end_col = 5 })
  h.eq(assert(saved.comments[1]).body, "check this")
  h.eq(threads.status(saved), "waiting on me")
end)

test("a mentioned participant's reply streams into the thread", function()
  local bufnr = vim.api.nvim_get_current_buf()
  comment_on(4, 4, { "@bot why?" })

  local thread = assert(
    vim.iter(listed()):find(
      function(thread) return assert(thread.comments[1]).body == "@bot why?" end
    )
  )
  h.eq(thread.participants, { "bot" })
  h.eq(threads.status(thread), "waiting on agent")
  h.wait(function() return #thread.comments == 2 end, "the participant replies")
  local reply = assert(thread.comments[2])
  h.eq(reply.author, "bot")
  h.eq(reply.body, "Because of `x`.")
  h.eq(thread.title, "Why THREE")
  h.eq(threads.status(thread), "waiting on me")

  h.eq(h.virt_lines(bufnr)[4], { "  ▸ Why THREE (2 messages)" })

  local request = bot_requests[#bot_requests]
  h.eq(request.path, "f.txt")
  h.eq(
    request.prompt:find("```text " .. root .. "/f.txt:4\nfour\n```", 1, true)
      ~= nil,
    true,
    request.prompt
  )
  h.eq(request.prompt:sub(-#"@bot why?"), "@bot why?")
end)

test("replies to a thread go to its participants", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  h.eq(threads.step(1, "j"), true)
  h.eq(vim.bo.filetype, "nvim-threads")
  h.eq(vim.api.nvim_get_current_line(), "▸ Why THREE (2 messages)")

  -- <CR> on the collapsed thread expands it, with the composer last.
  h.eq(threads.activate(), true)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  h.eq(vim.tbl_contains(lines, "Because of `x`."), true, vim.inspect(lines))
  vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
  h.type({ "and then?" })
  local before = #bot_requests
  -- <CR> in the composer sends the comment.
  h.eq(threads.activate(), true)
  local float_buf = vim.api.nvim_get_current_buf()
  h.eq(vim.bo[float_buf].filetype, "nvim-threads", "the thread stays open")
  local last = vim.api.nvim_buf_line_count(float_buf)
  h.eq(vim.api.nvim_buf_get_lines(float_buf, last - 1, last, false), { "" })
  h.eq(vim.api.nvim_win_get_cursor(0)[1], last, "the cursor is in the composer")
  local float_lines = vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)
  h.eq(
    vim.tbl_contains(float_lines, "and then?"),
    true,
    vim.inspect(float_lines)
  )
  h.leave()
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.wait(function() return #bot_requests > before end, "the reply is sent")
  local request = bot_requests[#bot_requests]
  h.eq(
    request.prompt:find(
      "<thread>\nme: @bot why?\nbot: Because of `x`.\n</thread>",
      1,
      true
    ) ~= nil,
    true,
    request.prompt
  )
  h.wait(function()
    local thread = assert(
      vim
        .iter(listed())
        :find(function(thread) return thread.title == "Why THREE" end)
    )
    return #thread.comments == 4
  end, "the participant replies again")
end)

test("stepping moves into and out of a thread's float", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  h.eq(threads.step(1, "j"), true)
  local float_win = vim.api.nvim_get_current_win()
  h.eq(vim.api.nvim_get_current_line(), "▸ check this (1 message)")
  h.eq(threads.step(-1, "k"), true)
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.eq(vim.api.nvim_win_get_cursor(0)[1], 3)
  h.eq(vim.api.nvim_win_is_valid(float_win), false, "the float closed")

  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  h.eq(threads.step(-1, "k"), true)
  h.eq(vim.bo.filetype, "nvim-threads", "moving up enters the thread above")
  h.eq(threads.step(1, "j"), true)
  h.eq(vim.api.nvim_win_get_cursor(0)[1], 4)

  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  h.eq(threads.step(1, "j"), false, "there's no thread below the first line")
end)

test("the cursor keeps its screen column through a thread's float", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local curswant = function() return vim.fn.winsaveview().curswant end

  vim.api.nvim_win_set_cursor(0, { 3, 4 })
  h.eq(threads.step(1, "j"), true)
  -- The float's text starts after its three cells of borders.
  h.eq(curswant(), 1)
  h.eq(threads.step(-1, "k"), true)
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.eq(vim.api.nvim_win_get_cursor(0), { 3, 4 })

  -- A column left of the float's text comes back unchanged.
  vim.api.nvim_win_set_cursor(0, { 3, 1 })
  h.eq(threads.step(1, "j"), true)
  h.eq(curswant(), 0)
  h.eq(threads.step(-1, "k"), true)
  h.eq(vim.api.nvim_win_get_cursor(0), { 3, 1 })

  -- Moving sideways in the float moves the column in the file.
  h.eq(threads.step(1, "j"), true)
  vim.cmd("normal! l")
  h.eq(threads.step(-1, "k"), true)
  h.eq(vim.api.nvim_win_get_cursor(0), { 3, 4 })
end)

test("expanding and collapsing a thread keeps the cursor's column", function()
  vim.api.nvim_win_set_cursor(0, { 3, 0 })
  h.eq(threads.step(1, "j"), true)
  -- On the title, after the chevron's three bytes and a space.
  vim.api.nvim_win_set_cursor(0, { 1, 6 })
  local cursor = vim.api.nvim_win_get_cursor(0)
  h.eq(threads.activate(), true)
  h.eq(vim.api.nvim_win_get_cursor(0), cursor, "expanding")
  h.eq(threads.activate(), true)
  h.eq(vim.api.nvim_win_get_cursor(0), cursor, "collapsing")
  h.leave()
end)

test(
  "a thread collapses when the cursor leaves it, keeping its draft",
  function()
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_win_set_cursor(0, { 4, 0 })
    h.eq(threads.step(1, "j"), true)
    h.eq(threads.activate(), true)
    vim.api.nvim_win_set_cursor(0, { vim.api.nvim_buf_line_count(0), 0 })
    h.type({ "unsent" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    h.eq(threads.step(-1, "k"), true)
    h.eq(vim.api.nvim_get_current_buf(), bufnr)
    h.eq(h.virt_lines(bufnr)[4], { "  ▸ Why THREE (4 messages, draft)" })

    -- The collapsed thread's float only has its header, which the cursor
    -- leaves with a single step.
    h.eq(threads.step(1, "j"), true)
    h.eq(vim.api.nvim_buf_line_count(0), 1)
    h.eq(threads.step(1, "j"), true)
    h.eq(vim.api.nvim_get_current_buf(), bufnr)
    h.eq(vim.api.nvim_win_get_cursor(0)[1], 5)
    vim.api.nvim_win_set_cursor(0, { 4, 0 })

    h.eq(threads.step(1, "j"), true)
    h.eq(threads.activate(), true)
    local last = vim.api.nvim_buf_line_count(0)
    h.eq(vim.api.nvim_buf_get_lines(0, last - 1, last, false), { "unsent" })
    vim.api.nvim_win_set_cursor(0, { last, 0 })
    h.type({ "" })
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    h.eq(threads.step(-1, "k"), true)
    h.eq(h.virt_lines(bufnr)[4], { "  ▸ Why THREE (4 messages)" })
  end
)

test("insert mode goes back to where it was left in the composer", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  h.eq(threads.step(1, "j"), true)
  h.eq(threads.activate(), true)
  local float_buf = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "<F3>", function()
    if not threads.insert_in_composer() then vim.cmd.startinsert() end
  end, { buffer = float_buf })
  local history = vim.api.nvim_buf_line_count(float_buf) - 1

  -- From the header, insert mode starts at the composer's end.
  vim.api.nvim_feedkeys(vim.keycode("<F3>abc<Esc>"), "x", false)
  local composer = function()
    return vim.api.nvim_buf_get_lines(float_buf, history, -1, false)
  end
  h.eq(composer(), { "abc" })

  vim.api.nvim_feedkeys(vim.keycode("0lgg<F3>X<Esc>"), "x", false)
  h.eq(composer(), { "abcX" }, "insert mode starts where it was left")

  -- Deleting before the composer's start does nothing.
  vim.api.nvim_win_set_cursor(0, { history + 1, 0 })
  vim.api.nvim_feedkeys(vim.keycode("i<BS><C-w><Esc>"), "x", false)
  h.eq(composer(), { "abcX" })
  h.eq(vim.api.nvim_buf_line_count(float_buf), history + 1)
  vim.api.nvim_feedkeys(vim.keycode("A<Del><Esc>"), "x", false)
  h.eq(composer(), { "abcX" })

  -- Inside the composer, they delete as usual.
  vim.api.nvim_feedkeys(
    vim.keycode("A<BS><CR>de<C-h><BS><BS><Esc>"),
    "x",
    false
  )
  h.eq(composer(), { "abc" })

  h.type({ "" })
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  h.eq(threads.step(-1, "k"), true)
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
end)

test("anchors follow edits made while the file was closed", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.cmd.bwipeout(bufnr)
  h.write(
    vim.fs.joinpath(root, "f.txt"),
    h.text({ "zero", "one", "two", "THREE", "four", "five" })
  )

  local reopened = h.open(root, "f.txt")
  local virt_lines = h.virt_lines(reopened)
  h.eq(virt_lines[4], { "  ▸ check this (1 message)" })
  h.eq(virt_lines[5], { "  ▸ Why THREE (4 messages)" })
end)

test("threads move with the lines moved out of the working copy", function()
  local bufnr = vim.api.nvim_get_current_buf()
  threads.move(root, "f.txt", { 4 }, parent)
  h.wait(
    function() return h.saved(root, parent)["f.txt"] ~= nil end,
    "the thread is saved under the parent"
  )
  local moved = assert(h.saved(root, parent)["f.txt"]).threads
  h.eq(#moved, 1)
  h.eq(assert(assert(moved[1]).comments[1]).body, "check this")
  h.eq(h.virt_lines(bufnr)[4], nil, "the moved thread isn't displayed")
  h.eq(#listed(), 1)
end)

test("deleting a thread from its float", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_win_set_cursor(0, { 5, 0 })
  h.eq(threads.step(1, "j"), true)
  h.eq(threads.delete(), true)
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.eq(h.virt_lines(bufnr), {})
  h.eq(#listed(), 0)
  h.wait(
    function() return h.saved(root, working_copy)["f.txt"] == nil end,
    "the thread is deleted from disk"
  )
end)

test("an empty thread is dropped when its float closes", function()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_feedkeys(vim.keycode("2G<F2>"), "x", false)
  vim.cmd.stopinsert()
  h.eq(vim.bo.filetype, "nvim-threads")
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  h.eq(threads.step(-1, "k"), true)
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.eq(h.virt_lines(bufnr), {})
end)

test("suggested edits are reviewed and applied", function()
  local editor = h.participant("editor", { "Like this." }, {
    edits = {
      { path = "f.txt", old_text = "THREE", new_text = "three" },
    },
  })
  threads.register(editor)

  ---@type { buf: integer, base: string[] }?
  local suggested
  vim.api.nvim_create_autocmd("User", {
    pattern = "NvimThreadsSuggestion",
    once = true,
    callback = function(ev) suggested = ev.data end,
  })

  local bufnr = vim.api.nvim_get_current_buf()
  comment_on(4, 4, { "@editor lowercase it" })
  local thread = assert(
    vim
      .iter(listed())
      :find(function(thread) return thread.participants[1] == "editor" end)
  )
  h.wait(function() return #thread.comments == 2 end, "the participant replies")

  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  h.eq(threads.step(1, "j"), true)
  h.eq(threads.activate(), true, "the thread expands")
  local float_buf = vim.api.nvim_get_current_buf()
  ---@type integer?
  local row
  for index, line in ipairs(vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)) do
    if line == "✎ Suggested edits to f.txt" then row = index end
  end
  vim.api.nvim_win_set_cursor(0, { assert(row), 0 })
  h.eq(threads.activate(), true)

  h.eq(suggested ~= nil, true, "the suggestion's buffer was announced")
  ---@cast suggested -nil
  h.eq(vim.api.nvim_get_current_buf(), suggested.buf)
  h.eq(suggested.base[4], "THREE")
  h.eq(vim.api.nvim_buf_get_lines(suggested.buf, 3, 4, false), { "three" })

  vim.cmd.write()
  h.wait(
    function() return vim.api.nvim_get_current_buf() == bufnr end,
    "the file is shown again"
  )
  h.eq(vim.api.nvim_buf_get_lines(bufnr, 3, 4, false), { "three" })
  h.eq(
    h.read(vim.fs.joinpath(root, "f.txt")),
    h.text({ "zero", "one", "two", "three", "four", "five" })
  )
  h.wait(function()
    local applied = assert(thread.comments[2]).applied
    return applied ~= nil and applied["f.txt"] == true
  end, "the suggestion is marked as applied")
end)

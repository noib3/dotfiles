local h = require("nvim_threads_tests")
local threads = require("nvim_threads")

local long = {}
for index = 1, 30 do
  long[#long + 1] = ("line %d of a long reply"):format(index)
end
threads.register(h.participant("bot", { table.concat(long, "\n") }))

h.setup(60, 15)

local lines = {}
for index = 1, 30 do
  lines[#lines + 1] = ("file line %d"):format(index)
end
local root = h.repo({ ["f.txt"] = h.text(lines) }, {})

vim.keymap.set({ "n", "x" }, "<F2>", function() threads.create() end)

--- Returns whether a row of the screen contains a text.
---@param rows string[]
---@param text string
---@return boolean
local shows = function(rows, text)
  return vim
    .iter(rows)
    :any(function(row) return row:find(text, 1, true) ~= nil end)
end

--- Returns the screen's rows, trimmed.
---@return string[]
local screen = function()
  vim.cmd.redraw()
  local rows = {}
  for row = 1, vim.o.lines - vim.o.cmdheight do
    local text = {}
    for col = 1, vim.o.columns do
      text[#text + 1] = vim.fn.screenstring(row, col)
    end
    rows[#rows + 1] = vim.trim(table.concat(text))
  end
  return rows
end

test("collapsing a thread taller than the window hides its comments", function()
  local bufnr = h.open(root, "f.txt")
  vim.api.nvim_feedkeys(vim.keycode("2G<F2>"), "x", false)
  vim.cmd.stopinsert()
  h.type({ "@bot explain" })
  h.eq(threads.submit(), true)
  h.leave()
  h.wait(function()
    local virt = h.virt_lines(bufnr)[2]
    return virt ~= nil and (virt[1] or ""):find("2 messages", 1, true) ~= nil
  end, "the participant replies")

  vim.api.nvim_win_set_cursor(0, { 2, 0 })
  h.eq(threads.step(1, "j"), true)
  h.eq(threads.activate(), true, "the thread expands")
  local float_win = vim.api.nvim_get_current_win()
  h.eq(
    #h.virt_lines(bufnr)[2] > vim.o.lines,
    true,
    "the thread is taller than the window"
  )
  h.eq(shows(screen(), "line 5 of a long reply"), true, "the reply is shown")

  vim.api.nvim_win_set_cursor(float_win, { 1, 0 })
  h.eq(threads.activate(), true, "the thread collapses")
  h.eq(#h.virt_lines(bufnr)[2], 1, "one virtual line is left")
  h.eq(vim.api.nvim_win_get_height(float_win), 1, "the float covers one line")
  local rows = screen()
  h.eq(shows(rows, "long reply"), false, table.concat(rows, "\n"))
  h.eq(threads.delete(), true, "the thread is deleted")
end)

for _, case in ipairs({
  { name = "from its title", scroll = false },
  { name = "after scrolling down through it", scroll = true },
}) do
  test(
    "collapsing a thread running past the window's bottom, " .. case.name,
    function()
      local bufnr = h.open(root, "f.txt")
      vim.cmd("normal! gg")
      vim.api.nvim_feedkeys(vim.keycode("9G<F2>"), "x", false)
      vim.cmd.stopinsert()
      h.type({ "@bot explain" })
      h.eq(threads.submit(), true)
      h.leave()
      h.wait(function()
        local virt = h.virt_lines(bufnr)[9]
        return virt ~= nil
          and (virt[1] or ""):find("2 messages", 1, true) ~= nil
      end, "the participant replies")

      vim.api.nvim_win_set_cursor(0, { 9, 0 })
      h.eq(threads.step(1, "j"), true)
      h.eq(threads.activate(), true, "the thread expands")
      local float_win = vim.api.nvim_get_current_win()
      if case.scroll then
        for _ = 1, 20 do
          threads.step(1, "j")
        end
        h.eq(
          vim.api.nvim_get_current_win(),
          float_win,
          "the cursor is still in the float"
        )
        for _ = 1, 40 do
          if vim.api.nvim_win_get_cursor(0)[1] == 1 then break end
          threads.step(-1, "k")
        end
      end
      h.eq(vim.api.nvim_win_get_cursor(0)[1], 1, "the cursor is on the title")
      local before = screen()

      h.eq(threads.activate(), true, "the thread collapses")
      local rows = screen()
      h.eq(
        shows(rows, "long reply"),
        false,
        "before:\n"
          .. table.concat(before, "\n")
          .. "\nafter:\n"
          .. table.concat(rows, "\n")
      )
      h.eq(threads.delete(), true, "the thread is deleted")
    end
  )
end

test("collapsing a thread leaves the cursor on its title", function()
  local bufnr = h.open(root, "f.txt")
  vim.api.nvim_feedkeys(vim.keycode("5G<F2>"), "x", false)
  vim.cmd.stopinsert()
  h.type({ "@bot explain" })
  h.eq(threads.submit(), true)
  local float_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_cursor(float_win, { 4, 0 })
  h.eq(threads.collapse(), true)
  h.eq(
    vim.api.nvim_get_current_win(),
    float_win,
    "the cursor stays in the float"
  )
  h.eq(vim.api.nvim_win_get_cursor(float_win), { 1, 0 })
  h.eq(#h.virt_lines(bufnr)[5], 1, "the thread is collapsed")
  h.eq(
    threads.collapse(),
    true,
    "collapsing a collapsed thread keeps the cursor there"
  )
  h.eq(vim.api.nvim_win_get_cursor(float_win), { 1, 0 })
  h.eq(threads.delete(), true, "the thread is deleted")
end)

test("a thread's float works in its source window's directory", function()
  local bufnr = h.open(root, "f.txt")
  local elsewhere = vim.fs.normalize(
    assert(
      vim.uv.fs_mkdtemp(
        vim.fs.joinpath(assert(vim.uv.os_tmpdir()), "elsewhere-XXXXXX")
      )
    )
  )
  vim.cmd.cd(vim.fn.fnameescape(elsewhere))
  vim.cmd.bcd(vim.fn.fnameescape(root))
  h.eq(vim.fn.getcwd(), root)
  vim.api.nvim_feedkeys(vim.keycode("5G<F2>"), "x", false)
  vim.cmd.stopinsert()
  h.eq(vim.bo.filetype, "nvim-threads")
  h.eq(vim.fn.getcwd(), root, "the float's directory is the file's window's")
  h.type({ "remark" })
  h.eq(threads.submit(), true)
  h.eq(threads.collapse(), true)
  h.eq(threads.delete(), true, "the thread is deleted")
  h.eq(vim.api.nvim_get_current_buf(), bufnr)
end)

--- Returns the groups of the highlights on a line of a buffer.
---@param buf integer
---@param line integer The 1-based line.
---@return string[]
local groups_on = function(buf, line)
  local groups = {}
  for _, namespace in pairs(vim.api.nvim_get_namespaces()) do
    for _, mark in
      ipairs(
        vim.api.nvim_buf_get_extmarks(
          buf,
          namespace,
          { line - 1, 0 },
          { line - 1, -1 },
          { details = true }
        )
      )
    do
      local group = assert(mark[4]).hl_group
      if group then groups[#groups + 1] = group end
    end
  end
  return groups
end

test("an expanded thread's float stays open below its last line", function()
  h.open(root, "f.txt")
  vim.api.nvim_feedkeys(vim.keycode("7G<F2>"), "x", false)
  vim.cmd.stopinsert()
  local float_win = vim.api.nvim_get_current_win()
  local last = vim.api.nvim_buf_line_count(0)
  vim.api.nvim_win_set_cursor(float_win, { last, 0 })
  h.eq(threads.step(1, "j"), true)
  h.eq(vim.api.nvim_get_current_win(), float_win)
  h.eq(vim.api.nvim_win_get_cursor(float_win)[1], last)
  h.type({ "x" })
  h.eq(threads.submit(), true)
  h.eq(threads.collapse(), true)
  h.eq(threads.delete(), true, "the thread is deleted")
end)

test(
  "authors have their own colors, and a line separates their messages",
  function()
    local tinted = h.participant("tinted", { "Hello @me." })
    tinted.color = "#d97757"
    threads.register(tinted)
    h.eq(vim.api.nvim_get_hl(0, { name = "ThreadsAuthorTinted" }).fg, 0xd97757)

    local bufnr = h.open(root, "f.txt")
    vim.api.nvim_feedkeys(vim.keycode("8G<F2>"), "x", false)
    vim.cmd.stopinsert()
    h.type({ "@tinted hi" })
    local float_buf = vim.api.nvim_get_current_buf()
    local composer = vim.api.nvim_buf_line_count(float_buf)
    h.eq(
      vim.list_contains(groups_on(float_buf, composer), "ThreadsMention"),
      true,
      "the composer's mention is highlighted"
    )
    h.eq(threads.submit(), true)
    h.wait(
      function()
        return vim.tbl_contains(
          vim.api.nvim_buf_get_lines(float_buf, 0, -1, false),
          "Hello @me."
        )
      end,
      "the participant replies"
    )
    -- The reply is done once its time replaces the spinner.
    h.wait(
      function()
        return vim.tbl_contains(
          vim.api.nvim_buf_get_lines(float_buf, 0, -1, false),
          "tinted  now"
        )
      end,
      "the reply is done"
    )

    local lines = vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)
    local reply = assert(
      vim
        .iter(ipairs(lines))
        :find(function(_, line) return line == "Hello @me." end)
    )
    h.eq(vim.list_contains(groups_on(float_buf, reply), "ThreadsMention"), true)
    h.eq(
      vim.list_contains(groups_on(float_buf, reply - 1), "ThreadsAuthorTinted"),
      true,
      "the author's name has their color"
    )

    -- Messages start with their author, after a line separating them from the
    -- previous one, which has no border.
    h.eq(lines[2], "me  now")
    h.eq(
      vim.startswith(lines[reply - 2] or "", "───"),
      true,
      vim.inspect(lines)
    )
    -- The virtual lines are trimmed, so the cells left on each side aren't in
    -- the text.
    local separator = h.virt_lines(bufnr)[8][reply - 2]
    h.eq(
      separator,
      ("─"):rep(vim.api.nvim_win_get_width(0) - 2),
      "it spans the window but a cell on each side"
    )
    h.eq(threads.collapse(), true)
    h.eq(threads.delete(), true, "the thread is deleted")
  end
)

test(
  "messages have a border on each side, and only the title and the composer are shaded",
  function()
    local bufnr = h.open(root, "f.txt")
    vim.api.nvim_feedkeys(vim.keycode("9G<F2>"), "x", false)
    vim.cmd.stopinsert()
    h.type({ "a remark" })
    h.eq(threads.submit(), true)
    local float_win = vim.api.nvim_get_current_win()
    local float_buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(float_buf, 0, -1, false)
    local remark = assert(
      vim
        .iter(ipairs(lines))
        :find(function(_, line) return line == "a remark" end)
    )
    local composer = #lines

    ---@param line integer
    ---@return vim.api.keyset.extmark_details[]
    local details_on = function(line)
      local namespace = vim.api.nvim_create_namespace("nvim-threads-float")
      return vim.tbl_map(
        function(mark) return assert(mark[4]) end,
        vim.api.nvim_buf_get_extmarks(
          float_buf,
          namespace,
          { line - 1, 0 },
          { line - 1, -1 },
          { details = true }
        )
      )
    end
    ---@param line integer
    ---@return vim.api.keyset.extmark_details?
    local right_border_on = function(line)
      return vim.iter(details_on(line)):find(
        function(details) return details.virt_text_win_col ~= nil end
      )
    end
    ---@param line integer
    ---@return boolean
    local is_shaded = function(line)
      return vim.iter(details_on(line)):any(
        function(details) return details.hl_group == "ThreadsNormal" end
      )
    end

    local text_width = vim.api.nvim_win_get_width(float_win) - 2
    local right = assert(right_border_on(remark))
    h.eq(
      right.virt_text_win_col,
      text_width - 2,
      "the right border ends at the window's edge"
    )
    h.eq((assert(right.virt_text)[1] or {})[1], " 🮇")
    h.eq(right_border_on(1), nil, "the title has no right border")
    h.eq(right_border_on(composer) ~= nil, true, "the composer has one")
    h.eq(is_shaded(1), true, "the title is shaded")
    h.eq(is_shaded(composer), true, "the composer is shaded")
    h.eq(is_shaded(remark), false, "the messages aren't")

    local virt = vim.api.nvim_buf_get_extmarks(
      bufnr,
      require("nvim_threads.render").namespace,
      0,
      -1,
      { details = true }
    )
    local mark = vim.iter(virt):find(
      function(mark) return assert(mark[4]).virt_lines ~= nil end
    )
    ---@type [string, (string|string[])?][][]
    local virt_lines = mark and assert(mark[4]).virt_lines or {}
    ---@param chunk? [string, (string|string[])?]
    ---@return string[]
    local groups_of = function(chunk)
      local hl = chunk and chunk[2]
      if type(hl) == "table" then return hl end
      return { hl }
    end
    local remark_chunks = virt_lines[remark] or {}
    h.eq(
      (remark_chunks[#remark_chunks] or {})[1],
      " 🮇",
      "the virtual lines have the right border too"
    )
    h.eq(
      vim.list_contains(groups_of((virt_lines[1] or {})[2]), "ThreadsNormal"),
      true,
      "the title's virtual line is shaded"
    )
    h.eq(
      vim.list_contains(groups_of(remark_chunks[2]), "ThreadsNormal"),
      false,
      "the messages' aren't"
    )
    h.eq(threads.collapse(), true)
    h.eq(threads.delete(), true, "the thread is deleted")
  end
)

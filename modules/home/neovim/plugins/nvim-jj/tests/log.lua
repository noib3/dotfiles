local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

--- Replaces the text of a line, the way typing does.
---@param bufnr integer
---@param row integer
---@param text string
local set_line = function(bufnr, row, text)
  local old = vim.api.nvim_buf_get_lines(bufnr, row - 1, row, false)[1]
  vim.api.nvim_buf_set_text(bufnr, row - 1, 0, row - 1, #old, { text })
end

---@param bufnr integer
local write = function(bufnr)
  vim.api.nvim_buf_call(bufnr, function() vim.cmd.write() end)
  h.wait(
    function() return not vim.bo[bufnr].modified end,
    "the edits are saved"
  )
end

test("the log shows each change's subject as its text", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  h.eq(h.screen(bufnr), {
    "@  <id> (no description set)",
    "│  <date>",
    "│  test <test@example.com>",
    "○  <id> two",
    "│  <date>",
    "│  test <test@example.com>",
    "○  <id> one",
    "│  <date>",
    "│  test <test@example.com>",
    "◆  <id> (no description set)",
  })
  h.eq(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { " ", "two", "one", " " }
  )
  h.eq(vim.api.nvim_win_get_cursor(0)[1], 1)
  h.eq(vim.bo[bufnr].modified, false)
end)

test("saving describes the changes whose subjects were edited", function()
  local root = h.repo({ "one\n\nbody", "two" })
  local bufnr = h.open(root)

  set_line(bufnr, 1, "wip")
  set_line(bufnr, 3, "uno ")
  write(bufnr)

  h.eq(h.query(root, "::@ ~ root()", 'description.lines().join("|")'), {
    "wip",
    "two",
    "uno||body",
  })
  h.eq(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "wip", "two", "uno", " " }
  )
end)

test("saving keeps the cursor where it was", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  set_line(bufnr, 3, "uno more")
  vim.api.nvim_win_set_cursor(0, { 3, 4 })
  write(bufnr)

  h.eq(vim.api.nvim_win_get_cursor(0), { 3, 4 })
end)

test("clearing a subject clears the description", function()
  local root = h.repo({ "one\n\nbody" })
  local bufnr = h.open(root)

  set_line(bufnr, 2, "")
  write(bufnr)

  h.eq(h.query(root, "@-", "description"), {})
end)

test("editing an immutable change's subject is an error", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)
  local messages = #h.messages

  local row = h.row(bufnr, "one")
  set_line(bufnr, 2, "dos")
  set_line(bufnr, row, "uno")
  vim.cmd.write()
  h.wait(function() return #h.messages > messages end, "an error is shown")

  h.eq(
    h.messages[#h.messages]:match("^error: %S+ one is immutable: ") ~= nil,
    true
  )
  h.eq(vim.bo[bufnr].modified, true)
  h.eq(h.query(root, "@-", "description.first_line()"), { "two" })
end)

test("the graph and details between changes are virtual lines", function()
  local root = h.repo({ "one", "two" })
  h.run(root, { "jj", "new", "--quiet", "@--", "-m", "three" })
  local bufnr = h.open(root)

  h.eq(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "three", "two", "one", " " }
  )
  h.eq(h.screen(bufnr), {
    "@  <id> three",
    "│  <date>",
    "│  test <test@example.com>",
    "│ ○  <id> two",
    "├─╯  <date>",
    "│    test <test@example.com>",
    "○  <id> one",
    "│  <date>",
    "│  test <test@example.com>",
    "◆  <id> (no description set)",
  })
end)

test("bookmarks follow the subject", function()
  local root = h.repo({ "one" }, 1)
  local bufnr = h.open(root)

  h.eq(h.screen(bufnr)[4], "◆  <id> one main")
end)

test("adding lines is an error", function()
  local root = h.repo({ "one" })
  local bufnr = h.open(root)
  local messages = #h.messages

  vim.api.nvim_buf_set_lines(bufnr, 1, 1, false, { "extra" })
  vim.cmd.write()
  h.wait(function() return #h.messages > messages end, "an error is shown")

  h.eq(h.messages[#h.messages]:match("^error: Lines were added") ~= nil, true)
  h.eq(vim.bo[bufnr].modified, true)
end)

test("moving lines is an error", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)
  local messages = #h.messages

  vim.api.nvim_win_set_cursor(0, { h.row(bufnr, "two"), 0 })
  vim.cmd.normal({ "ddp", bang = true })
  vim.cmd.write()
  h.wait(function() return #h.messages > messages end, "an error is shown")

  h.eq(
    h.messages[#h.messages]:match("^error: Lines were added, removed or moved")
      ~= nil,
    true
  )
  h.eq(h.query(root, "@--", "description.first_line()"), { "one" })
end)

test("the log is redrawn after a jj operation", function()
  local root = h.repo({ "one" })
  local bufnr = h.open(root)

  h.run(root, { "jj", "describe", "--quiet", "-r", "@-", "-m", "uno" })
  h.wait(
    function() return vim.api.nvim_buf_get_lines(bufnr, 1, 2, false)[1] == "uno" end,
    "the log is redrawn"
  )
end)

test("the log isn't redrawn over unsaved edits", function()
  local root = h.repo({ "one" })
  local bufnr = h.open(root)

  set_line(bufnr, 1, "wip")
  h.run(root, { "jj", "describe", "--quiet", "-r", "@-", "-m", "uno" })
  h.settle()

  h.eq(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), { "wip", "one", " " })
end)

--- Inserts a change above or below the changes between two subjects'
--- lines, and returns the new change's line.
---@param bufnr integer
---@param position "above"|"below"
---@param first string
---@param last? string
---@param branch? boolean
---@return integer
local insert = function(bufnr, position, first, last, branch)
  ---@type integer?
  local line
  nvim_jj.insert_change(
    bufnr,
    position,
    branch == true,
    h.row(bufnr, first),
    h.row(bufnr, last or first),
    function(l) line = l end
  )
  h.wait(function() return line ~= nil end, "the change is inserted")
  -- The new change is edited in insert mode, which the tests don't need.
  vim.cmd.stopinsert()
  return assert(line)
end

--- The template of a change's subject in brackets, marked with `@` for the
--- working copy.
local subject =
  '"[" ++ description.first_line() ++ if(current_working_copy, "@") ++ "]"'

test("a change opened above one goes between it and its children", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  h.eq(insert(bufnr, "above", "one"), 3)
  h.eq(
    h.query(root, "::@ ~ root()", subject),
    { "[@]", "[two]", "[]", "[one]" }
  )
end)

test("a change opened below one goes between it and its parents", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  h.eq(insert(bufnr, "below", "one"), 4)
  h.eq(
    h.query(root, "::@ ~ root()", subject),
    { "[@]", "[two]", "[one]", "[]" }
  )
end)

test("a change opened below the working copy leaves it checked out", function()
  local root = h.repo({ "one" })
  h.run(root, { "jj", "describe", "--quiet", "-m", "scratch" })
  local bufnr = h.open(root)

  h.eq(insert(bufnr, "below", "scratch"), 2)
  h.eq(h.query(root, "::@ ~ root()", subject), { "[scratch@]", "[]", "[one]" })
end)

test("a change opened above several merges them", function()
  local root = h.repo({ "one", "two" })
  h.run(root, { "jj", "new", "--quiet", "@--", "-m", "three" })
  local bufnr = h.open(root)

  insert(bufnr, "above", "three", "two")
  local parents = h.query(root, "parents(merges())", "description.first_line()")
  table.sort(parents)
  h.eq(parents, { "three", "two" })
end)

test(
  "code's backticks are concealed unless the cursor is in the code",
  function()
    local root = h.repo({ "add `foo` and `bar`" })
    local bufnr = h.open(root)
    local win = vim.api.nvim_get_current_win()
    vim.wo[win].conceallevel = 2
    vim.wo[win].concealcursor = "ni"

    ---@param col integer
    ---@return string
    local text_at = function(col)
      vim.api.nvim_win_set_cursor(win, { 2, col })
      vim.api.nvim_exec_autocmds("CursorMoved", { buffer = bufnr })
      vim.cmd.redraw()
      local row = vim.fn.screenpos(win, 2, 1).row
      local chars = {}
      for screen_col = 1, vim.api.nvim_win_get_width(win) do
        chars[#chars + 1] = vim.fn.screenstring(row, screen_col)
      end
      return vim.trim(table.concat(chars)):match("add.*$") or ""
    end

    h.eq(text_at(0), "add foo and bar")
    h.eq(text_at(6), "add `foo` and bar")
    h.eq(text_at(4), "add `foo` and bar")
    h.eq(text_at(15), "add foo and `bar`")
    h.eq(text_at(11), "add foo and bar")
  end
)

test(
  "a change opened on a branch above one takes none of its children",
  function()
    local root = h.repo({ "one", "two" })
    local bufnr = h.open(root)

    insert(bufnr, "above", "one", nil, true)
    h.eq(h.query(root, "::@ ~ root()", subject), { "[@]", "[two]", "[one]" })
    local children =
      h.query(root, 'children(description(exact:"one\\n"))', subject)
    table.sort(children)
    h.eq(children, { "[]", "[two]" })
  end
)

test("a change opened on a branch below one is its sibling", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  insert(bufnr, "below", "two", nil, true)
  local children =
    h.query(root, 'children(description(exact:"one\\n"))', subject)
  table.sort(children)
  h.eq(children, { "[]", "[two]" })
end)

--- Returns the texts of the virtual lines below a change's line.
---@param bufnr integer
---@param line integer
---@return string[]
local details_of = function(bufnr, line)
  local namespace = vim.api.nvim_create_namespace("nvim-jj")
  local marks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    namespace,
    { line - 1, 0 },
    { line - 1, -1 },
    { details = true }
  )
  local texts = {}
  for _, mark in ipairs(marks) do
    for _, virt_line in ipairs(assert(mark[4]).virt_lines or {}) do
      local text = ""
      for _, chunk in ipairs(virt_line) do
        text = text .. chunk[1]
      end
      texts[#texts + 1] = vim.trim((text:gsub("^[│├─╯ ]+", "")))
    end
  end
  return texts
end

test("the date shows the commit's UTC offset", function()
  local root = h.repo({ "z", "p", "m" })
  -- Describing a change rewrites its descendants with the same timestamp, so
  -- the oldest goes first.
  for _, change in ipairs({
    { "z", "zero", "+00:00" },
    { "p", "plus", "+05:30" },
    { "m", "minus", "-03:00" },
  }) do
    h.run(root, {
      "jj",
      "describe",
      "--quiet",
      "--config",
      ("debug.commit-timestamp=2001-02-03T04:05:06%s"):format(change[3]),
      "-r",
      ('description(exact:"%s\\n")'):format(change[1]),
      "-m",
      change[2],
    })
  end
  local bufnr = h.open(root)

  h.eq(details_of(bufnr, h.row(bufnr, "zero"))[1], "2001-02-03 04:05:06 UTC")
  h.eq(
    details_of(bufnr, h.row(bufnr, "plus"))[1],
    "2001-02-03 04:05:06 UTC+5:30"
  )
  h.eq(details_of(bufnr, h.row(bufnr, "minus"))[1], "2001-02-03 04:05:06 UTC-3")
end)

test("the authors are the author and the co-authors", function()
  local root = h.repo({ "one" })
  h.run(root, {
    "jj",
    "describe",
    "--quiet",
    "-r",
    "@-",
    "-m",
    "one\n\nCo-authored-by: Bob <bob@example.com>\nco-authored-by: Cy <cy@example.com>",
  })
  local bufnr = h.open(root)

  h.eq(
    details_of(bufnr, h.row(bufnr, "one"))[2],
    "test <test@example.com>, Bob <bob@example.com>, Cy <cy@example.com>"
  )
end)

--- Returns the text drawn on a screen row, without its trailing spaces.
---@param row integer
---@return string
local screen_row = function(row)
  local chars = {}
  for col = 1, vim.o.columns do
    chars[#chars + 1] = vim.fn.screenstring(row, col)
  end
  return (table.concat(chars):gsub("%s+$", ""))
end

test(
  "an empty subject's placeholder follows the ID, under the cursor",
  function()
    local root = h.repo({ "one" })
    local bufnr = h.open(root)
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_cursor(win, { 1, 0 })
    vim.cmd.redraw()

    local row = vim.fn.screenpos(win, 1, 1).row
    local text = screen_row(row)
    h.eq(text:match("^@%s+%S+ %(no description set%)$") ~= nil, true, text)
    local _, col = text:find("^@%s+%S+ ")
    local expected = vim.fn.strdisplaywidth(text:sub(1, col)) + 1
    h.eq(vim.fn.wincol(), expected)

    -- Insert mode empties the line and hides the placeholder, until it ends
    -- without anything typed.
    vim.api.nvim_exec_autocmds("InsertEnter", { buffer = bufnr })
    vim.cmd.redraw()
    h.eq(vim.api.nvim_buf_get_lines(bufnr, 0, 1, false), { "" })
    h.eq(screen_row(row):match("no description") == nil, true, screen_row(row))
    vim.api.nvim_exec_autocmds("InsertLeave", { buffer = bufnr })
    vim.cmd.redraw()
    h.eq(screen_row(row):match("%(no description set%)$") ~= nil, true)
    h.eq(vim.api.nvim_buf_get_lines(bufnr, 0, 1, false), { " " })
    h.eq(vim.bo[bufnr].modified, false)
  end
)

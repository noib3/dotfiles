local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

--- The template of a change's subject in brackets, marked with `@` for the
--- working copy.
local subject =
  '"[" ++ description.first_line() ++ if(current_working_copy, "@") ++ "]"'

--- Returns the subjects of the cut changes of a log buffer.
---@param bufnr integer
---@return string[]
local cut_subjects = function(bufnr)
  local namespace = vim.api.nvim_create_namespace("nvim-jj")
  local marks =
    vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })
  local subjects = {}
  for _, mark in ipairs(marks) do
    if assert(mark[4]).line_hl_group == "JjCut" then
      local line = vim.api.nvim_buf_get_lines(bufnr, mark[2], mark[2] + 1, false)
      subjects[#subjects + 1] = line[1]
    end
  end
  return subjects
end

---@param bufnr integer
---@param subject_text string
local cut = function(bufnr, subject_text)
  local line = h.row(bufnr, subject_text)
  nvim_jj.cut(bufnr, line, line)
end

--- Pastes the cut changes next to a subject's change, and returns the line
--- the cursor would move to.
---@param bufnr integer
---@param target string
---@param position "above"|"below"
---@param branch? boolean
---@return integer
local paste = function(bufnr, target, position, branch)
  ---@type integer?
  local line
  nvim_jj.paste(
    bufnr,
    h.row(bufnr, target),
    position,
    branch == true,
    function(l) line = l end
  )
  h.wait(function() return line ~= nil end, "the cut changes are pasted")
  return assert(line)
end

test("cutting a change highlights its line, and cutting it again doesn't", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  cut(bufnr, "one")
  h.eq(cut_subjects(bufnr), { "one" })
  -- The text after the subject keeps the line's highlight.
  local namespace = vim.api.nvim_create_namespace("nvim-jj")
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(bufnr, namespace, 0, -1, { details = true })) do
    h.eq(assert(mark[4]).hl_mode, "combine")
  end
  h.eq(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), { " ", "two", "one", " " })
  cut(bufnr, "one")
  h.eq(cut_subjects(bufnr), {})
end)

test("cut changes stay cut when the log is redrawn", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  cut(bufnr, "one")
  h.run(root, { "jj", "describe", "--quiet", "-r", "@-", "-m", "TWO" })
  h.wait(
    function() return (pcall(h.row, bufnr, "TWO")) end,
    "the log is redrawn"
  )
  h.eq(cut_subjects(bufnr), { "one" })
end)

test("pasting below a change puts the cut ones between it and its parents", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  cut(bufnr, "three")
  h.eq(paste(bufnr, "one", "below"), 4)
  h.eq(
    h.query(root, "::@ ~ root()", subject),
    { "[@]", "[two]", "[one]", "[three]" }
  )
  h.eq(cut_subjects(bufnr), {})
end)

test("pasting above a change puts the cut ones between it and its children", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  cut(bufnr, "one")
  h.eq(paste(bufnr, "two", "above"), 3)
  h.eq(
    h.query(root, "::@ ~ root()", subject),
    { "[@]", "[three]", "[one]", "[two]" }
  )
end)

test("several cut changes keep the edges between them", function()
  local root = h.repo({ "one", "two", "three", "four" })
  local bufnr = h.open(root)

  nvim_jj.cut(bufnr, h.row(bufnr, "four"), h.row(bufnr, "three"))
  paste(bufnr, "one", "below")
  h.eq(
    h.query(root, "::@ ~ root()", subject),
    { "[@]", "[two]", "[one]", "[four]", "[three]" }
  )
end)

test("pasting on a branch below a change makes the cut ones its siblings", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  cut(bufnr, "three")
  paste(bufnr, "two", "below", true)
  h.eq(h.query(root, "::@ ~ root()", subject), { "[@]", "[two]", "[one]" })
  h.eq(h.query(root, 'parents(description(exact:"three\\n"))', subject), { "[one]" })
end)

test("pasting on a branch above a change takes none of its children", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  cut(bufnr, "three")
  paste(bufnr, "one", "above", true)
  h.eq(h.query(root, "::@ ~ root()", subject), { "[@]", "[two]", "[one]" })
  h.eq(h.query(root, 'parents(description(exact:"three\\n"))', subject), { "[one]" })
end)

test("pasting next to a cut change is an error", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  h.messages = {}
  cut(bufnr, "one")
  nvim_jj.paste(bufnr, h.row(bufnr, "one"), "above", false)
  h.eq(h.messages, { "error: The change to paste next to is cut" })
end)

test("cutting an immutable change is an error", function()
  local root = h.repo({ "one", "two" }, 1)
  local bufnr = h.open(root)

  h.messages = {}
  cut(bufnr, "one")
  h.eq(#h.messages, 1)
  h.eq(assert(h.messages[1]):match("^error: .* one is immutable: ") ~= nil, true)
  h.eq(cut_subjects(bufnr), {})
end)

test("saving abandons the cut changes", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  cut(bufnr, "two")
  vim.cmd.write()
  h.wait(
    function() return #h.query(root, "::@ ~ root()", subject) == 3 end,
    "the cut change is abandoned"
  )
  h.eq(h.query(root, "::@ ~ root()", subject), { "[@]", "[three]", "[one]" })
  h.settle()
  h.eq(cut_subjects(bufnr), {})
end)

test("a cut change's details are highlighted like its line", function()
  local root = h.repo({ "one" })
  local bufnr = h.open(root)

  cut(bufnr, "one")
  local namespace = vim.api.nvim_create_namespace("nvim-jj")
  local line = h.row(bufnr, "one") - 1
  local marks = vim.api.nvim_buf_get_extmarks(
    bufnr,
    namespace,
    { line, 0 },
    { line, -1 },
    { details = true }
  )
  ---@type string[]
  local highlights = {}
  for _, mark in ipairs(marks) do
    for _, virt_line in ipairs(assert(mark[4]).virt_lines or {}) do
      local last = virt_line[#virt_line]
      highlights[#highlights + 1] = type(last[2]) == "table" and last[2][#last[2]]
        or last[2]
    end
  end
  h.eq(highlights, { "JjCut", "JjCut" })
end)

test("the descendants text objects cut a change's descendants", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  local done = false
  nvim_jj.cut_descendants(bufnr, h.row(bufnr, "two"), true, function() done = true end)
  h.wait(function() return done end, "the descendants are cut")
  h.eq(cut_subjects(bufnr), { " ", "three", "two" })

  -- Only the descendants of `one` are the ones already cut, which uncuts them.
  for _, expected in ipairs({ {}, { " ", "three", "two" } }) do
    done = false
    nvim_jj.cut_descendants(bufnr, h.row(bufnr, "one"), false, function() done = true end)
    h.wait(function() return done end, "the descendants are toggled")
    h.eq(cut_subjects(bufnr), expected)
  end
end)

test("copying drops the cut changes", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  cut(bufnr, "one")
  local line = h.row(bufnr, "two")
  nvim_jj.copy(bufnr, line, line)
  h.eq(cut_subjects(bufnr), {})
end)

test("pasting a copy on a branch below a change makes a sibling", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  local line = h.row(bufnr, "two")
  nvim_jj.copy(bufnr, line, line)
  paste(bufnr, "two", "below", true)
  local children = h.query(root, 'children(description(exact:"one\\n"))', subject)
  table.sort(children)
  h.eq(children, { "[two]", "[two]" })
  h.eq(h.query(root, "::@ ~ root()", subject), { "[@]", "[two]", "[one]" })

  -- The copied change stays copied.
  h.eq(nvim_jj.has_held(bufnr), true)
end)

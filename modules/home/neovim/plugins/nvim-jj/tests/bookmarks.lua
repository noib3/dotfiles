local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

--- Edits the bookmark of the change on a subject's line, answering the
--- prompt with the given text, and returns the prompt's default.
---@param bufnr integer
---@param subject string
---@param answer? string The text entered, or nil to cancel.
---@return string? default
local edit = function(bufnr, subject, answer)
  ---@type string?
  local default
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.input = function(opts, on_confirm)
    default = (opts or {}).default
    on_confirm(answer)
  end
  local done = false
  nvim_jj.edit_bookmark(
    bufnr,
    h.row(bufnr, subject),
    function() done = true end
  )
  h.wait(function() return done end, "the bookmark is edited")
  return default
end

---@param root string
---@return string[]
local bookmarks = function(root)
  return h.query(
    root,
    "bookmarks()",
    'local_bookmarks.map(|b| b.name() ++ ":" ++ description.first_line()).join(" ")'
  )
end

test("a new name creates a bookmark", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  h.eq(edit(bufnr, "two", "feature"), "")
  h.eq(bookmarks(root), { "feature:two" })
end)

test("the prompt starts with the bookmark's name, and renames it", function()
  local root = h.repo({ "one", "two" })
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  local bufnr = h.open(root)

  h.eq(edit(bufnr, "two", "renamed"), "feature")
  h.eq(bookmarks(root), { "renamed:two" })
end)

test("an empty name deletes the bookmark", function()
  local root = h.repo({ "one", "two" })
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  local bufnr = h.open(root)

  edit(bufnr, "two", "")
  h.eq(bookmarks(root), {})
end)

test("cancelling the prompt changes nothing", function()
  local root = h.repo({ "one", "two" })
  h.run(root, { "jj", "bookmark", "create", "--quiet", "feature", "-r", "@-" })
  local bufnr = h.open(root)

  edit(bufnr, "two", nil)
  h.eq(bookmarks(root), { "feature:two" })
end)

test("the log shows the new bookmark", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  edit(bufnr, "two", "feature")
  h.wait(
    function() return h.screen(bufnr)[4] == "○  <id> two feature" end,
    "the bookmark is drawn"
  )
end)

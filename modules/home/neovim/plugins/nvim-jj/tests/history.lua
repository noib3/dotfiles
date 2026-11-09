local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

--- The template of a change's subject in brackets, marked with `@` for the
--- working copy.
local subject =
  '"[" ++ description.first_line() ++ if(current_working_copy, "@") ++ "]"'

--- Runs an operation that calls back once it's done, and waits for it.
---@param fn fun(on_done: fun(...))
local wait_for = function(fn)
  local done = false
  fn(function() done = true end)
  h.wait(function() return done end, "the operation is done")
  h.settle()
end

---@param bufnr integer
local undo = function(bufnr)
  wait_for(function(on_done) nvim_jj.undo(bufnr, on_done) end)
end

---@param bufnr integer
local redo = function(bufnr)
  wait_for(function(on_done) nvim_jj.redo(bufnr, on_done) end)
end

---@param root string
---@return string[]
local history = function(root) return h.query(root, "::@ ~ root()", subject) end

test("an inserted change is undone and redone", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)
  local line = h.row(bufnr, "one")

  wait_for(
    function(on_done)
      nvim_jj.insert_change(bufnr, "above", false, line, line, on_done)
    end
  )
  -- The new change is edited in insert mode, which the tests don't need.
  vim.cmd.stopinsert()
  h.eq(history(root), { "[@]", "[two]", "[]", "[one]" })
  undo(bufnr)
  h.eq(history(root), { "[@]", "[two]", "[one]" })
  redo(bufnr)
  h.eq(history(root), { "[@]", "[two]", "[]", "[one]" })
end)

test(
  "undoing an inserted change that isn't empty anymore is an error",
  function()
    local root = h.repo({ "one" })
    local bufnr = h.open(root)
    local line = h.row(bufnr, "one")

    wait_for(
      function(on_done)
        nvim_jj.insert_change(bufnr, "above", false, line, line, on_done)
      end
    )
    -- The new change is edited in insert mode, which the tests don't need.
    vim.cmd.stopinsert()
    h.run(root, { "jj", "describe", "--quiet", "-r", "@-", "-m", "filled" })
    local file = assert(io.open(vim.fs.joinpath(root, "new"), "w"))
    file:write("new\n")
    file:close()
    h.run(root, { "jj", "squash", "--quiet", "--into", "@-" })
    h.settle()

    h.messages = {}
    undo(bufnr)
    h.eq(#h.messages, 1)
    h.eq(
      assert(h.messages[1]):match("^error: .* filled isn't empty anymore$")
        ~= nil,
      true
    )
  end
)

test("a paste is undone and redone", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  local line = h.row(bufnr, "three")
  nvim_jj.cut(bufnr, line, line)
  wait_for(
    function(on_done)
      nvim_jj.paste(bufnr, h.row(bufnr, "one"), "below", false, on_done)
    end
  )
  h.eq(history(root), { "[@]", "[two]", "[one]", "[three]" })
  undo(bufnr)
  h.eq(history(root), { "[@]", "[three]", "[two]", "[one]" })
  redo(bufnr)
  h.eq(history(root), { "[@]", "[two]", "[one]", "[three]" })
end)

test("undoing a paste of separate changes puts each back", function()
  local root = h.repo({ "one", "two", "three", "four" })
  local bufnr = h.open(root)

  for _, name in ipairs({ "one", "three" }) do
    local line = h.row(bufnr, name)
    nvim_jj.cut(bufnr, line, line)
  end
  wait_for(
    function(on_done)
      nvim_jj.paste(bufnr, h.row(bufnr, "four"), "above", false, on_done)
    end
  )
  undo(bufnr)
  h.eq(history(root), { "[@]", "[four]", "[three]", "[two]", "[one]" })
end)

test("an abandon is undone by recreating the changes", function()
  local root = h.repo({ "one", "two", "three" })
  local bufnr = h.open(root)

  local line = h.row(bufnr, "two")
  nvim_jj.cut(bufnr, line, line)
  vim.cmd.write()
  h.wait(function() return #history(root) == 3 end, "the change is abandoned")
  h.settle()
  undo(bufnr)
  h.eq(history(root), { "[@]", "[three]", "[two]", "[one]" })
  h.eq(h.query(root, 'description(exact:"three\\n")', "empty"), { "false" })

  redo(bufnr)
  h.eq(history(root), { "[@]", "[three]", "[one]" })
end)

test("a paste of copies is undone", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  local line = h.row(bufnr, "two")
  nvim_jj.copy(bufnr, line, line)
  wait_for(
    function(on_done)
      nvim_jj.paste(bufnr, h.row(bufnr, "two"), "below", true, on_done)
    end
  )
  h.eq(#h.query(root, 'description(exact:"two\\n")', subject), 2)
  undo(bufnr)
  h.eq(#h.query(root, 'description(exact:"two\\n")', subject), 1)
end)

test("a checkout is undone, recreating the empty working copy", function()
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)

  wait_for(
    function(on_done) nvim_jj.check_out(bufnr, h.row(bufnr, "one"), on_done) end
  )
  h.eq(history(root), { "[one@]" })
  undo(bufnr)
  h.eq(history(root), { "[@]", "[two]", "[one]" })
  redo(bufnr)
  h.eq(history(root), { "[one@]" })
end)

test("a new bookmark is undone and redone", function()
  local root = h.repo({ "one" })
  local bufnr = h.open(root)

  local input = vim.ui.input
  ---@diagnostic disable-next-line: duplicate-set-field
  vim.ui.input = function(_, on_confirm) on_confirm("feature") end
  wait_for(
    function(on_done) nvim_jj.edit_bookmark(bufnr, h.row(bufnr, "one"), on_done) end
  )
  vim.ui.input = input

  local bookmarks = 'local_bookmarks.map(|b| b.name()).join(" ")'
  h.eq(h.query(root, "@-", bookmarks), { "feature" })
  undo(bufnr)
  h.eq(h.query(root, "@-", bookmarks), {})
  redo(bufnr)
  h.eq(h.query(root, "@-", bookmarks), { "feature" })
end)

test("there's nothing to undo or redo at first", function()
  local root = h.repo({ "one" })
  local bufnr = h.open(root)

  h.messages = {}
  undo(bufnr)
  redo(bufnr)
  h.eq(h.messages, { "error: Nothing to undo", "error: Nothing to redo" })
end)

local h = require("nvim_jj_tests")
local nvim_jj = require("nvim_jj")

h.setup()

---@param bufnr integer
---@param line integer
---@return lsp.CodeAction[]
local code_actions = function(bufnr, line)
  local client =
    assert(vim.lsp.get_clients({ bufnr = bufnr, name = "nvim-jj" })[1])
  local response = client:request_sync("textDocument/codeAction", {
    textDocument = { uri = vim.uri.from_buf(bufnr) },
    range = {
      start = { line = line - 1, character = 0 },
      ["end"] = { line = line - 1, character = 0 },
    },
    context = { diagnostics = {} },
  }, 2000, bufnr)
  return response and response.result or {}
end

---@param actions lsp.CodeAction[]
---@return string[]
local titles = function(actions)
  return vim.tbl_map(function(action) return action.title end, actions)
end

---@param bufnr integer
---@param line integer
---@return string[]
local action_titles = function(bufnr, line) return titles(code_actions(bufnr, line)) end

--- Registers an action recording the contexts it runs in, offered on a
--- target, and returns the contexts.
---@param title string
---@param target nvim_jj.ActionTarget
---@return nvim_jj.ActionContext[]
local recording = function(title, target)
  local contexts = {}
  nvim_jj.register_action({
    title = title,
    available = function(ctx) return ctx.target == target end,
    run = function(ctx) contexts[#contexts + 1] = ctx end,
  })
  return contexts
end

test("the log offers the actions on a change's subject", function()
  local subjects = recording("Subject", "subject")
  recording("Description", "description")
  nvim_jj.register_action({
    title = "Only on two",
    available = function(ctx) return ctx.text == "two" end,
    run = function() end,
  })
  local root = h.repo({ "one", "two" })
  local bufnr = h.open(root)
  h.wait(
    function() return #code_actions(bufnr, h.row(bufnr, "two")) > 0 end,
    "the language server answers"
  )
  h.eq(action_titles(bufnr, h.row(bufnr, "one")), { "Subject" })
  h.eq(action_titles(bufnr, h.row(bufnr, "two")), { "Only on two", "Subject" })

  nvim_jj.run_action(bufnr, h.row(bufnr, "two"), "Subject")
  local ctx = assert(subjects[1])
  h.eq(ctx.root, root)
  h.eq(ctx.target, "subject")
  h.eq(ctx.text, "two")
  h.eq(ctx.diff[1], "-r")
  ctx.set_status("busy", "Writing")
  h.eq(h.status(bufnr, "two"), "busy: Writing")
  for _, title in ipairs({ "Subject", "Description", "Only on two" }) do
    nvim_jj.unregister_action(title)
  end
end)

test("an action replaces a subject in the log, keeping the body once saved", function()
  local subjects = recording("Subject", "subject")
  local root = h.repo({ "one", "two\n\nThe body." })
  local bufnr = h.open(root)
  nvim_jj.run_action(bufnr, h.row(bufnr, "two"), "Subject")
  assert(subjects[1]).replace("Better subject\nignored")

  h.eq(vim.api.nvim_get_current_buf(), bufnr)
  h.eq(h.row(bufnr, "Better subject") ~= nil, true)
  h.eq(vim.bo[bufnr].modified, true)
  vim.cmd("write")
  h.wait(function()
    return vim.deep_equal(
      h.query(root, "@-", "description"),
      { "Better subject", "", "The body." }
    )
  end, "the subject is saved")
  nvim_jj.unregister_action("Subject")
end)

test("a change's view offers the actions on its subject and on its description", function()
  local subjects = recording("Subject", "subject")
  local descriptions = recording("Description", "description")
  local root = h.repo({ "one", "two\n\nOld body." })
  local log = h.open(root)
  nvim_jj.open_change(log, h.row(log, "two"), "here")
  local view = vim.api.nvim_get_current_buf()
  h.wait(
    function() return #code_actions(view, 1) > 0 end,
    "the view's language server answers"
  )
  h.eq(action_titles(view, 1), { "Subject" })
  h.eq(action_titles(view, 3), { "Description" })

  nvim_jj.run_action(view, 3, "Description")
  local ctx = assert(descriptions[1])
  h.eq(ctx.text, "Old body.")
  ctx.replace("A new body\nover two lines.")
  h.wait(
    function() return vim.api.nvim_buf_get_lines(view, 2, 4, false)[1] == "A new body" end,
    "the description is replaced"
  )
  h.eq(vim.api.nvim_buf_get_lines(view, 0, 4, false), { "two", "", "A new body", "over two lines." })

  nvim_jj.run_action(view, 1, "Subject")
  assert(subjects[1]).replace("Two")
  h.eq(vim.api.nvim_buf_get_lines(view, 0, 1, false), { "Two" })
  vim.cmd("write")
  h.wait(function()
    return vim.deep_equal(
      h.query(root, "@-", "description"),
      { "Two", "", "A new body", "over two lines." }
    )
  end, "the description is saved")
  nvim_jj.unregister_action("Subject")
  nvim_jj.unregister_action("Description")
end)

test("an action's error is drawn after its change", function()
  local root = h.repo({ "one" })
  local bufnr = h.open(root)
  nvim_jj.register_action({
    title = "Broken",
    run = function() error("it broke", 0) end,
  })
  nvim_jj.run_action(bufnr, h.row(bufnr, "one"), "Broken")
  h.eq(h.status(bufnr, "one"), "failed: it broke")
  nvim_jj.unregister_action("Broken")
end)

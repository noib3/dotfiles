local h = require("nvim_agents_tests")
local mcp = require("nvim_agents.mcp")

local dir = h.tmpdir()

--- Runs a tool and waits for its result.
---@param name string
---@param args table
---@return nvim_agents.mcp.Result
local run = function(name, args)
  ---@type nvim_agents.mcp.Result?
  local result
  mcp.run(name, args, dir, function(r) result = r end)
  h.wait(function() return result ~= nil end, name .. " is done")
  return assert(result)
end

--- Opens a file in a buffer.
---@param name string
---@param text string
---@return integer bufnr
---@return string path
local open = function(name, text)
  local path = vim.fs.joinpath(dir, name)
  h.write(path, text)
  vim.cmd.edit(vim.fn.fnameescape(path))
  return vim.api.nvim_get_current_buf(), path
end

--- The positions the fake language server was asked about, last first.
---@type table[]
local asked = {}

--- Returns a fake language server.
---@param dispatchers vim.lsp.rpc.Dispatchers
---@return vim.lsp.rpc.Client
local server = function(dispatchers)
  local closing, request_id = false, 0
  local handle = function(method, params)
    if method == "initialize" then
      return {
        capabilities = {
          definitionProvider = true,
          referencesProvider = true,
          hoverProvider = true,
          workspaceSymbolProvider = true,
        },
      }
    elseif method == "shutdown" then
      return vim.NIL
    end
    table.insert(asked, 1, { method = method, params = params })
    local uri = params.textDocument and params.textDocument.uri
    local at = function(line)
      return {
        uri = uri,
        range = {
          start = { line = line, character = 0 },
          ["end"] = { line = line, character = 1 },
        },
      }
    end
    if method == "textDocument/definition" then
      return at(0)
    elseif method == "textDocument/references" then
      return { at(0), at(1), at(1) }
    elseif method == "textDocument/hover" then
      return {
        contents = {
          kind = "markdown",
          value = "```lua\nlocal x: integer\n```",
        },
      }
    elseif method == "workspace/symbol" then
      return {
        {
          name = "x",
          kind = 13,
          location = {
            uri = vim.uri.from_fname(vim.fs.joinpath(dir, "lsp.lua")),
            range = {
              start = { line = 0, character = 6 },
              ["end"] = { line = 0, character = 7 },
            },
          },
        },
      }
    end
    return vim.NIL
  end
  local client = {
    request = function(method, params, callback)
      request_id = request_id + 1
      vim.schedule(function() callback(nil, handle(method, params)) end)
      return true, request_id
    end,
    notify = function(method)
      if method == "exit" then
        closing = true
        dispatchers.on_exit(0, 0)
      end
      return true
    end,
    is_closing = function() return closing end,
    terminate = function() closing = true end,
  }
  return client --[[@as vim.lsp.rpc.Client]]
end

-- The fake language server attaches to the Lua files of the test's directory.
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  callback = function(ev)
    if not vim.startswith(vim.api.nvim_buf_get_name(ev.buf), dir) then
      return
    end
    vim.lsp.start(
      { name = "fake", cmd = server, root_dir = dir },
      { bufnr = ev.buf }
    )
  end,
})

test("read sees a buffer's unsaved changes, numbered", function()
  local bufnr = open("read.txt", "one\ntwo\nthree\n")
  vim.api.nvim_buf_set_lines(bufnr, 1, 2, false, { "TWO" })
  h.eq(
    run("read", { path = "read.txt" }).text,
    "     1\tone\n     2\tTWO\n     3\tthree"
  )
  h.eq(
    run("read", { path = "read.txt", offset = 2, limit = 1 }).text,
    "     2\tTWO"
  )
end)

test("read reads a file that isn't open from disk", function()
  local path = vim.fs.joinpath(dir, "closed.txt")
  h.write(path, "a\nb\n")
  h.eq(run("read", { path = path }).text, "     1\ta\n     2\tb")
  h.eq(run("read", { path = "missing.txt" }).is_error, true)
end)

test("edit keeps a modified buffer's changes and leaves it unsaved", function()
  local bufnr, path = open("modified.txt", "local x = 1\nlocal y = x + 1\n")
  vim.api.nvim_buf_set_lines(bufnr, 1, 2, false, { "local y = x + 2" })
  local result =
    run("edit", { path = path, old_text = "x = 1", new_text = "x = 10" })
  h.eq(result.is_error, nil)
  h.eq(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "local x = 10", "local y = x + 2" }
  )
  h.eq(vim.bo[bufnr].modified, true)
  h.eq(h.read(path), "local x = 1\nlocal y = x + 1\n")
  h.eq(result.text:find("unsaved changes", 1, true) ~= nil, true)
end)

test("edit saves a buffer without unsaved changes", function()
  local bufnr, path = open("saved.txt", "alpha\nbeta\n")
  run("edit", { path = path, old_text = "beta", new_text = "gamma\ndelta" })
  h.eq(
    vim.api.nvim_buf_get_lines(bufnr, 0, -1, false),
    { "alpha", "gamma", "delta" }
  )
  h.eq(vim.bo[bufnr].modified, false)
  h.eq(h.read(path), "alpha\ngamma\ndelta\n")
end)

test("edit refuses missing and repeated text, unless replacing all", function()
  local bufnr, path = open("repeated.txt", "a b a\n")
  h.eq(
    run("edit", { path = path, old_text = "c", new_text = "d" }).is_error,
    true
  )
  local repeated = run("edit", { path = path, old_text = "a", new_text = "x" })
  h.eq(repeated.is_error, true)
  h.eq(repeated.text:find("occurs 2 times", 1, true) ~= nil, true)
  run(
    "edit",
    { path = path, old_text = "a", new_text = "xy", replace_all = true }
  )
  h.eq(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), { "xy b xy" })
end)

test("edit writes a file that isn't open to disk", function()
  local path = vim.fs.joinpath(dir, "disk.txt")
  h.write(path, "one\ntwo\n")
  local result = run("edit", { path = path, old_text = "two", new_text = "2" })
  h.eq(result.is_error, nil)
  h.eq(h.read(path), "one\n2\n")
  h.eq(result.text, ("Edited %s:\n     1\tone\n     2\t2"):format(path))
end)

test("a file's state is whether it's loaded and has unsaved changes", function()
  local bufnr, path = open("is_modified.txt", "text\n")
  h.eq(mcp.file_state(path), "loaded")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "changed" })
  h.eq(mcp.file_state(path), "modified")
  h.eq(mcp.file_state(vim.fs.joinpath(dir, "not_open.txt")), nil)
end)

test("lsp tools ask about the symbol's position", function()
  local path = vim.fs.joinpath(dir, "lsp.lua")
  h.write(path, "local x = 1\nprint(x, x)\n")
  -- The file isn't open, so the tool loads it, and waits for its server.
  local result = run("lsp_references", { path = path, line = 2, symbol = "x" })
  h.eq(result.text, ("%s:1: local x = 1\n%s:2: print(x, x)"):format(path, path))
  local references = assert(asked[1])
  h.eq(references.method, "textDocument/references")
  h.eq(references.params.position, { line = 1, character = 6 })
  h.eq(references.params.context, { includeDeclaration = true })

  h.eq(
    run("lsp_definition", { path = path, line = 2 }).text,
    ("%s:1: local x = 1"):format(path)
  )
  h.eq(assert(asked[1]).params.position, { line = 1, character = 0 })
  h.eq(
    run("lsp_hover", { path = path, line = 1, symbol = "x" }).text,
    "```lua\nlocal x: integer\n```"
  )
  h.eq(
    run("lsp_workspace_symbols", { path = path, query = "x" }).text,
    ("x (Variable) %s:1"):format(path)
  )
end)

test("lsp tools explain a symbol missing from the line", function()
  local path = vim.fs.joinpath(dir, "lsp.lua")
  local result = run("lsp_hover", { path = path, line = 1, symbol = "nope" })
  h.eq(result.is_error, true)
  h.eq(result.text, "`nope` isn't on line 1, which is:\nlocal x = 1")
end)

test("lsp tools fail without a language server", function()
  local path = vim.fs.joinpath(dir, "plain.txt")
  h.write(path, "text\n")
  local result = run("lsp_definition", { path = path, line = 1 })
  h.eq(result.is_error, true)
  h.eq(result.text:find("no language server", 1, true) ~= nil, true)
end)

test("diagnostics are listed most severe first", function()
  local bufnr = open("diagnostics.txt", "a\nb\n")
  local namespace = vim.api.nvim_create_namespace("test-diagnostics")
  vim.diagnostic.set(namespace, bufnr, {
    {
      lnum = 0,
      col = 0,
      message = "a hint",
      severity = vim.diagnostic.severity.HINT,
    },
    {
      lnum = 1,
      col = 0,
      message = "an error",
      severity = vim.diagnostic.severity.ERROR,
      source = "test",
    },
  })
  local path = vim.api.nvim_buf_get_name(bufnr)
  h.eq(
    run("lsp_diagnostics", { path = "diagnostics.txt" }).text,
    ("%s:2:1: error: an error [test]\n%s:1:1: hint: a hint"):format(path, path)
  )
end)

test("the stdio server runs tool calls in the Neovim at $NVIM", function()
  local bufnr, path = open("stdio.txt", "on disk\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "unsaved" })
  local source = assert(
    vim.api.nvim_get_runtime_file("lua/nvim_agents/mcp/stdio.lua", false)[1]
  )
  local output = ""
  local process = vim.system({ vim.v.progpath, "--clean", "-l", source }, {
    stdin = true,
    cwd = dir,
    -- The server finds no other Neovims than the one at `$NVIM`.
    env = { NVIM = vim.v.servername, XDG_RUNTIME_DIR = h.tmpdir() },
    stdout = function(_, data) output = output .. (data or "") end,
  })
  local messages = {
    {
      jsonrpc = "2.0",
      id = 1,
      method = "initialize",
      params = { protocolVersion = "2025-06-18" },
    },
    { jsonrpc = "2.0", method = "notifications/initialized" },
    { jsonrpc = "2.0", id = 2, method = "tools/list" },
    {
      jsonrpc = "2.0",
      id = 3,
      method = "tools/call",
      params = { name = "read", arguments = { path = "stdio.txt" } },
    },
  }
  for _, message in ipairs(messages) do
    process:write(vim.json.encode(message) .. "\n")
  end
  h.wait(
    function() return select(2, output:gsub("\n", "")) >= 3 end,
    "the server answered"
  )
  process:kill("sigterm")

  local replies = {}
  for line in output:gmatch("[^\n]+") do
    local reply = vim.json.decode(line)
    replies[reply.id] = reply
  end
  h.eq(replies[1].result.serverInfo.name, "nvim")
  h.eq(replies[1].result.protocolVersion, "2025-06-18")
  h.eq(replies[1].result.instructions, mcp.instructions)
  h.eq(
    vim.tbl_map(function(tool) return tool.name end, replies[2].result.tools),
    vim.tbl_map(function(tool) return tool.name end, mcp.tools)
  )
  h.eq(replies[3].result, {
    content = { { type = "text", text = "     1\tunsaved" } },
    isError = false,
  })
  h.eq(path ~= nil, true)
end)

test("the stdio server lists no tools outside of a Neovim terminal", function()
  local source = assert(
    vim.api.nvim_get_runtime_file("lua/nvim_agents/mcp/stdio.lua", false)[1]
  )
  local result = vim
    .system({ vim.v.progpath, "--clean", "-l", source }, {
      stdin = vim.json.encode({
        jsonrpc = "2.0",
        id = 1,
        method = "tools/list",
      }) .. "\n",
      env = { NVIM = "", XDG_RUNTIME_DIR = h.tmpdir() },
      text = true,
    })
    :wait(5000)
  h.eq(vim.json.decode(vim.trim(result.stdout or "")).result.tools, {})
end)

test("outside of a Neovim terminal, the stdio server runs tool calls in the Neovim with the file", function()
  local bufnr, path = open("routed.txt", "on disk\n")
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "unsaved here" })
  -- The test's Neovim is the only one in the server's runtime directory.
  local run = h.tmpdir()
  local address = vim.fn.serverstart(vim.fs.joinpath(run, ("nvim.%d.0"):format(vim.fn.getpid())))
  local source = assert(vim.api.nvim_get_runtime_file("lua/nvim_agents/mcp/stdio.lua", false)[1])
  local output = ""
  local process = vim.system({ vim.v.progpath, "--clean", "-l", source }, {
    stdin = true,
    cwd = dir,
    env = { NVIM = "", XDG_RUNTIME_DIR = run },
    stdout = function(_, data) output = output .. (data or "") end,
  })
  for _, message in ipairs({
    { jsonrpc = "2.0", id = 1, method = "tools/list" },
    {
      jsonrpc = "2.0",
      id = 2,
      method = "tools/call",
      params = { name = "read", arguments = { path = path } },
    },
  }) do
    process:write(vim.json.encode(message) .. "\n")
  end
  h.wait(function() return select(2, output:gsub("\n", "")) >= 2 end, "the server answered")
  process:kill("sigterm")
  vim.fn.serverstop(address)

  local replies = {}
  for line in output:gmatch("[^\n]+") do
    local reply = vim.json.decode(line)
    replies[reply.id] = reply
  end
  h.eq(#replies[1].result.tools, #mcp.tools, "the tools are listed")
  h.eq(replies[2].result.content[1].text, "     1\tunsaved here")
end)

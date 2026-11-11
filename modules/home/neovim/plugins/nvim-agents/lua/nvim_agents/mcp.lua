--- The tools of the MCP server, which run in the Neovim whose terminal runs the
--- agent: reading and editing buffers, and asking the language servers.

local M = {}

local uv = vim.uv

--- The time a language server has to attach to a buffer just loaded.
local attach_timeout_ms = 1500

--- The time an attached language server has to initialize.
local initialize_timeout_ms = 15000

--- The time a language server has to answer a request.
local request_timeout_ms = 15000

--- The time a buffer just loaded waits for its first diagnostics.
local diagnostics_timeout_ms = 5000

--- The maximum number of locations, symbols or diagnostics listed.
local max_items = 200

--- The number of lines read by default.
local default_limit = 2000

--- The number of unchanged lines shown around an edit.
local edit_context = 3

M.instructions = table.concat({
  "Tools of the Neovim editor the user works in, which may have unsaved",
  "changes in its buffers. `read` and `edit` see those changes, and `edit`",
  "keeps the user's edits made since you last read the file: prefer them to",
  "the built-in tools for reading files, and use `edit` for every edit to an",
  "existing file instead of shell commands like sed. The `lsp_*` tools ask",
  "the language servers the editor already runs: prefer them to text search",
  "for definitions, references, types, symbols and diagnostics. Positions",
  "are a 1-based line and a symbol on that line.",
}, " ")

---@class nvim_agents.mcp.Result
---@field text string
---@field is_error? boolean

---@alias nvim_agents.mcp.Run fun(args: table, cwd: string, callback: fun(result: nvim_agents.mcp.Result))

---@class nvim_agents.mcp.Tool
---@field name string
---@field description string
---@field input_schema table
---@field run nvim_agents.mcp.Run

---@param text string
---@return nvim_agents.mcp.Result
local failure = function(text) return { text = text, is_error = true } end

--- Returns a path with its symlinks resolved, if it exists.
---@param path string
---@return string
local canonical = function(path)
  return vim.fs.normalize(uv.fs_realpath(path) or path)
end

---@param path any
---@param cwd string
---@return string?
local resolve = function(path, cwd)
  if type(path) ~= "string" or path == "" then return end
  if not vim.startswith(path, "/") then path = vim.fs.joinpath(cwd, path) end
  return canonical(path)
end

--- Returns the loaded buffer of a file, if any.
---@param path string A canonical path.
---@return integer?
local loaded_buffer = function(path)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if
      vim.api.nvim_buf_is_loaded(bufnr)
      and vim.bo[bufnr].buftype == ""
      and name ~= ""
      and canonical(name) == path
    then
      return bufnr
    end
  end
end

--- Returns the buffer of a file, loading it if it isn't. A file open in
--- another Neovim is loaded without asking about its swap file.
---@param path string
---@return integer? bufnr
---@return boolean? loaded Whether the buffer was loaded by this call.
local load_buffer = function(path)
  local bufnr = loaded_buffer(path)
  if bufnr then return bufnr, false end
  if not uv.fs_stat(path) then return end
  bufnr = vim.fn.bufadd(path)
  local shortmess = vim.o.shortmess
  vim.o.shortmess = shortmess .. "A"
  local ok = pcall(vim.fn.bufload, bufnr)
  vim.o.shortmess = shortmess
  if not ok then return end
  return bufnr, true
end

---@param path string
---@return string[]?
local read_lines = function(path)
  local file = io.open(path, "rb")
  if not file then return end
  local text = file:read("*a")
  file:close()
  local lines = vim.split(text, "\n", { plain = true })
  if lines[#lines] == "" then lines[#lines] = nil end
  return lines
end

--- Returns a file's lines, from its buffer if it's loaded.
---@param path string
---@return string[]?
local lines_of = function(path)
  local bufnr = loaded_buffer(path)
  if bufnr then return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false) end
  return read_lines(path)
end

---@param lines string[]
---@param first integer The 1-based number of the first line.
---@return string
local numbered = function(lines, first)
  local out = {}
  for index, line in ipairs(lines) do
    out[index] = ("%6d\t%s"):format(first + index - 1, line)
  end
  return table.concat(out, "\n")
end

---@type nvim_agents.mcp.Run
local read = function(args, cwd, callback)
  local path = resolve(args.path, cwd)
  if not path then return callback(failure("`path` is required")) end
  local lines = lines_of(path)
  if not lines then
    return callback(failure(("%s doesn't exist"):format(path)))
  end
  local offset = math.max(math.floor(tonumber(args.offset) or 1), 1)
  local limit = math.max(math.floor(tonumber(args.limit) or default_limit), 1)
  local slice = vim.list_slice(lines, offset, offset + limit - 1)
  if #slice == 0 then
    return callback({
      text = ("%s has %d lines"):format(path, #lines),
    })
  end
  callback({ text = numbered(slice, offset) })
end

--- Returns the 0-based row and byte column of a byte offset in a text.
---@param text string
---@param offset integer The 1-based offset.
---@return integer row
---@return integer col
local position_of = function(text, offset)
  local row, line_start = 0, 1
  local at = text:find("\n", line_start, true)
  while at and at < offset do
    row = row + 1
    line_start = at + 1
    at = text:find("\n", line_start, true)
  end
  return row, offset - line_start
end

--- Returns the 1-based offsets of the occurrences of a text.
---@param text string
---@param pattern string
---@return integer[]
local occurrences = function(text, pattern)
  ---@type integer[]
  local found, from = {}, 1
  while true do
    local at = text:find(pattern, from, true)
    if not at then return found end
    found[#found + 1] = at
    from = at + #pattern
  end
end

---@type nvim_agents.mcp.Run
local edit = function(args, cwd, callback)
  local path = resolve(args.path, cwd)
  local old_text, new_text = args.old_text, args.new_text
  if not path or type(old_text) ~= "string" or type(new_text) ~= "string" then
    return callback(failure("`path`, `old_text` and `new_text` are required"))
  end
  ---@cast old_text string
  ---@cast new_text string
  if old_text == "" then return callback(failure("`old_text` is empty")) end

  local bufnr = loaded_buffer(path)
  local lines = bufnr and vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    or read_lines(path)
  if not lines then
    return callback(failure(("%s doesn't exist"):format(path)))
  end
  local text = table.concat(lines, "\n")
  local found = occurrences(text, old_text)
  if #found == 0 then
    return callback(failure(("`old_text` isn't in %s"):format(path)))
  elseif #found > 1 and not args.replace_all then
    return callback(
      failure(
        ("`old_text` occurs %d times in %s: add context to make it unique, or set `replace_all`"):format(
          #found,
          path
        )
      )
    )
  end

  local edited, last = {}, 1
  for _, at in ipairs(found) do
    ---@cast at integer
    edited[#edited + 1] = text:sub(last, at - 1)
    edited[#edited + 1] = new_text
    last = at + #old_text
  end
  edited[#edited + 1] = text:sub(last)
  local result = table.concat(edited)

  if bufnr then
    local was_modified = vim.bo[bufnr].modified
    local new_lines = vim.split(new_text, "\n", { plain = true })
    -- The last occurrence is replaced first, so the offsets of the others
    -- stay valid.
    for index = #found, 1, -1 do
      local start_row, start_col = position_of(text, found[index])
      local end_row, end_col = position_of(text, found[index] + #old_text)
      vim.api.nvim_buf_set_text(
        bufnr,
        start_row,
        start_col,
        end_row,
        end_col,
        new_lines
      )
    end
    if not was_modified then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent write") end)
    end
  else
    local file = io.open(path, "wb")
    if not file then
      return callback(failure(("can't write %s"):format(path)))
    end
    file:write(result, "\n")
    file:close()
  end

  -- The rows of the first and last replacements, in the edited text.
  local shift = (#found - 1) * (#new_text - #old_text)
  local first_row = position_of(result, found[1] --[[@as integer]])
  local last_row = position_of(result, found[#found] + shift + #new_text)
  lines = bufnr and vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    or vim.split(result, "\n", { plain = true })
  local from = math.max(first_row + 1 - edit_context, 1)
  local to = math.min(last_row + 1 + edit_context, #lines)
  callback({
    text = ("Edited %s%s:\n%s"):format(
      path,
      bufnr
          and vim.bo[bufnr].modified
          and " in its buffer, which has the user's unsaved changes"
        or "",
      numbered(vim.list_slice(lines, from, to), from)
    ),
  })
end

--- Calls back with a buffer's initialized language servers supporting a
--- method, once they're initialized or the time to wait for them is up.
---@param bufnr integer
---@param method string
---@param callback fun(clients: vim.lsp.Client[])
local with_clients = function(bufnr, method, callback)
  local start = uv.now()
  local function try()
    local attached = vim.lsp.get_clients({ bufnr = bufnr })
    local elapsed = uv.now() - start
    local pending = vim
      .iter(attached)
      :any(function(client) return not client.initialized end)
    if
      (#attached == 0 and elapsed < attach_timeout_ms)
      or (pending and elapsed < initialize_timeout_ms)
    then
      return vim.defer_fn(try, 50)
    end
    callback(
      vim.tbl_filter(
        function(client)
          return client.initialized and client:supports_method(method, bufnr)
        end,
        attached
      )
    )
  end
  try()
end

--- Sends a request to a buffer's language servers, and calls back with their
--- results, or with an error if none could answer it.
---@param bufnr integer
---@param method string
---@param params fun(client: vim.lsp.Client): table
---@param callback fun(err?: string, results?: { client: vim.lsp.Client, result: any }[])
local request = function(bufnr, method, params, callback)
  with_clients(bufnr, method, function(clients)
    if #clients == 0 then
      return callback(
        ("no language server of %s supports %s"):format(
          vim.api.nvim_buf_get_name(bufnr),
          method
        )
      )
    end
    local results, remaining, finished = {}, #clients, false
    local finish = function()
      if finished then return end
      finished = true
      callback(nil, results)
    end
    vim.defer_fn(finish, request_timeout_ms)
    for _, client in ipairs(clients) do
      local lsp_method = method --[[@as vim.lsp.protocol.Method.ClientToServer.Request]]
      client:request(lsp_method, params(client), function(err, result)
        if not err and result ~= nil and result ~= vim.NIL then
          results[#results + 1] = { client = client, result = result }
        end
        remaining = remaining - 1
        if remaining == 0 then finish() end
      end, bufnr)
    end
  end)
end

--- Returns the position of a symbol on a buffer's line, for a language
--- server.
---@param bufnr integer
---@param line integer The 1-based line.
---@param symbol? string
---@return (fun(client: vim.lsp.Client): table)? params
---@return string? err
local position_params = function(bufnr, line, symbol)
  local text = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, false)[1]
  if not text then
    return nil,
      ("line %d is past the end of %s"):format(
        line,
        vim.api.nvim_buf_get_name(bufnr)
      )
  end
  local col
  if symbol and symbol ~= "" then
    local at = text:find(symbol, 1, true)
    if not at then
      return nil,
        ("`%s` isn't on line %d, which is:\n%s"):format(symbol, line, text)
    end
    col = at - 1
  else
    col = (text:find("%S") or 1) - 1
  end
  return function(client)
    return {
      textDocument = { uri = vim.uri.from_buf(bufnr) },
      position = {
        line = line - 1,
        character = vim.str_utfindex(text, client.offset_encoding, col, false),
      },
    }
  end
end

--- Returns a line of a file, preferably from its loaded buffer.
---@param path string
---@param line integer The 1-based line.
---@return string
local line_of = function(path, line)
  local lines = lines_of(path)
  return lines and lines[line] and vim.trim(lines[line]) or ""
end

---@param location table An LSP Location or LocationLink.
---@return string path
---@return integer line The 1-based line.
local location_of = function(location)
  local uri = location.uri or location.targetUri
  local range = location.targetSelectionRange
    or location.range
    or location.targetRange
  return vim.uri.to_fname(uri), range.start.line + 1
end

--- Returns the lines listing locations, each with the line it's on.
---@param results { result: any }[]
---@return string
local list_locations = function(results)
  local seen, lines = {}, {}
  for _, entry in ipairs(results) do
    local result = entry.result
    local locations = vim.islist(result) and result or { result }
    for _, location in ipairs(locations) do
      local path, line = location_of(location)
      local key = path .. ":" .. line
      if not seen[key] and #lines < max_items then
        seen[key] = true
        lines[#lines + 1] = ("%s:%d: %s"):format(
          path,
          line,
          line_of(path, line)
        )
      end
    end
  end
  if #lines == 0 then return "No locations found" end
  return table.concat(lines, "\n")
end

--- Runs a request on the position of a symbol in a file.
---@param args table
---@param cwd string
---@param method string
---@param params_of fun(position: table): table
---@param callback fun(err?: string, results?: { client: vim.lsp.Client, result: any }[])
local position_request = function(args, cwd, method, params_of, callback)
  local path = resolve(args.path, cwd)
  local line = tonumber(args.line)
  line = line and math.floor(line)
  if not path or not line then
    return callback("`path` and `line` are required")
  end
  local bufnr = load_buffer(path)
  if not bufnr then return callback(("%s doesn't exist"):format(path)) end
  local params, err = position_params(bufnr, line, args.symbol)
  if not params then return callback(err) end
  request(
    bufnr,
    method,
    function(client) return params_of(params(client)) end,
    callback
  )
end

---@param method string
---@param extra? table
---@return nvim_agents.mcp.Run
local locations_tool = function(method, extra)
  return function(args, cwd, callback)
    position_request(
      args,
      cwd,
      method,
      function(position) return vim.tbl_extend("force", position, extra or {}) end,
      function(err, results)
        if err then
          callback(failure(err))
          return
        end
        callback({ text = list_locations(results or {}) })
      end
    )
  end
end

---@type nvim_agents.mcp.Run
local hover = function(args, cwd, callback)
  position_request(
    args,
    cwd,
    "textDocument/hover",
    function(position) return position end,
    function(err, results)
      if err then
        callback(failure(err))
        return
      end
      local parts = {}
      for _, entry in ipairs(results or {}) do
        local contents = entry.result.contents
        if contents then
          local lines = vim.lsp.util.convert_input_to_markdown_lines(contents)
          parts[#parts + 1] = vim.trim(table.concat(lines, "\n"))
        end
      end
      callback({
        text = #parts > 0 and table.concat(parts, "\n\n") or "No information",
      })
    end
  )
end

---@type table<integer, string?>
local severities = { "error", "warning", "info", "hint" }

---@param bufnr? integer
---@return string
local list_diagnostics = function(bufnr)
  local diagnostics = vim.diagnostic.get(bufnr)
  table.sort(diagnostics, function(a, b)
    if a.severity ~= b.severity then return a.severity < b.severity end
    if a.bufnr ~= b.bufnr then return a.bufnr < b.bufnr end
    return a.lnum < b.lnum
  end)
  local lines = {}
  for _, diagnostic in ipairs(diagnostics) do
    if #lines >= max_items then break end
    lines[#lines + 1] = ("%s:%d:%d: %s: %s%s"):format(
      vim.api.nvim_buf_get_name(diagnostic.bufnr),
      diagnostic.lnum + 1,
      diagnostic.col + 1,
      severities[diagnostic.severity] or "unknown",
      diagnostic.message,
      diagnostic.source and (" [%s]"):format(diagnostic.source) or ""
    )
  end
  if #lines == 0 then return "No diagnostics" end
  return table.concat(lines, "\n")
end

---@type nvim_agents.mcp.Run
local diagnostics = function(args, cwd, callback)
  if args.path == nil then return callback({ text = list_diagnostics() }) end
  local path = resolve(args.path, cwd)
  if not path then return callback(failure("`path` is empty")) end
  local bufnr, loaded = load_buffer(path)
  if not bufnr then
    return callback(failure(("%s doesn't exist"):format(path)))
  end
  if not loaded then return callback({ text = list_diagnostics(bufnr) }) end

  -- A buffer just loaded has no diagnostics until its servers publish them.
  local finished = false
  local finish = function()
    if finished then return end
    finished = true
    callback({ text = list_diagnostics(bufnr) })
  end
  vim.api.nvim_create_autocmd("DiagnosticChanged", {
    buffer = bufnr,
    once = true,
    callback = function() vim.schedule(finish) end,
  })
  vim.defer_fn(finish, diagnostics_timeout_ms)
end

---@type nvim_agents.mcp.Run
local workspace_symbols = function(args, cwd, callback)
  local path = resolve(args.path, cwd)
  if not path or type(args.query) ~= "string" then
    return callback(failure("`query` and `path` are required"))
  end
  local bufnr = load_buffer(path)
  if not bufnr then
    return callback(failure(("%s doesn't exist"):format(path)))
  end
  request(
    bufnr,
    "workspace/symbol",
    function() return { query = args.query } end,
    function(err, results)
      if err then
        callback(failure(err))
        return
      end
      local lines = {}
      for _, entry in ipairs(results or {}) do
        for _, symbol in ipairs(entry.result) do
          if #lines >= max_items then break end
          local location = symbol.location or {}
          local symbol_path = location.uri and vim.uri.to_fname(location.uri)
            or "?"
          local line = location.range and location.range.start.line + 1
          lines[#lines + 1] = ("%s (%s) %s%s"):format(
            symbol.name,
            vim.lsp.protocol.SymbolKind[symbol.kind] or "?",
            symbol_path,
            line and (":%d"):format(line) or ""
          )
        end
      end
      callback({
        text = #lines > 0 and table.concat(lines, "\n") or "No symbols found",
      })
    end
  )
end

local path_property = {
  type = "string",
  description = "The file's absolute path, or its path relative to your working directory",
}

local position_schema = {
  type = "object",
  properties = {
    path = path_property,
    line = { type = "integer", description = "The 1-based line" },
    symbol = {
      type = "string",
      description = "The symbol on the line, whose first occurrence is the position. Without it, the position is the line's first non-blank character",
    },
  },
  required = { "path", "line" },
}

---@type nvim_agents.mcp.Tool[]
M.tools = {
  {
    name = "read",
    description = "Reads a file, with its buffer's unsaved changes if it's open in the editor. Lines are numbered from 1, like `cat -n`.",
    input_schema = {
      type = "object",
      properties = {
        path = path_property,
        offset = { type = "integer", description = "The first line read" },
        limit = { type = "integer", description = "The number of lines read" },
      },
      required = { "path" },
    },
    run = read,
  },
  {
    name = "edit",
    description = "Replaces text in a file. If it's open in the editor, the edit goes into its buffer, keeping the user's unsaved changes, and the buffer is saved unless it had unsaved changes before. `old_text` must occur exactly once, unless `replace_all` is set.",
    input_schema = {
      type = "object",
      properties = {
        path = path_property,
        old_text = { type = "string", description = "The text replaced" },
        new_text = { type = "string", description = "The text replacing it" },
        replace_all = {
          type = "boolean",
          description = "Whether to replace every occurrence of `old_text`",
        },
      },
      required = { "path", "old_text", "new_text" },
    },
    run = edit,
  },
  {
    name = "lsp_definition",
    description = "Lists the definitions of the symbol at a position, each with its line.",
    input_schema = position_schema,
    run = locations_tool("textDocument/definition"),
  },
  {
    name = "lsp_type_definition",
    description = "Lists the definitions of the type of the symbol at a position, each with its line.",
    input_schema = position_schema,
    run = locations_tool("textDocument/typeDefinition"),
  },
  {
    name = "lsp_implementation",
    description = "Lists the implementations of the symbol at a position, e.g. of a trait or an interface method, each with its line.",
    input_schema = position_schema,
    run = locations_tool("textDocument/implementation"),
  },
  {
    name = "lsp_references",
    description = "Lists the references to the symbol at a position, including its declaration, each with its line.",
    input_schema = position_schema,
    run = locations_tool(
      "textDocument/references",
      { context = { includeDeclaration = true } }
    ),
  },
  {
    name = "lsp_hover",
    description = "Returns the language server's information on the symbol at a position: its type, signature and documentation.",
    input_schema = position_schema,
    run = hover,
  },
  {
    name = "lsp_diagnostics",
    description = "Lists the diagnostics of a file, or of every file open in the editor without a path, most severe first.",
    input_schema = {
      type = "object",
      properties = { path = path_property },
    },
    run = diagnostics,
  },
  {
    name = "lsp_workspace_symbols",
    description = "Searches the symbols of the workspace of the language servers of a file.",
    input_schema = {
      type = "object",
      properties = {
        query = {
          type = "string",
          description = "The symbol's name, or part of it",
        },
        path = path_property,
      },
      required = { "query", "path" },
    },
    run = workspace_symbols,
  },
}

--- Runs a tool, and calls back with its result.
---@param name string
---@param args table
---@param cwd string The agent's working directory.
---@param callback fun(result: nvim_agents.mcp.Result)
M.run = function(name, args, cwd, callback)
  local tool = vim
    .iter(M.tools)
    :find(function(tool) return tool.name == name end)
  if not tool then
    return callback(failure(("No tool named %s"):format(name)))
  end
  local ok, err = pcall(tool.run, args or {}, cwd, callback)
  if not ok then callback(failure(tostring(err))) end
end

--- Returns whether a file is loaded in a buffer, and whether the buffer has
--- unsaved changes.
---@param path string An absolute path.
---@return "modified"|"loaded"|nil
M.file_state = function(path)
  local bufnr = loaded_buffer(canonical(path))
  if not bufnr then return end
  return vim.bo[bufnr].modified and "modified" or "loaded"
end

--- Returns the tools' descriptions, for the MCP server to list.
---@return table
M.list = function()
  return {
    instructions = M.instructions,
    tools = vim.tbl_map(
      function(tool)
        return {
          name = tool.name,
          description = tool.description,
          inputSchema = tool.input_schema,
        }
      end,
      M.tools
    ),
  }
end

--- Runs a tool for the MCP server on a channel, and sends it the result.
---@param channel integer
---@param id integer
---@param name string
---@param args table
---@param cwd string
M.call = function(channel, id, name, args, cwd)
  vim.schedule(function()
    M.run(
      name,
      args,
      cwd,
      function(result)
        vim.rpcnotify(
          channel,
          "nvim_exec_lua",
          "return _G.nvim_agents_mcp_deliver(...)",
          { id, result }
        )
      end
    )
  end)
end

return M

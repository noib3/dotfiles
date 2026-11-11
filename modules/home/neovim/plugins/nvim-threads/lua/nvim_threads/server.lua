local M = {}

--- The kind of the completion items of participants.
local participant_kind = vim.lsp.protocol.CompletionItemKind.Variable

---@param uri string
---@return integer?
local buffer_of_uri = function(uri)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.uri.from_buf(bufnr) == uri then return bufnr end
  end
end

--- Returns the completion items of the participants matching the mention
--- before the cursor, replacing what's typed of it.
---@param bufnr integer
---@param position lsp.Position
---@param participants fun(bufnr: integer): nvim_threads.Mention[]
---@return lsp.CompletionItem[]
local complete = function(bufnr, position, participants)
  local line = vim.api.nvim_buf_get_lines(
    bufnr,
    position.line,
    position.line + 1,
    false
  )[1] or ""
  -- The client's positions are in UTF-16 code units.
  local col = vim.str_byteindex(line, "utf-16", position.character, false)
  local before = line:sub(1, col)
  local typed = before:match("@([%w_.-]*)$")
  if not typed then return {} end

  local start = vim.str_utfindex(line, "utf-16", col - #typed, false)
  local items = {}
  for _, mention in ipairs(participants(bufnr)) do
    items[#items + 1] = {
      label = mention.name,
      kind = participant_kind,
      detail = mention.detail,
      filterText = mention.name,
      textEdit = {
        range = {
          start = { line = position.line, character = start },
          ["end"] = position,
        },
        newText = mention.name,
      },
    }
  end
  return items
end

---@class nvim_threads.server.Opts
--- Returns the mentions completed after `@` in a float's buffer.
---@field participants fun(bufnr: integer): nvim_threads.Mention[]
--- Returns the commands of the code actions on a 1-based line of a float's
--- buffer.
---@field code_actions fun(bufnr: integer, line: integer): lsp.Command[]
--- Runs a code action's command on a float's buffer.
---@field execute fun(bufnr: integer, command: string, arguments: any[])
---@field commands string[] The names of the code actions' commands.

--- Returns the in-process language server of the threads' floats, which
--- completes the participants after `@`, and offers the registered actions
--- as code actions.
---@param opts nvim_threads.server.Opts
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.Client
M.server = function(opts)
  local participants = opts.participants
  return function(dispatchers)
    local closing, request_id = false, 0

    ---@param method string
    ---@param params table
    ---@return any result
    ---@return lsp.ResponseError? err
    local handle = function(method, params)
      if method == "initialize" then
        return {
          capabilities = {
            completionProvider = { triggerCharacters = { "@" } },
            codeActionProvider = true,
            executeCommandProvider = { commands = opts.commands },
            textDocumentSync = 0,
          },
          serverInfo = { name = "nvim-threads" },
        }
      elseif method == "shutdown" then
        return vim.NIL
      elseif method == "textDocument/completion" then
        local bufnr = buffer_of_uri(params.textDocument.uri)
        if not bufnr or not vim.api.nvim_buf_is_loaded(bufnr) then return {} end
        return {
          isIncomplete = false,
          items = complete(bufnr, params.position, participants),
        }
      elseif method == "textDocument/codeAction" then
        local uri = params.textDocument.uri
        local bufnr = buffer_of_uri(uri)
        if not bufnr then return {} end
        local line = params.range.start.line + 1
        return vim.tbl_map(function(command)
          -- The buffer's URI comes first, so the command knows its float.
          command.arguments = vim.list_extend({ uri }, command.arguments or {})
          return { title = command.title, command = command }
        end, opts.code_actions(bufnr, line))
      elseif method == "workspace/executeCommand" then
        local args = params.arguments or {}
        local bufnr = buffer_of_uri(args[1])
        if bufnr then
          opts.execute(bufnr, params.command, vim.list_slice(args, 2))
        end
        return vim.NIL
      end
      return nil, { code = -32601, message = "Method not found: " .. method }
    end

    local client = {
      request = function(method, params, callback, notify_reply_callback)
        request_id = request_id + 1
        local id = request_id
        vim.schedule(function()
          local result, err = handle(method, params)
          callback(err, result)
          if notify_reply_callback then notify_reply_callback(id) end
        end)
        return true, id
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
    -- The client's private fields are the ones of a process it talks to.
    return client --[[@as vim.lsp.rpc.Client]]
  end
end

return M

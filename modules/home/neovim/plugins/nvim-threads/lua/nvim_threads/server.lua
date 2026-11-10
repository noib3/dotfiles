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
---@param participants fun(bufnr: integer): string[]
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
  for _, name in ipairs(participants(bufnr)) do
    items[#items + 1] = {
      label = name,
      kind = participant_kind,
      detail = "Participant",
      filterText = name,
      textEdit = {
        range = {
          start = { line = position.line, character = start },
          ["end"] = position,
        },
        newText = name,
      },
    }
  end
  return items
end

--- Returns the in-process language server of the threads' floats, which
--- completes the participants after `@`.
---@param participants fun(bufnr: integer): string[] The names of the participants of a float's buffer.
---@return fun(dispatchers: vim.lsp.rpc.Dispatchers): vim.lsp.rpc.Client
M.server = function(participants)
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

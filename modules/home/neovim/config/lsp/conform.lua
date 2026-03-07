local conform = require("conform")

local methods = vim.lsp.protocol.Methods

local handlers = {}

handlers[methods.initialize] = function(_, callback)
  callback(nil, {
    capabilities = {
      documentFormattingProvider = true,
    },
  })
end

handlers[methods.shutdown] = function(_, callback) callback(nil, nil) end

handlers[methods.textDocument_formatting] = function(params, callback)
  local uri = params and params.textDocument and params.textDocument.uri
  local bufnr = uri and vim.uri_to_bufnr(uri) or vim.api.nvim_get_current_buf()
  conform.format({
    bufnr = bufnr,
    lsp_format = "never",
    quiet = true,
  })
  callback(nil, {})
end

--- Returns the filetypes the conform LSP client should attach to, or `nil` if
--- it should attach to all filetypes.
---@return string[]|nil
local conform_filetypes = function()
  local has_global_formatter = conform.formatters_by_ft["*"] ~= nil
    or conform.formatters_by_ft["_"] ~= nil

  if has_global_formatter then return nil end

  return vim
    .iter(vim.tbl_keys(conform.formatters_by_ft))
    :filter(function(filetype) return filetype ~= "*" and filetype ~= "_" end)
    :totable()
end

---@type vim.lsp.Config
return {
  filetypes = conform_filetypes(),
  cmd = function()
    local next_request_id = 0

    ---@type vim.lsp.rpc.PublicClient
    return {
      request = function(method, params, callback, notify_reply_callback)
        local request_id = next_request_id
        next_request_id = next_request_id + 1
        if handlers[method] then handlers[method](params, callback) end
        if notify_reply_callback then notify_reply_callback(request_id) end
        return true, request_id
      end,
      notify = function() return true end,
      is_closing = function() return false end,
      terminate = function() end,
    }
  end,
}

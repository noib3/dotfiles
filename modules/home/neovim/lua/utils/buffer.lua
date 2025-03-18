local methods = vim.lsp.protocol.Methods

local M = {}

---@class BufferSaveOptions
---@field bufnr? number Buffer number to save (defaults to current buffer)

local check_modified_augroup_id = vim.api.nvim_create_augroup(
  "noib3/check_if_buffer_was_modified_since_formatting_request",
  { clear = true }
)

---Save a buffer, optionally formatting it via LSP first.
---@param opts? BufferSaveOptions
M.save = function(opts)
  opts = opts or {}
  local bufnr = opts.bufnr or vim.api.nvim_get_current_buf()

  local save_buf = function()
    vim.api.nvim_buf_call(bufnr, function() vim.cmd("silent write") end)
  end

  -- Find first LSP client that supports formatting.
  local formatting_client

  local clients = vim.lsp.get_clients({
    bufnr = bufnr,
  })

  for _, client in ipairs(clients) do
    if client.supports_method(methods.textDocument_formatting) then
      formatting_client = client
      break
    end
  end

  -- If there's no formatter available, just save.
  if not formatting_client then
    save_buf()
    return
  end

  local buffer_was_modified = false

  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" },
    {
      group = check_modified_augroup_id,
      buffer = bufnr,
      callback = function() buffer_was_modified = true end,
      once = true,
    })

  local offset_encoding = formatting_client.offset_encoding

  -- Request formatting.
  local did_send_request = formatting_client.request(
    "textDocument/formatting",
    vim.api.nvim_buf_call(bufnr, vim.lsp.util.make_formatting_params),
    function(_, result, _)
      -- Server was too slow.
      if buffer_was_modified then
        return
      end

      if result then
        vim.lsp.util.apply_text_edits(result, bufnr, offset_encoding)
      end

      save_buf()
    end,
    bufnr
  )

  if not did_send_request then
    save_buf()
  end
end

return M

---@type vim.lsp.Config
return {
  -- Lua files are formatted with stylua via conform, so don't let this server
  -- handle formatting requests.
  on_init = function(client)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
}

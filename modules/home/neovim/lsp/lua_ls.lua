---@type vim.lsp.Config
return {
  settings = {
    Lua = {
      completion = {
        callSnippet = "Disable",
        keywordSnippet = "Disable",
      },
      format = {
        enable = false,
      },
      telemetry = {
        enable = false,
      },
    },
  },
}

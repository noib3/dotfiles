---@type vim.lsp.Config
return {
  settings = {
    ["rust-analyzer"] = {
      cargo = {
        features = "all",
      },
      check = {
        command = "clippy",
      },
      completion = {
        callable = {
          snippets = "add_parentheses",
        },
      },
      imports = {
        granularity = {
          enforce = true,
          group = "module",
        },
        merge = {
          glob = false,
        },
        preferNoStd = true,
      },
      procMacro = {
        enable = true,
      },
    },
  },
}

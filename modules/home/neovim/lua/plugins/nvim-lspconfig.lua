return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "Saghen/blink.cmp" },
    opts = {
      servers = {
        marksman = {},
        rust_analyzer = {
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
        },
        taplo = {},
        ts_ls = {},
      },
    },
    config = function(_, opts)
      local blink = require("blink.cmp")

      vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })

      for server_name, config in pairs(opts.servers) do
        vim.lsp.config(server_name, config)
        vim.lsp.enable(server_name)
      end
    end,
  },
}

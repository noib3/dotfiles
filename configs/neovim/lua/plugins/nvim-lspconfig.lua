return {
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      local capabilities = vim.tbl_deep_extend(
        "force",
        vim.lsp.protocol.make_client_capabilities(),
        require("cmp_nvim_lsp").default_capabilities()
      )

      -- Lua.
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { "vim" },
              neededFileStatus = {
                ["codestyle-check"] = "Any",
              },
            },
            -- https://github.com/LuaLS/lua-language-server/wiki/Formatter#lua
            format = {
              enable = true,
              defaultConfig = {
                indent_style = "space",
                indent_size = "2",
              },
            },
            runtime = {
              version = "LuaJIT",
            },
            telemetry = {
              enable = false,
            },
          },
        },
      })

      -- Markdown.
      lspconfig.marksman.setup({
        capabilities = capabilities,
      })

      -- Nix.
      lspconfig.nil_ls.setup({
        capabilities = capabilities,
        settings = {
          ["nil"] = {
            formatting = {
              command = { "nixfmt" },
            },
          }
        }
      })

      -- Rust.
      lspconfig.rust_analyzer.setup({
        capabilities = capabilities,
        settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
            },
            completion = {
              limit = 69,
              privateEditable = {
                enable = true,
              },
            },
            imports = {
              merge = {
                blob = false,
              },
            },
            procMacro = {
              enable = true,
            },
          },
        },
      })

      -- Typescript.
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
      })
    end,
  }
}

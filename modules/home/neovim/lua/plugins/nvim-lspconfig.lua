return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "Saghen/blink.cmp" },
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = {
                disable = {
                  ["undefined-field"] = { "vim.uv" },
                },
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
                  quote_style = "double",
                  max_line_length = "79",
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
        },
        marksman = {},
        nil_ls = {
          settings = {
            ["nil"] = {
              formatting = {
                command = { "nixfmt", "--width", "79" },
              },
            }
          }
        },
        rust_analyzer = {
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
      local lspconfig = require("lspconfig")
      local blink = require("blink.cmp")
      for server, config in pairs(opts.servers) do
        config.capabilities = blink.get_lsp_capabilities(config.capabilities)
        lspconfig[server].setup(config)
      end
    end,
  }
}

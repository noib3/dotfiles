return {
  {
    "neovim/nvim-lspconfig",
    dependencies = { "Saghen/blink.cmp" },
    opts = {
      servers = {
        -- Wait to load lua_ls until after all the plugins have been loaded and
        -- their paths have been added to the runtimepath (or
        -- 'nvim_get_runtime_file' won't return the full list).
        lua_ls = function(setup_lsp)
          local config = function()
            return {
              settings = {
                Lua = {
                  diagnostics = {
                    disable = {
                      ["redefined-local"] = true,
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
                  workspace = {
                    ignoreDir = { ".git", "node_modules", "target", },
                    library = vim.api.nvim_get_runtime_file("", true),
                  },
                },
              },
            }
          end
          vim.api.nvim_create_autocmd("User", {
            pattern = "LazyDone",
            once = true,
            callback = function()
              setup_lsp(config())
            end
          })
        end,
        marksman = {},
        nixd = {
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
              cargo = {
                features = "all",
              },
              check = {
                overrideCommand = {
                  "cargo",
                  "clippy",
                  "--all-features",
                  "--all-targets",
                  "--no-deps",
                  "--workspace",
                  "--message-format=json",
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

      local setup_lsp = function(server_name)
        return function(config)
          config.capabilities = blink.get_lsp_capabilities(config.capabilities)
          vim.lsp.enable(server_name)
          vim.lsp.config(server_name, config)
        end
      end

      for server_name, config in pairs(opts.servers) do
        if type(config) == "table" then
          setup_lsp(server_name)(config)
        elseif type(config) == "function" then
          config(setup_lsp(server_name))
        end
      end
    end,
  }
}

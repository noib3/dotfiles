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

      -- https://github.com/sumneko/lua-language-server
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

      -- rustaceanvim will complain if this is enabled because it uses its own
      -- rust-analyzer setup.
      --
      -- TODO: replace rustaceanvim with something that respects your config.
      --
      -- -- https://github.com/rust-lang/rust-analyzer
      -- lspconfig.rust_analyzer.setup({
      --   capabilities = capabilities,
      --   cmd = { "rustup", "run", "nightly", "rust-analyzer" },
      --   settings = {
      --     ["rust-analyzer"] = {
      --       check = {
      --         command = "clippy",
      --       },
      --       completion = {
      --         limit = 69,
      --         privateEditable = {
      --           enable = true,
      --         },
      --       },
      --       imports = {
      --         merge = {
      --           blob = false,
      --         },
      --       },
      --       procMacro = {
      --         enable = true,
      --       },
      --     },
      --   },
      -- })
    end,
  }
}

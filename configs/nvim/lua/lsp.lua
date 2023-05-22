local has_lspconfig, lspconfig = pcall(require, "lspconfig")

if not has_lspconfig then
  return
end

local has_cmp, cmp = pcall(require, "cmp_nvim_lsp")

local capabilities =
    has_cmp
    and cmp.default_capabilities()
    or vim.lsp.protocol.make_client_capabilities()

local lsp_group = vim.api.nvim_create_augroup("Lsp", {})

vim.api.nvim_create_autocmd(
  "BufWritePre",
  {
    group = lsp_group,
    desc = "Formats the buffer before it gets saved to disk",
    callback = function()
      vim.lsp.buf.format({ timeout_ms = 1000 })
    end,
  }
)

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

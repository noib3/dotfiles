local has_lspconfig, lspconfig = pcall(require, "lspconfig")

-- If `https://github.com/neovim/nvim-lspconfig` is not available we return
-- early.
if not has_lspconfig then
  return
end

local api = vim.api
local keymap = vim.keymap
local lsp = vim.lsp

local has_cmp, cmp = pcall(require, "cmp_nvim_lsp")

local capabilities =
    has_cmp
    and cmp.default_capabilities()
    or vim.lsp.protocol.make_client_capabilities()

local lsp_group = vim.api.nvim_create_augroup("Lsp", {})

local on_attach = function(_ --[[ client ]], bufnr)
  local opts = { buffer = bufnr }

  -- Display infos about the symbol under the cursor in a floating window.
  keymap.set("n", "K", lsp.buf.hover, opts)

  -- Rename the symbol under the cursor.
  keymap.set("n", "grn", lsp.buf.rename, opts)

  -- Selects a code action available at the current cursor position.
  keymap.set("n", "gca", lsp.buf.code_action, opts)

  -- Jumps to the definition of the symbol under the cursor.
  keymap.set("n", "gd", lsp.buf.definition, opts)

  -- Jumps to the definition of the type of the symbol under the cursor.
  keymap.set("n", "gtd", lsp.buf.type_definition, opts)

  -- Format buffer on save w/ a 1s timeout.
  api.nvim_create_autocmd(
    "BufWritePre",
    {
      group = lsp_group,
      buffer = bufnr,
      desc = "Formats the buffer before saving it to disk",
      callback = function() lsp.buf.format({}, 1000) end,
    }
  )
end

-- Lua -> https://github.com/sumneko/lua-language-server
lspconfig.lua_ls.setup({
  capabilities = capabilities,
  on_attach = on_attach,
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

-- Rust -> https://github.com/rust-lang/rust-analyzer
lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  cmd = { "rustup", "run", "nightly", "rust-analyzer" },
  on_attach = on_attach,
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

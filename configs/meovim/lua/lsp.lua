local has_lspconfig, lspconfig = pcall(require, "lspconfig")

-- If `https://github.com/neovim/nvim-lspconfig` is not available we return
-- early.
if not has_lspconfig then
  return
end

local api = vim.api
local keymap = vim.keymap
local lsp = vim.lsp

local lsp_augroup_id = api.nvim_create_augroup("Lsp", {})

local on_attach = function(_ --[[ client ]] , bufnr)
  local opts = { buffer = bufnr }

  -- Display infos about the symbol under the cursor in a floating window.
  keymap.set("n", "K", lsp.buf.hover, opts)

  -- Rename the symbol under the cursor.
  keymap.set("n", "rn", lsp.buf.rename, opts)

  -- Formats the visually selected range.
  keymap.set("v", "rf", lsp.buf.range_formatting, opts)

  -- Selects a code action available at the current cursor position.
  keymap.set("n", "ca", lsp.buf.code_action, opts)

  -- Jumps to the definition of the symbol under the cursor.
  keymap.set("n", "gd", lsp.buf.definition, opts)

  -- Jumps to the definition of the type of the symbol under the cursor.
  keymap.set("n", "gtd", lsp.buf.type_definition, opts)

  -- Queries the code actions for the given range.
  keymap.set("v", "rca", lsp.buf.range_code_action, opts)

  -- Format buffer on save w/ a 1s timeout.
  api.nvim_create_autocmd(
    "BufWritePre",
    {
      group = lsp_augroup_id,
      buffer = bufnr,
      desc = "Formats the buffer before saving it to disk",
      callback = function() lsp.buf.formatting_sync({}, 1000) end,
    }
  )
end

-- Lua -> https://github.com/sumneko/lua-language-server
local rtp = vim.split(package.path, ";")
table.insert(rtp, "lua/?.lua")
table.insert(rtp, "lua/?/init.lua")

lspconfig.sumneko_lua.setup({
  on_attach = on_attach,
  settings = {
    ["Lua"] = {
      runtime = {
        version = "LuaJIT",
        path = rtp,
      },
      diagnostics = {
        globals = { "vim" }
      },
      workspace = {
        library = api.nvim_get_runtime_file("", true),
      },
      telemetry = {
        enable = false,
      },
    },
  }
})

-- Nix -> https://github.com/nix-community/rnix-lsp
lspconfig.rnix.setup({
  on_attach = on_attach,
})

-- Python -> https://github.com/microsoft/pyright
lspconfig.pyright.setup({
  on_attach = on_attach,
})

-- Rust -> https://github.com/rust-lang/rust-analyzer
lspconfig.rust_analyzer.setup({
  on_attach = on_attach,
  settings = {
    ["rust-analyzer"] = {
      -- checkOnSave = { command = "clippy" },
      procMacro = { enable = true },
    }
  }
})

-- Swift -> https://github.com/apple/sourcekit-lsp
lspconfig.sourcekit.setup({
  on_attach = on_attach,
  filetypes = { "swift" },
})

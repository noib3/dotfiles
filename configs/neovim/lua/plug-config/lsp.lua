local lspconfig = require("lspconfig")
local has_compleet, compleet = pcall(require, "compleet")

local capabilities =
has_compleet
    and compleet.lsp_client_capabilities()
    or vim.lsp.protocol.make_client_capabilities()

local fn = vim.fn
local keymap = vim.keymap

local on_attach = function(_, bufnr)
  keymap.set(
    "n",
    "K",
    vim.lsp.buf.hover,
    { buffer = bufnr, silent = true }
  )

  keymap.set(
    "n",
    "<Leader>rn",
    vim.lsp.buf.rename,
    { buffer = bufnr, silent = true }
  )

  vim.cmd([[
    autocmd BufWritePre <buffer> lua vim.lsp.buf.formatting_sync()
  ]])
end

local setup = function()
  -- C
  lspconfig.clangd.setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- Dart
  local dartls_snapshot_path = string.format(
    "%s/snapshots/analysis_server.dart.snapshot",
    fn.trim(fn.system("dirname (readlink -f (which dart))"))
  )

  lspconfig.dartls.setup({
    capabilities = capabilities,
    cmd = { "dart", dartls_snapshot_path, "--lsp" },
    on_attach = on_attach,
  })

  -- Lua
  local runtime_path = vim.split(package.path, ";")
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")

  lspconfig.sumneko_lua.setup({
    on_attach = on_attach,
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = runtime_path,
        },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        telemetry = { enable = false },
      },
    },
  })

  -- Nix
  lspconfig.rnix.setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- Python
  lspconfig.jedi_language_server.setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- Rust
  lspconfig.rust_analyzer.setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- Svelte
  lspconfig.svelte.setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })

  -- Typescript
  lspconfig.tsserver.setup({
    capabilities = capabilities,
    on_attach = on_attach,
  })
end

return {
  setup = setup,
}

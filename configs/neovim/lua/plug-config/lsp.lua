local lspconfig = require("lspconfig")
local sumneko_paths = require("plug-config/lsp-sumneko-paths")

local on_attach = function(_, bufnr)
  vim.keymap.set(
    "n",
    "K",
    vim.lsp.buf.hover,
    { buffer = bufnr, silent = true }
  )

  vim.keymap.set(
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
  -- Lua
  -- Why is this language server so damn complicated to configure compared to
  -- all the others? Will have to make my own lua language server one day.
  local sumneko_rtp = vim.split(package.path, ";")
  table.insert(sumneko_rtp, "lua/?.lua")
  table.insert(sumneko_rtp, "lua/?/init.lua")
  lspconfig.sumneko_lua.setup({
    cmd = { sumneko_paths.bin, "-E", sumneko_paths.main },
    on_attach = on_attach,
    settings = {
      Lua = {
        runtime = {
          version = "LuaJIT",
          path = sumneko_rtp,
        },
        diagnostics = { globals = { "vim" } },
        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
        telemetry = { enable = false },
      },
    },
  })

  -- Nix
  lspconfig.rnix.setup({
    on_attach = on_attach,
  })

  -- Python
  lspconfig.jedi_language_server.setup({
    on_attach = on_attach,
  })

  -- Rust
  lspconfig.rust_analyzer.setup({
    on_attach = on_attach,
  })
end

return {
  setup = setup,
}

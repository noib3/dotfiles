local rq_coq = require('coq')
local rq_lspconfig = require('lspconfig')
local rq_sumneko_paths = require('plug-config/lsp-sumneko-paths')

local tbl_insert = table.insert

local on_attach = function(client, bufnr)
  _G.localmap({
    bufnr = bufnr,
    modes = 'n',
    lhs = 'K',
    rhs = '<Cmd>lua vim.lsp.buf.hover()<CR>',
    opts = { noremap = true, silent = true },
  })

  _G.localmap({
    bufnr = bufnr,
    modes = 'n',
    lhs = '<Leader>rn',
    rhs = '<Cmd>lua vim.lsp.buf.rename()<CR>',
    opts = { noremap = true, silent = true },
  })

  if client.resolved_capabilities.document_highlight then
    _G.augroup({
      name = 'lsp_highlight_references',
      autocmds = {
        {
          event = 'CursorHold',
          pattern = '<buffer>',
          cmd = 'lua vim.lsp.buf.document_highlight()',
        },
        {
          event = 'CursorMoved',
          pattern = '<buffer>',
          cmd = 'lua vim.lsp.buf.clear_references()',
        },
      }
    })
  end
end

local sumneko_rtp = vim.split(package.path, ';')
tbl_insert(sumneko_rtp, 'lua/?.lua')
tbl_insert(sumneko_rtp, 'lua/?/init.lua')

local lsps = {
  -- name = settings,
  bashls = { on_attach = on_attach },
  jedi_language_server = { on_attach = on_attach },
  kotlin_language_server = { on_attach = on_attach },
  rust_analyzer = { on_attach = on_attach },
  sumneko_lua = {
    cmd = { rq_sumneko_paths.bin, '-E', rq_sumneko_paths.main },
    on_attach = on_attach,
    settings = {
      Lua = {
        runtime = {
          version = 'LuaJIT',
          path = sumneko_rtp,
        },
        diagnostics = { globals = { 'vim' } },
        workspace = { library = vim.api.nvim_get_runtime_file('', true) },
        telemetry = { enable = false },
      },
    },
  },
  vimls = { on_attach = on_attach },
}

local setup = function ()
  for lsp, settings in pairs(lsps) do
    rq_lspconfig[lsp].setup(rq_coq.lsp_ensure_capabilities(settings))
  end
end

return {
  setup = setup,
}

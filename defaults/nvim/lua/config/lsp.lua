local lspconfig = require('lspconfig')
vim.lsp.handlers["textDocument/publishDiagnostics"] = function() end

local custom_lsp_attach = function(client, bufnr)
require('completion').on_attach()

local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

local opts = { noremap=true, silent=true }
buf_set_keymap('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
buf_set_keymap('n', '<Leader>s', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
buf_set_keymap('n', '<Leader>gd', '<Cmd>lua vim.lsp.buf.definition()<CR>', opts)
buf_set_keymap('n', '<Leader>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)

if client.resolved_capabilities.document_formatting then
  vim.api.nvim_exec([[
  augroup lsp_format
    autocmd!
    autocmd BufWritePre * lua vim.lsp.buf.formatting()
  augroup END
  ]], false)
end

if client.resolved_capabilities.document_highlight then
  vim.api.nvim_exec([[
  augroup lsp_highlight
    autocmd!
    autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
    autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
  augroup END
  ]], false)
end
end

local servers = { 'pyls_ms', 'vimls' }
for _, server in ipairs(servers) do
  lspconfig[server].setup { on_attach = custom_lsp_attach }
end

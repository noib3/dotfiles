local lspconfig = require('lspconfig')

local on_attach = function(client, bufnr)
  local buf_opt = function(...) vim.api.nvim_buf_set_option(bufnr, ...) end
  local buf_map = function(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end

  buf_opt('omnifunc', 'v:lua.vim.lsp.omnifunc')

  local opts = {noremap=true, silent=true}
  buf_map('n', 'K', '<Cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_map('n', '<Leader>s', '<Cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_map('n', '<Leader>rn', '<Cmd>lua vim.lsp.buf.rename()<CR>', opts)

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

lspconfig.html.setup {
  on_attach = on_attach,
}

lspconfig.texlab.setup {
  on_attach = on_attach,
}

lspconfig.vimls.setup {
  on_attach = on_attach,
}

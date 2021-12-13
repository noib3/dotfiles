local rq_cmp = require('cmp')
local rq_lspkind = require('lspkind')
local rq_luasnip = require('luasnip')

local vim_fn = vim.fn

rq_lspkind.init()

local feedkey = function(key, mode)
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
end

local tab = function(fallback)
  -- I have no idea how the fuck this works. If
  if rq_cmp.visible() then
    print(vim_fn.complete_info().selected)
    return
      vim_fn.complete_info().selected ~= -1
      and feedkey('<C-y>', '')
       or feedkey('<C-n>', '')
  elseif rq_luasnip.expand_or_jumpable() then
    feedkey('<Plug>luasnip-expand-or-jump', '')
  else
    fallback()
  end
end

rq_cmp.setup({
  snippet = {
    expand = function(args)
      rq_luasnip.lsp_expand(args.body)
    end
  },

  mapping = {
    ['<Tab>'] = rq_cmp.mapping.confirm(),
  },

  sources = rq_cmp.config.sources({
    { name = 'luasnip' },
    { name = 'nvim_lua' },
    { name = 'nvim_lsp' },
    { name = 'path' },
  }),

  formatting = {
    format = rq_lspkind.cmp_format({
      with_text = true,
      menu = {
        nvim_lsp = '[LSP]',
        nvim_lua = '[API]',
        path = '[Path]',
        luasnip = '[Snippets]',
      }
    })
  },

  experimental = {
    ghost_text = true,
  },
})

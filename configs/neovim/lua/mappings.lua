local has_autopairs, autopairs = pcall(require, 'nvim-autopairs')
local has_bufdelete, _ = pcall(require, 'nvim-autopairs')
local has_cokeline, _ = pcall(require, 'cokeline')

local tbl_insert = table.insert

local vim_api = vim.api
local vim_cmd = vim.cmd
local vim_fn = vim.fn
local vim_g = vim.g
local vim_list_extend = vim.list_extend

local mappings = {
  -- Save the file.
  {
    modes = 'n',
    lhs = '<C-s>',
    rhs = '<Cmd>w<CR>',
    opts = { silent = true },
  },

  -- Open a new terminal buffer in a horizontal or vertical split.
  {
    modes = 'n',
    lhs = '<Leader>spt',
    rhs = '<Cmd>sp<Bar>term<CR>',
    opts = { silent = true },
  },
  {
    modes = 'n',
    lhs = '<Leader>vspt',
    rhs = '<Cmd>vsp<Bar>term<CR>',
    opts = { silent = true },
  },

  -- Either closes the window or deletes the current buffer.
  {
    modes = 'n',
    lhs = '<C-w>',
    rhs = '<Cmd>lua require("mappings").close()<CR>',
    opts = { silent = true },
  },

  -- Move between displayed lines instead of physical ones.
  {
    modes = {'n', 'v'},
    lhs = '<Up>',
    rhs = 'g<Up>',
    opts = { noremap = true, silent = true },
  },
  {
    modes = 'i',
    lhs = '<Up>',
    rhs = 'pumvisible() ? "<C-p>" : "<C-o>g<Up>"',
    opts = { expr = true, noremap = true, silent = true },
  },
  {
    modes = {'n', 'v'},
    lhs = '<Down>',
    rhs = 'g<Down>',
    opts = { noremap = true, silent = true },
  },
  {
    modes = 'i',
    lhs = '<Down>',
    rhs = 'pumvisible() ? "<C-n>" : "<C-o>g<Down>"',
    opts = { expr = true, noremap = true, silent = true },
  },

  -- Make `<Tab>`, `<S-Tab>`, `<CR>` and `<Esc>` work nicely with the popup
  -- menu.
  {
    modes = 'i',
    lhs = '<Tab>',
    rhs =
      'pumvisible()'
      .. ' ? (complete_info().selected == -1 ? "\\<C-n>\\<C-y>" : "\\<C-n>")'
      .. ' : "\\<Tab>"',
    opts = { expr = true, noremap = true, silent = true },
  },
  -- {
  --   modes = 'i',
  --   lhs = '<S-Tab>',
  --   rhs = 'pumvisible() ? "<C-p>" : "<BS>"',
  --   opts = { expr = true, noremap = true, silent = true },
  -- },
  {
    modes = 'i',
    lhs = '<CR>',
    rhs =
      'pumvisible()'
      .. ' ? (complete_info().selected == -1 ? "\\<C-e><CR>" : "\\<C-y>")'
      .. ' : "\\<CR>"',
    opts = { expr = true, noremap = true, silent = true },
  },
  -- {
  --   modes = 'i',
  --   lhs = '<Esc>',
  --   rhs = 'pumvisible() ? "<C-e><Esc>" : "<Esc>"',
  --   opts = { expr = true, noremap = true, silent = true },
  -- },

  -- Jump to the first non-whitespace character in the displayed line.
  {
    modes = {'n', 'v'},
    lhs = '<C-a>',
    rhs = 'g^',
  },
  {
    modes = 'i',
    lhs = '<C-a>',
    rhs = '<C-o>g^',
  },

  -- Jump to the end of the displayed line.
  {
    modes = {'n', 'v'},
    lhs = '<C-e>',
    rhs = 'g$',
  },
  {
    modes = 'i',
    lhs = '<C-e>',
    rhs = '<C-o>g$',
  },

  -- Move the screen up or down without moving the cursor.
  {
    modes = 'n',
    lhs = 'J',
    rhs = '1<C-d>',
    opts = { noremap = true },
  },
  {
    modes = 'n',
    lhs = 'K',
    rhs = '1<C-u>',
    opts = { noremap = true },
  },

  -- Toggle code folds.
  {
    modes = 'n',
    lhs = '<Space>',
    rhs = 'za',
  },

  -- Disable the `s` mapping in normal and visual mode.
  {
    modes = {'n', 'v'},
    lhs = 's',
    rhs = ''
  },

  -- Navigate window splits.
  {
    modes = 'n',
    lhs = '<S-Up>',
    rhs = '<C-w>k',
    opts = { noremap = true },
  },
  {
    modes = 'n',
    lhs = '<S-Down>',
    rhs = '<C-w>j',
    opts = { noremap = true },
  },
  {
    modes = 'n',
    lhs = '<S-Left>',
    rhs = '<C-w>h',
    opts = { noremap = true },
  },
  {
    modes = 'n',
    lhs = '<S-Right>',
    rhs = '<C-w>l',
    opts = { noremap = true },
  },

  -- Delete the previous word in insert mode.
  {
    modes = 'i',
    lhs = '<M-BS>',
    rhs = '<C-w>',
    opts = { noremap = true },
  },

  -- Escape terminal mode.
  {
    modes = 't',
    lhs = '<M-Esc>',
    rhs = '<C-\\><C-n>',
    opts = { noremap = true },
  },

  -- Jump to the beginning of the line in command mode.
  {
    modes = 'c',
    lhs = '<C-a>',
    rhs = '<C-b>',
  },

  -- Substitute globally
  {
    modes = 'n',
    lhs = 'ss',
    rhs = ':%s//g<Left><Left>',
  },

  -- Substitute locally.
  {
    modes = 'v',
    lhs = 'ss',
    rhs = ':s//g<Left><Left>',
  },

  -- Stop highlighting the latest search results.
  {
    modes = 'n',
    lhs = '<C-g>',
    rhs = '<Cmd>noh<CR>',
    opts = { silent = true },
  },
}

-- if not has_autopairs then
--   local vim_fn = vim.fn

--   _G.MUtils = {}

--   MUtils.CR = function()
--     return vim_fn.feedkeys("\\<C-y>")
--     -- return
--     --   vim_fn.pumvisible() ~= 0
--     --   and (vim_fn.complete_info().selected == -1
--     --         and autopairs.esc('<C-e>') .. autopairs.autopairs_cr()
--     --          or autopairs.esc('<C-y>'))
--     --    or autopairs.autopairs_cr()
--   end

--   MUtils.BS = function()
--     return
--       vim_fn.pumvisible() ~= 0 and vim_fn.complete_info({'mode'}).mode == 'eval'
--       and autopairs.esc('<C-e>') .. autopairs.autopairs_bs()
--        or autopairs.autopairs_bs()
--   end

--   vim_list_extend(mappings, {
--     {
--       modes = 'i',
--       lhs = '<CR>',
--       rhs = 'v:lua.MUtils.CR()',
--       opts = { expr = true, noremap = true, silent = true },
--     },
--     {
--       modes = 'i',
--       lhs = '<BS>',
--       rhs = 'v:lua.MUtils.BS()',
--       opts = { expr = true, noremap = true, silent = true },
--     },
--   })
-- end

if has_cokeline then
  vim_list_extend(mappings, {
    {
      modes = 'n',
      lhs = '<S-Tab>',
      rhs = '<Plug>(cokeline-focus-prev)',
      opts = { silent = true },
    },
    {
      modes = 'n',
      lhs = '<Tab>',
      rhs = '<Plug>(cokeline-focus-next)',
      opts = { silent = true },
    },
    {
      modes = 'n',
      lhs = '<Leader>p',
      rhs = '<Plug>(cokeline-switch-prev)',
      opts = { silent = true },
    },
    {
      modes = 'n',
      lhs = '<Leader>n',
      rhs = '<Plug>(cokeline-switch-next)',
      opts = { silent = true },
    },
  })

  for i = 1,9 do
    tbl_insert(mappings, {
      modes = 'n',
      lhs = ('<F%s>'):format(i),
      rhs = ('<Plug>(cokeline-focus-%s)'):format(i),
      opts = { silent = true },
    })
  end
end

local close = function()
  local bdelete = has_bufdelete and 'Bdelete' or 'bdelete'
  local filetype, buftype = vim.bo.filetype, vim.bo.buftype
  vim_cmd(
    (filetype == 'startify' and 'bd')
    or (buftype == 'terminal' and ('%s!'):format(bdelete))
    or (#vim_fn.getbufinfo({buflisted = 1}) == 1 and 'q')
    or bdelete
  )
end

local setup = function()
  vim_g.mapleader = ','
  vim_g.maplocalleader = ','
  for _, mapping in ipairs(mappings) do _G.map(mapping) end
end

return {
  close = close,
  setup = setup,
}

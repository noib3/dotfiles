vim.cmd('packadd packer.nvim')

local packer = require('packer')
local configs = {
  ale = function() require('plugins/config/ale') end,
  -- cokeline = function() require('plugins/config/cokeline') end,
  colorizer = function() require('plugins/config/colorizer') end,
  completions = function() require('plugins/config/completions') end,
  delimitmate = function() require('plugins/config/delimitmate') end,
  diffview = function() require('plugins/config/diffview') end,
  feline = function() require('plugins/config/feline') end,
  floaterm = function() require('plugins/config/floaterm') end,
  fzf = function() require('plugins/config/fzf') end,
  gitsigns = function() require('plugins/config/gitsigns') end,
  localvimrc = function() require('plugins/config/localvimrc') end,
  lsp = function() require('plugins/config/lsp') end,
  lspkind = function() require('plugins/config/lspkind') end,
  markdown_preview = function() require('plugins/config/markdown-preview') end,
  rust = function() require('plugins/config/rust') end,
  shade = function() require('plugins/config/shade') end,
  treesitter = function() require('plugins/config/treesitter') end,
  truezen = function() require('plugins/config/truezen') end,
  ultisnips = function() require('plugins/config/ultisnips') end,
  vimtex = function() require('plugins/config/vimtex') end,
  which_key = function() require('plugins/config/which-key') end,
}

return packer.startup(function()
  use {'wbthomason/packer.nvim', opt = true}
  use {'dense-analysis/ale', config = configs.ale}
  -- use {
  --   'akinsho/nvim-bufferline.lua',
  --   requires = {'kyazdani42/nvim-web-devicons'},
  --   config = configs.bufferline,
  -- }
  -- use {
  --   '~/Dropbox/projects/cokeline.nvim',
  --   requires = {'kyazdani42/nvim-web-devicons'},
  --   config = configs.cokeline,
  -- }
  use {'norcalli/nvim-colorizer.lua', config = configs.colorizer}
  use {'nvim-lua/completion-nvim', config = configs.completions}
  use {'Raimondi/delimitMate', config = configs.delimitmate}
  use {'sindrets/diffview.nvim', config = configs.diffview}
  use {
    'famiu/feline.nvim',
    requires = {'kyazdani42/nvim-web-devicons'},
    config = configs.feline,
  }
  use {'voldikss/vim-floaterm', config = configs.floaterm}
  use {'junegunn/fzf', config = configs.fzf}
  use {
    'lewis6991/gitsigns.nvim',
    requires = {'nvim-lua/plenary.nvim'},
    config = configs.gitsigns,
  }
  use {'embear/vim-localvimrc', config = configs.localvimrc}
  use {'neovim/nvim-lspconfig', config = configs.lsp}
  use {'onsails/lspkind-nvim', config = configs.lspkind}
  use {
    'iamcco/markdown-preview.nvim',
    config = configs.markdown_preview,
    run = 'cd app && yarn install',
  }
  use {'rust-lang/rust.vim', config = configs.rust, ft = 'rust'}
  use {'sunjon/Shade.nvim', config = configs.shade}
  use {'nvim-treesitter/nvim-treesitter', config = configs.treesitter}
  use {'Pocco81/TrueZen.nvim', config = configs.truezen}
  -- use {'SirVer/ultisnips', config = configs.ultisnips}
  use {'lervag/vimtex', config = configs.vimtex, ft = 'tex'}
  use {'liuchengxu/vim-which-key', config = configs.which_key}
  use {'qpkorr/vim-bufkill'}
  use {'tpope/vim-commentary'}
  use {'tpope/vim-eunuch'}
  use {'tpope/vim-fugitive'}
  use {'farmergreg/vim-lastplace'}
  use {'tpope/vim-repeat'}
  use {'timakro/vim-searchant'}
  use {'mhinz/vim-startify'}
  use {'tpope/vim-surround'}
  use {'tpope/vim-scriptease'}
  use {'tweekmonster/startuptime.vim', cmd = 'StartupTime'}
  use {'LnL7/vim-nix'}
  use {'danilo-augusto/vim-afterglow'}
  use {'morhetz/gruvbox'}
  use {'joshdick/onedark.vim'}
end)

vim.cmd('packadd packer.nvim')

return require('packer').startup(function()

  -- Let Packer manage itself as an optional plugin
  use {'wbthomason/packer.nvim', opt=true}

  -- Lsp, completions and linting
  use {'dense-analysis/ale', config=[[require('config.ale')]]}
  use {
    'neovim/nvim-lspconfig',
    requires = {
      'nvim-lua/completion-nvim',
      config = [[require('config.completions')]]
    },
    config = [[require('config.lsp')]]
  }

  -- Miscellaneous
  use {'Raimondi/delimitMate', config=[[require('config.delimitmate')]]}
  use {
    'junegunn/fzf.vim',
    requires = {'junegunn/fzf'},
    config = [[require('config.fzf')]]
  }
  use {'junegunn/goyo.vim', cmd='Goyo', config=[[require('config.goyo')]]}
  use {'iamcco/markdown-preview.nvim', run='cd app && yarn install'}
  use {
    'akinsho/nvim-bufferline.lua',
    -- disable = true,
    requires = {
      'kyazdani42/nvim-web-devicons',
      config = [[require('config.devicons')]]
    },
    config = [[require('config.bufferline')]],
  }
  use {'norcalli/nvim-colorizer.lua', config=[[require('config.colorizer')]]}
  -- use {
  --   'nvim-treesitter/nvim-treesitter',
  --   config = [[require('config.treesitter')]],
  -- }
  use {'qpkorr/vim-bufkill', cmd='BD'}
  use {'tpope/vim-commentary'}
  use {'voldikss/vim-floaterm', config=[[require('config.floaterm')]]}
  use {'farmergreg/vim-lastplace'}
  use {'embear/vim-localvimrc', config=[[require('config.localvimrc')]]}
  use {'tpope/vim-repeat'}
  use {'timakro/vim-searchant'}
  use {'mhinz/vim-startify'}
  use {'tpope/vim-surround'}
  use {'liuchengxu/vim-which-key', config=[[require('config.which-key')]]}

  -- Scripting and profiling
  use {'tpope/vim-scriptease'}
  use {'tweekmonster/startuptime.vim', cmd='StartupTime'}

  -- Filetype specific
  use {'rust-lang/rust.vim', ft='rust', config=[[require('config.rust')]]}
  use {'lervag/vimtex', ft='tex', config=[[require('config.vimtex')]]}
  use {'LnL7/vim-nix'}

  -- Colorschemes
  use {'danilo-augusto/vim-afterglow'}
  use {'morhetz/gruvbox'}
  use {'joshdick/onedark.vim'}

end)

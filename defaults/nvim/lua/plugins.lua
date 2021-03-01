vim.cmd('packadd packer.nvim')

return require('packer').startup(function()
  -- Let Packer manage itself as an optional plugin
  use {'wbthomason/packer.nvim', opt = true}

  -- Lsp, completions and linting
  -- use {'neovim/nvim-lspconfig', config = [[require('config.lsp')]]}
  use {'nvim-lua/completion-nvim', config = [[require('config.completions')]]}
  use {'dense-analysis/ale', config = [[require('config.ale')]]}

  -- UI
  use {'norcalli/nvim-colorizer.lua', config = [[require('config.colorizer')]]}
  use {
    'nvim-treesitter/nvim-treesitter',
    config = [[require('config.treesitter')]],
  }
  use {
    'akinsho/nvim-bufferline.lua',
    requires = {
      'kyazdani42/nvim-web-devicons',
      config = [[require('config.devicons')]]
    },
    config = [[require('config.bufferline')]],
  }

  -- Scripting and profiling
  use 'tpope/vim-scriptease'
  use {'tweekmonster/startuptime.vim', cmd = 'StartupTime'}

  -- Ergonomics
  use {'Raimondi/delimitMate', config = [[require('config.delimitmate')]]}
  use 'tpope/vim-commentary'
  use 'tpope/vim-repeat'
  use 'tpope/vim-surround'

  -- File navigation
  use {
    'junegunn/fzf.vim',
    requires = {'junegunn/fzf'},
    config = [[require('config.fzf')]]
  }

  -- Filetype specific
  use {'rust-lang/rust.vim', ft = 'rust', config = [[require('config.rust')]]}
  use {'lervag/vimtex', ft = 'tex', config = [[require('config.vimtex')]]}

  -- Misc
  use {'liuchengxu/vim-which-key', config = [[require('config.which-key')]]}
  use {'voldikss/vim-floaterm', config = [[require('config.floaterm')]]}
  use {'embear/vim-localvimrc', config = [[require('config.localvimrc')]]}
  use 'farmergreg/vim-lastplace'
  use 'timakro/vim-searchant'
  use {'junegunn/goyo.vim', cmd = 'Goyo', config = [[require('config.goyo')]]}
  use {'qpkorr/vim-bufkill', cmd = 'BD'}
  use {
    'iamcco/markdown-preview.nvim',
    run = 'cd app && yarn install',
    cmd = 'MarkdownPreview'
  }

  -- Colorschemes
  use 'danilo-augusto/vim-afterglow'
  use 'morhetz/gruvbox'
  use 'joshdick/onedark.vim'
end)

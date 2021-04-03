vim.cmd('packadd packer.nvim')

return require('packer').startup(function()
  -- Let Packer manage itself as an optional plugin
  use {'wbthomason/packer.nvim', opt=true}

  -- Lsp, completions and linting
  use {'neovim/nvim-lspconfig',
        config = [[require('plugins.config.lsp')]]}

  use {'nvim-lua/completion-nvim',
        config = [[require('plugins.config.completions')]]}

  use {'dense-analysis/ale',
        config=[[require('plugins.config.ale')]]}

  -- Miscellaneous
  use {'Raimondi/delimitMate',
        config=[[require('plugins.config.delimitmate')]]}

  use {'junegunn/fzf.vim',
        requires = {'junegunn/fzf'},
        config = [[require('plugins.config.fzf')]]}

  use {'junegunn/goyo.vim',
        config=[[require('plugins.config.goyo')]],
        cmd='Goyo'}

  use {'iamcco/markdown-preview.nvim',
        run='cd app && yarn install'}

  use {'akinsho/nvim-bufferline.lua',
        -- disable = true,
        requires = {'kyazdani42/nvim-web-devicons',
                     config = [[require('plugins.config.devicons')]]},
        config = [[require('plugins.config.bufferline')]]}

  use {'norcalli/nvim-colorizer.lua',
        config=[[require('plugins.config.colorizer')]]}

  use {'nvim-treesitter/nvim-treesitter',
        config = [[require('plugins.config.treesitter')]]}

  use {'qpkorr/vim-bufkill'}

  use {'tpope/vim-commentary'}

  use {'voldikss/vim-floaterm',
        config=[[require('plugins.config.floaterm')]]}

  use {'farmergreg/vim-lastplace'}

  use {'embear/vim-localvimrc',
        config=[[require('plugins.config.localvimrc')]]}

  use {'tpope/vim-repeat'}

  use {'timakro/vim-searchant'}

  use {'mhinz/vim-startify'}

  use {'tpope/vim-surround'}

  use {'liuchengxu/vim-which-key',
        config=[[require('plugins.config.which-key')]]}

  -- Scripting and profiling
  use {'tpope/vim-scriptease'}

  use {'tweekmonster/startuptime.vim',
        cmd='StartupTime'}

  -- Filetype specific
  use {'rust-lang/rust.vim',
        ft='rust',
        config=[[require('plugins.config.rust')]]}

  use {'lervag/vimtex',
        ft='tex',
        config=[[require('plugins.config.vimtex')]]}

  use {'LnL7/vim-nix'}

  -- Colorschemes
  use {'danilo-augusto/vim-afterglow'}

  use {'morhetz/gruvbox'}

  use {'joshdick/onedark.vim'}
end)

vim.cmd('packadd packer.nvim')

local packer = require('packer')
local configs = require('plugins/config')

return packer.startup(function()
  use {'wbthomason/packer.nvim', opt = true}
  use {'dense-analysis/ale', config = configs.ale}
  -- use {
  --   'akinsho/nvim-bufferline.lua',
  --   requires = {'kyazdani42/nvim-web-devicons', config = configs.devicons},
  --   config = configs.bufferline,
  -- }
  use {
    '~/sync/projects/cokeline.nvim',
    requires = {'kyazdani42/nvim-web-devicons'},
    config = configs.cokeline,
  }
  use {'norcalli/nvim-colorizer.lua', config = configs.colorizer}
  use {'nvim-lua/completion-nvim', config = configs.completions}
  use {'Raimondi/delimitMate', config = configs.delimitmate}
  use {
    'famiu/feline.nvim',
    requires = {'kyazdani42/nvim-web-devicons', 'lewis6991/gitsigns.nvim'},
    config = configs.feline,
  }
  use {'voldikss/vim-floaterm', config = configs.floaterm}
  use {'junegunn/fzf', config = configs.fzf}
  -- use {
  --   'glepnir/galaxyline.nvim',
  --    branch = main,
  --    requires = {'kyazdani42/nvim-web-devicons', config = configs.devicons},
  --    config = configs.galaxyline,
  -- }
  -- use {
  --   'hoob3rt/lualine.nvim',
  --    requires = {'kyazdani42/nvim-web-devicons', config = configs.devicons},
  --    config = configs.lualine,
  -- }
  use {'embear/vim-localvimrc', config = configs.localvimrc}
  use {'neovim/nvim-lspconfig', config = configs.lsp}
  use {'onsails/lspkind-nvim', config = configs.lspkind}
  use {
    'iamcco/markdown-preview.nvim',
    config = configs.markdown_preview,
    run = 'cd app && yarn install',
  }
  use {'rust-lang/rust.vim', config = configs.rust, ft = 'rust'}
  use {'Pocco81/TrueZen.nvim', config = configs.truezen}
  use {'SirVer/ultisnips', config = configs.snippets}
  use {'nvim-treesitter/nvim-treesitter', config = configs.treesitter}
  use {'lervag/vimtex', config = configs.vimtex, ft = 'tex'}
  use {'liuchengxu/vim-which-key', config = configs.which_key}
  use {'qpkorr/vim-bufkill'}
  use {'tpope/vim-commentary'}
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

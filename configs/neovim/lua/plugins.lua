vim.cmd('packadd packer.nvim')
local rq_packer = require('packer')
local use = rq_packer.use

local spec = function()
  -- Only using it to run fixers on file save.
  use({
    'dense-analysis/ale',
    config = function()
      local vim_g = vim.g
      vim_g.ale_disable_lsp = 1
      vim_g.ale_fix_on_save = 1
      vim_g.ale_linters_explicit = 1
      vim_g.ale_fixers = {
        nix = {'nixpkgs-fmt'},
        python = {'isort', 'yapf'},
        ['*'] = {'remove_trailing_lines', 'trim_whitespace'},
      }
    end
  })

  -- Delete a buffer without closing its window.
  use({'famiu/bufdelete.nvim'})

  -- Best autocompletion framework I could find, and it's far from perfect.
  use({
    'ms-jpq/coq_nvim',
    config = function()
      vim.g.coq_settings = {
        auto_start = 'shut-up',
        ['clients.buffers.enabled'] = false,
        ['clients.snippets.enabled'] = false,
        ['clients.tags.enabled'] = false,
        ['clients.tmux.enabled'] = false,
        ['display.ghost_text.enabled'] = false,
        ['display.pum'] = {
          fast_close = false,
          y_max_len = 7,
          kind_context = {'  ', ''},
          source_context = {'[', ']'},
        },
        ['display.preview'] = {
          border = {'', '', '', '', '', '', '', ''},
          positions = { east = 1, south = 2, north = 3, west = nil },
        },
        ['display.icons.mappings'] = {
          Text = '',
          Method = '',
          Function = '',
          Constructor = '',
          Field = 'ﰠ',
          Variable = '',
          Class = 'ﴯ',
          Interface = '',
          Module = '',
          Property = 'ﰠ',
          Unit = '塞',
          Value = '',
          Enum = '',
          Keyword = '',
          Snippet = '',
          Color = '',
          File = '',
          Reference = '',
          Folder = '',
          EnumMember = '',
          Constant = '',
          Struct = 'פּ',
          Event = '',
          Operator = '',
          TypeParameter = ''
        },
        ['keymap.recommended'] = false,
      }
    end,
  })

  use({
    'nvim-telescope/telescope.nvim',
    requires = 'nvim-lua/plenary.nvim',
  })

  -- One of the best general purpose cli tools ever made.
  use({
    'junegunn/fzf',
    config = function()
      -- I can't port that `fzf.vim` to Lua because the value of `sinklist`
      -- needs to be a vimscript `funcref`. Setting `sinklist = '`
      local vim_g = vim.g
      vim_g.fzf_layout = {
        window = {
          width = 1,
          height = 9,
          yoffset = 0,
          highlight = 'FzfBorder',
          border = 'bottom',
        }
      }
      vim.cmd('source ~/.config/nvim/lua/plug-config/fzf.vim')
    end,
  })

  -- Colorscheme.
  use({'morhetz/gruvbox'})

  -- Preview rendered markdown files in the browser.
  use({
    'iamcco/markdown-preview.nvim',
    config = function()
      local vim_g = vim.g
      vim_g.mkdp_browser = 'qutebrowser'
      vim_g.mkdp_browserfunc = 'html#open'
      vim_g.mkdp_filetypes = {'markdown'}
      vim_g.mkdp_page_title = '${name}'
    end,
    run = 'cd app && yarn install',
  })

  -- Autopairs quotes, parenthesis, etc. Not that good. I'll make my own when I
  -- have time.
  use({
    'windwp/nvim-autopairs',
    config = function()
      require('nvim-autopairs').setup()
    end,
  })

  -- Holy fuck every single completion framework is absolute garbage.
  -- Why does it flicker when I select a completion? Why doesn't `pumvisible`
  -- work? Why the fuck does it force me to have a snippet engine?? Why does it
  -- insist on setting the mappings for me instead of simply providing a public
  -- API like `<Plug>` that I can configure how I want???
  -- AAAARGHH... I'll have to make my own framework when I have time.
  -- use({
  --   'hrsh7th/nvim-cmp',
  --   requires = {
  --     'hrsh7th/cmp-cmdline',
  --     'hrsh7th/cmp-nvim-lsp',
  --     'hrsh7th/cmp-nvim-lua',
  --     'hrsh7th/cmp-path',
  --     'onsails/lspkind-nvim',
  --     'L3MON4D3/LuaSnip',
  --     'saadparwaiz1/cmp_luasnip',
  --   },
  --   config = function ()
  --     require('plug-config/cmp')
  --   end
  -- })

  -- Obviously the best bufferline plugin around ;)
  use({
    '~/Dropbox/projects/nvim-cokeline',
    requires = { 'kyazdani42/nvim-web-devicons' },
    config = function()
      require('plug-config/cokeline')
    end,
  })

  -- Highlight hexcolors strings in that color.
  use({
    'norcalli/nvim-colorizer.lua',
    config = function()
      require('colorizer').setup({'*'}, {names = false})
    end,
  })

  -- Utility plugin with default configurations for many LSPs.
  use({
    'neovim/nvim-lspconfig',
    config = function()
      require('plug-config/lsp').setup()
    end,
  })

  -- Now this is some revolutionary stuff.
  use({
    'nvim-treesitter/nvim-treesitter',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = 'maintained',
        highlight = {
          enable = true,
        },
      })
    end
  })

  -- Colorscheme.
  use({'joshdick/onedark.vim'})

  -- Plugin manager.
  use({
    'wbthomason/packer.nvim',
    opt = true,
  })

  -- QoL plugin for writing Rust code.
  use({
    'rust-lang/rust.vim',
    config = function()
      local vim_g = vim.g
      vim_g.rustfmt_autosave = 1
      vim_g.cargo_makeprg_params = 'run'
    end,
    ft = 'rust',
  })

  -- Profile your startup time. Anything above 30ms is unacceptable.
  use({
    'tweekmonster/startuptime.vim',
    cmd = 'StartupTime',
  })

  -- Colorscheme.
  use({
    'folke/tokyonight.nvim',
    config = function()
      vim.g.tokyonight_style = 'storm'
      vim.g.tokyonight_transparent = true
    end
  })

  -- Colorscheme.
  use({'danilo-augusto/vim-afterglow'})

  -- Comment and uncomment code with `gc`.
  use({'tpope/vim-commentary'})

  -- Delete, rename files while they're open in a buffer.
  use({
    'tpope/vim-eunuch',
    cmd = {'Delete', 'Rename',},
  })

  -- Floating terminal, doesn't react to `VimResized` so not that good.
  use({
    'voldikss/vim-floaterm',
    config = function()
      require('plug-config/floaterm')
    end,
  })

  -- Reopen files at last edit position.
  use({'farmergreg/vim-lastplace'})

  -- Syntax plugin for the Nix language.
  use({'LnL7/vim-nix'})

  -- Companion for `tpope/vim-surround`, extends `.` repeat to plugin mappings.
  use({'tpope/vim-repeat'})

  -- Highlight the current search result in a different color.
  use({'qxxxb/vim-searchhi'})

  -- Start screen with wise quotes.
  use({'mhinz/vim-startify'})

  -- Surround stuff with other stuff.
  use({'tpope/vim-surround'})

  -- QoL plugin for writing LaTeX documents.
  use({
    'lervag/vimtex',
    config = function()
      local vim_g = vim.g
      vim_g.vimtex_compiler_enabled = 0
      vim_g.vimtex_format_enabled = 1
      vim_g.vimtex_syntax_conceal_disable = 1
      vim_g.vimtex_toc_show_preamble = 0
      vim_g.vimtex_toc_config = {
        indent_levels = 1,
        layers = {'content', 'include'},
        show_help = 0,
        split_width = 40,
        tocdepth = 6,
      }
      vim_g.vimtex_view_method = (_G.OS == 'Darwin') and 'skim' or 'zathura'
      vim_g.vimtex_view_skim_reading_bar = 0
    end,
    ft = 'tex',
  })

  -- Displays a popup menu with possible endings for half-typed keymaps.
  use({
    'folke/which-key.nvim',
    config = function()
      require('which-key').setup()
    end
  })

  -- Write prose without any visual distractions.
  use({
    'folke/zen-mode.nvim',
    config = function()
      require('zen-mode').setup({
        window = {
          backdrop = 0.8,
          width = 81,
          options = {
            list = false,
            number = false,
            relativenumber = false,
          },
        },
      })
    end
  })
end

local setup = function()
  rq_packer.startup(spec)
end

return {
  setup = setup,
}

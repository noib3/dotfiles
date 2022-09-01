vim.cmd("packadd packer.nvim")

local packer = require("packer")

local use = packer.use

local plugins = function()
  -- Only using ALE to run a few fixers on save.
  use({
    "dense-analysis/ale",
    config = function()
      local g = vim.g
      g.ale_disable_lsp = 1
      g.ale_fix_on_save = 1
      g.ale_linters_explicit = 1
      g.ale_fixers = {
        ["*"] = { "remove_trailing_lines", "trim_whitespace" },
      }
    end
  })

  -- Delete buffers without closing the window they're in.
  use({ "famiu/bufdelete.nvim" })

  -- Automatically insert/delete matching parenthesis.
  use({
    "Raimondi/delimitMate",
    config = function()
      local g = vim.g
      g.delimitMate_expand_cr = 1
      g.delimitMate_expand_space = 1
    end
  })

  --
  use({
    "junegunn/fzf",
    config = function()
      -- I can't port that `fzf.vim` to Lua because the value of `sinklist`
      -- needs to be a vimscript `funcref`. Setting `sinklist = '`
      vim.g.fzf_layout = {
        window = {
          width = 1,
          height = 9,
          yoffset = 0,
          highlight = "FzfBorder",
          border = "bottom",
        },
      }
      vim.cmd("source ~/.config/nvim/lua/plug-config/fzf.vim")
    end,
  })

  -- -- Displays LSP progress infos on startup.
  -- use({
  --   "j-hui/fidget.nvim",
  --   config = function()
  --     require("fidget").setup({})
  --   end
  -- })

  use({
    "ellisonleao/gruvbox.nvim",
    config = function()
      require("gruvbox").setup({})
    end
  })

  -- Qutebrowser-like buffer navigation.
  use({
    "phaazon/hop.nvim",
    branch = "v2",
    config = function()
      require("hop").setup({})
      vim.keymap.set("n", "f", "<Cmd>HopWord<CR>")
    end
  })

  -- Bufferline.
  use({
    "noib3/nvim-cokeline",
    requires = { "kyazdani42/nvim-web-devicons" },
    config = function()
      require("plug-config/cokeline")
    end,
  })

  -- Highlight the background of colors in hex format in the color they
  -- represent.
  use({
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup(
        { "*" },
        { names = false }
      )
    end
  })

  -- Contains default configurations for many LSPs.
  use({ "neovim/nvim-lspconfig" })

  -- Tree-sitter highlighting.
  use({
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter/configs").setup({
        ensure_installed = "all",
        highlight = { enable = true },
      })
    end
  })


  -- Tree-sitter playground.
  use({
    "nvim-treesitter/playground",
    config = function()
      require("nvim-treesitter/configs").setup({
        playground = { enable = true },
      })
    end
  })


  -- Set the `commentstring` option baes on the current cursor location (useful
  -- when editing multi-language files).
  use({
    "JoosepAlviste/nvim-ts-context-commentstring",
    config = function()
      require("nvim-treesitter/configs").setup({
        context_commentstring = { enable = true },
      })
    end
  })

  -- Automatically add the `end` block when writing Lua.
  use({
    "RRethy/nvim-treesitter-endwise",
    config = function()
      require("nvim-treesitter/configs").setup({
        endwise = { enable = true },
      })
    end
  })

  -- Plugin manager.
  use({
    "wbthomason/packer.nvim",
    opts = true,
  })

  -- Comment and uncomment code with `gc`.
  use({ "tpope/vim-commentary" })

  -- Delete, rename files while they're open in a buffer.
  use({
    "tpope/vim-eunuch",
    cmd = { "Delete", "Rename" },
  })

  -- Floating terminal, doesn't react to `VimResized` so not that good.
  use({
    "voldikss/vim-floaterm",
    config = function()
      require("plug-config/floaterm")
    end,
  })

  -- Reopen files at the last edit position.
  use({ "farmergreg/vim-lastplace" })

  -- Syntax plugin for the Nix language.
  use({ "LnL7/vim-nix" })

  -- Companion for `tpope/vim-surround`, extends `.` repeat to plugin mappings.
  use({ "tpope/vim-repeat" })

  -- Highlight the current search result in a different color.
  use({ "qxxxb/vim-searchhi" })

  -- Surround stuff with other stuff.
  use({ "tpope/vim-surround" })

  -- Colorschemes.
  use({
    "Mofiqul/vscode.nvim",
    config = function()
      local g = vim.g
      g.vscode_style = "dark"
      g.vscode_italic_comments = 1
    end,
  })
end

packer.startup(plugins)

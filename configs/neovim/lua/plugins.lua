vim.cmd("packadd packer.nvim")
local rq_packer = require("packer")
local use = rq_packer.use

local spec = function()
  -- Only using it to run fixers on file save.
  use({
    "dense-analysis/ale",
    config = function()
      local vim_g = vim.g
      vim_g.ale_disable_lsp = 1
      vim_g.ale_fix_on_save = 1
      vim_g.ale_linters_explicit = 1
      vim_g.ale_lua_stylua_options =
        "--config-path ~/Dropbox/projects/nvim-cokeline/stylua.toml"

      vim_g.ale_fixers = {
        javascript = { "prettier" },
        kt = { "ktlint" },
        kotlin = { "ktlint" },
        lua = { "stylua" },
        nix = { "nixpkgs-fmt" },
        python = { "isort", "yapf" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        ["*"] = { "remove_trailing_lines", "trim_whitespace" },
      }
      -- vim_g.ale_linters = {
      --   kotlin = {'ktlint'},
      -- }
    end,
  })

  -- Delete a buffer without closing its window.
  use({ "famiu/bufdelete.nvim" })

  -- use({
  --   'akinsho/bufferline.nvim',
  --   config = function()
  --     require('bufferline').setup({ })
  --   end
  -- })

  -- Best autocompletion framework I could find, and it's far from perfect.
  -- Sometimes it needs to be started manually w/ `COQnow`.
  use({
    "ms-jpq/coq_nvim",
    config = function()
      vim.g.coq_settings = {
        -- auto_start = "shut-up",
        ["clients.buffers.enabled"] = false,
        ["clients.snippets.enabled"] = false,
        ["clients.tags.enabled"] = false,
        ["clients.tmux.enabled"] = false,
        ["display.ghost_text.enabled"] = false,
        ["display.pum"] = {
          fast_close = false,
          y_max_len = 7,
          kind_context = { "  ", "" },
          source_context = { "[", "]" },
        },
        ["display.preview"] = {
          border = { "", "", "", "", "", "", "", "" },
          positions = { east = 1, south = 2, north = 3, west = nil },
        },
        ["display.icons.mappings"] = {
          Text = "",
          Method = "",
          Function = "",
          Constructor = "",
          Field = "ﰠ",
          Variable = "",
          Class = "ﴯ",
          Interface = "",
          Module = "",
          Property = "ﰠ",
          Unit = "塞",
          Value = "",
          Enum = "",
          Keyword = "",
          Snippet = "",
          Color = "",
          File = "",
          Reference = "",
          Folder = "",
          EnumMember = "",
          Constant = "",
          Struct = "פּ",
          Event = "",
          Operator = "",
          TypeParameter = "",
        },
        ["keymap.recommended"] = false,
      }
    end,
  })

  use({
    "Raimondi/delimitMate",
    config = function()
      vim.g.delimitMate_expand_cr = 1
      vim.g.delimitMate_expand_space = 1
    end,
  })

  -- One of the best general purpose cli tools ever made.
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

  -- Colorscheme.
  use({ "morhetz/gruvbox" })

  -- Colorscheme
  use({ "rebelot/kanagawa.nvim" })

  -- Nicer UI for LSP-related things
  -- use({
  --   'glepnir/lspsaga.nvim',
  --   config = function()
  --     require('lspsaga').init_lsp_saga({})
  --   end
  -- })

  -- Preview rendered markdown files in the browser.
  use({
    "iamcco/markdown-preview.nvim",
    config = function()
      require("plug-config/markdown_preview")
    end,
    run = "cd app && yarn install",
  })

  -- Obviously the best bufferline plugin around ;)
  use({
    "~/Dropbox/projects/nvim-cokeline",
    requires = { "kyazdani42/nvim-web-devicons" },
    config = function()
      require("plug-config/cokeline")
    end,
  })

  -- Highlight hexcolors strings in that color.
  use({
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup({ "*" }, { names = false })
    end,
  })

  -- Wannabe completion framework.
  use({
    "~/Dropbox/projects/nvim-compleet",
    config = function()
      require("compleet").setup({
        autoshow_menu = false,
        show_hints = true,
      })
    end,
  })

  use({ "nvim-lua/plenary.nvim" })
  use({ "TimUntersberger/neogit" })

  -- Use external linters w/ the built-in `vim.diagnostic` module
  use({
    "mfussenegger/nvim-lint",
    config = function()
      require("lint").linters_by_ft = {
        kotlin = { "ktlint" },
      }
      -- This isn't the best user experience. Idk what's the best combination
      -- of autocmds to be added. ALE doesn't require worrying about this,
      -- neither should this plugin.
      vim.cmd([[au BufWritePost *.kt lua require('lint').try_lint()]])
    end,
  })

  -- Utility plugin with default configurations for many LSPs.
  use({
    "neovim/nvim-lspconfig",
    config = function()
      require("plug-config/lsp").setup()
    end,
  })

  -- Used to show step-by-step type hints of chained Rust code.
  use({ "nvim-lua/lsp_extensions.nvim" })

  -- File tree.
  use({
    "https://github.com/kyazdani42/nvim-tree.lua",
    requires = { "kyazdani42/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end,
  })

  -- Now this is some revolutionary stuff.
  use({
    "nvim-treesitter/nvim-treesitter",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = "maintained",
        highlight = {
          enable = true,
          disable = { "markdown" },
        },
        context_commentstring = {
          enable = true,
        },
      })
    end,
  })

  -- Set the `commentstring` option based on the current cursor location.
  use({ "JoosepAlviste/nvim-ts-context-commentstring" })

  -- Automatically add `end` block when writing Lua.
  use({
    "RRethy/nvim-treesitter-endwise",
    config = function()
      require("nvim-treesitter.configs").setup({
        endwise = { enable = true },
      })
    end,
  })

  -- Plugin manager.
  use({
    "wbthomason/packer.nvim",
    opt = true,
  })

  -- QoL plugin for writing Rust code.
  use({
    "rust-lang/rust.vim",
    config = function()
      local vim_g = vim.g
      vim_g.rustfmt_autosave = 1
      vim_g.cargo_makeprg_params = "run"
    end,
    ft = "rust",
  })

  -- Profile your startup time. Anything above 30ms is unacceptable.
  use({
    "tweekmonster/startuptime.vim",
    cmd = "StartupTime",
  })

  -- Colorscheme.
  use({
    "folke/tokyonight.nvim",
    config = function()
      vim.g.tokyonight_style = "storm"
      vim.g.tokyonight_transparent = true
    end,
  })

  -- Colorscheme.
  use({ "danilo-augusto/vim-afterglow" })

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

  -- Reopen files at last edit position.
  use({ "farmergreg/vim-lastplace" })

  -- Syntax plugin for the Nix language.
  use({ "LnL7/vim-nix" })

  -- Companion for `tpope/vim-surround`, extends `.` repeat to plugin mappings.
  use({ "tpope/vim-repeat" })

  -- Highlight the current search result in a different color.
  use({ "qxxxb/vim-searchhi" })

  -- Start screen with wise quotes.
  use({ "mhinz/vim-startify" })

  -- Surround stuff with other stuff.
  use({ "tpope/vim-surround" })

  -- QoL plugin for writing LaTeX documents.
  use({
    "lervag/vimtex",
    config = function()
      local vim_g = vim.g
      vim_g.vimtex_compiler_enabled = 0
      vim_g.vimtex_format_enabled = 1
      vim_g.vimtex_syntax_conceal_disable = 1
      vim_g.vimtex_toc_show_preamble = 0
      vim_g.vimtex_toc_config = {
        indent_levels = 1,
        layers = { "content", "include" },
        show_help = 0,
        split_width = 40,
        tocdepth = 6,
      }
      vim_g.vimtex_view_method = (_G.OS == "Darwin") and "skim" or "zathura"
      vim_g.vimtex_view_skim_reading_bar = 0
    end,
    ft = "tex",
  })

  -- Vscode inspired colorscheme
  use({
    "Mofiqul/vscode.nvim",
    config = function()
      vim.g.vscode_style = "dark"
      vim.g.vscode_italic_comments = 1
    end,
  })

  -- Displays a popup menu with possible endings for half-typed keymaps.
  -- use({
  --   'folke/which-key.nvim',
  --   config = function()
  --     require('which-key').setup()
  --   end
  -- })

  -- Write prose without any visual distractions.
  use({
    "folke/zen-mode.nvim",
    config = function()
      require("zen-mode").setup({
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
    end,
  })
end

return {
  setup = function()
    rq_packer.startup(spec)
  end,
}

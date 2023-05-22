return {
  -- Delete buffers without closing the window they're in.
  "famiu/bufdelete.nvim",

  --
  {
    "saecki/crates.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require('crates').setup()
    end,
  },

  -- Highlights hex-formatted color strings in the color they represent.
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require("colorizer").setup(
        { "*" },
        { names = false }
      )
    end
  },

  -- Qutebrowser-like buffer navigation.
  {
    "phaazon/hop.nvim",
    branch = "v2",
    config = function()
      require("hop").setup({})
      vim.keymap.set("n", "f", "<Cmd>HopWord<CR>")
    end,
  },

  -- Reopen files at the last edit position.
  {
    "ethanholz/nvim-lastplace",
    config = function()
      require("nvim-lastplace").setup({})
    end,
  },

  -- Default configs for many LSPs.
  "neovim/nvim-lspconfig",

  -- Telescope.
  {
    "nvim-telescope/telescope.nvim",
    enabled = false,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    config = function()
      local project_dir = function()
        local is_under_git = vim.fn.system("git status"):find("fatal") ~= nil
        if is_under_git then
          return vim.fn.systemlist("git rev-parse --show-toplevel")[1]
        else
          return vim.fn.expand("%:p:h")
        end
      end

      local ts = require("telescope")

      local builtin = require("telescope.builtin")

      ts.setup({
        defaults = {
          sorting_strategy = "ascending",
          layout_config = {
            prompt_position = "top",
            horizontal = {
              width_padding = 0.04,
              height_padding = 0.1,
              preview_width = 0.6,
            },
            vertical = {
              width_padding = 0.05,
              height_padding = 1,
              preview_height = 0.5,
            },
          },
        },
      })

      ts.load_extension("fzf")

      vim.keymap.set(
        "n",
        "<C-x><C-e>",
        function() builtin.find_files({ cwd = project_dir() }) end
      )

      vim.keymap.set(
        "n",
        "<Tab>",
        function() builtin.buffers() end
      )
    end,
  },

  -- Tokyonight colorscheme.
  {
    "folke/tokyonight.nvim",
    enabled = true,
    config = function()
      vim.g.tokyonight_style = "night"
      vim.g.tokyonight_transparent = true
      vim.cmd("colorscheme tokyonight-night")
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/playground",
      "JoosepAlviste/nvim-ts-context-commentstring",
      "RRethy/nvim-treesitter-endwise",
    },
    config = function()
      require("nvim-treesitter/configs").setup({
        ensure_installed = "all",
        context_commentstring = {
          enable = true,
        },
        endwise = {
          enable = true,
        },
        highlight = {
          enable = true,
        },
        playground = {
          enable = true
        },
      })
    end
  },
}

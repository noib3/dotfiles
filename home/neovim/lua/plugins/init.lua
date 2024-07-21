return {
  -- Delete buffers without closing the window they're in.
  "famiu/bufdelete.nvim",

  "github/copilot.vim",

  -- Lua port of `vim-commentary`.
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
  },

  -- Automatically insert/delete matching parenthesis.
  {
    "Raimondi/delimitMate",
    config = function()
      vim.g.delimitMate_expand_cr = 1
      vim.g.delimitMate_expand_space = 1
    end,
  },

  --
  -- {
  --   "junegunn/fzf",
  --   config = function()
  --     vim.g.fzf_layout = {
  --       window = {
  --         width = 1,
  --         height = 9,
  --         yoffset = 0,
  --         highlight = "FzfBorder",
  --         border = "bottom",
  --       },
  --     }
  --     vim.cmd("source ~/.config/nvim/lua/plug-config/fzf.vim")
  --   end,
  -- },

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

  -- Lua port of `vim-surround`.
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup({})
    end
  },

  -- Telescope.
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
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

      vim.keymap.set(
        "n",
        "<C-x><C-e>",
        function() builtin.find_files({ cwd = project_dir() }) end
      )

      -- vim.keymap.set("n", "<C-x><C-e>", builtin.find_files({ cwd = project_dir() }))

      vim.keymap.set(
        "n",
        "<Tab>",
        function() builtin.buffers() end
      )
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
        ensure_installed = { "c", "lua", "javascript", "nix", "rust" },
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

  -- Delete, rename files while they're open in a buffer.
  "tpope/vim-eunuch",

  -- Floating terminal, doesn't react to `VimResized` so not that good.
  {
    "voldikss/vim-floaterm",
    config = function()
      vim.g.floaterm_autoclose = 2
      vim.g.floaterm_height = 0.8
      vim.g.floaterm_opener = 'edit'
      vim.g.floaterm_title = ''
      vim.g.floaterm_width = 0.8

      LfOpener = function(path)
        print(path)

        local filetype =
            vim.fn.system(('file -Lb --mime-type "%s"'):format(path)):gsub('\n', '')

        local is_textfile =
            (filetype):find('text')
            or filetype == 'application/json'
            or filetype == 'inode/x-empty'

        local cmd = is_textfile
            and ('%s %s'):format(vim.g.floaterm_opener, path)
            or ('silent execute "!open %s"'):format(vim.fn.shellescape(path))

        vim.cmd(cmd)
      end

      local lf_select_current_buffer = function()
        local filename = vim.api.nvim_buf_get_name(0)
        if filename ~= '' then
          filename = vim.fn.shellescape(filename)
        end
        vim.cmd('FloatermNew --opener=LfOpener lf ' .. filename)
      end

      vim.cmd('command! -nargs=* LfOpener call luaeval("LfOpener(_A)", <q-args>)')
      vim.keymap.set("n", "ll", lf_select_current_buffer, { silent = true })
      vim.keymap.set("n", "lg", '<Cmd>FloatermNew lazygit<CR>', { silent = true })
    end,
  },
}

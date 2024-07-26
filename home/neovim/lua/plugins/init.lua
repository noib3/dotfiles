return {
  -- Delete buffers without closing the window they're in.
  "famiu/bufdelete.nvim",

  -- Lua port of `vim-commentary`.
  {
    'numToStr/Comment.nvim',
    config = function()
      require('Comment').setup()
    end
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

  -- Delete, rename files while they're open in a buffer.
  -- "tpope/vim-eunuch",

  -- Floating terminal, doesn't react to `VimResized` so not that good.
  {
    "voldikss/vim-floaterm",
    config = function()
      vim.g.floaterm_autoclose = 2
      vim.g.floaterm_height = 0.8
      vim.g.floaterm_opener = 'edit'
      vim.g.floaterm_title = ''
      vim.g.floaterm_width = 0.8
      vim.keymap.set("n", "lg", "<Cmd>FloatermNew lazygit<CR>", { silent = true })
    end,
  },
}

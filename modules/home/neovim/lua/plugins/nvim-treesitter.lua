return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/playground",
      "RRethy/nvim-treesitter-endwise",
    },
    opts = {
      endwise = {
        enable = true,
      },
      highlight = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<S-Up>",
          scope_incremental = "<S-Right>",
          node_incremental = "<S-Up>",
          node_decremental = "<S-Down>",
        }
      },
      playground = {
        enable = true
      },
      ensure_installed = {
        "c",
        "javascript",
        "lua",
        "markdown",
        "nix",
        "rust",
        "toml",
        "vimdoc",
      },
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end
  }
}

return {
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    dependencies = {
      "nvim-treesitter/playground",
      "metiulekm/nvim-treesitter-endwise",
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
          init_selection = "<Tab>",
          node_incremental = "<Tab>",
          node_decremental = "<S-Tab>",
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

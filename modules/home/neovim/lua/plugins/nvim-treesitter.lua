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

return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      "nvim-treesitter/playground",
      "JoosepAlviste/nvim-ts-context-commentstring",
      "RRethy/nvim-treesitter-endwise",
    },
    config = function()
      require("nvim-treesitter/configs").setup({
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
      })
    end
  }
}

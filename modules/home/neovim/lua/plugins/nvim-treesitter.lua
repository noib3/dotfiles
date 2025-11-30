return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    build = ":TSUpdate",
    lazy = false,
    dependencies = {
      "RRethy/nvim-treesitter-endwise",
    },
    opts = {
      install_dir = vim.fn.stdpath("data") .. "/site",
    }
  },
}

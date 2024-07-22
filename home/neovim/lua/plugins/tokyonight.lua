return {
  {
    "folke/tokyonight.nvim",
    config = function()
      vim.g.tokyonight_style = "night"
      vim.g.tokyonight_transparent = true
      vim.cmd("colorscheme tokyonight-night")
    end,
  }
}

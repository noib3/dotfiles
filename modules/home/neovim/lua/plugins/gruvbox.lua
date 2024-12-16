return {
  {
    "ellisonleao/gruvbox.nvim",
    cond = vim.env.COLORSCHEME == "gruvbox",
    config = function()
      vim.o.background = "dark"
      vim.cmd("colorscheme gruvbox")
    end,
  }
}

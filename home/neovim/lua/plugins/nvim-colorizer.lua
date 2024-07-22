return {
  {
    "norcalli/nvim-colorizer.lua",
    config = function()
      vim.opt.termguicolors = true
      require("colorizer").setup(
        { "*" },
        { names = false }
      )
    end
  }
}

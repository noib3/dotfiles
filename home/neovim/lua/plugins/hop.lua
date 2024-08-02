return {
  {
    "phaazon/hop.nvim",
    branch = "v2",
    config = function()
      require("hop").setup({})
      vim.keymap.set("n", "f", "<Cmd>HopWord<CR>")
    end,
  }
}

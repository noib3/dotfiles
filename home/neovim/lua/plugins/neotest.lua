return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("neotest").setup({
        output = {
          open_on_run = false,
        },
        adapters = {
          require("rustaceanvim.neotest"),
        },
      })
    end
  }
}

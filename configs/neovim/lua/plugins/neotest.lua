return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("neotest").setup({
        adapters = {
        },
        output = {
          open_on_run = false,
        },
        status = {
          signs = false,
          virtual_text = true,
        },
      })
    end
  }
}

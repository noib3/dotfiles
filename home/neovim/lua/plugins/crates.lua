return {
  {
    "saecki/crates.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    opts = {
      completion = {
        cmp = {
          enabled = true
        },
        crates = {
          enabled = true,
          min_chars = 1,
        }
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    }
  },
}

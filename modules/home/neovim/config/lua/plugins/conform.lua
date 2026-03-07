return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
      },
      notify_no_formatters = false,
    },
    config = function(_, opts)
      require("conform").setup(opts)
      vim.lsp.enable("conform")
    end,
  },
}

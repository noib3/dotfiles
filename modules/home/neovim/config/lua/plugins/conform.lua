require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
  },
  notify_no_formatters = false,
})

vim.lsp.enable("conform")

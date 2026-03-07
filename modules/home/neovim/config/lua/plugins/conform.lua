---@diagnostic disable-next-line: undefined-field
require("conform").setup({
  formatters_by_ft = {
    lua = { "stylua" },
    sh = { "shfmt" },
  },
  notify_no_formatters = false,
})

vim.lsp.enable("conform")

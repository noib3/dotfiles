---@diagnostic disable-next-line: undefined-field
require("conform").setup({
  formatters_by_ft = {
    c = { "uncrustify" },
    lua = { "stylua" },
    sh = { "shfmt" },
  },
  formatters = {
    -- Only enable uncrustify if the project has an uncrustify.cfg.
    uncrustify = {
      condition = function(_, ctx)
        return vim.fs.find(
          "uncrustify.cfg",
          { upward = true, path = ctx.dirname }
        )[1] ~= nil
      end,
    },
  },
  notify_no_formatters = false,
})

vim.lsp.enable("conform")

local lint = require("lint")

lint.linters_by_ft.ghaction = { "actionlint" }

local lint_group = vim.api.nvim_create_augroup("noib3/nvim-lint", {
  clear = true,
})

vim.api.nvim_create_autocmd({ "BufWritePost", "FileType" }, {
  group = lint_group,
  desc = "Runs configured linters",
  callback = function() lint.try_lint() end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  group = lint_group,
  desc = "Runs configured stdin-capable linters",
  callback = function() lint.try_lint(nil, { filter = "stdin" }) end,
})

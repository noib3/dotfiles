vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("noib3/rebalance-splits", { clear = true }),
  desc = "Rebalance window splits when terminal is resized",
  command = "wincmd =",
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  group = vim.api.nvim_create_augroup("noib3/reset-cursor", { clear = true }),
  desc = "Resets the cursor to a vertical bar before exiting Neovim",
  command = "set guicursor=a:ver25",
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("noib3/setup-terminal", { clear = true }),
  desc = "Disables line numbers and enters insert mode in terminals",
  callback = function()
    vim.opt_local.statusline = "%{b:term_title}"
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd("startinsert")
  end,
})

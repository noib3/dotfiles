vim.opt_local.formatoptions:remove({ "r", "o" })
vim.opt_local.shiftwidth = 2
vim.opt_local.spelllang = { "en_us", "it" }
vim.opt_local.tabstop = 2

vim.keymap.set("n", "<D-c>", "<Cmd>!context --purge %<CR>", {
  silent = true,
  buffer = true,
})

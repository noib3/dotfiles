vim.opt_local.formatoptions:remove("r")
vim.opt_local.formatoptions:remove("o")
vim.bo.shiftwidth = 2
vim.bo.spelllang = "en_us,it"
vim.bo.tabstop = 2

vim.keymap.set("n", "<D-c>", "<Cmd>!context --purge %<CR>", {
  silent = true,
  buffer = true,
})

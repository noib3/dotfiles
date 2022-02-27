vim.opt_local.formatoptions:remove({ "r", "o" })
vim.opt_local.spelllang = { "en_us", "it" }

vim.keymap.set(
  "n",
  "<C-t>",
  "<Cmd>!context --purge %<CR>",
  { silent = true, buffer = true }
)

vim.keymap.set(
  "n",
  "<Leader>lv",
  "<Cmd>silent call v:lua.open_tex_pdf()<CR>",
  { buffer = true, silent = true }
)

vim.cmd([[
  augroup ConTeXt
    autocmd!
    autocmd BufUnload *.tex silent call v:lua.close_tex_pdf()
  augroup END
]])

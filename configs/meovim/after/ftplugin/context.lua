vim.opt_local.formatoptions:remove({ "r", "o" })
vim.opt_local.spelllang = { "en_us", "it" }

local opts = { silent = true, buffer = true }

vim.keymap.set("n", "<C-t>", "<Cmd>!context --purge %<CR>", opts)
vim.keymap.set("n", "<Leader>lv", "<Cmd>lua _G.open_tex_pdf()<CR>", opts)

vim.cmd([[
  augroup ConTeXt
    autocmd!
    autocmd BufUnload *.tex silent call v:lua.close_tex_pdf()
  augroup END
]])

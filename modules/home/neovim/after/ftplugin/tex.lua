vim.bo.errorformat = "%f:%l: %m"
vim.opt_local.iskeyword:remove({ ":" })
vim.bo.makeprg = "pdflatex -halt-on-error -file-line-error %"
vim.opt_local.spelllang = { "en_us", "it" }

vim.b.delimitMate_matchpairs = "(:),[:],{:},`:'"
vim.b.delimitMate_quotes = "$"

vim.b["surround_" .. vim.fn.char2nr("c")] = "\\\1command: \1{\r}"
vim.b["surround_" .. vim.fn.char2nr("e")] =
  "\\begin{\1environment: \1}\n\t\r\n\\end{\1\1}"

vim.keymap.set(
  "n",
  "<C-t>",
  "<Cmd>make!<Bar>silent cc<CR>",
  { buffer = true, silent = true }
)

vim.keymap.set(
  "n",
  "<Leader>lv",
  "<Cmd>silent call v:lua.open_tex_pdf()<CR>",
  { buffer = true, silent = true }
)

vim.cmd([[
  augroup TeX
    autocmd!
    autocmd BufRead *.tex silent call v:lua.open_tex_pdf()
    autocmd BufUnload *.tex silent call v:lua.close_tex_pdf()
  augroup END
]])

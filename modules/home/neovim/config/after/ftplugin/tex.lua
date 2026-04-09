vim.bo.errorformat = "%f:%l: %m"
vim.bo.makeprg = "pdflatex -halt-on-error -file-line-error %"
vim.opt_local.iskeyword:remove({ ":" })
vim.opt_local.spelllang = { "en_us", "it" }

vim.bo.errorformat = [[%*\sFile "%f"\, line %l\, %m,]]
vim.bo.makeprg = "python3 %"
vim.opt_local.formatoptions:remove({ "r" })

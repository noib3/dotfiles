local localopt = vim.opt_local

localopt.formatoptions:append("c")
localopt.formatoptions:remove({ "r", "o" })
localopt.textwidth = 79

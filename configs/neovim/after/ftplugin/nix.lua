local b = vim.b
local opt = vim.opt_local

opt.iskeyword:remove({'-'})
b.delimitMate_expand_space = 1

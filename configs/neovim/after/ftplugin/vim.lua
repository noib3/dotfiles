local vim_localopt = vim.opt_local

vim_localopt.foldtext = 'folds#marker_folds_extract_title()'
vim_localopt.formatoptions:remove({'r', 'o'})
vim_localopt.iskeyword:remove({'#'})
vim_localopt.matchpairs:append({'<:>'})

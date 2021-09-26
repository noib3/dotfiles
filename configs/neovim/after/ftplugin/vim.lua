local b = vim.b
local opt = vim.opt_local

opt.foldtext = 'folds#marker_folds_extract_title()'
opt.formatoptions:remove({'r', 'o'})
opt.iskeyword:remove({'#'})
opt.matchpairs:append({'<:>'})

b['surround_{char2nr("z")}'] = [[" \1Title: \1 {{{\n\r\n" }}}]]

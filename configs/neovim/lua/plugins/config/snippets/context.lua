local U = require'snippets.utils'
local M = {}

-- Make unnumbered equation
M.mue = U.match_indentation [[
\startformula
  $1
\stopformula
$0
]]

return M

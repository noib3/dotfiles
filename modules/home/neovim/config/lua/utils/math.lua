local M = {}

---Rounds a number to the nearest integer.
---@param x number The number to round
---@return integer rounded
M.round = function(x) return math.floor(x + 0.5) end

return M

local M = {}

--- Split a table into two tables based on a predicate.
---
---@generic T
---@param tbl T[]
---@param predicate fun(value: T): boolean
---@return T[] matches
---@return T[] non_matches
M.split_table = function(tbl, predicate)
  local matches = {}
  local non_matches = {}
  for _, value in ipairs(tbl) do
    if predicate(value) then
      table.insert(matches, value)
    else
      table.insert(non_matches, value)
    end
  end
  return matches, non_matches
end

return M

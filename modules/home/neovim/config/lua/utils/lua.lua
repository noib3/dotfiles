local M = {}

---Iterates over lines in a string.
---
---@param str string The string to iterate over
---@return function lines Iterator over the string's lines
M.iter_lines = function(str)
  if not str then
    return function() return nil end
  end
  return str:gmatch("[^\r\n]+")
end

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

---Returns whether a string starts with a given prefix.
---
---@param str string
---@param prefix string
---@return boolean
M.starts_with = function(str, prefix) return str:sub(1, #prefix) == prefix end

return M

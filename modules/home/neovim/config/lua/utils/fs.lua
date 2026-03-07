local M = {}

---Reads the entire contents of a file.
---@param path string Path to the file to read
---@return string|nil content The file contents as a string, or nil if the file couldn't be opened
M.read_file = function(path)
  local f = io.open(path, "r")
  if not f then return nil end
  local content = f:read("*all")
  f:close()
  return content
end

return M

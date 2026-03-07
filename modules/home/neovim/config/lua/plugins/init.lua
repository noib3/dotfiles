for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/plugins/*.lua", true)) do
  local name = vim.fn.fnamemodify(path, ":t:r")
  if name ~= "init" then require("plugins." .. name) end
end

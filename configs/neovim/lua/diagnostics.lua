local vim_diagnostic = vim.diagnostic
local vim_cmd = vim.cmd

local signs = {
  error = '>>',
  warn = '??',
  info = '--',
  hint = '--',
}

local setup = function()
  for k, v in pairs(signs) do
    local name = ('DiagnosticSign%s'):format(k:gsub("^%l", string.upper))
    vim_cmd(('sign define %s text=%s texthl=%s'):format(name, v, name))
  end

  vim_diagnostic.config({
    severity_sort = true,
  })
end

return {
  setup = setup,
}

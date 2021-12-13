local vim_diagnostic = vim.diagnostic
local vim_cmd = vim.cmd

local signs = {
  DiagnosticSignError = { text = '>>' },
  DiagnosticSignWarn = { text = '--' },
  DiagnosticSignInfo = { text = '--' },
  DiagnosticSignHint = { text = '--' },
}

local setup = function()
  for k, sign in pairs(signs) do
    vim_cmd(('sign define %s text=%s texthl=%s'):format(k, sign.text, k))
  end

  vim_diagnostic.config({
    severity_sort = true,
  })
end

return {
  setup = setup,
}

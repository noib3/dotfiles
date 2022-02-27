local signs = {
  error = ">>",
  warn = "??",
  info = "--",
  hint = "--",
}

local setup = function()
  for k, v in pairs(signs) do
    local name = ("DiagnosticSign%s"):format(k:gsub("^%l", string.upper))
    vim.cmd(("sign define %s text=%s texthl=%s"):format(name, v, name))
  end

  vim.diagnostic.config({
    severity_sort = true,
  })
end

return {
  setup = setup,
}

local signs = {
  ["Error"] = ">>",
  ["Warn"] = "??",
  ["Info"] = "--",
  ["Hint"] = "--",
}

-- `:h diagnostic-highlights`
for name, sign in pairs(signs) do
  local hl = ("DiagnosticSign%s"):format(name)
  vim.cmd(("sign define %s text=%s texthl=%s"):format(hl, sign, hl))
end

-- `:h diagnostic-api`
vim.diagnostic.config({
  severity_sort = true,
})

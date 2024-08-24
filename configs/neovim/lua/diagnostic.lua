vim.diagnostic.config({
  -- Sort diagnostics by severity.
  severity_sort = true,

  -- Disable the sign column, I don't like the entire buffer shifting left and
  -- right.
  signs = false,

  -- Update diagnostics while in insert mode.
  update_in_insert = false,
})

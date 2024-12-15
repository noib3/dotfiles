local M = {}

--- The latest LSP progress message.
---@return string
function M.lsp_progress_component()
  return require("lsp-progress").progress()
end

M.render = function()
  return table.concat({
    M.lsp_progress_component(),
  })
end

vim.api.nvim_create_autocmd("User", {
  group = vim.api.nvim_create_augroup("noib3/statusline", { clear = true }),
  desc = "Redraw the LSP indexing progress indicator in the statusline",
  pattern = "LspProgressStatusUpdated",
  callback = function(_) vim.cmd.redrawstatus() end,
})

vim.opt.statusline = "%!v:lua.require'statusline'.render()"

return M

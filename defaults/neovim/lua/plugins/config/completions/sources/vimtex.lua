local M = {}

function M.getCompletionItems(prefix)
  -- Taken from [1].
  vim.api.nvim_call_function('vimtex#complete#omnifunc',{1, ''})

  -- Define your total completion items
  local items = vim.api.nvim_call_function('vimtex#complete#omnifunc',{0, prefix})
  return items
end

M.complete_item = {
  item = M.getCompletionItems
}

return M

-- [1]: https://github.com/nvim-lua/completion-nvim/issues/341#issuecomment-775459714

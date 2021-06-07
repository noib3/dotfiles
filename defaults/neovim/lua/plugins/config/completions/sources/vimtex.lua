local call_vim_function = vim.api.nvim_call_function

local M = {}

M.complete_item = {
  item = function (prefix)
    -- Taken from https://github.com/nvim-lua/completion-nvim/issues/341#issuecomment-775459714
    call_vim_function('vimtex#complete#omnifunc', {1, ''})

    local items = call_vim_function('vimtex#complete#omnifunc', {0, prefix})
    return items
  end
}

return M

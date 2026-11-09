local hop = require("hop")
local hunks = require("nvim_hunks")

hop.setup({})

vim.keymap.set("n", "f", function()
  local win = vim.api.nvim_get_current_win()
  local floats = hunks.open_floats(win)
  -- hop fills in the options left out, which its types require.
  ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
  if #floats == 0 then return hop.hint_words({}) end

  ---@diagnostic disable-next-line: missing-fields, param-type-mismatch
  hop.hint_words({
    multi_windows = true,
    windows_list = function() return vim.list_extend({ win }, floats) end,
  })

  local target = vim.api.nvim_get_current_win()
  for _, float in ipairs(floats) do
    if float == target then
      hunks.enter_float(float)
    else
      hunks.close_float(float)
    end
  end
end)

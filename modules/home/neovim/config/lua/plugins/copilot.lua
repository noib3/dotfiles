local is_enabled = false

if not is_enabled then return end

--- @param key string
local fallback = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

local suggestion = require("copilot.suggestion")

vim.api.nvim_set_keymap("i", "<Right>", "", {
  desc = "Select the entire Copilot suggestion or fallback",
  callback = function()
    if suggestion.is_visible() then
      suggestion.accept()
    else
      fallback("<Right>")
    end
  end,
})

-- By default, disable suggestions in markdown buffers (can be re-enabled
-- with `:Copilot suggestion toggle_auto_trigger`).
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function() vim.b.copilot_suggestion_auto_trigger = false end,
})

---@diagnostic disable-next-line: undefined-field
require("copilot").setup({
  suggestion = {
    auto_trigger = true,
  },
  filetypes = {
    markdown = function()
      local bufname = vim.api.nvim_buf_get_name(0)
      return not string.match(bufname, "claude%-prompt%-.*%.md$")
    end,
  },
  server = {
    type = "binary",
    -- custom_server_filepath = require("generated.tools").copilot,
  },
})

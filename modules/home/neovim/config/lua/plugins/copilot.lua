-- By default, disable suggestions in markdown buffers (can be re-enabled
-- with `:Copilot suggestion toggle_auto_trigger`).
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function() vim.b.copilot_suggestion_auto_trigger = false end,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    vim.api.nvim_set_hl(0, "CopilotSuggestion", { link = "Comment" })
  end,
})

---@diagnostic disable-next-line: undefined-field
require("copilot").setup({
  suggestion = {
    auto_trigger = true,
    keymap = {
      accept = "<Right>",
    },
    -- Don't trigger a new suggestion request on <Right> when no suggestion is
    -- visible, just pass the keystroke through.
    trigger_on_accept = false,
  },
  filetypes = {
    markdown = function()
      local bufname = vim.api.nvim_buf_get_name(0)
      return not string.match(bufname, "claude%-prompt%-.*%.md$")
    end,
  },
  server = {
    type = "binary",
    custom_server_filepath = vim.env.COPILOT_SERVER_PATH,
  },
})

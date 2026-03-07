--- @param key string
local fallback = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
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
        custom_server_filepath = require("generated.tools").copilot,
      },
    },
    config = function(_, opts)
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

      require("copilot").setup(opts)
    end,
  },
}

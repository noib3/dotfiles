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

      require("copilot").setup(opts)
    end
  }
}

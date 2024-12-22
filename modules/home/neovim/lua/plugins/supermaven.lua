--- @param key string
local fallback = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

return {
  {
    "supermaven-inc/supermaven-nvim",
    opts = {
      disable_keymaps = true,
    },
    config = function(_, opts)
      local preview = require("supermaven-nvim.completion_preview")

      vim.api.nvim_set_keymap("i", "<Right>", "", {
        desc = "Select the entire Supermaven suggestion or fallback",
        callback = function()
          if preview.has_suggestion() then
            preview.on_accept_suggestion()
          else
            fallback("<Right>")
          end
        end,
      })

      require("supermaven-nvim").setup(opts)
    end
  }
}

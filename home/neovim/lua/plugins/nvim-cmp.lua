--- @param key string
local fallback = function(key)
  local keys = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keys, "n", false)
end

return {
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
    },
    opts = function()
      local cmp = require("cmp")

      return {
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "path" },
        }),
      }
    end,
    config = function(_, opts)
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      vim.api.nvim_set_keymap("i", "<Tab>", "", {
        desc = "Select next completion or jump to next snippet or fallback",
        callback = function()
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback("<Tab>")
          end
        end,
      })

      cmp.setup(opts)
    end,
  }
}

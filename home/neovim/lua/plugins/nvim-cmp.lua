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
      "onsails/lspkind.nvim",
    },
    opts = function()
      local cmp = require("cmp")
      local lspkind = require("lspkind")

      return {
        experimental = {
          ghost_text = true,
        },
        completion = {
          autocomplete = false,
        },
        formatting = {
          fields = { "kind", "abbr", "menu" },
          format = lspkind.cmp_format({
            mode = "symbol_text",
          }),
        },
        sources = cmp.config.sources({
          { name = "crates" },
          { name = "nvim_lsp" },
          { name = "path" },
        }),
        view = {
          entries = {
            name = "custom",
            selection_order = "near_cursor",
          }
        }
      }
    end,

    config = function(_, opts)
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local neotab = require("neotab")

      vim.api.nvim_set_keymap("i", "<Tab>", "", {
        desc = "Select next completion or jump to next snippet or fallback",
        callback = function()
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.jumpable(1) then
            luasnip.jump(1)
          else
            neotab.tabout()
          end
        end,
      })

      vim.api.nvim_set_keymap("i", "<S-Tab>", "", {
        desc = "Select previous completion or jump to previous snippet or fallback",
        callback = function()
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback("<S-Tab>")
          end
        end,
      })

      vim.api.nvim_set_keymap("i", "<CR>", "", {
        desc = "Accept current completion or fallback",
        callback = function()
          if cmp.visible() and cmp.get_active_entry() then
            cmp.confirm({
              behavior = cmp.ConfirmBehavior.Replace,
              select = false,
            })
          else
            fallback("<CR>")
          end
        end,
      })

      cmp.setup(opts)
    end,
  }
}

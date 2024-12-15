return {
  {
    "Saghen/blink.cmp",
    version = "v0.7.6",
    opts = {
      keymap = {
        preset = "enter",
        ["<Tab>"] = { "snippet_forward", "select_next", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
      },
      completion = {
        keyword = {
          range = "prefix",
        },
        list = {
          selection = "manual",
        },
        menu = {
          auto_show = true,
          max_height = 7,
          draw = {
            columns = { { "label" } },
            treesitter = { "lsp" },
          }
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 50,
        },
      },
      sources = {
        default = { "lsp", "path" },
        providers = {
          lsp = {
            fallbacks = {},
            min_keyword_length = 3,
          },
          path = {
            fallbacks = {},
            min_keyword_length = 3,
          }
        },
      },
    },
    config = function(_, opts)
      vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { bold = true })
      require("blink.cmp").setup(opts)
    end,
  }
}

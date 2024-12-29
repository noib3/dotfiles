return {
  {
    "Saghen/blink.cmp",
    build = "cargo build --release --target-dir ./target",
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
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
      fuzzy = {
        prebuilt_binaries = { download = false },
      },
      sources = {
        default = { "lsp", "path" },
        providers = {
          buffer = {
            enabled = false,
          },
          lsp = {
            fallbacks = {},
          },
          path = {
            fallbacks = {},
          },
        },
      },
    },
    config = function(_, opts)
      require("blink.cmp").setup(opts)
      vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { bold = true })
      vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { background = "#7c6f64" })
      vim.api.nvim_set_hl(0, "BlinkCmpLabelDetail", { foreground = "#a89984" })
    end,
  }
}

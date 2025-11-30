return {
  {
    "Saghen/blink.cmp",
    build = "cargo build --release --target-dir ./target",
    dependencies = {
      {
        "noib3/colorful-menu.nvim",
        branch = "noib3",
      }
    },
    ---@type blink.cmp.Config
    opts = {
      keymap = {
        preset = "none",
        ["<CR>"] = { "accept", "fallback" },
        ["<Up>"] = { "select_next", "fallback" },
        ["<Down>"] = { "select_prev", "fallback" },
        ["<Tab>"] = { "select_next", "fallback" },
        ["<S-Tab>"] = { "select_prev", "fallback" },
      },
      completion = {
        keyword = {
          range = "prefix",
        },
        list = {
          max_items = 7,
          selection = {
            preselect = false,
            auto_insert = false,
          },
        },
        menu = {
          auto_show = true,
          draw = {
            columns = { { "label" }, { "label_detail" } },
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
      signature = {
        enabled = true,
        window = {
          show_documentation = false,
        }
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
      local blink = require("blink.cmp")
      local colorful_menu = require("colorful-menu")

      -- Highlight the completion labels with Tree-sitter.
      opts.completion.menu.draw.components = {
        label = {
          text = colorful_menu.blink_components_label_text,
          highlight = colorful_menu.blink_components_label_highlight,
        },
        label_detail = {
          text = colorful_menu.blink_components_detail_text,
          highlight = colorful_menu.blink_components_detail_highlight,
        }
      }

      blink.setup(opts)
      vim.api.nvim_set_hl(0, "BlinkCmpLabelMatch", { bold = true })
      vim.api.nvim_set_hl(0, "BlinkCmpMenuSelection", { background = "#7c6f64" })
      vim.api.nvim_set_hl(0, "BlinkCmpLabelDetail", { foreground = "#a89984" })
    end,
  }
}

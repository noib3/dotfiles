return {
  {
    "ellisonleao/gruvbox.nvim",
    cond = vim.env.COLORSCHEME == "gruvbox",
    config = function()
      local palette = require("generated.palette")
      local gruvbox = require("gruvbox")

      gruvbox.setup({
        -- https://github.com/sainnhe/gruvbox-material
        palette_overrides = {
          light1 = "#d4be98",
          bright_red = "#ea6962",
          bright_green = "#a9b665",
          bright_yellow = "#d8a657",
          bright_blue = "#7daea3",
          bright_purple = "#d3869b",
          bright_aqua = "#89b482",
          bright_orange = "#e78a4e",
        },
        overrides = {
          LspReferenceTarget = { bold = true },
          MsgArea = { bg = "#3a3735", fg = "#d4be98" },

          -- Selections.
          Visual = { bg = "#374141" },

          -- Statusline + split delimiters.
          StatusLine = { bg = "#3a3735", fg = "#d4be98", reverse = false },
          WinSeparator = { fg = "#3a3735" },

          -- Punctuation.
          ["@punctuation.delimiter"] = { fg = "#928374" },
          ["@punctuation.bracket"] = { fg = "#a89984" },

          -- Functions and function calls.
          ["@function"] = { fg = palette.bright.green },
          ["@function.call"] = { fg = palette.bright.green },
          ["@lsp.type.function"] = { fg = palette.bright.green },
          ["@lsp.type.method"] = { fg = palette.bright.green },

          -- Blink.
          BlinkCmpLabelMatch = { default = true },
        }
      })

      vim.o.background = "dark"
      vim.cmd.colorscheme("gruvbox")
    end,
  }
}

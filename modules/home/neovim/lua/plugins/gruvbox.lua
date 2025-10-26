local palette = require("generated.palette")

-- https://github.com/sainnhe/gruvbox-material (soft variant).
local overrides = {
  dark = {
    palette = {
      light1 = "#d4be98",
      bright_red = "#ea6962",
      bright_green = "#a9b665",
      bright_yellow = "#d8a657",
      bright_blue = "#7daea3",
      bright_purple = "#d3869b",
      bright_aqua = "#89b482",
      bright_orange = "#e78a4e",
    },
    hl_groups = {
      LspReferenceTarget = { bold = true },
      MsgArea = { bg = "#3a3735", fg = "#d4be98" },
      ColorColumn = { bg = "#3a3735" },

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
    },
  },
  light = {
    palette = {
      light0 = "#f2e5bc",
      light1 = "#654735",
      dark1 = "#654735",
      bright_red = "#ae5858",
      bright_green = "#6c782e",
      bright_yellow = "#b47109",
      bright_blue = "#45707A",
      bright_purple = "#945e80",
      bright_aqua = "#4c7a5d",
      bright_orange = "#c35e0a",
    },
    hl_groups = {
      LspReferenceTarget = { bold = true },
      MsgArea = { bg = "#dac9a5", fg = "#654735" },
      ColorColumn = { bg = "#dac9a5" },

      -- Selections.
      Visual = { bg = "#c2cfb4" },

      -- Statusline + split delimiters.
      StatusLine = { bg = "#dac9a5", fg = "#654735", reverse = false },
      WinSeparator = { fg = "#dac9a5" },

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
    },
  },
}

---@return GruvboxConfig
local config = function()
  local overrides =
      vim.opt.background:get() == "dark"
      and overrides.dark
      or overrides.light

  return {
    palette_overrides = overrides.palette,
    overrides = overrides.hl_groups,
  }
end

return {
  {
    "ellisonleao/gruvbox.nvim",
    cond = vim.env.COLORSCHEME == "gruvbox",
    config = function()
      local gruvbox = require("gruvbox")

      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        callback = function()
          if vim.g.colors_name ~= "gruvbox" then return end
          gruvbox.setup(config())
          vim.cmd.colorscheme("gruvbox")
        end
      })

      gruvbox.setup(config())
      vim.cmd.colorscheme("gruvbox")
    end,
  }
}

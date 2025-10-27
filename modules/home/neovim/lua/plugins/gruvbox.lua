-- https://github.com/sainnhe/gruvbox-material (soft variant).
local overrides = {
  dark = {
    palette = {
      dark0 = "#282828",
      dark0_soft = "#282828",
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
      -- Line numbers.
      LineNr = { fg = "#7c6f64" },

      -- Listchars.
      NonText = { fg = "#504945" },
      Whitespace = { fg = "#504945" },

      -- Selections.
      Visual = { bg = "#374141" },

      -- Statusline + split delimiters.
      StatusLine = { bg = "#3a3735", fg = "#d4be98", reverse = false },
      WinSeparator = { fg = "#3a3735" },
      MsgArea = { bg = "#3a3735", fg = "#d4be98" },
      ColorColumn = { bg = "#3a3735" },

      -- Floating windows.
      NormalFloat = { fg = "#d4be98", bg = "#3c3836" },

      -- Hovered symbol.
      LspReferenceTarget = { bold = true },

      -- Punctuation.
      ["@punctuation.delimiter"] = { fg = "#928374" },
      ["@punctuation.bracket"] = { fg = "#a89984" },

      -- Functions and function calls.
      ["@function"] = { fg = "#b8bb26" },
      ["@function.call"] = { link = "@function" },
      ["@function.method"] = { link = "@function" },
      ["@lsp.type.function"] = { link = "@function" },
      ["@lsp.type.method"] = { link = "@function" },

      -- Square brackets in Lua.
      ["@constructor.lua"] = { link = "@punctuation.bracket" },

      -- Blink.
      BlinkCmpLabelMatch = { default = true },

      -- Hop.
      HopNextKey = { fg = "#ee2a89", bold = true },
      HopNextKey1 = { fg = "#1fd2ee", bold = true },
      HopNextKey2 = { fg = "#2d8db3" },
      HopUnmatched = { fg = "#666666" },

      -- Incline.
      InclineNormal = { fg = "#ddc7a1", bg = "#3a3735" },
      InclineNormalNC = { fg = "#928374", bg = "#3a3735" },
    },
  },
  light = {
    palette = {
      light0 = "#f1e3b6",
      light1 = "#eddeb5",
      light2 = "#ebdbb2",
      light3 = "#e6d5ae",
      light4 = "#dac9a5",
      dark0 = "#42423c",
      dark1 = "#42423c",
      dark2 = "#42423c",
      dark3 = "#42423c",
      dark4 = "#42423c",
      faded_red = "#ae5858",
      faded_green = "#6c782e",
      faded_yellow = "#b47109",
      faded_blue = "#45707A",
      faded_purple = "#945e80",
      faded_aqua = "#4c7a5d",
      faded_orange = "#c35e0a",
      neutral_red = "#ae5858",
      neutral_green = "#6c782e",
      neutral_yellow = "#b47109",
      neutral_blue = "#45707A",
      neutral_purple = "#945e80",
      neutral_aqua = "#4c7a5d",
      light_red = "#ae5858",
      light_green = "#6c782e",
      light_aqua = "#4c7a5d",
      gray = "#928374",
    },
    hl_groups = {
      -- Line numbers.
      LineNr = { fg = "#c3ac8a" },

      -- Listchars.
      NonText = { fg = "#d0c0a0" },
      Whitespace = { fg = "#d0c0a0" },

      -- Selections.
      Visual = { bg = "#d9e0be" },

      -- Statusline + split delimiters.
      StatusLine = { bg = "#dac9a0", fg = "#494944", reverse = false },
      MsgArea = { bg = "#dac9a0", fg = "#3d3d39" },
      ColorColumn = { link = "StatusLine" },
      WinSeparator = { fg = "#dac9a0" },

      -- Floating windows.
      NormalFloat = { bg = "#dac9a5" },
      FloatBorder = { fg = "#c3ac8a" },

      -- Hovered symbol.
      LspReferenceTarget = { bold = true },

      -- Punctuation.
      ["@punctuation.delimiter"] = { fg = "#504b47" },
      ["@punctuation.bracket"] = { fg = "#756a61" },

      -- Functions and function calls.
      ["@function"] = { fg = "#809a00" },
      ["@function.call"] = { link = "@function" },
      ["@function.method"] = { link = "@function" },
      ["@lsp.type.function"] = { link = "@function" },
      ["@lsp.type.method"] = { link = "@function" },

      -- Square brackets in Lua.
      ["@constructor.lua"] = { link = "@punctuation.bracket" },

      -- Blink.
      BlinkCmpLabelMatch = { default = true },

      -- Fzf.
      FzfLuaBorder = { link = "FloatBorder" },

      -- Hop.
      HopNextKey = { fg = "#c8569f", bold = true },
      HopNextKey1 = { fg = "#2fa2bb", bold = true },
      HopNextKey2 = { fg = "#55b3c8" },
      HopUnmatched = { fg = "#9f9f95" },

      -- Incline.
      InclineNormal = { fg = "#50504a", bg = "#dac9a5" },
      InclineNormalNC = { fg = "#8b8b81", bg = "#dac9a5" },
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

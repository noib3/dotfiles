local rq_palette = require("colorscheme").palette

---@param hex1  string
---@param hex2  string
---@param a  number
local mix = function(hex1, hex2, a)
  local to_rgb = function(hex)
    local hexfmt = "[%a|%d][%a|%d]"
    for r, g, b in hex:gmatch(("#(%s)(%s)(%s)"):format(hexfmt, hexfmt, hexfmt)) do
      return {
        r = tonumber(r, 16),
        g = tonumber(g, 16),
        b = tonumber(b, 16),
      }
    end
  end

  local lerp = function(x, y)
    return a * x + (1 - a) * y
  end

  local rgb1 = to_rgb(hex1)
  local rgb2 = to_rgb(hex2)

  return ("#%x%x%x"):format(
    lerp(rgb1.r, rgb2.r),
    lerp(rgb1.b, rgb2.b),
    lerp(rgb1.g, rgb2.g)
  )
end

local highlights = {
  -- Basic highlight groups that I want to be set for every colorscheme.
  ["*"] = {
    { name = "Normal", guibg = "NONE" },
    -- { name = 'Comment', gui = 'italic' },
    { name = "texComment", link = "Comment" },

    -- Text displayed on a closed fold.
    { name = "Folded", gui = "italic" },

    -- Part of the tabline not filled by cokeline.
    {
      name = "TabLineFill",
      clear = true,
      guibg = "NONE",
    },

    -- Variable references reported by the LSP.
    {
      name = "LspReferenceRead",
      guibg = rq_palette.bright.black,
    },
    {
      name = "LspReferenceText",
      guibg = rq_palette.bright.black,
    },
    {
      name = "LspReferenceWrite",
      guibg = rq_palette.bright.black,
    },

    -- Matching characters in `nvim-cmp` results.
    {
      name = "CmpItemAbbrMatch",
      guifg = rq_palette.normal.blue,
    },
    {
      name = "CmpItemAbbrMatchFuzzy",
      guifg = rq_palette.normal.blue,
    },

    -- Diagnostic errors, warnings, infos and hints reported by LSPs and other
    -- sources.
    {
      name = "DiagnosticError",
      guifg = rq_palette.normal.red,
      guibg = mix(rq_palette.normal.red, rq_palette.primary.background, 0.125),
    },
    {
      name = "DiagnosticWarn",
      guifg = rq_palette.normal.yellow,
      guibg = mix(
        rq_palette.normal.yellow,
        rq_palette.primary.background,
        0.125
      ),
    },
    {
      name = "DiagnosticInfo",
      guifg = rq_palette.normal.blue,
    },
    {
      name = "DiagnosticHint",
      link = "DiagnosticInfo",
      clear = true,
    },

    -- Words not recognized by the spellchecker.
    {
      name = "SpellBad",
      gui = "undercurl",
      guifg = rq_palette.normal.red,
    },

    -- Column separating vertically split windows.
    {
      name = "VertSplit",
      clear = true,
      gui = "NONE",
      guifg = { "ColorColumn", "bg" },
      guibg = "NONE",
    },

    -- `fzf` and `vim-floaterm`'s borders.
    {
      name = "FzfBorder",
      link = "CursorColumn",
    },
    {
      name = "FloatermBorder",
      link = "CursorColumn",
    },
  },

  -- Highlight groups specific to the `afterglow` colorscheme.
  afterglow = {
    {
      name = "SpellCap",
      gui = "NONE",
      guifg = rq_palette.bright.yellow,
    },
    {
      name = "Visual",
      guifg = rq_palette.normal.white,
      guibg = rq_palette.bright.black,
    },
  },

  -- Highlight groups specific to the `gruvbox` colorscheme.
  gruvbox = {
    {
      name = "SpellCap",
      gui = "NONE",
      guifg = rq_palette.normal.yellow,
    },
    {
      name = "FzfBorder",
      guifg = rq_palette.bright.white,
    },
  },

  -- Highlight groups specific to the `tokyonight` colorscheme.
  tokyonight = {
    {
      name = "ColorColumn",
      guibg = "#24283b",
    },

    {
      name = "SignColumn",
      guibg = "NONE",
    },

    -- Even though this exact highlight is already defined in the `*` part I
    -- still have to add it here because `ColorScheme *` seems to trigger
    -- *before* `ColorScheme tokyonight`, so the `ColorColumn`'s background
    -- value is not the same. There should be a way to link the individual
    -- attributes of highlight groups (e.g. VertSplit fg linked to ColorColumn
    -- bg).
    {
      name = "VertSplit",
      clear = true,
      gui = "NONE",
      guifg = { "ColorColumn", "bg" },
      guibg = "NONE",
    },

    -- Non current windows.
    {
      name = "NormalNC",
      guibg = "NONE",
    },

    -- Floating windows.
    {
      name = "NormalFloat",
      guibg = "#2c3046",
    },

    -- Popup menu.
    {
      name = "Pmenu",
      clear = true,
      link = "NormalFloat",
    },

    -- Status line for current and non current windows.
    {
      name = "StatusLine",
      gui = "NONE",
      guifg = rq_palette.normal.yellow,
      guibg = { "ColorColumn", "bg" },
    },
    {
      name = "StatusLineNC",
      gui = "NONE",
      guifg = { "Comment", "fg" },
      guibg = { "ColorColumn", "bg" },
    },
  },

  vscode = {
    {
      name = "Comment",
      guifg = "#5a5a5a",
    },
    {
      name = "ColorColumn",
      guibg = "#252526",
    },

    -- Status line for current and non current windows.
    {
      name = "StatusLine",
      gui = "NONE",
      guifg = { "Normal", "fg" },
      guibg = { "ColorColumn", "bg" },
    },
    {
      name = "StatusLineNC",
      gui = "NONE",
      guifg = { "Comment", "fg" },
      guibg = { "ColorColumn", "bg" },
    },
  },
}

local setup = function()
  for colorscheme, _ in pairs(highlights) do
    _G.augroup({
      name = "highlights_" .. colorscheme,
      autocmds = {
        {
          event = "ColorScheme",
          pattern = colorscheme,
          cmd = ('lua require("globalutils").apply_highlights("%s")'):format(
            colorscheme
          ),
        },
      },
    })
  end
end

return {
  highlights = highlights,
  setup = setup,
}

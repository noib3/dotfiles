local rq_palette = require('colorscheme').palette

local highlights = {
  -- Basic highlight groups that I want to be set for every colorscheme.
  ['*'] = {
    { name = 'Normal', guibg = 'NONE' },
    { name = 'Comment', gui = 'italic' },
    { name = 'texComment', link = 'Comment' },

    -- Part of the tabline not filled by cokeline.
    {
      name = 'TabLineFill',
      clear = true,
      link = 'ColorColumn',
    },

    -- Variable references reported by the LSP.
    {
      name = 'LspReferenceRead',
      guibg = rq_palette.bright.black,
    },
    {
      name = 'LspReferenceText',
      guibg = rq_palette.bright.black,
    },
    {
      name = 'LspReferenceWrite',
      guibg = rq_palette.bright.black,
    },

    -- Matching characters in `nvim-cmp` results.
    {
      name = 'CmpItemAbbrMatch',
      guifg = rq_palette.normal.blue,
    },
    {
      name = 'CmpItemAbbrMatchFuzzy',
      guifg = rq_palette.normal.blue,
    },

    -- Diagnostic errors, warnings, infos and hints reported by LSPs and other
    -- sources.
    -- {
    --   name = 'DiagnosticError',
    --   gui = 'bold',
    --   guifg = rq_palette.normal.red,
    -- },
    -- {
    --   name = 'DiagnosticWarn',
    --   gui = 'bold',
    --   guifg = rq_palette.normal.yellow,
    -- },
    -- {
    --   name = 'DiagnosticInfo',
    --   guifg = rq_palette.normal.white,
    -- },
    -- {
    --   name = 'DiagnosticHint',
    --   link = 'DiagnosticInfo',
    -- },

    -- Words not recognized by the spellchecker.
    {
      name = 'SpellBad',
      gui = 'undercurl',
      guifg = rq_palette.normal.red,
    },

    -- Column separating vertically split windows.
    {
      name = 'VertSplit',
      clear = true,
      gui = 'NONE',
      guifg = { 'ColorColumn', 'bg' },
      guibg = 'NONE',
    },

    -- `fzf` and `vim-floaterm`'s borders.
    {
      name = 'FzfBorder',
      link = 'CursorColumn',
    },
    {
      name = 'FloatermBorder',
      link = 'CursorColumn',
    },
  },

  -- Highlight groups specific to the `afterglow` colorscheme.
  afterglow = {
    {
      name = 'SpellCap',
      gui = 'NONE',
      guifg = rq_palette.bright.yellow,
    },
    {
      name = 'Visual',
      guifg = rq_palette.normal.white,
      guibg = rq_palette.bright.black,
    },
  },

  -- Highlight groups specific to the `gruvbox` colorscheme.
  gruvbox = {
    {
      name = 'SpellCap',
      gui = 'NONE',
      guifg = rq_palette.normal.yellow,
    },
    {
      name = 'FzfBorder',
      guifg = rq_palette.bright.white,
    },
  },

  -- Highlight groups specific to the `onedark` colorscheme.
  onedark = {
    {
      name = 'SpellCap',
      gui = 'NONE',
      guifg = rq_palette.bright.yellow,
    },
    {
      name = 'LspReferenceRead',
      guibg = rq_palette.bright.black,
    },
    {
      name = 'LspReferenceText',
      guibg = rq_palette.bright.black,
    },
    {
      name = 'LspReferenceWrite',
      guibg = rq_palette.bright.black,
    },
    {
      name = 'FzfBorder',
      guifg = rq_palette.bright.white,
    },
  },

  -- Highlight groups specific to the `tokyonight` colorscheme.
  tokyonight = {
    {
      name = 'ColorColumn',
      guibg = '#24283b',
    },

    {
      name = 'SignColumn',
      guibg = 'NONE',
    },

    -- Even though this exact highlight is already defined in the `*` part I
    -- still have to add it here because `ColorScheme *` seems to trigger
    -- *before* `ColorScheme tokyonight`, so the `ColorColumn`'s background
    -- value is not the same. There should be a way to link the individual
    -- attributes of highlight groups (e.g. VertSplit fg linked to ColorColumn
    -- bg).
    {
      name = 'VertSplit',
      clear = true,
      gui = 'NONE',
      guifg = { 'ColorColumn', 'bg' },
      guibg = 'NONE',
    },

    -- Non current windows.
    {
      name = 'NormalNC',
      guibg = 'NONE',
    },

    -- Floating windows.
    {
      name = 'NormalFloat',
      guibg = '#2c3046',
    },

    -- Popup menu.
    {
      name = 'Pmenu',
      clear = true,
      link = 'NormalFloat',
    },

    -- Status line for current and non current windows.
    {
      name = 'StatusLine',
      gui = 'NONE',
      guifg = rq_palette.normal.yellow,
      guibg = { 'ColorColumn', 'bg' },
    },
    {
      name = 'StatusLineNC',
      gui = 'NONE',
      guifg = { 'Comment', 'fg' },
      guibg = { 'ColorColumn', 'bg' },
    },
  },
}

local setup = function()
  for colorscheme, _ in pairs(highlights) do
    _G.augroup({
      name = 'highlights_' .. colorscheme,
      autocmds = {{
        event = 'ColorScheme',
        pattern = colorscheme,
        cmd =
          ('lua require("globalutils").apply_highlights("%s")')
            :format(colorscheme)
      }}
    })
  end
end

return {
  highlights = highlights,
  setup = setup,
}

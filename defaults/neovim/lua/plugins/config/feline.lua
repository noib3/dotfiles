local fn = vim.fn
local g = vim.g

local colors = {
  red     = g.terminal_color_1;
  green   = g.terminal_color_2;
  yellow  = g.terminal_color_3;
  blue    = g.terminal_color_4;
  magenta = g.terminal_color_5;
  cyan    = g.terminal_color_6;
  fg      = g.terminal_color_7,
  bg      = '#2c323c',
  gray    = '#5c6073',
}

local file_info = {
  provider = 'file_info',
  enabled = function()
    return fn.empty(fn.expand('%:t')) ~= 1
  end,
  hl = function()
    local val = {}
    val.fg = colors.fg
    val.bg = colors.bg
    return val
  end,
  left_sep = ' ',
}

local file_encoding = {
  provider = 'file_encoding',
  enabled = function()
    return fn.empty(fn.expand('%:t')) ~= 1
  end,
  hl = {
    fg = colors.gray,
    bg = colors.bg,
    style = 'bold',
  },
  left_sep = ' ',
}

local git_branch = {
  provider = 'git_branch',
  icon = ' ',
  hl = {
    fg = colors.magenta,
    bg = colors.bg,
    style = 'bold',
  },
  right_sep = ' ',
}

local components = {
  left = {
    active = {file_info, file_encoding},
    inactive = {file_info, file_encoding},
  },

  mid = {
    active = {},
    inactive = {},
  },

  right = {
    active = {git_branch},
    inactive = {git_branch},
  },
}

local properties = {
  force_inactive = {
    filetypes = {
      'NvimTree',
      'dbui',
      'packer',
      'startify',
      'fugitive',
      'fugitiveblame',
    },
    buftypes = {'terminal'},
    bufnames = {},
  }
}

require('feline').setup({
  default_bg = colors.bg,
  components = components,
  properties = properties,
})

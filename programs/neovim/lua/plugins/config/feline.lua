local get_icon = require('nvim-web-devicons').get_icon

local fn = vim.fn
local g = vim.g
local b = vim.b

local colors = {
  bg = fn.synIDattr(fn.hlID('ColorColumn'), 'bg'),
  red = g.terminal_color_1,
  green = g.terminal_color_2,
  yellow = g.terminal_color_3,
  blue = g.terminal_color_4,
  magenta = g.terminal_color_5,
  cyan = g.terminal_color_6,
  fg = g.terminal_color_7,
  gray = fn.synIDattr(fn.hlID('Comment'), 'fg'),
}

local buffer_not_empty = function()
  return fn.empty(fn.expand('%:t')) ~= 1
end

local get_devicon = function()
  local filename = fn.expand('%:t')
  local extension = fn.expand('%:e')
  local icon, iconhl = get_icon(filename, extension, {default = true})
  return {
    icon = icon,
    fg = fn.synIDattr(fn.hlID(iconhl), 'fg'),
  }
end

local file_icon = {
  provider = function() return get_devicon().icon end,
  enabled = buffer_not_empty,
  hl = function()
    return {
      fg = get_devicon().fg,
      bg = colors.bg,
    }
  end,
  left_sep = ' ',
  right_sep = ' ',
}

local file_name = {
  provider = function()
    return fn.expand('%:t')
  end,
  enabled = buffer_not_empty,
  hl = {
    fg = colors.fg,
    bg = colors.bg,
  },
  right_sep = '  ',
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
  -- right_sep = function()
  --   return (
  --     b.gitsigns_status_dict.added
  --     or b.gitsigns_status_dict.changed
  --     or b.gitsigns_status_dict.removed
  --   ) and ' ' or ''
  -- end
}

local git_diff_added = {
  provider = 'git_diff_added',
  icon = ' +',
  hl = {
    fg = colors.green,
    bg = colors.bg,
  },
}

local git_diff_changed = {
  provider = 'git_diff_changed',
  icon = ' ~',
  hl = {
    fg = colors.yellow,
    bg = colors.bg,
  },
}

local git_diff_removed = {
  provider = 'git_diff_removed',
  icon = ' -',
  hl = {
    fg = colors.red,
    bg = colors.bg,
  },
}

local space = {
  provider = function() return ' ' end,
  -- provider = function()
  --   return (
  --     b.gitsigns_status_dict.added
  --     or b.gitsigns_status_dict.changed
  --     or b.gitsigns_status_dict.removed
  --   ) and ' ' or ''
 -- end,
  hl = {
    fg = 'NONE',
    bg = colors.bg,
  },
}

local components = {
  left = {
    active = {
      file_icon,
      file_name,
      file_encoding,
    },
    inactive = {
      file_icon,
      file_name,
      file_encoding,
    },
  },

  mid = {
    active = {},
    inactive = {},
  },

  right = {
    active = {
      git_branch,
      git_diff_added,
      git_diff_changed,
      git_diff_removed,
      space,
    },
    inactive = {
      git_branch,
      git_diff_added,
      git_diff_changed,
      git_diff_removed,
      space,
    },
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

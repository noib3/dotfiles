local g = vim.g
local gls = require('galaxyline').section
local condition = require('galaxyline.condition')

local colors = {
  NONE = "NONE",
  fg = g.terminal_color_7,
  bg = '#2c323c',
  gray = '#5c6073',
  red = g.terminal_color_1;
  green = g.terminal_color_2;
  yellow = g.terminal_color_3;
  blue = g.terminal_color_4;
  magenta = g.terminal_color_5;
  cyan = g.terminal_color_6;
}

gls.left[1] = {
  space = {
    provider = function() return ' ' end,
    highlight = {colors.fg, colors.bg}
  }
}

gls.left[2] = {
  FileIcon = {
    provider = 'FileIcon',
    condition = condition.buffer_not_empty,
    highlight = {require('galaxyline.provider_fileinfo').get_file_icon_color, colors.bg}
  }
}

gls.left[3] = {
  FileName = {
    provider = 'FileName',
    condition = condition.buffer_not_empty,
    highlight = {colors.fg, colors.bg}
  }
}

gls.left[4] = {
  spaces = {
    provider = function() return '  ' end,
    highlight = {colors.fg, colors.bg}
  }
}

gls.left[5] = {
  FileEncode = {
    provider = 'FileEncode',
    highlight = {colors.gray, colors.bg, 'bold'}
  }
}

gls.left[6] = {
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = {colors.red,colors.bg}
  }
}
gls.left[7] = {
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {colors.yellow,colors.bg},
  }
}


gls.mid[1] = {
  space = {
    provider = function() return ' ' end,
    highlight = {'NONE', colors.bg}
  }
}

gls.right[1] = {
  GitBranch = {
    provider = 'GitBranch',
    condition = condition.check_git_workspace,
    icon = '  ',
    highlight = {colors.magenta, colors.bg, 'bold'}
  }
}

gls.right[2] = {
  DiffAdd = {
    provider = 'DiffAdd',
    condition = condition.hide_in_width,
    icon = '  ',
    highlight = {colors.green,colors.bg},
  }
}

gls.right[3] = {
  DiffModified = {
    provider = 'DiffModified',
    condition = condition.hide_in_width,
    icon = ' 柳',
    highlight = {colors.orange,colors.bg},
  }
}

gls.right[4] = {
  DiffRemove = {
    provider = 'DiffRemove',
    condition = condition.hide_in_width,
    icon = '  ',
    highlight = {colors.red,colors.bg},
  }
}

gls.right[5] = {
  space = {
    provider = function() return ' ' end,
    highlight = {colors.fg, colors.bg}
  }
}

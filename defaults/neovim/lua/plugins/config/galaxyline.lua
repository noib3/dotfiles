local gls = require('galaxyline').section
local condition = require('galaxyline/condition')

local format = string.format

local fn = vim.fn
local g = vim.g

local colors = {
  fg = g.terminal_color_7,
  bg = '#2c323c',
  gray = '#5c6073',
  red = g.terminal_color_1;
  green = g.terminal_color_2;
  yellow = g.terminal_color_3;
  blue = g.terminal_color_4;
  magenta = g.terminal_color_5;
  cyan = g.terminal_color_6;
  NONE = 'NONE',
}

local add_left = function(t)
  table.insert(gls.left, t)
end

local add_right = function(t)
  table.insert(gls.right, t)
end

local cmd_fmt = [[git --no-optional-locks status --porcelain=2 --branch | rg '^%s.*$' | wc -l]]

local git_status = {
  get_staged = function()
    if not condition.check_git_workspace() then
      return 0
    end
    return fn.system(cmd_fmt:format('1 (M|A)'))
  end,
}

local function get_git_staged()
  local staged_files = 1
  return format('%ss', staged_files)
end

local function get_git_untracked()
  local untracked_files = 1
  return format('%sa', untracked_files)
end

local function get_git_modified()
  local modified_files = 1
  return format('%sm', modified_files)
end

local function get_git_renamed()
  local renamed_files = 1
  return format('%sr', renamed_files)
end

local function get_git_deleted()
  local deleted_files = 1
  return format('%sd', deleted_files)
end

condition['git_staged'] = function()
  if not condition.check_git_workspace() then
    return false
  end
  return true
end

condition['git_untracked'] = function()
  if not condition.check_git_workspace() then
    return false
  end
  return true
end

condition['git_modified'] = function()
  if not condition.check_git_workspace() then
    return false
  end
  return true
end

condition['git_renamed'] = function()
  if not condition.check_git_workspace() then
    return false
  end
  return true
end

condition['git_deleted'] = function()
  if not condition.check_git_workspace() then
    return false
  end
  return true
end

condition['check_git_status'] = function()
  return condition.git_staged()
    or condition.git_untracked()
    or condition.git_modified()
    or condition.git_renamed()
    or condition.git_deleted()
end

add_left({
  Space = {
    provider = function() return ' ' end,
    highlight = {colors.fg, colors.bg},
  }
})

add_left({
  FileIcon = {
    provider = 'FileIcon',
    condition = condition.buffer_not_empty,
    highlight = {
      require('galaxyline/provider_fileinfo').get_file_icon_color,
      colors.bg,
    },
  }
})

add_left({
  FileName = {
    provider = 'FileName',
    condition = condition.buffer_not_empty,
    highlight = {colors.fg, colors.bg},
  }
})

add_left({
  Spaces = {
    provider = function() return '  ' end,
    highlight = {colors.fg, colors.bg},
  }
})

add_left({
  FileEncode = {
    provider = 'FileEncode',
    highlight = {colors.gray, colors.bg, 'bold'},
  }
})

add_left({
  DiagnosticError = {
    provider = 'DiagnosticError',
    icon = '  ',
    highlight = {colors.red, colors.bg},
  },
})

add_left({
  DiagnosticWarn = {
    provider = 'DiagnosticWarn',
    icon = '  ',
    highlight = {colors.yellow, colors.bg},
  }
})

add_right({
  GitBranch = {
    provider = 'GitBranch',
    condition = condition.check_git_workspace,
    icon = '  ',
    highlight = {colors.magenta, colors.bg, 'bold'},
  }
})

add_right({
  GitStatusSpace = {
    provider = function() return ' ' end,
    condition = condition.check_git_status,
    highlight = {colors.fg, colors.bg},
  }
})

add_right({
  GitStatusLeftBracket = {
    provider = function() return '(' end,
    condition = condition.check_git_status,
    highlight = {colors.magenta, colors.bg, 'bold'},
  }
})

add_right({
  GitStatusStaged = {
    provider = function() return format('%ss', git_status.get_staged()) end,
    condition = function() return git_status.get_staged() ~= 0 end,
    -- provider = get_git_staged,
    -- condition = condition.git_staged,
    highlight = {colors.blue, colors.bg, 'bold'},
  }
})

add_right({
  GitStatusUntracked = {
    provider = get_git_untracked,
    condition = condition.git_untracked,
    highlight = {colors.green, colors.bg, 'bold'},
  }
})

add_right({
  GitStatusModified = {
    provider = get_git_modified,
    condition = condition.git_modified,
    highlight = {colors.yellow, colors.bg, 'bold'},
  }
})

add_right({
  GitStatusRenamed = {
    provider = get_git_renamed,
    condition = condition.git_renamed,
    highlight = {colors.magenta, colors.bg, 'bold'},
  }
})

add_right({
  GitStatusDeleted = {
    provider = get_git_deleted,
    condition = condition.git_deleted,
    highlight = {colors.red, colors.bg, 'bold'},
  }
})

add_right({
  GitStatusRightBracket = {
    provider = function() return ')' end,
    condition = condition.check_git_status,
    highlight = {colors.magenta, colors.bg, 'bold'},
  }
})

add_right({
  Space = {
    provider = function() return ' ' end,
    highlight = {colors.fg, colors.bg}
  }
})

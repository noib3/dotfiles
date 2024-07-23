local devicons = require("nvim-web-devicons")

local colorscheme = vim.g.colors_name

--- Returns the background color in "#aabbcc" format for the given highlight
--- group.
---
--- @param hl_group string
--- @return string
local hl_bg = function(hl_group)
  return vim.fn.synIDattr(
    vim.fn.synIDtrans(vim.api.nvim_get_hl_id_by_name(hl_group)),
    "bg"
  )
end

--- Returns the foreground color in hex format for the given highlight
--- group.
---
--- @param hl_group string
--- @return string
local hl_fg = function(hl_group)
  return vim.fn.synIDattr(
    vim.fn.synIDtrans(vim.api.nvim_get_hl_id_by_name(hl_group)),
    "fg"
  )
end

local HlGroup = {}
HlGroup.__index = HlGroup

function HlGroup:new(opts)
  local this = setmetatable({}, HlGroup)

  this.name = opts.name
  this.fg = opts.fg
  this.bg = opts.bg
  this.ns = opts.ns or 0

  vim.api.nvim_set_hl(this.ns, this.name, {
    fg = this.fg,
    bg = this.bg,
    force = true,
  })

  return this
end

-- The default highlight group for the winbar.
local WinBar = HlGroup:new({
  name = "WinBar",
  fg = hl_fg("Comment"),
  bg = hl_bg("WinBar"),
})

-- The highlight group used to display the file path in the winbar, i.e.
-- `/path/to` in `/path/to/file.txt`.
local WinBarPath = HlGroup:new({
  name = "WinBarPath",
  fg = hl_fg("Comment"),
  bg = hl_bg("WinBar"),
})

-- The highlight group used to display the file name in the winbar, i.e.
-- `file.txt` in `/path/to/file.txt`.
local WinBarFileName = HlGroup:new({
  name = "WinBarFileName",
  fg = hl_fg("Label"),
  bg = hl_bg("WinBar"),
})

local highlights = {
  WinBar = WinBar,
  WinBarPath = WinBarPath,
  WinBarFileName = WinBarFileName,
}

return highlights

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
  this.bold = opts.bold
  this.ns = opts.ns or 0

  vim.api.nvim_set_hl(this.ns, this.name, {
    fg = this.fg,
    bg = this.bg,
    bold = this.bold,
    force = true,
  })

  return this
end

local highlights = {
  fg_of = hl_fg,
  bg_of = hl_bg,
  HlGroup = HlGroup,
}

return highlights

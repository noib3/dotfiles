--- Returns the background color in hex format for the given highlight group.
---
--- @param hl_group string
--- @return string
local bg_of = function(hl_group)
  return vim.fn.synIDattr(
    vim.fn.synIDtrans(vim.api.nvim_get_hl_id_by_name(hl_group)),
    "bg"
  )
end

--- Returns the foreground color in hex format for the given highlight group.
---
--- @param hl_group string
--- @return string
local fg_of = function(hl_group)
  return vim.fn.synIDattr(
    vim.fn.synIDtrans(vim.api.nvim_get_hl_id_by_name(hl_group)),
    "fg"
  )
end

return {
  fg_of = fg_of,
  bg_of = bg_of,
}

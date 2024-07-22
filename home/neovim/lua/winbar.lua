local devicons = require("nvim-web-devicons")

local sep = "/"

--- Returns the file type icon for the given buffer.
--- @param bufnr number
--- @return string
local buf_icon = function(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local extension = vim.fn.fnamemodify(filepath, ":e")
  return devicons.get_icon(filepath, extension, { default = true })
end

--- Returns the full path of the project root for the given buffer.
--- @param bufnr number
--- @return string
local buf_project_root = function(bufnr)
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  local project_root = vim.fs.root(filepath, { ".git", "Cargo.toml" })
  return project_root or vim.fs.dirname(filepath)
end

--- Returns whether the winbar should be displayed for the given buffer.
---
--- @param bufnr number
--- @return boolean
local buf_should_display_winbar = function(bufnr)
  return
      vim.bo[bufnr].buftype == ""
      and vim.api.nvim_buf_get_name(bufnr) ~= ""
      and not vim.api.nvim_win_get_config(0).zindex
end

--- Wraps the text in the given highlight group according to the statusline
--- highlight format.
---
--- @param text string
--- @param hl_group string
--- @return string
local highlight = function(text, hl_group)
  return ("%%#%s#%s"):format(hl_group, text)
end

local M = {}

--- Renders the winbar.
M.render = function()
  local bufnr = vim.api.nvim_get_current_buf()

  local root_path = buf_project_root(bufnr)

  local buf_abs_path = vim.api.nvim_buf_get_name(bufnr)
  local buf_rel_path = buf_abs_path:gsub("^" .. root_path .. sep, "")

  -- The path of the buffer relative to the project root, without the root
  -- and the filename.
  local buf_intermediate_path = vim.fs.dirname(buf_rel_path)

  local intermediates = vim.iter(vim.split(buf_intermediate_path, sep)):map(
    function(dirname)
      return dirname
    end
  )

  local root_name = root_path:match("([^/]+)$")
  local intermediate_dirs = sep .. intermediates:join(sep) .. sep
  local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")

  return table.concat({
    highlight(" ", "Normal"),
    highlight(root_name, "Title"),
    highlight(intermediate_dirs, "Comment"),
    highlight(filename, "Debug"),
    -- highlight(" ", "Normal"),
    -- highlight(buf_icon(bufnr), "Normal"),
  })
end

vim.api.nvim_create_autocmd("BufWinEnter", {
  group = vim.api.nvim_create_augroup("noib3/winbar", { clear = true }),
  desc = "Render the winbar",
  callback = function(args)
    if buf_should_display_winbar(args.buf) then
      vim.wo.winbar = "%{%v:lua.require'winbar'.render()%}"
    end
  end,
})

return M

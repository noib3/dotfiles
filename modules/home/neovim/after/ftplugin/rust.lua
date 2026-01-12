---Parses the `rustfmt.toml` file for the given buffer's project and returns
---its `max_width` setting, if any.
---@param bufnr integer
---@return integer|nil
local rustfmt_max_width = function(bufnr)
  local rustfmt = vim.fs.find("rustfmt.toml", {
    path = vim.api.nvim_buf_get_name(bufnr),
    upward = true,
    stop = vim.env.HOME,
  })[1]

  if not rustfmt then return nil end

  for _, line in ipairs(vim.fn.readfile(rustfmt)) do
    local max_width = line:match("^%s*max_width%s*=%s*(%d+)")
    if max_width then return tonumber(max_width) end
  end

  return nil
end

---Sets the `textwidth` option for the given buffer based on its project's
---`rustfmt.toml`'s `max_width` setting.
---@param bufnr integer
---@return nil
local set_textwidth_from_rustfmt = function(bufnr)
  local max_width = rustfmt_max_width(bufnr)
  if not max_width then return end
  vim.api.nvim_set_option_value(
    "textwidth",
    max_width,
    { scope = "local", buf = bufnr }
  )
end

-- Update the `textwidth` of all Rust buffers when a `rustfmt.toml` is saved.
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = "rustfmt.toml",
  callback = function()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].filetype == "rust" then
        set_textwidth_from_rustfmt(buf)
      end
    end
  end,
})

vim.opt_local.formatoptions:append("c")
set_textwidth_from_rustfmt(0)

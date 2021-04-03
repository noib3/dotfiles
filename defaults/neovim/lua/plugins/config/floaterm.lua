local g = vim.g
local map = vim.api.nvim_set_keymap

g.floaterm_title = ''
g.floaterm_width = 0.8
g.floaterm_height = 0.8
g.floaterm_opener = 'edit'
g.floaterm_autoclose = 2

map('n', 'll', ':lua open_lf_select_current_file()<CR>', { silent = true })
map('n', 'lg', ':FloatermNew lazygit<CR>', { silent = true })

function open_lf_select_current_file()
  local filename = vim.api.nvim_buf_get_name(0)
  local cmd = "FloatermNew lf"
  if filename ~= "" then
    cmd = cmd .. (" -command 'select %s'"):format(filename)
  end
  vim.cmd(cmd)
end

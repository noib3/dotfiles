local tbl_concat = table.concat

local vim_keymap = vim.api.nvim_set_keymap
local vim_local_keymap = vim.api.nvim_buf_set_keymap
local vim_fn = vim.fn
local vim_cmd = vim.cmd
local vim_map = vim.tbl_map

_G.OS =
  vim_fn.has('win32') == 0
  and vim_fn.system('uname'):gsub('[\r\n]', '')
   or 'Windows'

---Returns the color set by the current colorscheme for the `attr` attribute of
---the `hlgroup_name` highlight group in hexadecimal format.
---@param hlgroup_name  string
---@param attr  '"fg"' | '"bg"'
---@return string
local get_hex = function(hlgroup_name, attr)
  local hlgroup_ID = vim_fn.synIDtrans(vim_fn.hlID(hlgroup_name))
  local hex = vim_fn.synIDattr(hlgroup_ID, attr)
  return hex ~= '' and hex or 'NONE'
end

---@param colorscheme  string
local apply_highlights = function(colorscheme)
  for _, hi in pairs(require('highlights').highlights[colorscheme]) do
    if hi.clear then vim_cmd(('highlight clear %s'):format(hi.name)) end

    local guifg =
      (type(hi.guifg) == 'string' and hi.guifg)
      or (type(hi.guifg) == 'table' and get_hex(hi.guifg[1], hi.guifg[2]))
      or nil

    local guibg =
      (type(hi.guibg) == 'string' and hi.guibg)
      or (type(hi.guibg) == 'table' and get_hex(hi.guibg[1], hi.guibg[2]))
      or nil

    local gui_options = ''
    gui_options = hi.gui and gui_options .. 'gui=' .. hi.gui or gui_options
    gui_options = guifg and gui_options .. ' guifg=' .. guifg or gui_options
    gui_options = guibg and gui_options .. ' guibg=' .. guibg or gui_options

    vim_cmd(
      hi.link
      and ('highlight link %s %s'):format(hi.name, hi.link)
       or ('highlight %s %s'):format(hi.name, gui_options)
    )
  end
end

---@param m  table
_G.map = function(m)
  local opts = m.opts or {}
  if type(m.modes) == 'string' then
    vim_keymap(m.modes, m.lhs, m.rhs, opts)
  elseif type(m.modes) == 'table' then
    for _, mode in ipairs(m.modes) do
      vim_keymap(mode, m.lhs, m.rhs, opts)
    end
  end
end

---@param m  table
_G.localmap = function(m)
  local bufnr = m.bufnr or 0
  local opts = m.opts or {}
  if type(m.modes) == 'string' then
    vim_local_keymap(bufnr, m.modes, m.lhs, m.rhs, opts)
  elseif type(m.modes) == 'table' then
    for _, mode in ipairs(m.modes) do
      vim_local_keymap(bufnr, mode, m.lhs, m.rhs, opts)
    end
  end
end

---@param augroup  table
_G.augroup = function(augroup)
  ---@param autocmd  table
  ---@return string
  local autocmd_to_str = function(autocmd)
    return
      ('autocmd %s %s %s'):format(
        autocmd.event,
        autocmd.pattern,
        autocmd.cmd
      )
  end

  local autocmds = vim_map(function(autocmd)
    return autocmd_to_str(autocmd)
  end, augroup.autocmds)

  vim_cmd(([[
  augroup %s
    autocmd!
    %s
  augroup END
  ]]):format(augroup.name, tbl_concat(autocmds, '\n')))
end

---@param filename  string
local linux_open_tex_pdf = function(filename)
  local opened_windows = vim_fn.systemlist('wmctrl -l')
  local pdf_is_opened

  for _, window_name in pairs(opened_windows) do
    if window_name:find(filename) then
      pdf_is_opened = true
      break
    end
  end

  if not pdf_is_opened then
    vim_cmd(('!nohup xdg-open "%s" &>/dev/null &'):format(filename))
  end
end

---@param filename  string
local macos_open_tex_pdf = function(filename)
end

-- Try to open the compiled PDF file if it's not already opened.
_G.open_tex_pdf = function()
  local pdf_filename = ('%s.pdf'):format(vim_fn.expand('%:p:r'))
  if _G.OS == 'Linux' then
    linux_open_tex_pdf(pdf_filename)
  elseif _G.OS == 'Darwin' then
    macos_open_tex_pdf(pdf_filename)
  end
end

---@param filename  string
local linux_close_tex_pdf = function(filename)
  vim_cmd(('!wmctrl -F -c "%s"'):format(filename))
end

---@param filename  string
local macos_close_tex_pdf = function(filename)
-- function! tex#PdfClose(filepath) " {{{1
--   " Close the PDF file created by a TeX document. Note that this function only
--   " works with the yabai window manager and the Skim PDF viewer.
--   if !filereadable(a:filepath) | return | endif
--
--   let l:windows = json_decode(join(systemlist("yabai -m query --windows")))
--   let l:Skim_windows = filter(l:windows, 'v:val.app=="Skim"')
--   if len(l:Skim_windows) == 0 | return | endif
--
--   " macOS interprets every ':' as a '/'. We need to do the opposite
--   " substitution in the window titles. We also remove everything after the
--   " .pdf extension.
--   for window in l:Skim_windows
--     let window.title = substitute(window.title, '/', ':', 'g')
--     let window.title = substitute(window.title, '\.pdf.*', '.pdf', '')
--   endfor
--
--   let l:filename = trim(system("basename " . a:filepath))
--
--   " If there is just one Skim window and its title matches the filename of
--   " the file in the buffer, quit Skim. If there are more Skim windows look
--   " for the one whose title matches the filename of the file in the buffer
--   " and close it.
--   if len(l:Skim_windows) == 1 && l:Skim_windows[0].title == l:filename
--     execute "silent !osascript -e \'quit app \"Skim\"\'"
--   else
--     for window in l:Skim_windows
--       if window.title == l:filename
--         execute
--           \ "silent !yabai -m window " . shellescape(window.id, 1) . " --close"
--       endif
--     endfor
--   endif
-- endfunction " }}}1
end

-- Close the compiled PDF file.
_G.close_tex_pdf = function()
  local pdf_filename = ('%s.pdf'):format(vim_fn.expand('%:p:r'))
  if _G.OS == 'Linux' then
    linux_close_tex_pdf(pdf_filename)
  elseif _G.OS == 'Darwin' then
    macos_close_tex_pdf(pdf_filename)
  end
end

return {
  apply_highlights = apply_highlights,
}

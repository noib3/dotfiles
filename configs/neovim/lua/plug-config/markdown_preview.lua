local vim_g = vim.g

vim_g.mkdp_auto_close = 0
vim_g.mkdp_browser = "qutebrowser"
vim_g.mkdp_browserfunc = "g:MkdpBrowserfunc"
vim_g.mkdp_filetypes = { "markdown" }
vim_g.mkdp_page_title = "${name}"

vim.cmd([[
  function! g:MkdpBrowserfunc(url)
    let l:current_desktop =
      \ trim(system(
      \   'wmctrl -d'
      \   . '| sed "s/\([0-9]*\) *\([-\*]\).*/\2\1/"'
      \   . "| sed '/^[^\*].*$/d'"
      \   . '| sed "s/\*//"'
      \ ))

    let l:qutebrowser_windows_on_current_desktop =
      \ len(systemlist(
      \  'xdotool search --desktop '
      \   . l:current_desktop
      \   . ' --class qutebrowser'
      \ ))

    let l:target =
      \   (l:qutebrowser_windows_on_current_desktop == 0)
      \   ? 'window'
      \   : 'tab'

    silent execute
      \   printf('!qutebrowser --target %s %s', l:target, a:url)
  endfunction
]])

-- _G.localmap({
--   modes = 'n',
--   lhs = '<Leader>p',
--   rhs = '<Cmd>MarkdownPreview<CR>',
--   opts = { silent = true },
-- })

-- _G.localmap({
--   modes = 'n',
--   lhs = '<Leader>k',
--   rhs = '<Cmd>MarkdownPreviewStop<CR>',
--   opts = { silent = true },
-- })

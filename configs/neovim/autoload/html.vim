function! html#open(url)
  let l:current_desktop =
    \ trim(system(
    \   'wmctrl -d'
    \   . '| sed "s/\([0-9]*\) *\([-\*]\).*/\2\1/"'
    \   . "| sed '/^[^\*].*$/d'"
    \   . '| sed "s/\*//"'
    \ ))

  let l:qb_windows_current_desktop =
    \ len(systemlist(
    \  'xdotool search --desktop ' . l:current_desktop . ' --class qutebrowser'
    \ ))

  let l:target = l:qb_windows_current_desktop == 0 ? 'window' : 'tab'

  silent execute printf('!qutebrowser --target %s %s', l:target, a:url)
endfunction

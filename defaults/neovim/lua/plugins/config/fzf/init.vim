let s:rg_previewer = expand('<sfile>:p:h').'/rg-previewer'

function! s:open_edits(basedir, lines)
  let s:files = map(a:lines, 'a:basedir."/". v:val')
  execute 'edit '.remove(s:files, 0)
  for file in s:files | execute 'badd '.file | endfor
endfunction

function! s:open_ripgreps(basedir, lines)
  let s:regex = '^\([^:]*\):\([^:]*\):\([^:]*\):.*$'
  let s:lnum = matchlist(a:lines[0], s:regex)[2]
  let s:col = matchlist(a:lines[0], s:regex)[3]
  let s:files = map(a:lines, 'a:basedir."/". matchlist(v:val, s:regex)[1]')
  execute 'edit '.remove(s:files, 0)
  call cursor(s:lnum, s:col)
  for file in s:files | execute 'badd '.file | endfor
endfunction

function! s:fuzzy_edit()
  let s:dir = '$HOME'
  let s:spec = {
    \ 'options': ['--multi', '--prompt=Edit> ', '--preview=bat ~/{}',
                  \ '--preview-window=border-left'],
    \ 'sink*': function('<SID>open_edits', [s:dir]),
    \ }
  call fzf#run(fzf#wrap(s:spec))
endfunction

function! s:fuzzy_ripgrep()
  let s:command_fmt = 'rg --smart-case --column --line-number --no-heading'
                        \ . ' --color=always -- %s || true'
  let s:initial_command = printf(s:command_fmt, shellescape(''))
  let s:reload_command = printf(s:command_fmt, '{q}')
  let s:dir = system('git status') =~ '^fatal' ?
              \ expand('%:p:h') :
              \ systemlist('git rev-parse --show-toplevel')[0]
  let s:spec = {
    \ 'source': s:initial_command,
    \ 'options': ['--multi', '--prompt=Rg> ', '--disabled',
                  \ '--bind=change:reload:'.s:reload_command,
                  \ '--delimiter=:', '--with-nth=1,2,4',
                  \ '--preview='.fzf#shellescape(s:rg_previewer).' {}',
                  \ '--preview-window=+{2}-/2',
                  \ '--preview-window=border-left'],
    \ 'dir': s:dir,
    \ 'sink*': function('<SID>open_ripgreps', [s:dir]),
    \ }
  call fzf#run(fzf#wrap(s:spec))
endfunction

nmap <silent> <C-x><C-e> <Cmd>call <SID>fuzzy_edit()<CR>
nmap <silent> <C-x><C-r> <Cmd>call <SID>fuzzy_ripgrep()<CR>

augroup all
  autocmd!
  autocmd BufWritePre * call s:StripTrailingWhiteSpace()
  autocmd BufLeave * call s:AutoSaveWinView()
  autocmd BufEnter * call s:AutoRestoreWinView()
  autocmd BufRead *.cls setlocal filetype=tex
  autocmd BufRead lfrc,skhdrc setlocal filetype=conf
augroup END

function! s:StripTrailingWhiteSpace()
  let current_pos = getpos(".")
  %s/\s\+$//e
  call setpos (".", current_pos)
endfunction

" https://vim.fandom.com/wiki/Avoid_scrolling_when_switch_buffers {{{

" Save current view settings on a per-window, per-buffer basis.
function! s:AutoSaveWinView()
  if !exists("w:SavedBufView")
    let w:SavedBufView = {}
  endif
  let w:SavedBufView[bufnr("%")] = winsaveview()
endfunction

" Restore current view settings.
function! s:AutoRestoreWinView()
  let buf = bufnr("%")
  if exists("w:SavedBufView") && has_key(w:SavedBufView, buf)
    let v = winsaveview()
    let atStartOfFile = v.lnum == 1 && v.col == 0
    if atStartOfFile && !&diff
      call winrestview(w:SavedBufView[buf])
    endif
    unlet w:SavedBufView[buf]
  endif
endfunction

" }}}

" vim:fdm=marker

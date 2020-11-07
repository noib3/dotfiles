augroup all
  autocmd!
  autocmd BufWritePre * call s:StripTrailingWhiteSpace()
  autocmd BufLeave * call s:AutoSaveWinView()
  autocmd BufEnter * call s:AutoRestoreWinView()
  autocmd ColorScheme * highlight Normal guibg=NONE
  autocmd ColorScheme * highlight Comment gui=italic
  autocmd BufRead *.cls setlocal filetype=tex
augroup END

augroup tex
  autocmd!
  autocmd BufRead *.tex call tex#PdfOpen()
  autocmd BufUnload *.tex call tex#PdfClose(expand("<afile>:p:r") . ".pdf",
                                            \ expand("<afile>:t:r") . ".pdf")
  autocmd ColorScheme * highlight texComment gui=italic
augroup END

function! s:StripTrailingWhiteSpace()
  let curr_pos = getpos(".")
  %s/\s\+$//e
  call setpos (".", curr_pos)
endfunction

" https://vim.fandom.com/wiki/Avoid_scrolling_when_switch_buffers

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

" Maintainer: Riccardo Mazzarini
" Github:     https://github.com/n0ibe/macOS-dotfiles

" https://github.com/lervag/vimtex/issues/557

" TODO text inside both textit and textbf should be bolditalic
" TODO understand why some commands are highlighted differently than others:
" \text is magenta, \mathit is yellow.
" TODO if amsmath is loaded, text inside \mathit should be italic, inside \mathbf
" bold, inside both formatted like the inner-most command (basically the
" opposite of the wrong behaviour of normal text), inside \boldsymbol bolditalic
" TODO if bm is loaded, text inside \bm should be bolditalic

" syntax cluster texMathZoneGroup add=texItalStyle
" syntax cluster texMathMatchGroup add=texItalStyle

" syntax cluster texMathZoneGroup add=texBoldStyle
" syntax cluster texMathMatchGroup add=texBoldStyle

" syntax cluster texMathZoneGroup add=texBoldItalStyle
" syntax cluster texMathMatchGroup add=texBoldItalStyle

" If I uncomment this, \textit outside math mode becomes magenta, and in math
" mode text inside \textit and \mathit is white and not blue
" " \textit and \mathit
" syntax region texItalStyle matchgroup=texStatement start='\\\(textit\|mathit\)\s*{' end='}'
"                                \ contains=texMathZoneX contained

" " \mathbf
" syntax region texBoldStyle matchgroup=texStatement start='\\mathbf\s*{' end='}'
"                                \ contains=texMathZoneX contained

" " \boldsymbol
" syntax region texBoldItalStyle matchgroup=texStatement start='\\\(boldsymbol\|bm\)\s*{' end='}'
"                                \ contains=texMathZoneX contained

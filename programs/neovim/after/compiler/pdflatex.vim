if exists('current_compiler')
  finish
endif
let current_compiler = 'pdflatex'

let s:cpo_save = &cpo
set cpo&vim

CompilerSet errorformat=%f:%l:\ %m
CompilerSet makeprg=pdflatex\ -halt-on-error\ -file-line-error\ %

let &cpo = s:cpo_save
unlet s:cpo_save

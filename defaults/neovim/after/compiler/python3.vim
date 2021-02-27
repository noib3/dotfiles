if exists("current_compiler")
  finish
endif
let current_compiler = "python3"

let s:cpo_save = &cpo
set cpo&vim

CompilerSet errorformat=
  \%*\\sFile\ \"%f\"\\,\ line\ %l\\,\ %m,
  \%*\\sFile\ \"%f\"\\,\ line\ %l,
CompilerSet makeprg=python3\ %

let &cpo = s:cpo_save
unlet s:cpo_save

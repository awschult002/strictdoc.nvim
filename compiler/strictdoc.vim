" Vim compiler file for StrictDoc (.sdoc)
if exists('current_compiler') | finish | endif
let current_compiler = 'strictdoc'

let s:cpo_save = &cpo
set cpo&vim

" `strictdoc format FILE` parses and validates just that file (exit 1 on
" error). It may rewrite the file when document_line_width is configured.
let s:prg = get(g:, 'strictdoc_makeprg', 'strictdoc format %:S')
execute 'CompilerSet makeprg=' . escape(s:prg, ' \|"')

CompilerSet errorformat=
      \%-Gerror\ source:%.%#,
      \%Eerror:\ Could\ not\ parse\ file:\ %.%#\ Error:\ TextXSyntaxError:\ %f:%l:%c:\ %m,
      \%Eerror:\ could\ not\ parse\ file:\ %f.,
      \%CSemantic\ error:\ %m,
      \%ZLocation:\ %f:%l:%c,
      \%+G[SECTION]\ elements\ %m,
      \%Eerror:\ %m,
      \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save

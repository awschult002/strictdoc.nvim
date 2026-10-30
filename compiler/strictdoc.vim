" Vim compiler file for StrictDoc (.sdoc)
if exists('current_compiler') | finish | endif
let current_compiler = 'strictdoc'

let s:cpo_save = &cpo
set cpo&vim

" An HTML export of the project in the cwd parses every document and also runs
" the RST in each >>> block through docutils, which `strictdoc format` skips.
" Output goes to a throwaway cache dir. RST errors are mapped back to the
" .sdoc line by lua/strictdoc/make.lua.
let s:prg = get(g:, 'strictdoc_makeprg', 'strictdoc export --formats=html --output-dir '
      \ . shellescape(stdpath('cache') . '/strictdoc-make') . ' .')
execute 'CompilerSet makeprg=' . escape(s:prg, ' \|"')

" RST errors span the message, the fragment text and its closing <<<.
CompilerSet errorformat=
      \%Eerror:\ problems\ when\ converting\ RST\ to\ HTML:\ RST\ markup\ syntax\ error\ on\ line\ %l:\ %m,
      \%CRST\ fragment:\ >>>,
      \%Z<<<,
      \%-Gerror\ source:%.%#,
      \%trror:\ Could\ not\ parse\ file:\ %.%#\ Error:\ TextXSyntaxError:\ %f:%l:%c:\ %m,
      \%Eerror:\ could\ not\ parse\ file:\ %f.,
      \%CSemantic\ error:\ %m,
      \%ZLocation:\ %f:%l:%c,
      \%+G[SECTION]\ elements\ %m,
      \%trror:\ %m,
      \%C%m,
      \%-G%.%#

let &cpo = s:cpo_save
unlet s:cpo_save

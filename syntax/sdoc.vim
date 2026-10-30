" Vim syntax file
" Language:   StrictDoc SDoc (*.sdoc)
" Grammar:    strictdoc/backend/sdoc/grammar/ in strictdoc-project/strictdoc
" Modeled on: runtime/syntax/toml.vim

if exists('b:current_syntax')
  finish
endif

" Inline markup, valid in field values and text blocks.
syn match sdocLink /\[LINK: [^\]]\+\]/ display
syn match sdocAnchor /^\s*\[ANCHOR: [^\]]\+\]\s*$/ display

" KEY: value. Keys follow FieldName ([A-Z][A-Za-z0-9_-]*); grammar and
" document metadata keys may be lowercase or follow a '- ' list dash.
syn match sdocDash /^\s*\zs- / display
syn match sdocKey /\%(^\s*\%(- \)\=\)\@<=[A-Za-z_][A-Za-z0-9_-]*\ze:\%(\s\|$\)/ nextgroup=sdocSep display
syn match sdocKey /\%(^\s*\)\@<=TITLE\ze: / nextgroup=sdocTitleSep display
syn match sdocKey /\%(^\s*\)\@<=\%(UID\|MID\|VALUE\)\ze: / nextgroup=sdocUidSep display
syn match sdocKey /\%(^\s*- \)\@<=TYPE\ze: / nextgroup=sdocTypeSep display
syn match sdocSep /: / contained nextgroup=sdocValue,sdocBoolean,sdocString display
syn match sdocTitleSep /: / contained nextgroup=sdocTitle display
syn match sdocUidSep /: / contained nextgroup=sdocUid display
syn match sdocTypeSep /: / contained nextgroup=sdocRelationType,sdocValue display
syn match sdocValue /.*$/ contained contains=sdocLink display
syn match sdocBoolean /\%(True\|False\)$/ contained display
syn match sdocRelationType /\%(Parent\|Child\|File\)$/ contained display
syn match sdocTitle /.*$/ contained contains=sdocLink display
syn match sdocUid /.*$/ contained display

" Node markers: [NODE], [[NODE]] / [[/NODE]], [SECTION] / [/SECTION].
syn match sdocNode /^\s*\[[A-Z][A-Z_]*\]\s*$/ display
syn match sdocNode /^\s*\[\[\/\=[A-Z][A-Z_]*\]\]\s*$/ display
syn match sdocSection /^\s*\[\/\=SECTION\]\s*$/ display
syn match sdocSection /^\s*\[\[\/\=SECTION\]\]\s*$/ display
syn match sdocDocument /^\s*\[\%(DOCUMENT\|GRAMMAR\|DOCUMENT_FROM_FILE\)\]\s*$/ display

" KEY: >>> ... <<< is verbatim text; so is the legacy [FREETEXT] block. The
" first unmatched line that is just <<< (any indent) ends the block; nested
" KEY: >>> ... <<< examples are skipped.
" Block text is reStructuredText; set g:strictdoc_rst_syntax = 0 to skip it.
let s:rst = get(g:, 'strictdoc_rst_syntax', 1)
if s:rst
  unlet! b:current_syntax
  syn include @sdocRst syntax/rst.vim
  unlet! b:current_syntax
endif

syn region sdocNested contained transparent start=/^\s*[A-Z][A-Za-z0-9_-]*: >>>\s*$/ end=/^\s*<<<\s*$/ contains=sdocNested
execute 'syn region sdocString matchgroup=sdocDelimiter start=/\%(^\s*\S.*: \)\@<=>>>$/ end=/^\s*<<<\s*$/ keepend contains=sdocNested,sdocLink,sdocAnchor,@Spell' . (s:rst ? ',@sdocRst' : '')
syn region sdocString matchgroup=sdocNode start=/^\s*\[FREETEXT\]\s*$/ end=/^\s*\[\/FREETEXT\]\s*$/ contains=sdocLink,sdocAnchor,@Spell

hi def link sdocDocument PreProc
hi def link sdocSection Title
hi def link sdocNode Statement
hi def link sdocKey Identifier
hi def link sdocDash Delimiter
hi def link sdocDelimiter Delimiter
hi def link sdocSep Delimiter
hi def link sdocTitleSep sdocSep
hi def link sdocUidSep sdocSep
hi def link sdocTypeSep sdocSep
hi def link sdocValue String
hi def link sdocString String
hi def link sdocTitle Title
hi def link sdocUid Constant
hi def link sdocBoolean Boolean
hi def link sdocRelationType Type
hi def link sdocLink Underlined
hi def link sdocAnchor Label

syn sync minlines=500
let b:current_syntax = 'sdoc'

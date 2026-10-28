if vim.b.did_indent then return end
vim.b.did_indent = 1

vim.bo.indentexpr = "v:lua.require'strictdoc.indent'.expr()"
vim.bo.indentkeys = '!^F,o,O,0=<<<,0=[/,0=[[/'
vim.bo.autoindent = false
-- Keep tabs inside >>> blocks when `=` leaves their indent alone.
vim.bo.preserveindent = true
vim.b.undo_indent = 'setl inde< indk< ai< pi<'

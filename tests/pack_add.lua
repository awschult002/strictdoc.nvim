-- Install this checkout with the built-in vim.pack.add() and check it loads.
-- Tests the committed HEAD. Run with throwaway XDG_DATA_HOME and XDG_CONFIG_HOME (see Makefile).
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
-- Pin the commit under test: CI checkouts have a detached HEAD.
local rev = vim.trim(vim.system({ 'git', '-C', root, 'rev-parse', 'HEAD' }):wait().stdout)
vim.pack.add({ { src = 'file://' .. root, name = 'strictdoc.nvim', version = rev } },
  { confirm = false })
-- What startup does after init.lua.
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
vim.cmd('silent edit ' .. root .. '/tests/fixtures/relations.sdoc')
local ok = vim.bo.filetype == 'sdoc' and vim.b.current_syntax == 'sdoc'
  and vim.bo.indentexpr:find('strictdoc') ~= nil
print((ok and 'ok   ' or 'FAIL ') .. 'vim.pack.add: filetype, syntax and indent load')
vim.cmd(ok and 'quitall!' or 'cquit 1')

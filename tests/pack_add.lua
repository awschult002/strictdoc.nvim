-- Install this checkout with the built-in vim.pack.add() and check it loads.
-- Tests the committed HEAD. Run with throwaway XDG_DATA_HOME and XDG_CONFIG_HOME (see Makefile).
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
-- Serve the commit under test from a scratch repo whose HEAD is a branch:
-- CI checkouts have a detached HEAD, which vim.pack cannot clone from.
local src = vim.fn.tempname()
local function git(...)
  local r = vim.system({ 'git', '-C', src, ... }):wait()
  assert(r.code == 0, r.stderr)
end
vim.fn.mkdir(src, 'p')
git('init', '-q')
git('fetch', '-q', root, 'HEAD:refs/heads/test')
git('symbolic-ref', 'HEAD', 'refs/heads/test')
vim.pack.add({ { src = 'file://' .. src, name = 'strictdoc.nvim' } }, { confirm = false })
-- What startup does after init.lua.
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
vim.cmd('silent edit ' .. root .. '/tests/fixtures/relations.sdoc')
local ok = vim.bo.filetype == 'sdoc' and vim.b.current_syntax == 'sdoc'
  and vim.bo.indentexpr:find('strictdoc') ~= nil
print((ok and 'ok   ' or 'FAIL ') .. 'vim.pack.add: filetype, syntax and indent load')
vim.cmd(ok and 'quitall!' or 'cquit 1')

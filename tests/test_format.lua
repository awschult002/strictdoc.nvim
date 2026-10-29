local H = require('helpers')
local T = {}

local bad = {
  '[DOCUMENT]', 'TITLE: T', 'OPTIONS:', '  ENABLE_MID: True',
  '[TEXT]', 'STATEMENT: >>>', 'a', '[TEXT]', '', '', '  b', '<<<',
  '', '', '[[SECTION]]', 'TITLE: S', '  [REQUIREMENT]', 'TITLE: R', '[[/SECTION]]', '',
}
local good = {
  '[DOCUMENT]', 'TITLE: T', 'OPTIONS:', '  ENABLE_MID: True', '',
  '[TEXT]', 'STATEMENT: >>>', 'a', '[TEXT]', '', '', '  b', '<<<',
  '', '[[SECTION]]', 'TITLE: S', '', '[REQUIREMENT]', 'TITLE: R', '', '[[/SECTION]]', '',
}

T['gg=G fixes blank lines, keeps blocks, idempotent'] = function()
  H.buf(bad)
  H.feed('gg=G')
  H.eq(good, H.lines())
  H.feed('gg=G')
  H.eq(good, H.lines())
end

T['gq and :StrictdocFormat'] = function()
  H.buf(bad)
  H.feed('gggqG')
  H.eq(good, H.lines())
  H.buf(bad)
  vim.cmd('StrictdocFormat')
  H.eq(good, H.lines())
end

T['= on a range only touches that range'] = function()
  H.buf(bad)
  H.feed('16G=G')
  H.eq('[TEXT]', H.lines()[5])
  H.eq({ 'TITLE: S', '', '[REQUIREMENT]' }, vim.list_slice(H.lines(), 16, 18))
end

T['no_mappings keeps builtin ='] = function()
  vim.g.strictdoc_no_mappings = 1
  H.buf(bad)
  vim.g.strictdoc_no_mappings = nil
  H.feed('gg=G')
  H.eq('[TEXT]', H.lines()[5])
end

T['format on save'] = function()
  vim.g.strictdoc_format_on_save = 1
  local f = vim.fn.tempname() .. '.sdoc'
  vim.fn.writefile(bad, f)
  vim.cmd('edit ' .. f)
  vim.g.strictdoc_format_on_save = nil
  vim.cmd('silent write')
  H.eq(good, vim.fn.readfile(f))
end

T['strictdoc accepts the result'] = function()
  if vim.fn.executable('strictdoc') == 0 then print('skip: no strictdoc'); return end
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir)
  H.buf(bad)
  H.feed('gg=G')
  vim.fn.writefile(H.lines(), dir .. '/a.sdoc')
  local out = vim.fn.system({ 'strictdoc', 'export', '--output-dir', dir .. '/out', dir })
  H.eq(0, vim.v.shell_error, out)
end

return T

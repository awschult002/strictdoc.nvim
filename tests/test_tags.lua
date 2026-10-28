local H = require('helpers')
local T = {}

T['Ctrl-] on a [LINK: ...] jumps to its [ANCHOR: ...]'] = function()
  H.open('anchors.sdoc')
  vim.fn.cursor(9, 15)
  H.feed('<C-]>')
  H.eq(25, vim.fn.line('.'))
end

T[':tag finds UIDs and section titles'] = function()
  H.open('expected/nested_composite.sdoc')
  vim.cmd('tag REQ-2')
  H.eq(37, vim.fn.line('.'))
  vim.cmd('tag Req_1_1_1')
  H.eq(44, vim.fn.line('.'))
end

T['Ctrl-] on a parent UID opens the document that defines it'] = function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir .. '/.git', 'p')
  vim.fn.writefile(H.read(H.fixtures .. 'relations.sdoc'), dir .. '/child.sdoc')
  vim.fn.writefile({ '[DOCUMENT]', 'TITLE: P', '', '[REQUIREMENT]', 'UID: REQ-2' }, dir .. '/parent.sdoc')
  vim.cmd('silent edit ' .. dir .. '/child.sdoc')
  vim.fn.cursor(10, 12)
  H.feed('<C-]>')
  H.eq('parent.sdoc', vim.fn.expand('%:t'))
  H.eq(5, vim.fn.line('.'))
end

return T

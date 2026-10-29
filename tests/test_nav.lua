local H = require('helpers')
local T = {}

T[']] and [[ jump between nodes, with counts'] = function()
  H.open('anchors.sdoc')
  H.feed('gg]]')
  H.eq(4, vim.fn.line('.'))
  H.feed(']]')
  H.eq(7, vim.fn.line('.'))
  H.feed('2]]')
  H.eq(21, vim.fn.line('.'))
  H.feed('[[')
  H.eq(18, vim.fn.line('.'))
  H.feed('G[[')
  H.eq(21, vim.fn.line('.'))
end

T['d]] deletes up to the next node'] = function()
  H.open('relations.sdoc')
  H.feed('ggd]]')
  H.eq('[REQUIREMENT]', H.lines()[1])
end

T['an / in select a node'] = function()
  H.open('anchors.sdoc')
  H.feed('9Gvan<Esc>')
  H.eq({ 7, 14 }, { vim.fn.line("'<"), vim.fn.line("'>") })
  H.feed('5Gvin<Esc>')
  H.eq({ 7, 14 }, { vim.fn.line("'<"), vim.fn.line("'>") })
  H.feed('5Gvan<Esc>')
  H.eq({ 4, 16 }, { vim.fn.line("'<"), vim.fn.line("'>") })
  H.feed('19Gdan')
  H.eq('[DOCUMENT]', H.lines()[1])
  H.eq(17, vim.fn.line('$'))
end

T['at / it select a multi-line block'] = function()
  H.buf({ '[REQUIREMENT]', 'STATEMENT: >>>', 'one', '', 'two', '<<<', 'TITLE: x' })
  H.feed('4Gvit<Esc>')
  H.eq({ 3, 5 }, { vim.fn.line("'<"), vim.fn.line("'>") })
  H.feed('3Gvat<Esc>')
  H.eq({ 2, 6 }, { vim.fn.line("'<"), vim.fn.line("'>") })
  H.feed('3Gdit')
  H.eq({ '[REQUIREMENT]', 'STATEMENT: >>>', '<<<', 'TITLE: x' }, H.lines())
end

T['it picks the innermost nested block'] = function()
  H.buf({ 'CODE: >>>', 'a', 'INNER: >>>', 'b', '<<<', 'c', '<<<' })
  H.feed('4Gvit<Esc>')
  H.eq({ 4, 4 }, { vim.fn.line("'<"), vim.fn.line("'>") })
  H.feed('6Gvit<Esc>')
  H.eq({ 2, 6 }, { vim.fn.line("'<"), vim.fn.line("'>") })
end

return T

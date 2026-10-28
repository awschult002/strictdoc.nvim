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

return T

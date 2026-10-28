local H = require('helpers')
local T = {}

local function group(l, c)
  return vim.fn.synIDattr(vim.fn.synID(l, c, 1), 'name')
end

T['highlight groups follow the grammar'] = function()
  H.open('expected/nested_composite.sdoc')
  H.eq('sdocDocument', group(1, 1))
  H.eq('sdocKey', group(2, 1))
  H.eq('sdocTitle', group(2, 8))
  H.eq('sdocDash', group(6, 1))
  H.eq('sdocBoolean', group(8, 20))
  H.eq('sdocNode', group(30, 1))
  H.eq('sdocUid', group(31, 10))
  H.eq('sdocDelimiter', group(33, 14))
  H.eq('sdocString', group(34, 1))
  H.eq('sdocDelimiter', group(35, 3))
  H.eq('sdocNode', group(51, 6))
end

T['sections, links, anchors, relations and FREETEXT'] = function()
  H.buf({ '[SECTION]', 'TITLE: A [LINK: X]', '', '[REQUIREMENT]', 'STATEMENT: >>>',
          'UID: looks like a field', '[ANCHOR: X]', '<<<', 'RELATIONS:', '- TYPE: Parent',
          '  VALUE: REQ-1', '', '[FREETEXT]', 'free [LINK: X]', '[/FREETEXT]', '', '[/SECTION]' })
  vim.cmd('syntax sync fromstart')
  H.eq('sdocSection', group(1, 1))
  H.eq('sdocLink', group(2, 12))
  H.eq('sdocString', group(6, 1))
  H.eq('sdocAnchor', group(7, 2))
  H.eq('sdocRelationType', group(10, 10))
  H.eq('sdocUid', group(11, 10))
  H.eq('sdocNode', group(13, 2))
  H.eq('sdocString', group(14, 1))
  H.eq('sdocLink', group(14, 8))
  H.eq('sdocSection', group(17, 2))
  H.eq('Title', vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.synID(1, 1, 1)), 'name'))
end

T['an indented <<< ends the block, nothing leaks past it'] = function()
  H.buf({ '[REQUIREMENT]', '  STATEMENT: >>>', 'body', '      <<<  ', 'UID: R-1' })
  vim.cmd('syntax sync fromstart')
  H.eq('sdocString', group(3, 1))
  H.eq('sdocDelimiter', group(4, 7))
  H.eq('sdocKey', group(5, 1))
end

return T

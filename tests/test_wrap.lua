local H = require('helpers')
local T = {}

local doc = { '[DOCUMENT]', 'TITLE: D', '', '[SECTION]', '  TITLE: S', '',
              '  first line', '  second line', '', '[/SECTION]' }

T['gr wraps in [REQUIREMENT] at the section indent'] = function()
  H.buf(doc)
  H.feed('7GVjgr')
  H.eq({ '[DOCUMENT]', 'TITLE: D', '', '[SECTION]', '  TITLE: S', '',
         '  [REQUIREMENT]', '  STATEMENT: >>>', '  first line', '  second line', '  <<<',
         '', '[/SECTION]' }, H.lines())
end

T['gt wraps in [TEXT] with STATEMENT'] = function()
  H.buf({ '[DOCUMENT]', 'TITLE: D', '', 'some text' })
  H.feed('4GVgt')
  H.eq({ '[DOCUMENT]', 'TITLE: D', '', '[TEXT]', 'STATEMENT: >>>', 'some text', '<<<' }, H.lines())
end

T['gs wraps in [SECTION] and leaves the cursor after TITLE: '] = function()
  H.buf(doc)
  H.feed('7GVjgs')
  H.eq({ '[DOCUMENT]', 'TITLE: D', '', '[SECTION]', '  TITLE: S', '',
         '  [SECTION]', '    TITLE: ', '', '    first line', '    second line', '',
         '  [/SECTION]', '', '[/SECTION]' }, H.lines())
  H.eq(8, vim.fn.line('.'))
  assert(vim.fn.col('.') >= #'    TITLE:', 'cursor not on the title')
end

T['gs nests a requirement and keeps its >>> text verbatim'] = function()
  H.buf({ '[DOCUMENT]', 'TITLE: D', '', '[REQUIREMENT]', 'STATEMENT: >>>', ' keep', '<<<' })
  H.feed('4GVGgs')
  H.eq({ '[DOCUMENT]', 'TITLE: D', '', '[SECTION]', '  TITLE: ', '',
         '  [REQUIREMENT]', '  STATEMENT: >>>', ' keep', '  <<<', '', '[/SECTION]' }, H.lines())
end

T['g:strictdoc_composite_sections makes gs emit [[SECTION]]'] = function()
  vim.g.strictdoc_composite_sections = 1
  H.buf({ 'x' })
  H.feed('Vgs')
  H.eq({ '[[SECTION]]', '  TITLE: ', '', '  x', '', '[[/SECTION]]' }, H.lines())
end

return T

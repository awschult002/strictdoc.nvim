local H = require('helpers')
local T = {}

local fixtures = { 'anchors', 'from_file', 'legacy_sections', 'metadata',
                   'nested_composite', 'relations', 'views' }

local function reindent(name)
  H.open('scrambled/' .. name .. '.sdoc')
  vim.cmd('silent normal! gg=G')
  return H.lines()
end

for _, f in ipairs(fixtures) do
  T['gg=G on scrambled ' .. f] = function()
    H.eq(H.read(H.fixtures .. 'expected/' .. f .. '.sdoc'), reindent(f))
  end
  T['gg=G with g:strictdoc_indent=0 restores upstream ' .. f] = function()
    vim.g.strictdoc_indent = 0
    H.eq(H.read(H.fixtures .. f .. '.sdoc'), reindent(f))
  end
end

T['gg=G with g:strictdoc_indent=0 leaves the 6k-line user guide untouched'] = function()
  vim.g.strictdoc_indent = 0
  H.open('user_guide.sdoc')
  local t = vim.uv.hrtime()
  vim.cmd('silent normal! gg=G')
  -- Vim's `=` always empties whitespace-only lines; that is the one change.
  local want = vim.tbl_map(function(l) return l:match('^%s+$') and '' or l end,
    H.read(H.fixtures .. 'user_guide.sdoc'))
  H.eq(want, H.lines())
  assert(vim.uv.hrtime() - t < 2e9, 'gg=G took more than 2s')
end

T['text between >>> and <<< is never reindented'] = function()
  H.buf({ '[SECTION]', 'TITLE: S', '', '[TEXT]', 'STATEMENT: >>>',
          '      odd', '\ttab', 'UID: not-a-field', '[REQUIREMENT]', '<<<', '', '[/SECTION]' })
  vim.cmd('silent normal! gg=G')
  H.eq({ '[SECTION]', '  TITLE: S', '', '  [TEXT]', '  STATEMENT: >>>',
         '      odd', '\ttab', 'UID: not-a-field', '[REQUIREMENT]', '  <<<', '', '[/SECTION]' }, H.lines())
end

local misplaced = { '[SECTION]', 'TITLE: S', '', '[REQUIREMENT]', '      STATEMENT: >>>',
                    '   body', '        <<<', 'UID: R-1', '', '[/SECTION]' }

T['mis-indented >>> and <<< snap to the field level'] = function()
  H.buf(misplaced)
  vim.cmd('silent normal! gg=G')
  H.eq({ '[SECTION]', '  TITLE: S', '', '  [REQUIREMENT]', '  STATEMENT: >>>',
         '   body', '  <<<', '  UID: R-1', '', '[/SECTION]' }, H.lines())
end

T['mis-indented <<< snaps to column 0 with g:strictdoc_indent=0'] = function()
  vim.g.strictdoc_indent = 0
  H.buf(misplaced)
  vim.cmd('silent normal! gg=G')
  H.eq({ '[SECTION]', 'TITLE: S', '', '[REQUIREMENT]', 'STATEMENT: >>>',
         '   body', '<<<', 'UID: R-1', '', '[/SECTION]' }, H.lines())
end

return T

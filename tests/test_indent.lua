local H = require('helpers')
local indent = require('strictdoc.indent')
local virtual = require('strictdoc.virtual')
local T = {}

local fixtures = { 'anchors', 'from_file', 'legacy_sections', 'metadata',
                   'nested_composite', 'relations', 'views' }

local function reindent(name)
  H.open('scrambled/' .. name .. '.sdoc')
  vim.cmd('silent normal! gg=G')
  return H.lines()
end

-- Virtual padding width per line (0 when none).
local function widths(buf)
  local w = {}
  for i = 1, vim.api.nvim_buf_line_count(buf) do w[i] = 0 end
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(buf, virtual.ns, 0, -1, { details = true })) do
    w[m[2] + 1] = #m[4].virt_text[1][1]
  end
  return w
end

local function strictdoc()
  local exe = vim.env.STRICTDOC or '/tmp/sdvenv/bin/strictdoc'
  if vim.fn.executable(exe) == 1 then return exe end
  if vim.fn.executable('strictdoc') == 1 then return 'strictdoc' end
end

for _, f in ipairs(fixtures) do
  T['gg=G on scrambled ' .. f .. ' gives the flat upstream file'] = function()
    H.eq(H.read(H.fixtures .. f .. '.sdoc'), reindent(f))
  end
  T['virtual indent of ' .. f .. ' renders the nested layout'] = function()
    local buf = H.open(f .. '.sdoc')
    local before = H.lines()
    local w, want = widths(buf), H.read(H.fixtures .. 'expected/' .. f .. '.sdoc')
    local st, ind = indent.new(), nil
    for i, l in ipairs(before) do
      ind, _, st = indent.step(st, l)
      if ind ~= -1 then -- text inside >>> <<< keeps its own spacing
        H.eq(want[i], string.rep(' ', w[i]) .. l, 'line ' .. i)
      end
    end
    H.eq(H.read(H.fixtures .. f .. '.sdoc'), H.lines(), 'buffer text changed')
  end
end

T['strictdoc export parses gg=G output (skipped without strictdoc)'] = function()
  local exe = strictdoc()
  if not exe then print('     skip: strictdoc not installed'); return end
  -- legacy_sections uses [SECTION]; relations has dangling parent UIDs.
  for _, f in ipairs({ 'anchors', 'metadata', 'nested_composite', 'views' }) do
    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir .. '/in', 'p')
    vim.fn.writefile(reindent(f), dir .. '/in/' .. f .. '.sdoc')
    local r = vim.system({ exe, 'export', '--formats', 'json', '--output-dir', dir .. '/out',
      dir .. '/in' }, { text = true }):wait()
    assert(r.code == 0, f .. ': strictdoc export failed:\n' .. r.stdout .. r.stderr)
  end
end

T['gg=G leaves the 6k-line user guide untouched'] = function()
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
  H.buf({ '[SECTION]', '  TITLE: S', '', '  [TEXT]', '  STATEMENT: >>>',
          '      odd', '\ttab', 'UID: not-a-field', '[REQUIREMENT]', '    <<<', '', '  [/SECTION]' })
  vim.cmd('silent normal! gg=G')
  H.eq({ '[SECTION]', 'TITLE: S', '', '[TEXT]', 'STATEMENT: >>>',
         '      odd', '\ttab', 'UID: not-a-field', '[REQUIREMENT]', '<<<', '', '[/SECTION]' }, H.lines())
end

T['virtual indent pads fields and nested markers, buffer stays flat'] = function()
  local lines = { '[SECTION]', 'TITLE: S', '', '[[REQUIREMENT]]', 'STATEMENT: >>>',
                  'body', '<<<', '[TEXT]', 'UID: T', '[[/REQUIREMENT]]', '[/SECTION]' }
  local buf = H.buf(lines)
  H.eq({ 0, 2, 0, 2, 4, 4, 4, 4, 4, 2, 0 }, widths(buf))
  H.eq(lines, H.lines())
  vim.bo.shiftwidth = 4
  virtual.refresh(buf)
  H.eq({ 0, 4, 0, 4, 8, 8, 8, 8, 8, 4, 0 }, widths(buf))
end

T['virtual indent follows edits'] = function()
  local buf = H.buf({ '[SECTION]', 'TITLE: S', '[/SECTION]' })
  H.feed('2GOx<Esc>')
  vim.api.nvim_exec_autocmds('TextChanged', { buffer = buf })
  H.eq({ 0, 2, 2, 0 }, widths(buf))
  H.eq({ '[SECTION]', 'x', 'TITLE: S', '[/SECTION]' }, H.lines())
end

T['g:strictdoc_virtual_indent=0 disables the padding'] = function()
  vim.g.strictdoc_virtual_indent = 0
  local buf = H.buf({ '[SECTION]', 'TITLE: S', '[/SECTION]' })
  H.eq({ 0, 0, 0 }, widths(buf))
end

return T

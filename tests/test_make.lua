local H = require('helpers')
local T = {}

-- Captured from strictdoc 0.30.4.
local out = {
  "Step 'Find and read SDoc files' start.",
  'Reading SDOC: 1 tasks',
  'error: Could not parse file: /tmp/sde/syn.sdoc. Error: TextXSyntaxError: /tmp/sde/syn.sdoc:5:4: Expected \': \' => \'EMENT] UID* A \'',
  'error source: /x/reader.py:54, function: _read()',
  'Rerun with strictdoc --debug <...> to enable stack trace printing.',
  'error: could not parse file: rel/field.sdoc.',
  'Semantic error: Invalid requirement field: FOO',
  'Location: rel/field.sdoc:4:1',
  'Hint: Compare with the document grammar: [UID, TITLE] for type: REQUIREMENT.',
  'error: [DocumentIndex.create] Requirement B references parent requirement which doesn\'t exist: NOPE.',
  'error: ',
  '[SECTION] elements are no longer supported by StrictDoc. See the migration guide for more details:',
  '"',
  'Total execution time ........................................ 0.52s',
}

local function qf()
  return vim.tbl_map(function(e)
    return { vim.fn.bufname(e.bufnr), e.lnum, e.col, vim.trim(e.text) }
  end, vim.tbl_filter(function(e) return e.valid == 1 end, vim.fn.getqflist()))
end

T['compiler sets makeprg/errorformat and undo restores'] = function()
  H.open('relations.sdoc')
  H.eq('strictdoc', vim.b.current_compiler)
  H.eq('strictdoc format %:S', vim.bo.makeprg)
  vim.cmd('set filetype=text')
  H.eq('make', vim.bo.makeprg)
end

T['g:strictdoc_makeprg overrides'] = function()
  vim.g.strictdoc_makeprg = 'strictdoc export --output-dir /tmp/x %:p:h'
  H.open('relations.sdoc')
  vim.g.strictdoc_makeprg = nil
  H.eq('strictdoc export --output-dir /tmp/x %:p:h', vim.bo.makeprg)
end

T['errorformat parses captured output'] = function()
  H.open('relations.sdoc')
  vim.fn.setqflist({}, 'r', { lines = out, efm = vim.bo.errorformat })
  H.eq({
    { '/tmp/sde/syn.sdoc', 5, 4, "Expected ': ' => 'EMENT] UID* A '" },
    { 'rel/field.sdoc', 4, 1, 'Invalid requirement field: FOO' },
    { '', 0, 0, "[DocumentIndex.create] Requirement B references parent requirement which doesn't exist: NOPE." },
    { '', 0, 0, '[SECTION] elements are no longer supported by StrictDoc. See the migration guide for more details:' },
  }, qf())
end

T['real :make'] = function()
  if vim.fn.executable('strictdoc') == 0 then print('skip: no strictdoc'); return end
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir)
  vim.fn.writefile({ '[DOCUMENT]', 'TITLE: Bad', '', '[REQUIREMENT]', 'UID A' }, dir .. '/bad.sdoc')
  vim.cmd.cd(dir)
  vim.cmd('edit bad.sdoc')
  vim.cmd('silent make!')
  vim.cmd.cd('-')
  local e = qf()
  H.eq(1, #e)
  H.eq(dir .. '/bad.sdoc', vim.fn.fnamemodify(e[1][1], ':p'))
  H.eq({ 5, 4 }, { e[1][2], e[1][3] })
end

return T

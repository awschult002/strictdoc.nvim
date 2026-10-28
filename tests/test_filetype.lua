local H = require('helpers')
local T = {}

T['.sdoc is detected and all runtime files load'] = function()
  H.open('relations.sdoc')
  H.eq('sdoc', vim.bo.filetype)
  H.eq('sdoc', vim.b.current_syntax)
  H.eq(1, vim.b.did_ftplugin)
  H.eq("v:lua.require'strictdoc.indent'.expr()", vim.bo.indentexpr)
  H.eq('expr', vim.wo.foldmethod)
  H.eq("v:lua.require'strictdoc.tags'.tagfunc", vim.bo.tagfunc)
  H.eq(2, vim.fn.exists(':StrictdocOutline'))
end

T['help file has valid tags'] = function()
  local dir = vim.fn.tempname()
  vim.fn.mkdir(dir)
  vim.fn.writefile(H.read(H.root .. '/doc/strictdoc.txt'), dir .. '/strictdoc.txt')
  vim.cmd('helptags ' .. dir)
  local tags = table.concat(H.read(dir .. '/tags'), '\n')
  for _, t in ipairs({ 'strictdoc.txt', ':StrictdocOutline', 'g:strictdoc_no_mappings' }) do
    assert(tags:find(t, 1, true), 'missing help tag ' .. t)
  end
end

T['undo_ftplugin removes mappings'] = function()
  H.open('relations.sdoc')
  vim.cmd('setfiletype text | set filetype=text')
  H.eq('', vim.fn.maparg('gr', 'x'))
  H.eq('', vim.fn.maparg(']]', 'n'))
end

T['g:strictdoc_no_mappings keeps <Plug> maps only'] = function()
  vim.g.strictdoc_no_mappings = 1
  H.open('relations.sdoc')
  vim.g.strictdoc_no_mappings = nil
  H.eq('', vim.fn.maparg('gr', 'x'))
  assert(vim.fn.maparg('<Plug>(strictdoc-wrap-requirement)', 'x') ~= '')
end

return T

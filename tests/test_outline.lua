local H = require('helpers')
local T = {}

local function outline_buf()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.bo[b].filetype == 'strictdoc-outline' then return b, w end
  end
end

T['outline lists nested nodes with titles and UIDs'] = function()
  H.open('nested_composite.sdoc')
  vim.cmd('StrictdocOutline')
  local b, w = outline_buf()
  H.eq({ 'REQUIREMENT: Req_1 [REQ-1]', '  REQUIREMENT: Req_1_1 [REQ-2]',
         '    REQUIREMENT: Req_1_1_1 [REQ-3]' }, H.lines(b))
  H.eq(vim.o.columns, vim.api.nvim_win_get_position(w)[2] + vim.api.nvim_win_get_width(w))
  vim.cmd('StrictdocOutline')
  H.eq(nil, (outline_buf()))
end

T['<CR> jumps, the tree refreshes on write and folds'] = function()
  local tmp = vim.fn.tempname() .. '.sdoc'
  vim.fn.writefile(H.read(H.fixtures .. 'anchors.sdoc'), tmp)
  vim.cmd('silent edit ' .. tmp)
  local src = vim.api.nvim_get_current_win()
  vim.cmd('StrictdocOutline')
  local b, w = outline_buf()
  H.eq({ 'Referencing section', 'Section with anchor' }, H.lines(b))
  vim.api.nvim_set_current_win(w)
  vim.api.nvim_win_set_cursor(w, { 2, 0 })
  H.feed('<CR>')
  H.eq(src, vim.api.nvim_get_current_win())
  H.eq(18, vim.fn.line('.'))
  vim.api.nvim_buf_set_lines(0, 18, 19, false, { 'UID: SEC-2', 'TITLE: Renamed' })
  vim.api.nvim_buf_set_lines(0, 22, 22, false, { 'UID: TXT-1' })
  vim.cmd('silent write')
  H.eq({ 'Referencing section', 'Renamed [SEC-2]', '  TEXT [TXT-1]' }, H.lines(b))
  H.eq(1, vim.api.nvim_win_call(w, function() return vim.fn.foldlevel(3) end))
end

return T

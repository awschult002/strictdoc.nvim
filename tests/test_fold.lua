local H = require('helpers')
local T = {}

local function levels()
  local out = {}
  for l = 1, vim.fn.line('$') do out[l] = vim.fn.foldlevel(l) end
  return out
end

T['nested composite nodes fold by depth'] = function()
  H.open('expected/nested_composite.sdoc')
  local lv = levels()
  H.eq(1, lv[1], '[DOCUMENT]')
  H.eq(1, lv[4], '[GRAMMAR]')
  H.eq(0, lv[3], 'blank between top-level nodes')
  H.eq({ 1, 1, 2, 2, 3, 3, 3, 2, 1 },
    { lv[30], lv[35], lv[37], lv[42], lv[44], lv[49], lv[51], lv[53], lv[55] })
  H.eq('>3', require('strictdoc.fold').expr(44))
end

T['legacy [SECTION] and leaf nodes fold'] = function()
  H.open('anchors.sdoc')
  local lv = levels()
  H.eq({ 1, 1, 0, 1, 1, 1, 2, 2, 1, 1, 0, 1, 1 },
    { lv[1], lv[2], lv[3], lv[4], lv[5], lv[6], lv[7], lv[14], lv[15], lv[16], lv[17], lv[18], lv[19] })
  vim.cmd('normal! zM')
  H.eq(4, vim.fn.foldclosed(10))
  H.eq(16, vim.fn.foldclosedend(10))
end

return T

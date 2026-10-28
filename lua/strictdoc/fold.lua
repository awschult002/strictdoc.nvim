-- foldexpr: every node folds; sections and [[NODE]]s nest their children.
local scan = require('strictdoc.scan')
local M = {}
local cache = {}

local function levels(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local c = cache[buf]
  if c and c.tick == tick then return c.lv end
  local lv = {}
  for _, n in ipairs(scan.nodes(buf)) do
    local l = n.depth + 1
    for i = n.lnum, n.last do lv[i] = tostring(l) end
    lv[n.lnum] = '>' .. l
  end
  cache[buf] = { tick = tick, lv = lv }
  return lv
end

-- Blank lines between children take their parent's level (or 0).
function M.expr(lnum)
  return levels(vim.api.nvim_get_current_buf())[lnum or vim.v.lnum] or '0'
end

return M

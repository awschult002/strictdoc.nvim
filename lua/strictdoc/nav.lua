-- Node motions (]] [[) and the node text object (an / in).
local scan = require('strictdoc.scan')
local M = {}

function M.jump(dir)
  local cur = vim.fn.line('.')
  local nodes, target = scan.nodes(0), nil
  for _ = 1, vim.v.count1 do
    local found
    for i = dir > 0 and 1 or #nodes, dir > 0 and #nodes or 1, dir do
      local l = nodes[i].lnum
      if (dir > 0 and l > cur) or (dir < 0 and l < cur) then found = l; break end
    end
    if not found then break end
    target, cur = found, found
  end
  if not target then return end
  if vim.fn.mode() == 'n' then vim.cmd("normal! m'") end
  vim.api.nvim_win_set_cursor(0, { target, 0 })
end

-- Innermost node containing the cursor.
local function around(lnum)
  local best
  for _, n in ipairs(scan.nodes(0)) do
    if n.lnum <= lnum and lnum <= n.last then best = n end
  end
  return best
end

function M.select(inner)
  local n = around(vim.fn.line('.'))
  if not n then return end
  local s, e = n.lnum, n.last
  if inner then
    s = s + 1
    if n.section then
      e = e - 1
      while s <= e and vim.fn.getline(s):match('%S') do s = s + 1 end -- skip header
    end
    while s <= e and not vim.fn.getline(s):match('%S') do s = s + 1 end
    while e >= s and not vim.fn.getline(e):match('%S') do e = e - 1 end
    if s > e then return end
  end
  vim.cmd(('normal! %dGV%dG'):format(s, e))
end

return M

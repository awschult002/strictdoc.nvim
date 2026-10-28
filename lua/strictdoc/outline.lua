-- :StrictdocOutline - a right-side scratch tree of sections and nodes.
local scan = require('strictdoc.scan')
local M = {}
local views = {} -- source buf -> { buf, win, map }

-- Prose [TEXT] nodes only show up when they carry a UID.
local skip = { DOCUMENT = true, GRAMMAR = true }

-- Outline lines and the source line each one points at.
function M.lines(src)
  local lines, map = {}, {}
  for _, n in ipairs(scan.nodes(src)) do
    if not skip[n.tag] and (n.tag ~= 'TEXT' or n.uid) then
      local label = n.title or n.tag
      if n.tag ~= 'SECTION' and n.title then label = n.tag .. ': ' .. label end
      if n.uid then label = label .. ' [' .. n.uid .. ']' end
      lines[#lines + 1] = string.rep('  ', n.depth) .. label
      map[#lines] = n.lnum
    end
  end
  return lines, map
end

local function render(src)
  local v = views[src]
  if not v or not vim.api.nvim_buf_is_valid(v.buf) then return end
  local lines
  lines, v.map = M.lines(src)
  vim.bo[v.buf].modifiable = true
  vim.api.nvim_buf_set_lines(v.buf, 0, -1, false, lines)
  vim.bo[v.buf].modifiable = false
end

local function goto_node(src)
  local v = views[src]
  local lnum = v and v.map[vim.fn.line('.')]
  if not lnum then return end
  local win = vim.fn.bufwinid(src)
  if win == -1 then return end
  vim.api.nvim_set_current_win(win)
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(win, { lnum, 0 })
  vim.cmd('normal! zvzz')
end

function M.toggle()
  local src = vim.b.strictdoc_outline_src or vim.api.nvim_get_current_buf()
  local v = views[src]
  if v and vim.api.nvim_win_is_valid(v.win) then
    vim.api.nvim_win_close(v.win, true)
    views[src] = nil
    return
  end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].filetype = 'strictdoc-outline'
  vim.b[buf].strictdoc_outline_src = src
  vim.bo[buf].shiftwidth = 2
  local win = vim.api.nvim_open_win(buf, false,
    { split = 'right', win = -1, width = math.max(30, math.floor(vim.o.columns / 4)) })
  local wo = vim.wo[win]
  wo.number, wo.relativenumber, wo.wrap, wo.cursorline = false, false, false, true
  wo.foldmethod, wo.foldlevel, wo.winfixwidth = 'indent', 99, true
  views[src] = { buf = buf, win = win, map = {} }
  vim.keymap.set('n', '<CR>', function() goto_node(src) end, { buffer = buf, desc = 'Jump to node' })
  vim.keymap.set('n', 'q', M.toggle, { buffer = buf, desc = 'Close outline' })
  local group = vim.api.nvim_create_augroup('strictdoc_outline_' .. src, {})
  vim.api.nvim_create_autocmd('BufWritePost', { group = group, buffer = src,
    callback = function() render(src) end })
  vim.api.nvim_create_autocmd('BufWipeout', { group = group, buffer = buf,
    callback = function() views[src] = nil; pcall(vim.api.nvim_del_augroup_by_id, group) end })
  render(src)
end

return M

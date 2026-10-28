-- Visual wrap mappings: gr (REQUIREMENT), gt (TEXT), gs (SECTION).
local indent = require('strictdoc.indent')
local M = {}

local function block(tag, ind, lines)
  local out = { ind .. '[' .. tag .. ']', ind .. 'STATEMENT: >>>' }
  vim.list_extend(out, lines)
  out[#out + 1] = ind .. '<<<'
  return out
end

-- kind: 'requirement' | 'text' | 'section'. Uses the last visual selection.
function M.wrap(kind)
  local s, e = vim.fn.line("'<"), vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  local ind = string.rep(' ', indent.marker(0, s))
  if kind ~= 'section' then
    vim.api.nvim_buf_set_lines(0, s - 1, e, false,
      block(kind == 'text' and 'TEXT' or 'REQUIREMENT', ind, lines))
    vim.api.nvim_win_set_cursor(0, { s, 0 })
    return
  end
  local open, close = '[SECTION]', '[/SECTION]'
  if vim.g.strictdoc_composite_sections == 1 then
    open, close = '[[SECTION]]', '[[/SECTION]]'
  end
  local out = { ind .. open, 'TITLE: ', '' }
  vim.list_extend(out, lines)
  vim.list_extend(out, { '', ind .. close })
  vim.api.nvim_buf_set_lines(0, s - 1, e, false, out)
  -- Let indentexpr place the title and the selection one level in.
  vim.cmd(('silent keepjumps normal! %dGV%dG='):format(s + 1, s + #out - 2))
  local title = vim.fn.getline(s + 1)
  vim.api.nvim_win_set_cursor(0, { s + 1, #title })
  vim.cmd('startinsert!')
end

return M

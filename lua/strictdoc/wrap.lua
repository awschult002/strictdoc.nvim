-- Visual wrap mappings: gr (REQUIREMENT), gt (TEXT), gs (SECTION).
local M = {}

-- Inserted markers are flat; strictdoc.virtual shows the nesting.
local function block(tag, lines)
  local out = { '[' .. tag .. ']', 'STATEMENT: >>>' }
  vim.list_extend(out, lines)
  out[#out + 1] = '<<<'
  return out
end

-- kind: 'requirement' | 'text' | 'section'. Uses the last visual selection.
function M.wrap(kind)
  local s, e = vim.fn.line("'<"), vim.fn.line("'>")
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  if kind ~= 'section' then
    vim.api.nvim_buf_set_lines(0, s - 1, e, false,
      block(kind == 'text' and 'TEXT' or 'REQUIREMENT', lines))
    vim.api.nvim_win_set_cursor(0, { s, 0 })
    return
  end
  local open, close = '[[SECTION]]', '[[/SECTION]]'
  if vim.g.strictdoc_composite_sections == 0 then
    open, close = '[SECTION]', '[/SECTION]'
  end
  local out = { open, 'TITLE: ', '' }
  vim.list_extend(out, lines)
  vim.list_extend(out, { '', close })
  vim.api.nvim_buf_set_lines(0, s - 1, e, false, out)
  vim.api.nvim_win_set_cursor(0, { s + 1, #'TITLE: ' })
  vim.cmd('startinsert!')
end

return M

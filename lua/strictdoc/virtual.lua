-- Virtual indent: show nesting with inline padding extmarks, one
-- shiftwidth per level, without touching the (flat) buffer text.
local indent = require('strictdoc.indent')
local M = {}
local ns = vim.api.nvim_create_namespace('strictdoc_virtual_indent')
M.ns = ns

function M.enabled()
  return vim.g.strictdoc_virtual_indent ~= 0
end

function M.refresh(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  if not M.enabled() then return end
  local sw, st, lvl = vim.fn.shiftwidth(), indent.new(), nil
  for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    _, lvl, st = indent.step(st, l)
    if lvl > 0 and l ~= '' then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, {
        virt_text = { { string.rep(' ', sw * lvl) } },
        virt_text_pos = 'inline', right_gravity = false,
      })
    end
  end
end

function M.attach(buf)
  local group = vim.api.nvim_create_augroup('strictdoc_virtual_' .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI' }, {
    group = group, buffer = buf, callback = function() M.refresh(buf) end,
  })
  M.refresh(buf)
end

function M.detach(buf)
  pcall(vim.api.nvim_del_augroup_by_name, 'strictdoc_virtual_' .. buf)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
end

return M

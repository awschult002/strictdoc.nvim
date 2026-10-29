-- Blank-line normalization: StrictDoc needs exactly one empty line before
-- every node marker ([TEXT], [[SECTION]], [[/SECTION]], [DOCUMENT_FROM_FILE],
-- ...) except the leading [DOCUMENT]; none or two fail to parse. Text in
-- >>> <<< blocks and [FREETEXT] is never touched. Indent stays flat via `=`.
local step, new = require('strictdoc.indent').step, require('strictdoc.indent').new
local classify = require('strictdoc.scan').classify
local M = {}

-- Fix blank lines before markers in l1..l2; returns the new l2.
function M.blank_lines(buf, l1, l2)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local lines = vim.api.nvim_buf_get_lines(buf, 0, l2, false)
  local st, edits = new(), {}
  for i, line in ipairs(lines) do
    local kind = classify(line)
    if i >= l1 and not st.block and not st.ft and i > 1
      and (kind == 'open' or kind == 'close' or kind == 'leaf' or kind == 'freetext') then
      local j = i - 1
      while j >= 1 and classify(lines[j]) == 'blank' do j = j - 1 end
      if j >= 1 and i - j ~= 2 then edits[#edits + 1] = { j, i - 1 } end
    end
    _, _, st = step(st, line)
  end
  for k = #edits, 1, -1 do -- replace lines j+1..i-1 with one blank
    local e = edits[k]
    vim.api.nvim_buf_set_lines(buf, e[1], e[2], false, { '' })
    l2 = l2 + 1 - (e[2] - e[1])
  end
  return l2
end

function M.format(l1, l2)
  l2 = M.blank_lines(0, l1, l2)
  vim.cmd(('silent keepjumps normal! %dG=%dG'):format(l1, l2))
end

function M.formatexpr()
  if vim.fn.mode():find('[iR]') then return 1 end -- auto-wrap: default
  M.format(vim.v.lnum, vim.v.lnum + vim.v.count - 1)
  return 0
end

function M.opfunc()
  M.format(vim.fn.line("'["), vim.fn.line("']"))
end

function M.operator()
  vim.o.operatorfunc = "v:lua.require'strictdoc.format'.opfunc"
  return 'g@'
end

return M

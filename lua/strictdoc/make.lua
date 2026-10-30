-- :make post-processing. StrictDoc reports RST errors with the line inside the
-- >>> block and the block's text, but no file. Find that text in the .sdoc
-- files and point the quickfix entry at the real file and line.
local M = {}

-- First line of `frag` inside a >>> block of `lines`, or nil.
local function find(lines, frag)
  for i, l in ipairs(lines) do
    if l:match('>>>%s*$') then
      local ok = true
      for j, f in ipairs(frag) do
        if lines[i + j] ~= f then ok = false; break end
      end
      if ok then return i + 1 end
    end
  end
end

local function locate(frag)
  local cur = vim.api.nvim_buf_get_name(0)
  local files = { cur }
  for _, f in ipairs(vim.fn.globpath('.', '**/*.sdoc', false, true)) do
    f = vim.fn.fnamemodify(f, ':p')
    if f ~= cur then files[#files + 1] = f end
  end
  for _, f in ipairs(files) do
    local b = vim.fn.bufnr(f)
    local lines = b > 0 and vim.api.nvim_buf_is_loaded(b)
      and vim.api.nvim_buf_get_lines(b, 0, -1, false)
      or (vim.fn.filereadable(f) == 1 and vim.fn.readfile(f) or {})
    local l = find(lines, frag)
    if l then return f, l end
  end
end

-- The errorformat puts the RST message on the first text line and the block's
-- text after it; lnum is the line inside the block.
function M.fixup()
  local items, changed = vim.fn.getqflist(), false
  for _, e in ipairs(items) do
    if e.bufnr == 0 and e.lnum > 0 and e.text:find('\n') then
      local frag = vim.split(e.text, '\n', { plain = true })
      local msg = table.remove(frag, 1)
      local f, l = locate(frag)
      if f then
        e.bufnr, e.filename, e.lnum = 0, f, l + e.lnum - 1
      end
      e.text, changed = 'RST: ' .. msg, true
    end
  end
  if changed then
    vim.fn.setqflist({}, 'r', { items = items, title = vim.fn.getqflist({ title = 1 }).title })
  end
end

return M

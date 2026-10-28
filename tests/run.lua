-- nvim --headless -u NONE -l tests/run.lua [test_file ...]
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
package.path = root .. '/tests/?.lua;' .. package.path

-- Install the plugin the way a user would: as a pack/*/start package.
local pack = vim.fn.tempname()
vim.fn.mkdir(pack .. '/pack/test/start', 'p')
vim.uv.fs_symlink(root, pack .. '/pack/test/start/strictdoc.nvim')
vim.o.packpath = pack
vim.cmd('packloadall')
vim.cmd('filetype plugin indent on')
vim.cmd('syntax on')
vim.o.shortmess = vim.o.shortmess .. 'AF'
vim.o.report = 10000

local files = #_G.arg > 0 and _G.arg or vim.fn.glob(root .. '/tests/test_*.lua', false, true)
local pass, fail = 0, 0
for _, f in ipairs(files) do
  local name = vim.fn.fnamemodify(f, ':t:r')
  local cases = dofile(f)
  local keys = vim.tbl_keys(cases)
  table.sort(keys)
  for _, k in ipairs(keys) do
    vim.cmd('silent! %bwipeout!')
    vim.g.strictdoc_virtual_indent, vim.g.strictdoc_composite_sections = nil, nil
    local ok, err = pcall(cases[k])
    if ok then
      pass = pass + 1
      print('ok   ' .. name .. ': ' .. k)
    else
      fail = fail + 1
      print('FAIL ' .. name .. ': ' .. k .. '\n     ' .. tostring(err))
    end
  end
end
io.stdout:write(('\n%d passed, %d failed\n'):format(pass, fail))
vim.cmd(fail > 0 and 'cquit 1' or 'quitall!')

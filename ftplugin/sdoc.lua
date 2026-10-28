if vim.b.did_ftplugin then return end
vim.b.did_ftplugin = 1

local o = vim.opt_local
o.foldmethod = 'expr'
o.foldexpr = "v:lua.require'strictdoc.fold'.expr()"
o.foldlevel = 99
o.tagfunc = "v:lua.require'strictdoc.tags'.tagfunc"
o.commentstring = ''
-- Tabs would end up inside the grammar's fixed two-space lists.
o.expandtab = true
o.shiftwidth = 2
o.softtabstop = 2

vim.cmd.compiler('strictdoc')

local undo = { 'setl fdm< fde< fdl< tfu< cms< et< sw< sts< mp< efm<', 'unlet! b:current_compiler', 'silent! delcommand -buffer StrictdocOutline' }
local function map(modes, lhs, rhs, desc)
  vim.keymap.set(vim.split(modes, ''), lhs, rhs, { buffer = true, silent = true, desc = desc })
  for m in modes:gmatch('.') do
    undo[#undo + 1] = ("exe 'silent! %sunmap <buffer> %s'"):format(m, lhs)
  end
end

local nav = "<Cmd>lua require'strictdoc.nav'"
local obj = ":<C-u>lua require'strictdoc.nav'"
local wrap = ":<C-u>lua require'strictdoc.wrap'.wrap"
map('nxo', '<Plug>(strictdoc-next-node)', nav .. '.jump(1)<CR>', 'Next StrictDoc node')
map('nxo', '<Plug>(strictdoc-prev-node)', nav .. '.jump(-1)<CR>', 'Previous StrictDoc node')
map('xo', '<Plug>(strictdoc-node-outer)', obj .. '.select(false)<CR>', 'Around node')
map('xo', '<Plug>(strictdoc-node-inner)', obj .. '.select(true)<CR>', 'Inside node')
map('x', '<Plug>(strictdoc-wrap-requirement)', wrap .. "('requirement')<CR>", 'Wrap in [REQUIREMENT]')
map('x', '<Plug>(strictdoc-wrap-text)', wrap .. "('text')<CR>", 'Wrap in [TEXT]')
map('x', '<Plug>(strictdoc-wrap-section)', wrap .. "('section')<CR>", 'Wrap in [SECTION]')
map('n', '<Plug>(strictdoc-outline)', "<Cmd>lua require'strictdoc.outline'.toggle()<CR>", 'Toggle outline')

local off = vim.g.strictdoc_no_mappings
if not off or off == 0 then
  map('nxo', ']]', '<Plug>(strictdoc-next-node)')
  map('nxo', '[[', '<Plug>(strictdoc-prev-node)')
  map('xo', 'an', '<Plug>(strictdoc-node-outer)')
  map('xo', 'in', '<Plug>(strictdoc-node-inner)')
  map('x', 'gr', '<Plug>(strictdoc-wrap-requirement)')
  map('x', 'gt', '<Plug>(strictdoc-wrap-text)')
  map('x', 'gs', '<Plug>(strictdoc-wrap-section)')
end

vim.api.nvim_buf_create_user_command(0, 'StrictdocOutline',
  function() require('strictdoc.outline').toggle() end, { desc = 'Toggle StrictDoc outline' })

require('strictdoc.virtual').attach(vim.api.nvim_get_current_buf())
undo[#undo + 1] = "lua require'strictdoc.virtual'.detach(vim.api.nvim_get_current_buf())"

vim.b.undo_ftplugin = table.concat(undo, ' | ')

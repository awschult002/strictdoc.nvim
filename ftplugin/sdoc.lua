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
-- gq/=/:StrictdocFormat also fix blank lines before node markers.
o.formatexpr = "v:lua.require'strictdoc.format'.formatexpr()"

vim.cmd.compiler('strictdoc')
vim.api.nvim_create_autocmd('QuickFixCmdPost', {
  group = vim.api.nvim_create_augroup('strictdoc_make', { clear = true }), pattern = 'make',
  callback = function()
    if vim.b.current_compiler == 'strictdoc' then require('strictdoc.make').fixup() end
  end,
})

local undo = { 'setl fdm< fde< fdl< tfu< cms< et< sw< sts< fex< mp< efm<', 'unlet! b:current_compiler', 'silent! delcommand -buffer StrictdocOutline', 'silent! delcommand -buffer StrictdocFormat', "exe 'silent! au! strictdoc_format * <buffer>'" }
local function map(modes, lhs, rhs, desc, expr)
  vim.keymap.set(vim.split(modes, ''), lhs, rhs, { buffer = true, silent = true, desc = desc, expr = expr })
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
map('xo', '<Plug>(strictdoc-block-outer)', obj .. '.select_block(false)<CR>', 'Around >>> <<< block')
map('xo', '<Plug>(strictdoc-block-inner)', obj .. '.select_block(true)<CR>', 'Inside >>> <<< block')
map('x', '<Plug>(strictdoc-wrap-requirement)', wrap .. "('requirement')<CR>", 'Wrap in [REQUIREMENT]')
map('x', '<Plug>(strictdoc-wrap-text)', wrap .. "('text')<CR>", 'Wrap in [TEXT]')
map('x', '<Plug>(strictdoc-wrap-section)', wrap .. "('section')<CR>", 'Wrap in [SECTION]')
local fmt = function() return require('strictdoc.format').operator() end
map('nx', '<Plug>(strictdoc-format)', fmt, 'Format (indent + blank lines)', true)
map('n', '<Plug>(strictdoc-format-line)', function() return fmt() .. '_' end, 'Format line', true)
map('n', '<Plug>(strictdoc-outline)', "<Cmd>lua require'strictdoc.outline'.toggle()<CR>", 'Toggle outline')

local off = vim.g.strictdoc_no_mappings
if not off or off == 0 then
  map('nxo', ']]', '<Plug>(strictdoc-next-node)')
  map('nxo', '[[', '<Plug>(strictdoc-prev-node)')
  map('xo', 'an', '<Plug>(strictdoc-node-outer)')
  map('xo', 'in', '<Plug>(strictdoc-node-inner)')
  map('xo', 'at', '<Plug>(strictdoc-block-outer)')
  map('xo', 'it', '<Plug>(strictdoc-block-inner)')
  map('x', 'gr', '<Plug>(strictdoc-wrap-requirement)')
  map('x', 'gt', '<Plug>(strictdoc-wrap-text)')
  map('x', 'gs', '<Plug>(strictdoc-wrap-section)')
  map('nx', '=', '<Plug>(strictdoc-format)')
  map('n', '==', '<Plug>(strictdoc-format-line)')
end

vim.api.nvim_buf_create_user_command(0, 'StrictdocOutline',
  function() require('strictdoc.outline').toggle() end, { desc = 'Toggle StrictDoc outline' })

vim.api.nvim_buf_create_user_command(0, 'StrictdocFormat',
  function(a) require('strictdoc.format').format(a.line1, a.line2) end,
  { range = '%', desc = 'Fix indent and blank lines before node markers' })
local fos = vim.g.strictdoc_format_on_save
if fos and fos ~= 0 then
  vim.api.nvim_create_autocmd('BufWritePre', {
    group = vim.api.nvim_create_augroup('strictdoc_format', { clear = false }), buffer = 0,
    callback = function()
      local view = vim.fn.winsaveview()
      require('strictdoc.format').format(1, vim.api.nvim_buf_line_count(0))
      vim.fn.winrestview(view)
    end,
  })
end

require('strictdoc.virtual').attach(vim.api.nvim_get_current_buf())
undo[#undo + 1] = "lua require'strictdoc.virtual'.detach(vim.api.nvim_get_current_buf())"

vim.b.undo_ftplugin = table.concat(undo, ' | ')

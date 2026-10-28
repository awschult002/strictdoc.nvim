-- indentexpr: column 0 for markers and fields, fixed 2-space sub-indent for
-- grammar-defined lists (RELATIONS, OPTIONS, VIEWS, GRAMMAR), and -1 (keep)
-- for text between >>> and <<<. Nesting is shown by strictdoc.virtual.
local classify = require('strictdoc.scan').classify
local M = {}

local function sub(ctx, t)
  local dkey = t:match('^%- ([%w_%-]+):')
  local key = dkey or t:match('^([%w_%-]+):')
  local dash = t:match('^%- ') ~= nil
  if t == 'RELATIONS:' then
    if ctx == 'grammar' then return 1, ctx end
    return 0, 'rel'
  elseif t == 'OPTIONS:' then return 0, 'options'
  elseif t == 'METADATA:' then return 0, 'metadata'
  elseif t == 'VIEWS:' then return 0, 'views'
  elseif ctx == 'rel' then
    return dkey == 'TYPE' and 0 or 1, ctx
  elseif ctx == 'options' or ctx == 'metadata' then
    return 1, ctx
  elseif ctx == 'views' then
    if dkey == 'ID' then return 0, ctx end
    if dkey == 'NAME' or key == 'VISIBLE_FIELDS' then return 2, ctx end
    if key == 'PLACEMENT' then return 3, ctx end
    return 1, ctx
  elseif ctx == 'grammar' then
    if key == 'ELEMENTS' or key == 'IMPORT_FROM_FILE' or dkey == 'TAG' then return 0, ctx end
    if key == 'PROPERTIES' or key == 'FIELDS' or dkey == 'TITLE' or dkey == 'TYPE' then
      return 1, ctx
    end
    return 2, ctx
  end
  return dash and 1 or 0, ctx
end

local function new() return { depth = 0 } end

-- Files stay flat: markers and fields in column 0 (StrictDoc rejects
-- leading whitespace), grammar lists keep their fixed two-space steps.
-- Returns the indent for `line` given the state before it (-1 = keep),
-- its nesting level (shown by strictdoc.virtual), and the next state.
function M.step(st, line)
  local kind, tag = classify(line)
  local s = { depth = st.depth, ctx = st.ctx, block = st.block, ft = st.ft, bind = st.bind }
  local ind, lvl = nil, s.depth
  if s.block then
    ind = -1 -- nested `KEY: >>>` examples count up, `<<<` counts down
    if kind == 'mlstart' then s.block = s.block + 1
    elseif kind == 'mlend' then
      s.block = s.block - 1
      if s.block == 0 then ind, s.block = s.bind, false end
    end
  elseif s.ft then
    if kind == 'ftend' then ind, s.ft = 0, false else ind = -1 end
  elseif kind == 'blank' then
    ind, s.ctx = 0, nil
  elseif kind == 'open' then
    ind, s.depth, s.ctx = 0, s.depth + 1, nil
  elseif kind == 'close' then
    s.depth = math.max(0, s.depth - 1)
    ind, lvl, s.ctx = 0, s.depth, nil
  elseif kind == 'leaf' or kind == 'freetext' then
    ind = 0
    s.ctx = tag == 'GRAMMAR' and 'grammar' or nil
    s.ft = kind == 'freetext'
  else
    local n
    n, s.ctx = sub(s.ctx, line:match('^%s*(.-)%s*$'))
    ind = 2 * n
    if kind == 'mlstart' then s.block, s.bind = 1, ind end
  end
  return ind, lvl, s
end

-- State before line `lnum` of `buf`, scanning from the top.
function M.state(buf, lnum)
  local st = new()
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, lnum - 1, false)) do
    _, _, st = M.step(st, l)
  end
  return st
end

-- `=` calls this line by line, top to bottom; reuse the state from the
-- previous call when at most that line's indent changed in between.
local cache = {}

function M.expr()
  local buf, lnum = vim.api.nvim_get_current_buf(), vim.v.lnum
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local c, st = cache[buf], nil
  if c and c.lnum < lnum and lnum - c.lnum <= 50 and tick - c.tick <= 1 then
    st = c.st -- `=` skips empty lines, so catch up over the gap
    for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, c.lnum - 1, lnum - 1, false)) do
      _, _, st = M.step(st, l)
    end
  else
    st = M.state(buf, lnum)
  end
  cache[buf] = { lnum = lnum, tick = tick, st = st }
  return (M.step(st, vim.fn.getline(lnum)))
end

M.new = new
return M

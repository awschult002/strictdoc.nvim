-- indentexpr: one shiftwidth per open [SECTION]/[[NODE]], fixed 2-space
-- sub-indent for grammar-defined lists (RELATIONS, OPTIONS, VIEWS, GRAMMAR),
-- and -1 (keep) for text between >>> and <<<.
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

-- Indent for `line` given the state before it; returns indent, next state.
function M.step(st, line, sw)
  local kind, tag = classify(line)
  local s = { depth = st.depth, ctx = st.ctx, block = st.block, ft = st.ft, bind = st.bind }
  local ind
  if s.block then
    ind = -1 -- nested `KEY: >>>` examples count up, `<<<` counts down
    if kind == 'mlstart' then s.block = s.block + 1
    elseif kind == 'mlend' then
      s.block = s.block - 1
      if s.block == 0 then ind, s.block = s.bind, false end
    end
  elseif s.ft then
    if kind == 'ftend' then ind, s.ft = s.depth * sw, false else ind = -1 end
  elseif kind == 'blank' then
    ind, s.ctx = 0, nil
  elseif kind == 'open' then
    ind, s.depth, s.ctx = s.depth * sw, s.depth + 1, nil
  elseif kind == 'close' then
    s.depth = math.max(0, s.depth - 1)
    ind, s.ctx = s.depth * sw, nil
  elseif kind == 'leaf' or kind == 'freetext' then
    ind = s.depth * sw
    s.ctx = tag == 'GRAMMAR' and 'grammar' or nil
    s.ft = kind == 'freetext'
  else
    local n
    n, s.ctx = sub(s.ctx, line:match('^%s*(.-)%s*$'))
    ind = s.depth * sw + 2 * n
    if kind == 'mlstart' then s.block, s.bind = 1, ind end
  end
  return ind, s
end

local function width()
  if vim.g.strictdoc_indent == 0 then return 0 end
  return vim.fn.shiftwidth()
end

-- State before line `lnum` of `buf`, scanning from the top.
function M.state(buf, lnum)
  local st, sw = new(), width()
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, lnum - 1, false)) do
    _, st = M.step(st, l, sw)
  end
  return st
end

-- Indent of a node marker inserted at `lnum`.
function M.marker(buf, lnum)
  return M.state(buf, lnum).depth * width()
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
      _, st = M.step(st, l, width())
    end
  else
    st = M.state(buf, lnum)
  end
  cache[buf] = { lnum = lnum, tick = tick, st = st }
  return (M.step(st, vim.fn.getline(lnum), width()))
end

return M

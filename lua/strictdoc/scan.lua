-- Line classifier and node scanner shared by indent, fold, outline and tags.
local M = {}

-- Block markers are matched by content, never by indentation: a line that
-- is just `<<<` closes the innermost open `KEY: >>>` (examples may nest).

-- Classify one line. Returns kind, tag. Kinds: blank, open, close, leaf,
-- freetext, ftend, mlstart, mlend, field.
function M.classify(line)
  local t = line:match('^%s*(.-)%s*$')
  if t == '' then return 'blank' end
  local tag = t:match('^%[%[/([A-Z][A-Z_]*)%]%]$')
  if tag then return 'close', tag end
  tag = t:match('^%[%[([A-Z][A-Z_]*)%]%]$')
  if tag then return 'open', tag end
  tag = t:match('^%[/([A-Z][A-Z_]*)%]$')
  if tag == 'SECTION' then return 'close', tag end
  if tag == 'FREETEXT' then return 'ftend', tag end
  tag = t:match('^%[([A-Z][A-Z_]*)%]$')
  if tag == 'SECTION' then return 'open', tag end
  if tag == 'FREETEXT' then return 'freetext', tag end
  if tag then return 'leaf', tag end
  if t == '<<<' then return 'mlend' end
  if t:match('^[A-Z][%w_%-]*: >>>$') then return 'mlstart' end
  return 'field'
end

local function parse(lines)
  local nodes, stack, cur, leaf = {}, {}, nil, nil
  local block, ft = 0, false -- block: open `KEY: >>>` nesting depth
  for i, line in ipairs(lines) do
    local kind, tag = M.classify(line)
    local marker = block == 0 and not ft and
      (kind == 'open' or kind == 'close' or kind == 'leaf' or kind == 'freetext')
    if leaf and kind ~= 'blank' and not marker then leaf.last = i end
    if block > 0 then
      block = block + (kind == 'mlstart' and 1 or kind == 'mlend' and -1 or 0)
    elseif ft then
      ft = kind ~= 'ftend'
    elseif kind == 'open' or kind == 'leaf' or kind == 'freetext' then
      cur = { lnum = i, last = i, tag = tag, depth = #stack,
              section = kind == 'open' }
      nodes[#nodes + 1] = cur
      if kind == 'open' then table.insert(stack, cur); leaf = nil else leaf = cur end
      ft = kind == 'freetext'
    elseif kind == 'close' then
      local n = table.remove(stack)
      if n then n.last = i end
      cur, leaf = nil, nil
    elseif kind == 'mlstart' then
      block = 1
    elseif kind == 'field' and cur then
      local k, v = line:match('^%s*([A-Z]+): (.+)$')
      if (k == 'TITLE' or k == 'UID') and not cur[k:lower()] then
        cur[k:lower()] = v
      end
    end
  end
  for _, n in ipairs(stack) do n.last = #lines end
  return nodes
end

local cache = {}

-- Nodes of a buffer in document order, cached per changedtick:
-- { lnum, last, tag, depth, section, title?, uid? }
function M.nodes(buf)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local c = cache[buf]
  if not c or c.tick ~= tick then
    c = { tick = tick, nodes = parse(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) }
    cache[buf] = c
  end
  return c.nodes
end

M.parse = parse
return M

-- tagfunc: jump to UIDs, section/node titles and [ANCHOR: ...] names with
-- Ctrl-], :tag and friends. Falls back to *.sdoc files in the project for UIDs.
local scan = require('strictdoc.scan')
local M = {}

-- UID-ish word under the cursor ([LINK: X] targets included).
local function cword()
  local line, col = vim.fn.getline('.'), vim.fn.col('.')
  local s = 1
  while true do
    local a, b = line:find('[%w_%-%./]+', s)
    if not a then return vim.fn.expand('<cword>') end
    if a <= col and col <= b then return line:sub(a, b) end
    s = b + 1
  end
end

local function local_tags(buf, name, fuzzy)
  local file, out = vim.api.nvim_buf_get_name(buf), {}
  local function add(n, lnum, kind)
    out[#out + 1] = { name = n, filename = file, cmd = tostring(lnum), kind = kind }
  end
  for _, n in ipairs(scan.nodes(buf)) do
    if n.uid == name then add(name, n.lnum, 'u') end
    if n.title == name or (fuzzy and n.title and n.title:find(name, 1, true)) then
      add(n.title, n.lnum, 't')
    end
  end
  for i, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    local a = l:match('^%s*%[ANCHOR: ([^,%]]+)')
    if a == name then add(name, i, 'a') end
  end
  return out
end

local function project_tags(buf, name)
  local out = {}
  local root = vim.fs.root(buf, { '.git', 'strictdoc.toml' }) or vim.fn.getcwd()
  local files = vim.fs.find(function(f) return f:match('%.sdoc$') end,
    { path = root, type = 'file', limit = 5000 })
  for _, f in ipairs(files) do
    for i, l in ipairs(vim.fn.readfile(f)) do
      if l:match('^%s*UID: (.-)%s*$') == name then
        out[#out + 1] = { name = name, filename = f, cmd = tostring(i), kind = 'u' }
      end
    end
  end
  return out
end

function M.tagfunc(pattern, flags)
  if flags:find('i') then return vim.NIL end -- insert completion: default
  local cursor = flags:find('c') ~= nil
  local name = cursor and cword() or pattern
  local buf = vim.api.nvim_get_current_buf()
  local res = local_tags(buf, name, false)
  if #res == 0 then res = project_tags(buf, name) end
  if #res == 0 and cursor then res = local_tags(buf, name, true) end
  return res
end

return M

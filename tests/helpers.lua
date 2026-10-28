local H = {}
H.root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
H.fixtures = H.root .. '/tests/fixtures/'

function H.read(path) return vim.fn.readfile(path) end

function H.open(name)
  vim.cmd('silent edit! ' .. vim.fn.fnameescape(H.fixtures .. name))
  return vim.api.nvim_get_current_buf()
end

-- Scratch sdoc buffer with the given lines.
function H.buf(lines)
  vim.cmd('enew!')
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.filetype = 'sdoc'
  return vim.api.nvim_get_current_buf()
end

function H.lines(buf) return vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false) end

function H.feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), 'x', false)
end

function H.eq(want, got, msg)
  if vim.deep_equal(want, got) then return end
  if type(want) == 'table' and type(got) == 'table' then
    for i = 1, math.max(#want, #got) do
      if want[i] ~= got[i] then
        error(('%sline %d: want %q, got %q'):format(msg and msg .. ': ' or '', i,
          tostring(want[i]), tostring(got[i])), 2)
      end
    end
  end
  error((msg and msg .. ': ' or '') .. 'want ' .. vim.inspect(want) .. ', got ' .. vim.inspect(got), 2)
end

return H

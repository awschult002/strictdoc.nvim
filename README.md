# strictdoc.nvim

Native Neovim support for [StrictDoc](https://github.com/strictdoc-project/strictdoc)
`.sdoc` files: syntax, indent, folding, node motions, wrap mappings, an
outline and tag jumps. Pure Lua plus one Vimscript syntax file. No
dependencies, no `setup()`, no Treesitter.

The syntax follows StrictDoc's textX grammar
(`strictdoc/backend/sdoc/grammar/`), and the tests run on real `.sdoc` files
from the StrictDoc repo.

## Install

As a package:

```sh
git clone https://github.com/awschult002/strictdoc.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/strictdoc.nvim
nvim -c 'helptags ALL' -c q
```

Or with the built-in `vim.pack` (Neovim 0.12+):

```lua
vim.pack.add({ 'https://github.com/awschult002/strictdoc.nvim' })
```

## Features

- **Filetype**: `*.sdoc` is detected as `sdoc`.
- **Syntax** (modeled on the bundled `toml.vim`): `[DOCUMENT]`, `[GRAMMAR]`,
  `[DOCUMENT_FROM_FILE]`, `[SECTION]`/`[/SECTION]`, `[[NODE]]`/`[[/NODE]]`
  composite nodes, `[REQUIREMENT]`, `[TEXT]` and custom nodes, legacy
  `[FREETEXT]`/`[/FREETEXT]`, `KEY:` fields, `>>>`/`<<<` text blocks,
  RELATIONS (`- TYPE: Parent`, `VALUE:`), booleans, `[LINK: …]` and
  `[ANCHOR: …]`. Groups link to standard ones (`Title`, `Statement`,
  `PreProc`, `Identifier`, `String`, …) so any colorscheme works.
- **Indent**: `indentexpr` indents one `shiftwidth` inside each `[SECTION]`
  and `[[NODE]]`, dedents at the closing marker, and keeps the grammar's
  two-space lists (RELATIONS, OPTIONS, VIEWS, `[GRAMMAR]`). Text between
  `>>>` and `<<<` is never reindented, so `gg=G` is safe on a whole file.
- **Folding**: `foldexpr` folds every node; sections nest their children.
- **Motions**: `]]`/`[[` jump between nodes (counts, visual and
  operator-pending work); `an`/`in` select a node.
- **Wrap**: visual `gr`, `gt`, `gs` wrap the selection in a requirement,
  a text node or a section at the current section's indent.
- **Outline**: `:StrictdocOutline` toggles a tree of sections and nodes
  (titles and UIDs) on the right. `<CR>` jumps, `zc`/`zo` fold, `q`
  closes. It refreshes when you write the file.
- **Tags**: `Ctrl-]` on a UID, `[LINK: X]` or `VALUE: X` jumps to the node
  or anchor, also across the project's other `.sdoc` files.
  `:tag Section title` jumps to a section by title.

> StrictDoc wants every marker and field in column 0. The indented layout
> is easier to read and edit; set `vim.g.strictdoc_indent = 0` and run
> `gg=G` to get back a file StrictDoc parses.

## Mappings

Buffer-local, in `sdoc` buffers only.

| Keys | Mode | `<Plug>` | Action |
| --- | --- | --- | --- |
| `]]` / `[[` | n x o | `(strictdoc-next-node)` / `(strictdoc-prev-node)` | next / previous node |
| `an` / `in` | x o | `(strictdoc-node-outer)` / `(strictdoc-node-inner)` | around / inside node |
| `gr` | x | `(strictdoc-wrap-requirement)` | `[REQUIREMENT]` + `STATEMENT: >>>` … `<<<` |
| `gt` | x | `(strictdoc-wrap-text)` | `[TEXT]` + `STATEMENT: >>>` … `<<<` |
| `gs` | x | `(strictdoc-wrap-section)` | `[SECTION]` + `TITLE: ` (cursor there) … `[/SECTION]` |
| | n | `(strictdoc-outline)` | toggle the outline |

In sdoc buffers these shadow the visual-mode `gs` (sleep), the visual
`gra` LSP code action, and the Treesitter `an`/`in` selections (no sdoc
parser exists). Nowhere else.

## Options

| Variable | Default | Effect |
| --- | --- | --- |
| `vim.g.strictdoc_no_mappings` | unset | `1`: skip the default keys; `<Plug>` maps stay |
| `vim.g.strictdoc_indent` | `1` | `0`: markers and fields in column 0 (StrictDoc's layout) |
| `vim.g.strictdoc_composite_sections` | `0` | `1`: `gs` emits `[[SECTION]]` / `[[/SECTION]]` |

The ftplugin sets `expandtab`, `shiftwidth=2`, `softtabstop=2` and
`foldlevel=99` for sdoc buffers.

## Example config

```lua
vim.pack.add({ 'https://github.com/awschult002/strictdoc.nvim' })

vim.g.strictdoc_composite_sections = 1 -- gs writes [[SECTION]]
vim.g.strictdoc_no_mappings = 1        -- pick your own keys

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'sdoc',
  callback = function()
    local map = function(m, l, r) vim.keymap.set(m, l, r, { buffer = true }) end
    map({ 'n', 'x', 'o' }, ']]', '<Plug>(strictdoc-next-node)')
    map({ 'n', 'x', 'o' }, '[[', '<Plug>(strictdoc-prev-node)')
    map('x', '<leader>r', '<Plug>(strictdoc-wrap-requirement)')
    map('x', '<leader>t', '<Plug>(strictdoc-wrap-text)')
    map('x', '<leader>s', '<Plug>(strictdoc-wrap-section)')
    map('n', '<leader>o', '<Plug>(strictdoc-outline)')
  end,
})
```

See `:help strictdoc` for details.

## Tests

```sh
make test
```

Runs `nvim --headless -u NONE` on `tests/run.lua` with the plugin installed
as a `pack/*/start` package, then installs it with `vim.pack.add()`. CI runs
the same on Neovim stable.

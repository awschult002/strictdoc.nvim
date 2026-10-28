# strictdoc.nvim

Native Neovim support for [StrictDoc](https://github.com/strictdoc-project/strictdoc)
`.sdoc` files: syntax, indent, folding, node motions, wrap mappings, an
outline and tag jumps. Pure Lua plus one Vimscript syntax file. No
dependencies, no `setup()`, no Treesitter.

The syntax follows StrictDoc's textX grammar
(`strictdoc/backend/sdoc/grammar/`), and the tests run on real `.sdoc` files
from the StrictDoc repo.

## Install

With the built-in `vim.pack` (Neovim 0.12+), in your `init.lua`:

```lua
vim.pack.add({ 'https://github.com/awschult002/strictdoc.nvim' })
```

Or by hand as a native package (any name works in place of `plugins`):

```sh
git clone https://github.com/awschult002/strictdoc.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/strictdoc.nvim
nvim -c 'helptags ALL' -c q
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
- **Indent**: files stay flat, the way StrictDoc requires: `=`/`gg=G` puts
  every marker and field in column 0 and keeps the grammar's two-space
  lists (RELATIONS, OPTIONS, VIEWS, `[GRAMMAR]`). Text between `>>>` and
  `<<<` is never reindented, so `gg=G` is safe on a whole file.
- **Virtual indent**: nesting is shown with inline virtual text, one
  `shiftwidth` per open `[SECTION]`/`[[NODE]]`. The buffer text is never
  changed, so what you save is what StrictDoc parses.
- **Folding**: `foldexpr` folds every node; sections nest their children.
- **Motions**: `]]`/`[[` jump between nodes (counts, visual and
  operator-pending work); `an`/`in` select a node.
- **Wrap**: visual `gr`, `gt`, `gs` wrap the selection in a requirement,
  a text node or a section, always written flat.
- **Outline**: `:StrictdocOutline` toggles a tree of sections and nodes
  (titles and UIDs) on the right. `<CR>` jumps, `zc`/`zo` fold, `q`
  closes. It refreshes when you write the file.
- **Tags**: `Ctrl-]` on a UID, `[LINK: X]` or `VALUE: X` jumps to the node
  or anchor, also across the project's other `.sdoc` files.
  `:tag Section title` jumps to a section by title.

> StrictDoc 0.30 rejects leading whitespace before markers and fields.
> Files indented by older versions of this plugin are fixed with `gg=G`.

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

| Option | Default | Effect |
| --- | --- | --- |
| `vim.g.strictdoc_virtual_indent` | on | `0`: no virtual indent (plain flat view) |
| `shiftwidth` (buffer) | `2` | width of one virtual indent level |
| `vim.g.strictdoc_no_mappings` | unset | `1`: skip the default keys; `<Plug>` maps stay |
| `vim.g.strictdoc_composite_sections` | `0` | `1`: `gs` emits `[[SECTION]]` / `[[/SECTION]]` |
| `:StrictdocOutline` | | toggle the outline; in it `<CR>` jumps, `zc`/`zo` fold, `q` closes |
| `tagfunc` | set | `Ctrl-]`/`:tag` on UIDs, links, anchors, section titles |
| `foldmethod=expr`, `foldlevel` | `99` | every node folds; `zM` closes all |

Set the `vim.g` variables before the first `.sdoc` file opens. The
ftplugin sets `expandtab`, `shiftwidth=2`, `softtabstop=2`,
`foldmethod=expr` and `foldlevel=99`; override them in
`~/.config/nvim/after/ftplugin/sdoc.lua`:

```lua
vim.bo.shiftwidth = 4   -- virtual indent of 4 per level
vim.wo.foldlevel = 0    -- open files folded
```

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

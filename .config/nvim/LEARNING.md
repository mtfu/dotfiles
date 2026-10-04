# Shortcuts to Learn

Practice list. When something is muscle memory, delete it from here.
Full reference lives in [NVIM_SETUP.md](NVIM_SETUP.md).

## Quickfix

| Key                     | What it does                                          |
|-------------------------|-------------------------------------------------------|
| `<leader>q` / `<A-0>`   | All diagnostics → quickfix                            |
| `]q` / `[q`             | Next / prev quickfix entry                            |
| `]Q` / `[Q`             | Last / first entry                                    |
| `]<C-q>` / `[<C-q>`     | Next / prev **file** in the list (or `:cnfile`)       |
| `<C-q>` (in Telescope)  | Send all picker results → quickfix                    |
| `:copen` / `:cclose`    | Open / close the quickfix window                      |
| `:colder` / `:cnewer`   | Switch to older / newer quickfix list                 |
| `:cdo s/old/new/g \| update` | Run a command on every entry and save            |
| `:cdo norm @a`          | Run macro `a` on every entry                          |

Workflow: `<leader>fg` grep → `<C-q>` → `]q` through results, or `:cdo` to fix them all.

## Change list (across all files)

| Key     | What it does                                     |
|---------|--------------------------------------------------|
| `g;`    | Back to previous edit (any buffer), like Rider   |
| `g,`    | Forward to next edit                             |
| `<C-o>` | Back to where you were before the jump           |

## Registers

Note: `clipboard=unnamedplus` means every yank **and delete** hits the system clipboard.

| Key                   | What it does                                            |
|-----------------------|---------------------------------------------------------|
| `"0p`                 | Paste last **yank** (survives `dd`/`x`), use this first |
| `"1p` then `.` `.`    | Walk back through recent line deletes (`"2`, `"3`…)     |
| `"ayiw` / `"ap`       | Yank into / paste from named register `a`               |
| `"Ayy`                | **Append** line to register `a`                         |
| `<leader>d`           | Delete into black hole (keeps register)                 |
| `P` (visual)          | Paste over selection without losing register            |
| `cp{motion}` / `cpp`  | Replace with register (repeatable with `.`)             |
| `<C-r>0` (insert/cmd) | Insert register `0` without leaving insert mode         |
| `<C-r><C-w>` (cmd)    | Insert word under cursor on the command line            |
| `<leader>fr`          | Telescope register picker (pick to paste)               |
| `:reg`                | Show all registers                                      |

Special registers: `"%` file name · `".` last insert · `":` last command (`@:` repeats it) · `"/` last search.

### Register workflows (stop reaching for Win+V)

| Situation                                   | Do this                                             |
|---------------------------------------------|-----------------------------------------------------|
| Replace a word with what I yanked           | `cpiw` (not `ciw` + paste). Next word: just `.`     |
| Replace inside quotes / parens / line       | `cpi"` · `cpi(` · `cpp`                             |
| Replace a visual selection                  | `P` (keeps register; `p` would overwrite it)        |
| Pasted and got the wrong thing              | `u` then `"0p`: `"0` is always the last yank        |
| Need to delete junk before pasting          | `<leader>d{motion}` (black hole), then `p`          |
| Paste the same thing into many places       | Yank, then `cpiw` + `.` `.` `.`                     |
| Juggle two snippets                         | `"ayiw` and `"byiw`, then `"ap` / `"bp`             |
| Collect lines from around a file            | `"ayy` first, then `"Ayy` on the rest, then `"ap`   |
| Paste while typing                          | `<C-r>0` (or `<C-r>a`) in insert mode               |
| Can't remember where it went                | `<leader>fr` and pick it                            |

Rule of thumb: **`d`, `c`, `x` overwrite your clipboard. `cp`, `<leader>d`, visual `P` and `"0` don't.**

## Macros

| Key          | What it does                        |
|--------------|-------------------------------------|
| `qa` … `q`   | Record macro into register `a`      |
| `@a` / `@@`  | Play macro `a` / repeat last macro  |
| `5@a`        | Play it 5 times                     |

# Neovim Setup Reference

## LSP Architecture

| Layer | Plugin | Responsibility |
|---|---|---|
| **Server definitions** | `nvim-lspconfig` | Provides `cmd`, `filetypes`, `root_markers` via `lsp/*.lua` files in the runtimepath |
| **Server binaries** | `mason` | Downloads and installs the actual LSP server executables |
| **Bridging** | `mason-lspconfig` | Auto-installs servers in `ensure_installed`; auto-enables them via `automatic_enable` (default on) |
| **Native API** | Neovim 0.11+ | `vim.lsp.config()` merges custom settings per server |

nvim-lspconfig is still needed because Neovim ships with zero built-in server configs — the plugin provides all of them as `lsp/*.lua` files.

This setup follows [Part 6 — Recommended setup for most people](https://dotfiles.substack.com/i/193270606/part-6-recommended-setup-for-most-people) from *Native LSP in Neovim 0.12*.

### Adding a new LSP server

**No custom settings needed:**
1. `:MasonInstall <package>` — that's it, the server is auto-enabled

**Custom settings needed:**
1. `:MasonInstall <package>` (or add to `ensure_installed` for reproducibility)
2. Add `vim.lsp.config('name', { settings = { ... } })` in `pack.lua`

---

## First Time Setup (after pulling config)

1. Open nvim — `vim.pack` will auto-download missing plugins on startup.
2. LSP servers auto-install on first launch via mason-lspconfig `ensure_installed`.
3. Treesitter parsers auto-install on demand when opening a file (`auto_install = true`).

> **Note:** `nvim-treesitter` is kept solely as a parser manager/installer. The treesitter *runtime* (highlighting, queries, parsing API) is native in Neovim 0.12 — but parser *installation* is not. The plugin exists only because there is no built-in equivalent for auto-installing parsers.

---

## Installed LSP Servers

| Mason package                   | LSP name         | Filetype          | Notes                          |
|---------------------------------|------------------|-------------------|--------------------------------|
| `lua-language-server`           | `lua_ls`         | `.lua`            |                                |
| `typescript-language-server`    | `ts_ls`          | `.ts` `.js`       |                                |
| `angular-language-server`       | `angularls`      | `.ts` (Angular)   |                                |
| `powershell-editor-services`    | `powershell_es`  | `.ps1`            |                                |
| *(manual)*                      | `roslyn`         | `.cs` `.razor`    | `:MasonInstall roslyn` (uses Crashdummyy registry) |

---

## Keymaps

### LSP (on attach)

| Key         | Description                           |
|-------------|---------------------------------------|
| `<F2>`      | Rename symbol (overrides `grn`)       |
| `grr`       | Find references (Telescope)           |
| `grt`       | Type definition                       |
| `gra`       | Code actions                          |
| `gri`       | Show implementations                  |
| `gO`        | List document symbols                 |
| `<C-k>`     | Signature help (Insert)               |

### Diagnostics

| Key         | Description                           |
|-------------|---------------------------------------|
| `]d` / `[d` | Next/prev diagnostic (with float)     |
| `]e` / `[e` | Next/prev error only                  |
| `gl`        | Open diagnostic float                 |
| `<A-0>` / `<leader>q` | Send all diagnostics to quickfix |

### Telescope

| Key              | Description              |
|------------------|--------------------------|
| `<C-p>`          | Find files               |
| `<leader>hh`     | Recent files             |
| `<leader>fg`     | Live grep                |
| `<leader>ff`     | Grep word under cursor   |
| `<leader>fb`     | Buffers                  |
| `<leader>fs`     | Go to symbol             |
| `<leader>fc`     | Go to class              |
| `<leader>:`      | Command history          |
| `<leader>fr`     | Registers (pick to paste)|

### Other

| Key              | Description                            |
|------------------|----------------------------------------|
| `<leader><leader>` | Format (conform, fallback to LSP)    |
| `<leader>lg`     | LazyGit                                |
| `<leader>aa`     | Git blame line                         |
| `<leader>s`      | Search & replace word under cursor     |
| `<leader>cd`     | cd to current file's directory         |
| `g;` / `g,`      | Prev/next change across all buffers   |
| `<S-M-l>`        | Reveal current file in nvim-tree       |
| `-`              | Open oil (parent dir of current file)  |
| `<C-\>`          | Toggle terminal (float)                |

### Herdr (send file refs to an agent pane)

| Key              | Description                                  |
|------------------|----------------------------------------------|
| `<leader>hf`     | Ask a question about the file: submits `@file <question>` (empty: just inserts `@file`) |
| `<leader>hl`     | Same for the current line, submitting `file:line <question>` (visual: `file:first-last`) |
| `<leader>hp`     | Pick a different target agent pane           |
| `<leader>hc`     | Add review comment (visual: on range); on an existing one, edit it (empty deletes) |
| `<leader>hs`     | Submit all review comments as one prompt, then clear them |

### Oil (inside oil buffer)

| Key       | Description                              |
|-----------|------------------------------------------|
| `<CR>`    | Open file or directory                   |
| `-`       | Go up to parent directory                |
| `_`       | Open current working directory           |
| `g.`      | Toggle hidden files                      |
| `gs`      | Change sort order                        |
| `gx`      | Open file with system default            |
| `g?`      | Show help                                |
| `<C-s>`   | Save pending changes (rename/delete/etc) |
| `<C-c>`   | Discard changes                          |
| `<C-p>`   | Preview file                             |

### Treesitter Text Objects

| Key       | Description                          |
|-----------|--------------------------------------|
| `af` / `if` | Outer/inner function               |
| `aa` / `ia` | Outer/inner argument               |
| `]]` / `[[` | Next/prev function start           |
| `an` / `in` | Select outward/inward (structural) |

### Completion (blink.cmp)

| Key              | Mode          | Description                    |
|------------------|---------------|--------------------------------|
| `<C-n>` / `<C-p>` | Insert       | Navigate menu                  |
| `<CR>` / `<C-y>` | Insert        | Confirm selection              |
| `<C-e>`          | Insert        | Dismiss menu                   |
| `<Tab>`          | Insert/Select | Next snippet placeholder       |
| `<S-Tab>`        | Insert/Select | Previous snippet placeholder   |

---

## Commands

### vim.pack

| Command                          | Description              |
|----------------------------------|--------------------------|
| `:lua vim.pack.update()`         | Update all plugins       |
| `:lua vim.pack.update('name')`   | Update a specific plugin |

### Mason

| Command                    | Description                              |
|----------------------------|------------------------------------------|
| `:Mason`                   | Open Mason UI                            |
| `:MasonInstall <package>`  | Install a package                        |
| `:MasonUninstall <package>`| Uninstall a package                      |
| `:MasonUpdate`             | Update all installed packages            |

### LSP & Health

| Command                                                      | Description                          |
|--------------------------------------------------------------|--------------------------------------|
| `:checkhealth lsp`                                           | LSP health report for current buffer |
| `:checkhealth vim.lsp`                                       | Which buffers LSP is attached to     |
| `:checkhealth mason`                                         | Mason health check                   |
| `:lua vim.print(vim.lsp.get_clients({ bufnr = 0 }))`        | List attached clients                |
| `:lsp restart [client]`                                      | Restart LSP clients                  |

---

## Neovim 0.12 Notable Changes

### New Commands

| Command       | Description                                   |
|---------------|-----------------------------------------------|
| `:restart`    | Restart Neovim and reattach all UIs           |
| `:Undotree`   | Visual undo-tree (built-in)                   |
| `:DiffTool`   | Directory/file diff (built-in)                |
| `:wall ++p`   | Write all buffers, creating missing parent dirs |

---

## Reviewing Agent-Written Code

The goal: no line an agent wrote reaches a commit without passing your eyes.

**The git index is the ledger.** Unstaged means unreviewed. Staged means read and
accepted. There is no separate tracking to maintain, it survives restarts, and it
is already what you commit from.

### The loop

| Key | Does |
|---|---|
| `<leader>gr` | **Review list**: every file with unreviewed changes, into quickfix |
| `<leader>gl` | Fuzzy-jump to a file in the list by name instead of scrolling it |
| `]a` / `[a` | Next / previous **unreviewed** hunk, showing what it replaced |
| `<leader>gy` | **Yes**: accept (stage) the hunk. Only ever accepts; `<leader>gu` undoes all accepts in the file |
| `<leader>gn` | **No**: reject (discard) the hunk |
| `<leader>hc` / `<leader>hs` | Needs work: comment on it, then send all comments to the agent (see Herdr keys above) |
| `<leader>gr` | Re-run. A shorter list is your progress bar. Empty means done |

`<leader>gy` and `<leader>gn` also work on a visual selection (only those lines),
and `<leader>gY` / `<leader>gN` accept / reject the whole file.

Then commit normally (`<leader>lg` for lazygit).

**Review mode.** Change marks are hidden while you code, so the screen stays
clean. `<leader>gh` turns them all on together: `+` / `~` / `_` signs, line
colour on every unstaged line, and the exact words changed. Press it again to
hide them. `]a`, accepting and the rest work either way; review mode only makes
progress visible, since a hunk loses its marks the moment it is accepted.

`<leader>gr` lists both modified **and** brand-new files. That matters: gitsigns
only knows about tracked files, so a file the agent just created has no hunks and
would otherwise be invisible to a hunk-based review.

Deleted files are listed too, as `deleted: <path>` lines you cannot jump to,
because there is no buffer left to open. Read them in `<leader>gv` and accept
with `git rm <path>` or in lazygit.

### Reading a hunk properly

`]a` moves to the hunk and renders whatever it **removed** as virtual lines, in
place. Deleted lines do not exist in the working-tree buffer, which makes
deletions the easiest thing to wave through by accident.

On a pure-addition hunk nothing extra appears. That is correct, not a bug:
there is nothing removed to show, and the added lines are already on screen.
Most agent output is pure additions, so expect inline preview to be silent a
lot of the time. It earns its keep on the hunks that quietly take things away.

| Key | Does |
|---|---|
| `<leader>gh` | Review mode: show/hide all change marks (signs, line colour, changed words) |
| `<leader>gp` | Show removed lines inline (same thing `]a` does, on demand) |
| `<leader>gP` | Preview the whole hunk in a float |
| `<leader>gd` / `<leader>gD` | Diff this file against the index / the last commit |
| `<leader>gb` | Blame the current line |
| `<leader>gq` | Every hunk in the repo into quickfix (per hunk, tracked files only) |
| `ih` | Hunk text object: `vih` selects the hunk, then `<leader>hc`, `<leader>hl` or `<leader>gy` act on all of it |

### Zooming out: diffview and history

| Key | Answers |
|---|---|
| `]a` | What changed *here*? |
| `<leader>gv` | What changed overall, and how does it fit together? |
| `<leader>gf` | *Why* does this code look like this, and when did it change? |

**`<leader>gv`** shows the whole changeset side by side, with a file list. Use it when:

- the agent restructured code (moved a method, split a class, reordered a
  file). Hunk by hunk that is a pile of deletions and additions; side by side
  you see what moved where.
- the change is big and you want the overview before starting the `<leader>gr` loop.
- a file was deleted, since there is no buffer to open from `<leader>gr`.

**`<leader>gf`** lists the commits that touched the current file, each with its diff. Use it when:

- the agent changed something that looks deliberate, like removing an odd
  check. The commit that added it often says why it was there, which tells
  you whether to reject the hunk or `<leader>hc` "this was added for X, keep it".
- something broke a few rounds ago, to find the commit where the behaviour changed.

Both open in their own tab. Close with `:DiffviewClose` (or `:tabclose`).

### Rider

The review loop is nvim-only. Rider keeps `<leader>r` for run/debug, which is
why review lives under `<leader>g`. In Rider, `<leader>ac` opens the Commit
window to see what is staged.

### Why it is built this way

Everything above is gitsigns, telescope, diffview and git. The only custom code
is `<leader>gr` (about 20 lines in `lua/config/editor.lua`, because gitsigns
cannot see untracked files).

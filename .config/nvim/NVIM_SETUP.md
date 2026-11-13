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
3. Treesitter parsers in the list in `editor.lua` install on startup and highlight via `vim.treesitter.start()`.
   Installing compiles them with zig (`CC="zig cc"`, set in `editor.lua` when CC is unset) and Mason's `tree-sitter-cli`.

> **Note:** `nvim-treesitter` is kept solely as a parser manager/installer. The treesitter *runtime* (highlighting, queries, parsing API) is native in Neovim 0.12 — but parser *installation* is not. The plugin exists only because there is no built-in equivalent for auto-installing parsers.

---

## Installed LSP Servers

| Mason package                   | LSP name         | Filetype          | Notes                          |
|---------------------------------|------------------|-------------------|--------------------------------|
| `lua-language-server`           | `lua_ls`         | `.lua`            |                                |
| `typescript-language-server`    | `ts_ls`          | `.ts` `.js`       |                                |
| `angular-language-server`       | `angularls`      | `.ts` (Angular)   |                                |
| `powershell-editor-services`    | `powershell_es`  | `.ps1`            |                                |
| `roslyn-language-server`        | `roslyn`         | `.cs` `.razor`    | Via mason-tool-installer; run by roslyn.nvim (lspconfig's `roslyn_ls` is excluded) |

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
| `<leader>xq` | Toggle the quickfix window |

### Telescope

| Key              | Description              |
|------------------|--------------------------|
| `<C-p>`          | Find files               |
| `<leader>hh`     | Recent files             |
| `<leader>hr`     | Recent files in this repo |
| `<leader>gg`     | Git changed files        |
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
| `<leader>lf`     | LazyGit: history of current file       |
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

### Vault initiative notes

The initiative is found by the checkout path in its `Stories.md` or `Tasks.md` in the vault at
`$OBSIDIAN_VAULT` (set per machine; the keys only warn without it); without a match, pick one.

| Key              | Description                                             |
|------------------|---------------------------------------------------------|
| `<leader>ns`     | This checkout's `START-HERE.md`, at `## Open questions` |
| `<leader>nt`     | This checkout's `Tasks.md`                              |

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
| `<leader>gr` | **Review list**: every file with unreviewed changes, into quickfix. Also turns review mode on |
| `<leader>gl` | Fuzzy-jump to a file in the list by name instead of scrolling it |
| `<leader>gh` | **Review mode**: show/hide changes PR-style (signs, line colour, changed words, removed lines) |
| `]c` / `[c` | Next / previous **unreviewed** hunk, showing what it replaced. In a diff (difftool, mergetool) vim's own next / previous change |
| `gy` | **Yes**: accept (stage) the hunk and jump to the next unreviewed one in this file. Only ever accepts; `<leader>gu` undoes the accept on the ✓ hunk under the cursor, `<leader>gU` all accepts in the file |
| `<leader>gn` | **No**: reject (discard) the hunk |
| `]q` / `[q` | Next / previous file in the review list, landing on its first unreviewed hunk |
| `<leader>hc` / `<leader>hs` | Needs work: comment on it, then send all comments to the agent (see Herdr keys above) |
| *(automatic)* | The list is your progress bar: a file leaves it once nothing in it is left to review, and the title counts down. Empty means done. `<leader>gr` rebuilds it after the agent changes more |

`gy` and `<leader>gn` also work on a visual selection (only those lines),
and `gY` / `<leader>gN` accept / reject the whole file. `ih` is a hunk
text object: `vih` selects the hunk, then `<leader>hc`, `<leader>hl` or
`gy` act on all of it.

Then commit in lazygit (`<leader>lg`).

**Review mode.** Change marks are hidden while you code, so the screen stays
clean. `<leader>gr` turns them on in place, and they stay put as you move
between hunks; `<leader>gh` toggles them. Accepted hunks swap their
`+` / `~` / `_` for a `✓` rather than going blank, so a reviewed file still
reads as changed. Blank then means genuinely untouched, which matters when an
agent edits files you never opened.

`]c` renders whatever the hunk **removed** as virtual lines, in place (in
review mode they are already shown for every hunk, so it only moves). Deleted
lines do not exist in the working-tree buffer, which makes deletions the
easiest thing to wave through. On a pure-addition hunk nothing extra appears;
that is correct, the added lines are already on screen.

`<leader>gr` lists modified, brand-new **and** deleted files. `git diff` only
lists tracked files, so new ones are collected separately; gitsigns attaches to
untracked files (`attach_to_untracked`), so a new file is one all-added hunk.
Deleted files show as `deleted: <path>` lines you cannot jump to. Read and
accept them in lazygit.

### History

`<leader>lf` opens lazygit filtered to the current file: the commits that
touched it, each with its diff. Use it when the agent changed something that
looks deliberate, like removing an odd check. The commit that added it often
says why it was there, which tells you whether to reject the hunk or
`<leader>hc` "this was added for X, keep it".

### Merge conflicts

`git mergetool` opens git's built-in `nvimdiff`, one conflicted file at a time:
BASE (A), LOCAL (B, ours) and REMOTE (C) on top, left to right, MERGED (the file
you edit) below. Every conflict line in MERGED gets an A/B/C sign for its source,
and each window's winbar names the commit it shows.

| Key / command | Does |
|---|---|
| `]x` / `[x` | Next / previous conflict |
| `<leader>2` / `3` | Take B (LOCAL) / C (REMOTE) for this conflict, like kdiff3 Ctrl+2/3 |
| `<leader>4` / `5` | Take both: B then C / C then B (e.g. `using` lists) |
| `<leader>xa` | Auto-solve every whitespace-only conflict, like kdiff3's auto-solve |
| `]c` / `[c` | Next / previous change (any difference, not only conflicts) |
| `:wqa` | Done with this file, go to the next |
| `:cqa` | Abort this file (stays conflicted) |

The keys work on the conflict markers in MERGED (`lua/config/conflicts.lua`), so
they also work on any conflicted file opened normally. `<leader>xa` solves a
conflict when both sides are equal apart from whitespace (takes B), or when one
side only changed whitespace compared with BASE (takes the other). It needs the
`|||||||` BASE section for the second case, which `merge.conflictStyle = zdiff3`
provides.

`git difftool` opens Neovim's built-in `:DiffTool` (`nvim.difftool`). `git difftool -d` hands it
both versions as folders, so every changed file is in the quickfix list (`]q` / `[q`); lazygit's
`Ctrl+t` opens the selected file. kdiff3 is still installed as a fallback:
`git mergetool -t kdiff3`, `git difftool -g`.

### Rider

The review loop is nvim-only. Rider keeps `<leader>r` for run/debug, which is
why review lives under `<leader>g`. In Rider, `<leader>ac` opens the Commit
window to see what is staged.

### Why it is built this way

Everything above is gitsigns, telescope, lazygit and git. The custom code is
in `lua/config/editor.lua`: `<leader>gr`, because `git diff` does not list untracked
files, and keeping that list current (landing on the first hunk, dropping
reviewed files, `]q` after a drop), because quickfix has no idea what gitsigns does.

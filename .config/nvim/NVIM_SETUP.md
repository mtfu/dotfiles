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
| `<A-0>`     | Send all diagnostics to quickfix      |

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

### Other

| Key              | Description                            |
|------------------|----------------------------------------|
| `<leader><leader>` | Format (conform, fallback to LSP)    |
| `<leader>lg`     | LazyGit                                |
| `<leader>aa`     | Git blame line                         |
| `<leader>s`      | Search & replace word under cursor     |
| `<leader>cd`     | cd to current file's directory         |
| `<S-M-l>`        | Reveal current file in nvim-tree       |
| `-`              | Open oil (parent dir of current file)  |
| `<C-\>`          | Toggle terminal (float)                |

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

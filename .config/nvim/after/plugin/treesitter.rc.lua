local status, ts = pcall(require, "nvim-treesitter.configs")
if (not status) then return end

ts.setup {
  highlight = {
    enable = true,
    disable = {},
  },
  indent = {
    enable = true,
    disable = {},
  },
  sync_install = false,
  ensure_installed = {
    "tsx",
    "toml",
    "rust",
    "json",
    "yaml",
    "css",
    "html",
    "lua",
    "c_sharp",
    "markdown",
  },
  autotag = {
    enable = true,
  },
}

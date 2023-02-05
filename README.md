#### Purpose of the repo
To easy get a new computer up and running with the same configuration as my other machines.

Contains installation scripts to download and install programs with choco and winget.

Creates a bunch of symbolic links, so it is easy to update the config between machines.
# Git
Insert into gitconfig.local
[user]
    email = 
    name = 

# NEOVIM
To install extensions for neovim run :PlugInstall, and :PlugUpdate to update plugins

# Treesitter
1. Enable Developer Mode In Windows to make sure that the parsers can do symbolic links
2. Install zig and also mingw (Was needed on my laptop to install the svelte parser)

https://github.com/nvim-treesitter/nvim-treesitter/wiki/Windows-support

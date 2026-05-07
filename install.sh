#!/usr/bin/env bash

# Exit immediately if the script fails
set -e

clone_path="${clone_path:-"${PWD}"}"
echo "Current working directory: $clone_path"

sudo apt-get install -y software-properties-common
apt_packages="curl git python3-pip tmux git zsh fzf fd-find bat direnv keychain"

# Install packages
sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get install -y ${apt_packages}

# Create initial directories
mkdir -p "${HOME}/.config/zsh"  \
    "${HOME}/.local/bin" "${HOME}/.local/share" \
    "${HOME}/.local/state" "${HOME}/.cache/zsh" 

# Setup local git
cp "${clone_path}/.gitconfig.local" "${HOME}/.gitconfig.local"

# Make Bat avaiable in path
ln -fs /usr/bin/batcat $HOME/.local/bin/bat

# Install zsh plugins
"${clone_path}/.local/bin/update-zsh-plugins.sh"

# Create symbolic links
rm -rf ~/.config/nvim;
ln -fs "${clone_path}/.zshenv" "${HOME}/.zshenv" \
    && ln -fs "${clone_path}/.config/zsh/.zshrc" "${HOME}/.config/zsh/.zshrc" \
    && ln -fs "${clone_path}/.config/zsh/.zprofile" "${HOME}/.config/zsh/.zprofile" \
    && ln -fs "${clone_path}/.config/zsh/.aliases" "${HOME}/.config/zsh/.aliases" \
    && ln -fs "${clone_path}/.gitconfig" "${HOME}/.gitconfig" \
    && ln -fs "${clone_path}/.vimrc.minimal" "${HOME}/.vimrc.minimal" \
    && ln -fs "${clone_path}/.config/nvim" "${HOME}/.config/nvim" \
    && ln -fs "${clone_path}/.local/bin/update-zsh-plugins.sh" "${HOME}/.local/bin/update-zsh-plugins.sh" \
	&& ln -fs "${clone_path}/.starship/starship.toml" "${HOME}/.config/starship.toml"

if grep -qE "(Microsoft|microsoft|WSL)" /proc/version &>/dev/null; then
    sudo ln -fs "${clone_path}/etc/wsl.conf" /etc/wsl.conf
fi

# Install Neovim via snap
sudo snap install nvim --classic

# Install Starship
curl -sS https://starship.rs/install.sh | sh -s -- --bin-dir "$HOME/.local/bin" --yes

# Install nvm and Node.js LTS
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
. "${HOME}/.nvm/nvm.sh"
nvm install --lts

# Change default shell to zsh
sudo chsh -s $(which zsh) $USER

cat << EOF
Everything was installed successfully!
EOF

exit 0

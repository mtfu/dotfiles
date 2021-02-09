# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# oh my posh
ZSH_THEME="powerlevel9k/powerlevel9k" # a custom-installed theme

# powerlevel9k  
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(context ssh dir_writable dir rbenv virtualenv vcs)
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time root_indicator background_jobs time)
POWERLEVEL9K_MODE="nerdfont-complete"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=2
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_left"

ENABLE_CORRECTION="true"

COMPLETION_WAITING_DOTS="true"

ZSH_CUSTOM=$HOME/zsh_custom


plugins=(
  git
  git-extras
  thefuck
  zsh-z
  common-aliases
  zsh-aliases-exa
  zsh-syntax-highlighting
  zsh-better-npm-completion
  zsh-nvm
)

source $ZSH/oh-my-zsh.sh

# VS Cde
export EDITOR='code'

export SSH_KEY_PATH="~/.ssh/rsa_id"

# Example aliases
alias zshconfig="nano ~/.zshrc"
alias zshreload="exec $SHELL -l"
alias ohmyzsh="nano ~/.oh-my-zsh"
alias dc="docker-compose"

# Shorthand for `docker exec -it [container] /bin/bash`
# into `db [container]`
function db() {
  docker exec -it $1 /bin/bash
}

# Shorthand for `docker kill [container]`
# into `dk [container]`
function dk() {
  docker kill $1
}

# Stops all running docker containers
# http://blog.baudson.de/blog/stop-and-remove-all-docker-containers-and-images
function dkall() {
  docker stop $(docker ps -aq)
}

# Shorthand for `docker ps`
function dps() {
  docker ps "$@"
}

# Shorthand for `docker inspect`
function di() {
  docker inspect "$@"
}

# Shorthand for `mkdir [folder] && cd [folder]`
function mkd() {
  mkdir -p -- "$1" && cd -P -- "$1"
}

# Hide the user and computer name in our prompt
DEFAULT_USER=$USER

# Alias to open explorer in the current directory, returning true to override explorer's failure
alias ii ="explorer.exe . || true"


# Add $HOME/bin to path
export PATH=$HOME/bin:$PATH
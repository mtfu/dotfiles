export VISUAL=nvim
export EDITOR=$VISUAL
export XDG_DATA_HOME="$HOME/.local/share"


# Enable emacs bindings in the shell
bindkey -e

# Cusor style: blinking bar just like in windows
echo -ne '\e[5 q'

# Shortcuts to make ctrl + arrows navigate like in pwershell and make ctrl + space delete a whole word.
bindkey '^H' backward-kill-word
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# Load local settings for this machine
[[ -f "${XDG_CONFIG_HOME}/zsh/.zshrc.local" ]] && source "${XDG_CONFIG_HOME}/zsh/.zshrc.local"
[ -f "${XDG_CONFIG_HOME}/zsh/.aliases" ] && . "${XDG_CONFIG_HOME}/zsh/.aliases"
[[ -f "${XDG_CONFIG_HOME}/zsh/.aliases.local" ]] && source "${XDG_CONFIG_HOME}/zsh/.aliases.local"

# History settings.
export HISTFILE="${XDG_CACHE_HOME}/zsh/.history"
export HISTTIMEFORMAT="%Y/%m/%d %H:%M:%S:   "
export HISTSIZE=50000        # History lines stored in mememory.
export SAVEHIST=50000        # History lines stored on disk.
setopt INC_APPEND_HISTORY    # Immediately append commands to history file.
setopt HIST_IGNORE_ALL_DUPS  # Never add duplicate entries.
setopt HIST_IGNORE_SPACE     # Ignore commands that start with a space.
setopt HIST_REDUCE_BLANKS    # Remove unnecessary blank lines.
setopt HIST_FIND_NO_DUPS	 # Do not show duplicates on search.


# fzf
[[ $- == *i* ]] && . "${XDG_DATA_HOME}/fzf/shell/completion.zsh" 2> /dev/null
. "${XDG_DATA_HOME}/fzf/shell/key-bindings.zsh"

export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS='--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"

precmd_functions+=('echo -ne "\033]0; $(basename "$PWD") \007"')

# Load / source zsh plugins.
. "${XDG_DATA_HOME}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
. "${XDG_DATA_HOME}/zsh-z/zsh-z.plugin.zsh"
. "${XDG_DATA_HOME}/fzf-tab/fzf-tab.plugin.zsh"
. "${XDG_DATA_HOME}/zsh-autosuggestions/zsh-autosuggestions.zsh"


# Must be placed after zsh-autosuggestions.zsh
bindkey '^P' autosuggest-accept
bindkey '^r' fzf-history-widget
fpath=(path/to/zsh-completions/src $fpath)


eval "$(direnv hook zsh)"
eval "$(starship init zsh)"

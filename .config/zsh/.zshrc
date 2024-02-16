export VISUAL=nvim
export EDITOR=$VISUAL
export XDG_DATA_HOME="$HOME/.local/share"


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

export PATH="$PATH:$HOME/.dotnet/tools/"

# Load aliases if they exist.
[ -f "${XDG_CONFIG_HOME}/zsh/.aliases" ] && . "${XDG_CONFIG_HOME}/zsh/.aliases"
[ -f "${XDG_CONFIG_HOME}/zsh/.aliases.local" ] && . "${XDG_CONFIG_HOME}/zsh/.aliases.local"

echo "${WSL_DISTRO_NAME}"
if grep -q "microsoft" /proc/version > /dev/null 2>&1; then
    if service docker status 2>&1 | grep -q "is not running"; then
        wsl.exe --distribution "${WSL_DISTRO_NAME}" --user root \
            --exec /usr/sbin/service docker start > /dev/null 2>&1
    fi
fi

# Enable FZF (this replaces needing ~/.fzf.zsh in your home directory).
if [[ ! "${PATH}" == *${XDG_DATA_HOME}/fzf/bin* ]]; then
    export PATH="${PATH:+${PATH}:}${XDG_DATA_HOME}/fzf/bin"
fi
[[ $- == *i* ]] && . "${XDG_DATA_HOME}/fzf/shell/completion.zsh" 2> /dev/null
. "${XDG_DATA_HOME}/fzf/shell/key-bindings.zsh"

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS='--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"

# Enable asdf to manage various programming runtime versions.
[ -f "${XDG_DATA_HOME}/asdf/asdf.sh" ] && . "${XDG_DATA_HOME}/asdf/asdf.sh"

# fzf
export FZF_DEFAULT_COMMAND='fd --type f --color=never --hidden'
export FZF_DEFAULT_OPTS='--no-height --color=bg+:#343d46,gutter:-1,pointer:#ff3c3c,info:#0dbc79,hl:#0dbc79,hl+:#23d18b'

export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --line-range :50 {}'"

export FZF_ALT_C_COMMAND='fd --type d . --color=never --hidden'
export FZF_ALT_C_OPTS="--preview 'tree -C {} | head -50'"

function set_win_title(){
    echo -ne "\033]0; $(basename "$PWD") \007"
}
precmd_functions+=(set_win_title)

# Load / source zsh plugins.
. "${XDG_DATA_HOME}/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
. "${XDG_DATA_HOME}/zsh-z/zsh-z.plugin.zsh"
. "${XDG_DATA_HOME}/fzf-tab/fzf-tab.plugin.zsh"

. "${XDG_DATA_HOME}/zsh-autosuggestions/zsh-autosuggestions.zsh"
# Must be placed after zsh-autosuggestions.zsh
bindkey '^P' autosuggest-accept
bindkey '^r' fzf-history-widget
fpath=(path/to/zsh-completions/src $fpath)

eval "$(starship init zsh)"

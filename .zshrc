# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh
export ZSH_CUSTOM=$HOME/.oh-my-zsh-custom

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="mcpolemic"

# Just update each time rather than asking.
DISABLE_UPDATE_PROMPT="true"
# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

source ~/.common_profile.sh

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

alias be="noglob bundle exec"
alias bi="noglob bundle install"

# ZSH freaks out with rake arguments
# http://mikeballou.com/blog/2011/07/18/zsh-and-rake-parameters/
alias rake='noglob rake'

# Use Neovim if available
if [[ -x "/opt/boxen/homebrew/bin/nvim" ]]
then
	alias vim=nvim
fi

# From https://github.com/garybernhardt/dotfiles/blob/ee3915b903/.zshrc#L118
# By default, ^S freezes terminal output and ^Q resumes it. Disable that so
# that those keys can be used for other things.
unsetopt flowcontrol

# Unset shared history and incremental appending history. This allows the time
# of each command to be written to the ZSH history file
unsetopt sharehistory
unsetopt incappendhistory
setopt incappendhistorytime

# Run command and pipe to Selecta in the current working directory, appending
# the selected result to the command line
function run_fuzzy_find_command_and_insert_in_command_line() {
    local command="$1"
    local output
    # Print a newline or we'll clobber the old prompt.
    echo

    output=$(fuzzy_find "$command") || return
    # Append the selection to the current command buffer.
    eval 'LBUFFER="$LBUFFER$output"'
    # Redraw the prompt since Selecta has drawn several new lines of text.
    zle reset-prompt
}

# Give a menu and return the selected git branch
function fuzzy-find-git-branch() {
    run_fuzzy_find_command_and_insert_in_command_line "git branch -l | grep -v '^* ' | grep -o '[^ ]\\+'"
}

# Give a menu and return the selected file
function fuzzy-find-find-file() {
    run_fuzzy_find_command_and_insert_in_command_line "fd"
}

# Create the zle widget
zle -N fuzzy-find-git-branch
zle -N fuzzy-find-find-file

# Bind the key to the newly created widget
bindkey "^F^B" "fuzzy-find-git-branch"
bindkey "^F^F" "fuzzy-find-find-file"

test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# tabtab source for serverless package
# uninstall by removing these lines or running `tabtab uninstall serverless`
[[ -f /Users/adam/src/pgahq/pga-site-redesign/node_modules/tabtab/.completions/serverless.zsh ]] && . /Users/adam/src/pgahq/pga-site-redesign/node_modules/tabtab/.completions/serverless.zsh
# tabtab source for sls package
# uninstall by removing these lines or running `tabtab uninstall sls`
[[ -f /Users/adam/src/pgahq/pga-site-redesign/node_modules/tabtab/.completions/sls.zsh ]] && . /Users/adam/src/pgahq/pga-site-redesign/node_modules/tabtab/.completions/sls.zsh
# tabtab source for slss package
# uninstall by removing these lines or running `tabtab uninstall slss`
[[ -f /Users/adam/src/pgahq/pga-site-redesign/node_modules/tabtab/.completions/slss.zsh ]] && . /Users/adam/src/pgahq/pga-site-redesign/node_modules/tabtab/.completions/slss.zsh

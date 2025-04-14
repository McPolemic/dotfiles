# Common profile used for both ZSH and Bash
##################### Variables ####################
export EDITOR=vim
# Much larger history
export HISTFILESIZE=1000000
export PATH=~/bin:~/private_bin:~/.deno/bin:/opt/homebrew/opt/libpq/bin:$PATH:/usr/local/bin:/usr/local/sbin:~/.local/bin:~/.rbenv/bin:~/src/flutter/bin:/Applications/Visual\ Studio\ Code.app/Contents/Resources/app/bin:/usr/local/go/bin
export DENO_INSTALL=~/.deno

# Enable homebrew if it exists
if [[ -d "/opt/homebrew/bin" ]]; then
	eval $(/opt/homebrew/bin/brew shellenv)
fi

# Disable Docker constantly asking if we want to scan for vulnerabilities
export DOCKER_SCAN_SUGGEST=false

##################### Aliases ####################
alias v="f -e vim"
alias be="bundle exec"
alias bi="bundle install"
alias dc="docker compose"
alias dce="docker compose exec"

# Small utility to highlight matches while showing the entire output
alias hl="rg --passthru --colors match:fg:124 --colors match:bg:229"

##################### Functions ####################
# Edit the current clipboard in vim
function edit_clipboard {
  FILE=$(mktemp)
  pbpaste > $FILE
  vim $FILE
  cat $FILE | pbcopy
  rm $FILE
}

# Make a directory and go to it
function mkdircd() { mkdir -p "$@" && eval cd "\"\$$#\""; }

# Run the argument as a command and feed it to a fuzzy-finder
function fuzzy_find() {
    local command="$1"

    echo "$(eval $command | fzf --height=20)"
}

# Select from a list of files already added/modified/deleted from Git
function vc() { vim $(fuzzy_find "git status -s | cut -c 3-"); }
function branchp() { git checkout $(fuzzy_find "git branch -la | tr '*' '1' | sort -r | sed 's/remotes\/origin\///g' | cut -c 3- | sort | uniq"); }
function isodate() { date +%Y-%m-%d; }
function isotime() { gdate +%Y-%m-%dT%H-%M-%S-%3N-%z; }
function proj() { cd $(fuzzy_find "find ~/src -maxdepth 2 -type d"); }

function editp () {
	PATTERN=$1
	vim $(ag -c "$PATTERN" | cut -d ':' -f 1) "+/$PATTERN"
}

# Watch a given SHA on GitHub for when the tests have passed/failed
function pr_watch() {
  GIT_REV="${1:-HEAD}"
  STATUS="$(hub ci-status "${GIT_REV}")"
  while [ $STATUS  = "pending" ]; do
    STATUS="$(hub ci-status "${GIT_REV}")"
    NEW_OUTPUT=$(hub ci-status -v --color "${GIT_REV}" | sort -u -k1,2)
    tput clear; echo "${NEW_OUTPUT}"; sleep 10
  done
}

# Give us a temporary directory and a shell. Once we exit, delete the directory
function sandbox () {
	local MY_TEMP_DIR="$(mktemp -d)"

	echo "Entering sandbox directory: $MY_TEMP_DIR"
	sh -c "cd $MY_TEMP_DIR; exec \"${SHELL:-sh}\""
	echo "Exiting and deleting sandbox directory..."
	rm -rf $MY_TEMP_DIR
}

# Whenever we `cat`, attempt to use `bat` (enhanced `cat`) if it's installed
# https://github.com/sharkdp/bat
#
# Fun fact: We use `command cat` below to guarantee we run the command, not the
# shell function. This way we can, you know, exit successfully.
function cat {
  if command -v bat 2>&1 >/dev/null; then
    command bat "$@"
  else
    command cat "$@"
  fi
}

# The number of times I need to count uniq instances, sorted by the number of
# occurrences...
function count_uniq {
  sort | uniq -c | sort -n
}

#################### Go ######################
export GOPATH=~/src/go
export PATH=$PATH:$GOPATH/bin

################## Elixir ####################
export ERL_AFLAGS="-kernel shell_history enabled"


################## ASDF ######################
if [[ -d "$HOME/.asdf" ]]; then
	source $HOME/.asdf/asdf.sh
	if [ -n "$BASH_VERSION" ]; then
		source $HOME/.asdf/asdf.sh
	elif [ -n "$ZSH_VERSION" ]; then
		# https://github.com/asdf-vm/asdf/issues/68#issuecomment-624231622
		fpath=(${ASDF_DIR}/completions $fpath)
		autoload -Uz compinit && compinit
	fi
fi

################## Ruby ######################
# Load rbenv if it's installed
if [[ -d "$HOME/.rbenv" ]]; then
	eval "$(rbenv init -)"
fi

##################### Secrets (API Keys, etc. Gitignored) ####################
if [ -e ~/.secrets ]
then
    source ~/.secrets
fi

##################### Bold Penguin-specific initialization ####################
if [ -e ~/.bp_profile ]
then
    source ~/.bp_profile
fi

############# Rust/Cargo #################
if [ -e ~/.cargo/env ]
then
    source ~/.cargo/env
fi

##################### Miscellaneous ####################
eval "$(fasd --init auto)"

# Have `cd` keep track of history by using `pushd`
pushd()
{
	if [ $# -eq 0 ]; then
		DIR="${HOME}"
	else
		DIR="$1"
	fi

	builtin pushd "${DIR}" > /dev/null
}

pushd_builtin()
{
	builtin pushd > /dev/null
	echo -n "DIRSTACK: "
	dirs
}

popd()
{
	builtin popd > /dev/null
}

alias cd='pushd'
alias back='popd'
alias flip='pushd_builtin'
alias agrb='ag --ruby'

if ! command -v fd &>/dev/null; then
	if command -v fdfind &>/dev/null; then
		# Ubuntu uses `fd-find` instead of `fd`, so fix that
		alias fd='fdfind'
	fi
fi

# Install shellfish shell integration
test -e "$HOME/.shellfishrc" && source "$HOME/.shellfishrc"

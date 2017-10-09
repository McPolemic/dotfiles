# Common profile used for both ZSH and Bash
##################### Variables ####################
export EDITOR=vim
# Much larger history
export HISTFILESIZE=1000000
export PATH=~/bin:/usr/local/bin:/usr/local/sbin:$PATH:~/.local/bin:~/.rbenv/bin

##################### Aliases ####################
alias v="f -e vim"
alias be="bundle exec"
alias bi="bundle install"

##################### Functions ####################
# Make a directory and go to it
function mkdircd() { mkdir -p "$@" && eval cd "\"\$$#\""; }

# Open a fuzzy-finder of files of X type and then open vim to it
function vp() { vim $(find . -name '*.rb' \
	                  -o -name '*.rake' \
	                  -o -name '*.gemspec' \
	                  -o -name '*.erb' \
	                  -o -name '*.py' \
			  -o -name '*.java' \
			  -o -name '*.xml' \
			  -o -name '*.html' \
			  -o -name '*.haml' \
			  -o -name '*.clj' \
			  -o -name '*.sh' \
			  -o -name '*.js' \
			  -o -name '*.coffee' \
			  -o -name '*.hbs' \
			  -o -name '*.go' |
                      grep -v node_modules |
		      grep -v bower_components |
		      selecta); }
# Select from a list of files already added/modified/deleted from Git
function vc() { vim $(git status -s | cut -c 3- | selecta); }
function branchp() { git checkout $(git branch -la | tr '*' '1' | sort -r | sed 's/remotes\/origin\///g' | cut -c 3- | sort | uniq | selecta); }
function isodate() { date +%Y-%m-%d; }
function proj() { cd $(find ~/src ~/src/experiments -maxdepth 1 -type d | selecta); }

function editp () {
	PATTERN=$1
	vim $(ag -c "$PATTERN" | cut -d ':' -f 1) "+/$PATTERN"

}

# Give us a temporary directory and a shell. Once we exit, delete the directory
function sandbox () {
	local MY_TEMP_DIR="$(mktemp -d)"
	echo "Entering sandbox directory: $MY_TEMP_DIR"
	sh -c "cd $MY_TEMP_DIR; exec \"${SHELL:-sh}\""
	echo "Exiting and deleting sandbox directory..."
	rm -rf $MY_TEMP_DIR
}

##################### NeoVim/Vim ####################
# Set Vim runtime for Neovim
if [[ -d "/usr/share/vim/vim73/" ]]
then
	export VIMRUNTIME=/usr/share/vim/vim73
elif [[ -d "/usr/share/vim/vim74/" ]]
then
	export VIMRUNTIME=/usr/share/vim/vim74
fi

# Use Neovim if available
if [[ -x "/opt/boxen/homebrew/bin/nvim" ]]
then
	alias vim=nvim
fi

#################### Go ######################
export GOPATH=~/src/go
export PATH=$PATH:$GOPATH/bin

################## Elixir ####################
export ERL_AFLAGS="-kernel shell_history enabled"


################## ASDF ######################
if [[ -d "$HOME/.asdf" ]]; then
	source $HOME/.asdf/asdf.sh
	source $HOME/.asdf/completions/asdf.bash
fi

################## Ruby ######################
# Load rbenv if it's installed
eval "$(rbenv init -)"

##################### Secrets (API Keys, etc. Gitignored) ####################
if [ -e ~/.secrets ]
then
    source ~/.secrets
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

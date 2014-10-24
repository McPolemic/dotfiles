export PS1='\h:\W \u$ '
export PATH=/usr/local/bin:/usr/local/sbin:~/bin:$PATH
export EDITOR=vim
alias v="f -e vim"
alias be="bundle exec"
alias bi="bundle install"

eval "$(fasd --init auto)"

export GOPATH=~/src/go

# Load rbenv if it's installed
if hash foo 2>/dev/null; then
  eval "$(rbenv init -)"
fi

source ~/bin/git-completion.bash

#API keys, etc
if [ -e ~/.bashrc_private ]
then
    source ~/.bashrc_private
fi

function mkdircd() { mkdir -p "$@" && eval cd "\"\$$#\""; }
function vp() { vim $(find . -name '*.rb' \
	                  -o -name '*.erb' \
	                  -o -name '*.py' \
			  -o -name '*.java' \
			  -o -name '*.go' | selecta); }
function branchp() { git checkout $(git branch | tr '*' '1' | sort -r | cut -c 3- | selecta); }

# Much larger history
HISTFILESIZE=1000000

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

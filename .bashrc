export PS1='\h:\W \u$ '
export PATH=/usr/local/bin:/usr/local/sbin:~/bin:$PATH
export EDITOR=vim
export SSL_CERT_FILE=/opt/boxen/homebrew/opt/curl-ca-bundle/share/ca-bundle.crt
alias v="f -e vim"
alias be="bundle exec"
alias bi="bundle install"

eval "$(fasd --init auto)"

alias emacs=/opt/boxen/homebrew/bin/emacs
alias light=/Applications/LightTable/light
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

#Docker/Boot2Docker
export DOCKER_HOST=tcp://

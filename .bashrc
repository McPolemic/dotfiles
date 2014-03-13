export PS1='\h:\W \u$ '
export PATH=/usr/local/bin:/usr/local/sbin:~/bin:$PATH
export EDITOR=vim
export SSL_CERT_FILE=/opt/boxen/homebrew/opt/curl-ca-bundle/share/ca-bundle.crt
alias v="f -e vim"
alias be="bundle exec"
alias bi="bundle install"

eval "$(rbenv init -)"
eval "$(fasd --init auto)"

alias emacs=/opt/boxen/homebrew/bin/emacs
alias light=/Applications/LightTable/light
export GOPATH=~/src/go

source /opt/boxen/rbenv/versions/2.0.0-p0/lib/ruby/gems/2.0.0/gems/tmuxinator-0.6.5/completion/tmuxinator.bash
source ~/bin/git-completion.bash

#API keys, etc
if [ -e "~/.bashrc_private" ]
then
    source ~/.bashrc_private
fi

function mkdircd() { mkdir -p "$@" && eval cd "\"\$$#\""; }

#Docker/Boot2Docker
export DOCKER_HOST=tcp://

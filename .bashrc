source ~/.common_profile.sh
export PS1='\h:\W \u$ '

# Disable XON/XOFF (Ctrl-S/Ctrl-Q) for interactive shells
[[ $- == *i* ]] && stty -ixon

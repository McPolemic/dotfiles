#!/bin/sh
set -e

git clone --recursive git@github.com:McPolemic/dotfiles.git
cd dotfiles

# Set globs to show dotfiles
shopt -s dotglob
for d in *
  do if [ -e ~/${d} ]
       then mv ~/${d} ~/${d}.bak
     fi
     ln -s `pwd`/${d} ~/${d}
done
# Set it back to normal
shopt -u dotglob

#!/bin/sh
set -e

git clone https://github.com/McPolemic/dotfiles.git
cd dotfiles

# Set globs to show dotfiles
shopt -s dotglob
for d in *; do ln -s `pwd`/${d} ~/${d}; done
# Set it back to normal
shopt -u dotglob

#!/bin/bash
set -e

# Create an SSH key if needed
if [ ! -d ~/.ssh ]
then
  echo "No SSH key found. Creating a new one..."
  ssh-keygen -f ~/.ssh/id_rsa

  echo "Public key (for adding to GitHub)"
  echo "================================="
  cat ~/.ssh/id_rsa
  echo "================================="
  echo
  echo "Press enter to continue..."
  # Pause for copying
  read
fi

mkdir ~/src
cd ~/src

# Pull down the dotfiles repo
git clone --recursive git@github.com:McPolemic/dotfiles.git
# Read-only
# git clone --recursive https://github.com/McPolemic/dotfiles.git

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

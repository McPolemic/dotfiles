#!/bin/bash
set -e

SSH_KEY=~/.ssh/id_rsa

# Create an SSH key if needed
if [ ! -f "${SSH_KEY}" ]
then
  echo "No SSH key found. Creating a new one..."
  ssh-keygen -f "${SSH_KEY}"

  echo "Public key (for adding to GitHub)"
  echo "================================="
  cat "${SSH_KEY}.pub"
  echo "================================="
  echo
  echo "Press enter to continue..."

  # Pause for copying
  read
fi

mkdir -p ~/src
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

# Install Homebrew (on MacOS)
if [ $(uname) = "Darwin" ]; then
  if ! [ -x "$(command -v brew)" ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
fi

# Install Brewfile
brew bundle

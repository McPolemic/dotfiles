#!/bin/bash

#https://bugs.launchpad.net/ubuntu/+source/ruby2.0/+bug/1310292
#https://bugs.launchpad.net/ubuntu/+source/ruby2.0/+bug/1310292/comments/25

# Rename original out of the way, so updates / reinstalls don't squash our hack fix
sudo dpkg-divert --add --rename --divert /usr/bin/ruby.divert /usr/bin/ruby
sudo dpkg-divert --add --rename --divert /usr/bin/gem.divert /usr/bin/gem
# Create an alternatives entry pointing ruby -> ruby2.0
sudo update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby2.0 1
sudo update-alternatives --install /usr/bin/gem gem /usr/bin/gem2.0 1

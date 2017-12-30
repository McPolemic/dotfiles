#!/bin/sh
# Updates the Plex server for 64-bit Ubuntu
wget -O plex.deb 'https://plex.tv/downloads/latest/1?channel=16&build=linux-ubuntu-x86_64&distro=ubuntu&X-Plex-Token=Zeeatz18gEikwjBU5ya6' && sudo dpkg -i plex.deb && rm plex.deb

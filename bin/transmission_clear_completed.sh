#!/bin/bash
for torrent in $(transmission-remote -l | grep Finished | awk '{print $1}')
  do transmission-remote --torrent $torrent --remove
done

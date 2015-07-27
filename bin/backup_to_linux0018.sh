#!/bin/sh
rsync -avzh --progress -e "ssh -l alukens" src linux0018:/home/alukens/

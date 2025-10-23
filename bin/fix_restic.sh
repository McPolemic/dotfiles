#!/bin/zsh
source ~/.restic/restic-env && restic unlock
RESTIC_REPOSITORY='sftp://august@puck//media/backups/lumo-obsidian-repo' restic unlock

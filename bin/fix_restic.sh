#!/bin/zsh
source ~/.restic/restic-env && restic unlock
RESTIC_REPOSITORY='sftp://adam@puck//media/backups/lumo-obsidian-repo' restic unlock

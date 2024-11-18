#!/bin/sh 

set -eu

tar -czvf ~/minecraft_backups/minecraft_backup-"$(date "+%Y_%m_%d_%H_%M_%S")".tar.gz -C ~/ Minecraft


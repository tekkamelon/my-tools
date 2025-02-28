#!/bin/sh 

set -eu
set -xv

# セッション名
session_name="minecraft"

# セッションを起動
tmux new-session -d -s "${session_name}"

# セッション内でコマンドを実行
tmux send-keys -t "${session_name}" "cd Minecraft && java -Xmx12G -Xms12G -jar server.jar nogui" C-m


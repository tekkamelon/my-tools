#!/bin/sh 

set -eu
set -xv

# セッション名
session_name="minecraft"

# 起動時RAMサイズ
ram_size="12G"

# セッションをデタッチ状態で起動,既にセッションがあれば何もしない
tmux new-session -A -d -s "${session_name}"

# マイクラサーバーが起動していれば真
if pgrep -f "java.*server.jar" > /dev/null; then

    echo "マインクラフトサーバーは既に起動しています"

else

	# セッション内でコマンドを実行
	tmux send-keys -t "${session_name}" "cd ~/Minecraft && java -Xmx${ram_size} -Xms${ram_size} -jar server.jar nogui" C-m

fi


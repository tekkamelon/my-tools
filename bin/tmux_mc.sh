#!/bin/sh 

set -eu
set -xv

# セッション名
session_name="minecraft"

# 起動時RAMサイズ
ram_size="12G"

# セッションをデタッチ状態で起動,既にセッションがあれば何もしない
if tmux has-session -t "${session_name}" 2>/dev/null ; then

	echo "セッション ${session_name} は既に存在します"

else

	tmux new-session -d -s "${session_name}"

fi

# マイクラサーバーが起動していれば真
if pgrep -f "java.*server.jar" > /dev/null; then

    echo "マインクラフトサーバーは既に起動しています"

else

	# セッション内でコマンドを実行
	tmux send-keys -t "${session_name}" "cd ~/Minecraft && java -Xmx${ram_size} -Xms${ram_size} -jar server.jar nogui" C-m

fi


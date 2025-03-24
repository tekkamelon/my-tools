#!/bin/sh

# /usr/local/bin/以下に配置

set -eu

# 第1引数に応じ処理を分岐
if [ "$1" = "bat" ]; then

	# tlpを起動
    /usr/sbin/tlp bat

	# ログを出力
    echo "$(date): Switched to battery mode" >> /var/log/tlp-switch.log

elif [ "$1" = "ac" ]; then

    /usr/sbin/tlp ac

    echo "$(date): Switched to AC mode" >> /var/log/tlp-switch.log

fi


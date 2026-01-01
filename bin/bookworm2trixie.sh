#!/bin/sh

set -eu

# このコマンド自身の名前
script_name="${0##*/}"

# GUI,音声で通知
notify(){

	# 通知用コマンド検出
	if command -v notify-send >/dev/null 2>&1; then
		notify-send -u critical "${script_name}" 'アップグレード完了' -i /usr/share/pixmaps/debian-logo.png
	fi

	if command -v paplay >/dev/null 2>&1; then
		paplay /usr/share/sounds/freedesktop/stereo/complete.oga
	fi

}

# root権限確認
if [ "$(id -u)" -ne 0 ]; then

	# エラーメッセージ表示
    printf '%s: root権限で実行してください: sudo sh "%s"\n' "${script_name}" "${0}" >&2
    exit 1

# debian bookwormでなければ終了
elif ! grep -q '^12\.' /etc/debian_version 2>/dev/null; then

    printf '%s: Debian Bookworm (12) で実行してください \n' "${script_name}" >&2
    exit 1

fi

# 現在のリリース確認 (lsb_release優先、/etc/debian_version fallback)
CURRENT_RELEASE="$(lsb_release -cs 2>/dev/null || awk -F= '/^VERSION_CODENAME/{gsub(/"/, "", $2); print $2}' /etc/os-release 2>/dev/null || printf 'unknown\n')"

# # リリースが取得できなかった場合のエラー処理
case "${CURRENT_RELEASE}" in
    bookworm|12) ;;
    *) printf '%s: Debian Bookworm (12) で実行してください 現在: %s\n' "${script_name}" "${CURRENT_RELEASE}" >&2; exit 1 ;;
esac

# sources.list バックアップ
cp /etc/apt/sources.list /etc/apt/sources.list.bak."${script_name}" || {
    printf '%s: sources.list バックアップ失敗\n' "${script_name}" >&2
    exit 1
}

# bookworm を trixie に置換 (security/backports含む)
sed -i 's/\(codename\s*\|\b\)bookworm\b/\1trixie/g' /etc/apt/sources.list || {
    printf '%s: sources.list 置換失敗\n' "${script_name}" >&2
    exit 1
}

# リポジトリ更新
apt update -y || printf "apt update 失敗 sources.listを確認してください\n"

cat << EOF
Trixieリポジトリに切り替えました
アップグレードを続行しますか? (y/N): 
EOF
read -r RESPONSE
case "${RESPONSE}" in
    [Yy]*) ;;
    *) printf '%s: ユーザー中止\n' "${script_name}" >&2; exit 1 ;;
esac

# アップグレード実行
printf "最小アップグレードを実行\n"
apt upgrade --without-new-pkgs || {
    printf "apt upgradeが失敗しました\n" >&2
    exit 1
}

printf "フルアップグレードを実行\n"
apt full-upgrade || {
	printf "apt full-upgradeが失敗しました\n" >&2
    exit 1
}

cat << EOF
アップグレード完了
再起動をおすすめします: reboot
バックアップ: /etc/apt/sources.list.bak.${script_name}
EOF

# 通知を送る
notify


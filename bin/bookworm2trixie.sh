#!/bin/sh

set -eu

SCRIPT_NAME="${0##*/}"

# root権限確認
if [ "$(id -u)" -ne 0 ]; then

	# エラーメッセージ表示
    printf '%s: root権限で実行してください: sudo sh "%s"\n' "${SCRIPT_NAME}" "${0}" >&2
    exit 1
fi

# 現在のリリース確認 (lsb_release優先、/etc/debian_version fallback)
CURRENT_RELEASE="$(lsb_release -cs 2>/dev/null || awk -F= '/^VERSION_CODENAME/{gsub(/"/, "", $2); print $2}' /etc/os-release 2>/dev/null || printf 'unknown\n')"

# # リリースが取得できなかった場合のエラー処理
case "${CURRENT_RELEASE}" in
    bookworm|12) ;;
    *) printf '%s: Debian Bookworm (12) で実行してください。現在: %s\n' "${SCRIPT_NAME}" "${CURRENT_RELEASE}" >&2; exit 1 ;;
esac

# sources.list バックアップ
cp /etc/apt/sources.list /etc/apt/sources.list.bak."${SCRIPT_NAME}" || {
    printf '%s: sources.list バックアップ失敗\n' "${SCRIPT_NAME}" >&2
    exit 1
}

# bookworm を trixie に置換 (security/backports含む)
sed -i 's/\(codename\s*\|\b\)bookworm\b/\1trixie/g' /etc/apt/sources.list || {
    printf '%s: sources.list 置換失敗\n' "${SCRIPT_NAME}" >&2
    exit 1
}

# リポジトリ更新
apt update -y || echo "apt update 失敗 sources.listを確認してください"

printf 'Trixieリポジトリに切り替えました。\n'
printf 'アップグレードを続行しますか？ (y/N): '
read -r RESPONSE
case "${RESPONSE}" in
    [Yy]*) ;;
    *) printf '%s: ユーザー中止\n' "${SCRIPT_NAME}" >&2; exit 1 ;;
esac

# アップグレード実行
echo "最小アップグレードを実行"
apt upgrade --without-new-pkgs || echo "apt upgradeが失敗しました"

echo "フルアップグレードを実行"
apt full-upgrade || echo "apt full-upgradeが失敗しました"

cat << EOF
アップグレード完了
再起動をおすすめします: reboot
バックアップ: /etc/apt/sources.list.bak.${SCRIPT_NAME}
EOF

# 通知を送る
notify-send -u critical 'bookworm2trixie' 'アップグレード完了' 
paplay /usr/share/sounds/freedesktop/stereo/complete.oga


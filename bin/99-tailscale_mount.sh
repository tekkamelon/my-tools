#!/bin/sh
# /etc/NetworkManager/dispatcher.d/99-tailscale_mount.sh
# 自宅SSIDまたは自宅有線以外で接続したら tailscale up + NASマウント、
# 自宅なら tailscale down

set -eu

TAILSCALE=/usr/bin/tailscale
MOUNT=/usr/bin/mount
NMCLI=/usr/bin/nmcli

# 自宅の有線プロファイル名 (nmcli con show で確認、不要なら空のまま)
home_wired=""

iface="${1:-}"
action="${2:-}"
conn="${CONNECTION_ID:-}"

log() {
    logger -t 99-tailscale_mount "$*"
}

# 自宅用: tailscale down後に古いNFSマウントを張り替えてLAN直結に戻す
remount_home() {
    ${TAILSCALE} down || log "tailscale down failed"
    # 外出先(exit node経由)で確立したNFSはstaleになるため外して張り直す
    /usr/bin/umount -l /mnt/omv 2>/dev/null || true
    if out=$(/usr/bin/timeout 20 ${MOUNT} /mnt/omv 2>&1); then
        log "mounted /mnt/omv"
    else
        log "mount failed: ${out}"
    fi
}

# 外出先用: tailscale up後に古いNFSマウントを張り替える
remount_outside() {
    if ! ${TAILSCALE} up; then
        log "tailscale up failed"
        return 0
    fi
    # 自宅LAN直結で確立したstaleマウントを外す
    /usr/bin/umount -l /mnt/omv 2>/dev/null || true
    # exit node/subnet routeが整うまで待って張り直す
    # (失敗してもx-systemd.automountが次回access時に再試行する)
    i=0
    while [ "${i}" -lt 4 ]; do
        if out=$(/usr/bin/timeout 20 ${MOUNT} /mnt/omv 2>&1); then
            log "mounted /mnt/omv"
            return 0
        fi
        log "mount retry ${i}: ${out}"
        i=$((i + 1))
        sleep 5
    done
    return 0
}

# up系以外のイベント(down/pre-up等)では何もしない
case "${action}" in
    up|connectivity-change|dhcp4-change|dhcp6-change) ;;
    *) exit 0 ;;
esac

# 仮想IFのイベントでは何もしない (tailscale操作による再発火ループ防止)
case "${iface}" in
    tailscale0|lo|docker*|veth*|br-*) exit 0 ;;
esac

# 接続プロファイルからSSIDを取得 (有線なら空になる)
ssid=""
if [ -n "${conn}" ]; then
    ssid=$(${NMCLI} -g 802-11-wireless.ssid con show "${conn}" 2>/dev/null || true)
fi

# 自宅SSID (完全一致、複数可)
case "${ssid}" in
    laeria|laeria628_5GHz|laeria628_2.4GHz)
        log "home wifi (${ssid}), tailscale down"
        remount_home
        exit 0
        ;;
esac

# 自宅有線プロファイルに一致したらtailscale down
if [ -n "${home_wired}" ] && [ "${conn}" = "${home_wired}" ]; then
    log "home wired (${conn}), tailscale down"
    remount_home
    exit 0
fi

# 接続情報が空(グローバルなconnectivity-change等)なら何もしない
# 空を外出先扱いにすると、直後のdownがupで打ち消されてしまう
if [ -z "${conn}" ] && [ -z "${ssid}" ]; then
    exit 0
fi

# 上記以外(外出先wifi/有線テザリング/ホテル有線等)はtailscale up + マウント
log "outside (conn=${conn}, ssid=${ssid}), tailscale up"
remount_outside
log "done"

exit 0

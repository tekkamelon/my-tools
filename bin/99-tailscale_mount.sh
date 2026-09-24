#!/bin/sh
# 自宅 LAN に直結している時だけ tailscale down、それ以外は up。
# NAS は名前 rei でマウントし解決先が場所で変わるため、切替時に必ず張り直す。
set -u

route=$(ip route get 192.168.1.145 2>/dev/null | head -1)
case "${route}" in
  *"dev tailscale0"*) tailscale up ;;    # サブネットルート経由 = 外出先
  *" via "*)          tailscale up ;;    # 他ネットワークのGW経由 = 外出先
  *)                  tailscale down ;;  # LAN 直結 = 自宅
esac

exit 0

#!/bin/sh 

# このスクリプトを"/etc/NetworkManager/dispatcher.d/"以下のディレクトリに配置
# hogeを適宜除外するAP名に設定

set -eu

# 除外するAP
home_ap=hoge

# 接続先のAP
ap_name=$(

	iwconfig 2> /dev/null |

	# 区切り文字を":"とスペースに指定
	awk -F[:" "] '

	# 1行目のみを処理
	NR == 1{

		# 6フィールド目が"802.11"かつ9フィールド目が"off/any"ではない場合に真
		if($6 == "802.11" && $9 != "off/any"){

			# AP名を出力
			print $9

		}else{

			print "no_wireless"

		}

	}
	'
)

# wi-fiに接続されていないか"home_ap"に接続されている場合に真
if [ "${ap_name}" = "no_wireless" ] || echo "${ap_name}" | grep -F -q "${home_ap}" ; then

	tailscale down

# "home_ap"以外のwi-fiに接続されている場合に真
elif echo "${ap_name}" | grep -F -v -q "${home_ap}" ; then

	tailscale up &&

	systemctl restart rc-local.service

fi


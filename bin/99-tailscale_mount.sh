#!/bin/sh 

# このスクリプトを"/etc/NetworkManager/dispatcher.d/"以下のディレクトリに配置
# hogeを適宜除外するAP名に設定

set -eu

# 除外するAP
ignore_ap=hoge

# 接続先のAP
ap_name=$(

	iwconfig 2> /dev/null |

	# 区切り文字を":"とスペースに指定
	awk -F[:" "] '

	# 1行目のみを処理
	NR == 1{

		# 6フィールド目が"802.11"かつ9フィールド目が"off/any"ではない場合に真
		if($6 == "802.11" && $9 != "off/any"){

			print "<" $9 ">"

		}else{

			print "<no " "wireless>"

		}

	}
	'
)

# wi-fiが接続されかつAP名が"ignore_ap"以外であれば真
if [ "${2}" = "up" ] && echo "${ap_name}" | grep -q ^${ignore_ap} ; then

	tailscale up &&

	systemctl restart rc-local.service

# wi-fiが接続されかつAP名が"ignore_ap"であれば真
elif [ "${2}" = "up" ] && echo "${ap_name}" | grep -v -q ^${ignore_ap} ; then

	tailscale down

fi


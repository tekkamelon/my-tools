#!/bin/sh
# Node.js 2026-10-21 セキュリティリリース対応スクリプト
# 対象CVE: CVE-2026-105482, CVE-2026-105483, CVE-2026-106069,
#          CVE-2026-111497, CVE-2026-105481, CVE-2026-106072,
#          CVE-2026-106074, CVE-2026-106070, CVE-2026-106071,
#          CVE-2026-106073
# 修正版: 22.23.4 / 24.22.1 / 26.12.1
# shellcheck disable=SC2317
# trap 経由で呼び出すため shellcheck の到達性判定を無効化
set -eu

IFS=$(printf '\n\t')
export POSIXLY_CORRECT=1

# ====== 定数の宣言 ======
SCRIPT_NAME=$(basename "$0")
FIXED_22="22.23.4"
FIXED_24="24.22.1"
FIXED_26="26.12.1"

mode="check"
assume_yes=0
vulnerable_count=0
unknown_count=0
checked_count=0
system_vulnerable=0
# ====== 定数の宣言ここまで ======

# ====== 関数の宣言 ======
log() {

    printf '[%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$*" >&2

}

die() {

    log "エラー: $*"
    exit 2

}

usage() {

    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTION]

Node.js 2026-10-21 セキュリティリリース (CVE-2026-105482 ほか) の
影響確認と更新を行う。

Options:
  -c, --check   影響確認のみ (既定)
  -a, --apply   影響確認後にシステムの nodejs パッケージを更新
  -y, --yes     apt-get を非対話で実行 (--apply と併用)
  -h, --help    このヘルプを表示

修正版:
  Node.js 22.x -> v${FIXED_22}
  Node.js 24.x -> v${FIXED_24}
  Node.js 26.x -> v${FIXED_26}

主な脆弱性:
  CVE-2026-105482 (high)   dns.resolve の NUL 文字による名前切り捨て
  CVE-2026-105483 (high)   全角数字IPによるTLSホスト名検証回避
  CVE-2026-106069 (high)   IPに緩く解決されるホスト名のTLS検証回避
  CVE-2026-111497 (high)   Brotliデコーダの領域外書き込み (RCE)
  CVE-2026-105481 (medium) keep-aliveソケットの応答混入
  CVE-2026-106072 (medium) 非正規IPv4ホスト名の証明書検証不備
  CVE-2026-106074 (medium) 起動スナップショットへの乱数キャッシュ保存
  CVE-2026-106070 (low)    ZipFile のヘッダ検証不備
  CVE-2026-106071 (low)    Permission Model のワイルドカード過剰許可
  CVE-2026-106073 (low)    Permission Model の realpathSync 回避

終了コード:
  0  脆弱なランタイムなし
  1  脆弱なランタイムあり
  2  判定不能またはエラー
EOF

}

normalize_version() {

    printf '%s' "$1" |
        sed -e 's/^v//' -e 's/[^0-9.].*$//'

}

major_of() {

    printf '%s' "$1" | awk -F. '{ print $1 + 0 }'

}

version_lt() {

    awk -v a="$1" -v b="$2" 'BEGIN {
        na = split(a, x, ".")
        nb = split(b, y, ".")
        n = (na > nb ? na : nb)
        for (i = 1; i <= n; i++) {
            av = (i <= na ? x[i] + 0 : 0)
            bv = (i <= nb ? y[i] + 0 : 0)
            if (av < bv) {
                print "yes"
                exit
            }
            if (av > bv) {
                print "no"
                exit
            }
        }
        print "no"
    }'

}

fixed_version_for() {

    case "$1" in
        22) printf '%s' "${FIXED_22}" ;;
        24) printf '%s' "${FIXED_24}" ;;
        26) printf '%s' "${FIXED_26}" ;;
        *) printf '' ;;
    esac

}

# 戻り値: 0=安全, 1=脆弱, 2=判定不能
evaluate_node() {

    label="${1}"
    raw_version="${2}"
    version=$(normalize_version "${raw_version}")

    if [ -z "${version}" ]; then
        printf '  [判定不能] %s (バージョン取得失敗)\n' "${label}"
        return 2
    fi

    major=$(major_of "${version}")
    fixed=$(fixed_version_for "${major}")

    if [ -z "${fixed}" ]; then
        if [ "${major}" -ge 27 ]; then
            printf '  [判定不能] %s: v%s (修正版情報なし)\n' "${label}" "${version}"
            return 2
        fi
        printf '  [脆弱] %s: v%s (EOL系列のため修正版なし。22/24/26系へ移行)\n' \
            "${label}" "${version}"
        return 1
    fi

    if [ "${version}" = "${fixed}" ] || [ "$(version_lt "${version}" "${fixed}")" = "no" ]; then
        printf '  [安全] %s: v%s (修正版 v%s)\n' "${label}" "${version}" "${fixed}"
        return 0
    fi

    printf '  [脆弱] %s: v%s (修正版 v%s)\n' "${label}" "${version}" "${fixed}"
    return 1

}

record_result() {

    result="${1}"
    checked_count=$((checked_count + 1))

    case "${result}" in
        0) ;;
        1) vulnerable_count=$((vulnerable_count + 1)) ;;
        *) unknown_count=$((unknown_count + 1)) ;;
    esac

}

check_path_nodes() {

    printf '== PATH上のnode ==\n'

    old_ifs="${IFS}"
    IFS=:

    for dir in ${PATH}; do
        [ -n "${dir}" ] || continue
        bin="${dir}/node"
        [ -x "${bin}" ] || continue

        real=$(readlink -f "${bin}" 2>/dev/null || printf '%s' "${bin}")

        if grep -qxF "${real}" "${seen_file}"; then
            continue
        fi
        printf '%s\n' "${real}" >> "${seen_file}"

        raw_version=$("${bin}" -v 2>/dev/null || printf 'unknown')
        evaluate_node "PATH: ${bin}" "${raw_version}" && result=0 || result=$?
        record_result "${result}"
    done

    IFS="${old_ifs}"

}

check_bundled_nodes() {

    printf '== 同梱ランタイム ==\n'

    for root in \
        "${HOME}/.nvm/versions/node" \
        "${HOME}/.hermes/tools" \
        "${HOME}/.vscode-oss" \
        "${HOME}/.cache/uv"; do

        [ -d "${root}" ] || continue

        find "${root}" -maxdepth 8 -type f -name node -perm -u+x \
            2>/dev/null >> "${found_file}" || true

    done

    while IFS= read -r bin; do
        [ -x "${bin}" ] || continue

        real=$(readlink -f "${bin}" 2>/dev/null || printf '%s' "${bin}")

        if grep -qxF "${real}" "${seen_file}"; then
            continue
        fi
        printf '%s\n' "${real}" >> "${seen_file}"

        raw_version=$("${bin}" -v 2>/dev/null || printf 'unknown')
        evaluate_node "同梱: ${bin}" "${raw_version}" && result=0 || result=$?
        record_result "${result}"
    done < "${found_file}"

}

check_system_package() {

    printf '== システムパッケージ ==\n'

    if ! command -v dpkg-query >/dev/null 2>&1; then
        printf '  dpkg-query が見つからないためシステムパッケージを確認できない\n'
        return 0
    fi

    if ! dpkg-query -W -f='${Status}' nodejs 2>/dev/null |
        grep -qF 'install ok installed'; then
        printf '  nodejs パッケージは未導入\n'
        return 0
    fi

    pkg_version=$(dpkg-query -W -f='${Version}' nodejs 2>/dev/null)
    printf '  nodejs パッケージ: %s\n' "${pkg_version}"

    sys_bin="/usr/bin/node"
    if [ ! -x "${sys_bin}" ]; then
        printf '  /usr/bin/node が見つからない\n'
        return 0
    fi

    real=$(readlink -f "${sys_bin}" 2>/dev/null || printf '%s' "${sys_bin}")
    printf '%s\n' "${real}" >> "${seen_file}"

    raw_version=$("${sys_bin}" -v 2>/dev/null || printf 'unknown')
    evaluate_node "システム: ${sys_bin}" "${raw_version}" && result=0 || result=$?
    record_result "${result}"

    if [ "${result}" -eq 1 ]; then
        system_vulnerable=1
    fi

    system_version=$(normalize_version "${raw_version}")

}

apply_system_update() {

    printf '== システムパッケージの更新 ==\n'

    if ! command -v apt-get >/dev/null 2>&1; then
        die "apt-get が見つからない。手動で nodejs を更新すること"
    fi

    if ! dpkg-query -W -f='${Status}' nodejs 2>/dev/null |
        grep -qF 'install ok installed'; then
        die "nodejs パッケージが未導入。利用中のランタイムを提供元の方法で更新すること"
    fi

    current_major=$(major_of "${system_version}")
    fixed=$(fixed_version_for "${current_major}")

    if [ -z "${fixed}" ]; then
        die "Node.js v${system_version} は修正版のない系列。22/24/26系へ移行すること"
    fi

    log "apt-get update を実行"
    apt-get update || die "apt-get update に失敗"

    candidate=$(LC_ALL=C apt-cache policy nodejs 2>/dev/null |
        awk '/Candidate:/{ print $2; exit }')

    if [ -z "${candidate}" ]; then
        die "更新候補を取得できない"
    fi

    candidate_version=$(normalize_version "${candidate}")

    log "更新候補: ${candidate} (必要: ${fixed} 以上)"

    if [ "$(version_lt "${candidate_version}" "${fixed}")" = "yes" ]; then
        die "更新候補が修正版より古い。NodeSource の 24.x リポジトリ等を確認すること"
    fi

    if [ "${assume_yes}" -eq 1 ]; then
        apt-get install --only-upgrade -y nodejs || die "nodejs の更新に失敗"
    else
        apt-get install --only-upgrade nodejs || die "nodejs の更新に失敗"
    fi

    after_version=$(normalize_version "$(/usr/bin/node -v 2>/dev/null || printf 'unknown')")
    log "更新後のシステムNode.js: v${after_version}"
    log "注意: 更新前に起動したNode.jsプロセスは再起動するまで旧版のまま"

    evaluate_node "システム: /usr/bin/node" "${after_version}" && result=0 || result=$?
    if [ "${result}" -ne 0 ]; then
        die "更新後も脆弱なバージョンが残っている"
    fi

    log "システムパッケージの更新が完了"

}

# ====== 関数の宣言ここまで ======

# ====== 引数の解析 ======
while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -c|--check)
            mode="check"
            shift
            ;;
        -a|--apply)
            mode="apply"
            shift
            ;;
        -y|--yes)
            assume_yes=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf '未知の引数: %s\n\n' "${1}" >&2
            usage >&2
            exit 2
            ;;
    esac
done
# ====== 引数の解析ここまで ======

# ====== 事前確認 ======
if [ "${mode}" = "apply" ] && [ "$(id -u)" -ne 0 ]; then
    if command -v sudo >/dev/null 2>&1; then
        log "root権限が必要なため sudo で再実行"
        exec sudo -- "${0}" "${@}"
    fi
    die "root権限が必要。sudo を利用できる環境で実行すること"
fi

system_version=""
seen_file=$(mktemp)
found_file=$(mktemp)

cleanup() {

    rm -f "${seen_file}" "${found_file}"

}

trap cleanup EXIT
trap 'exit 2' INT TERM
# ====== 事前確認ここまで ======

# ====== 影響確認 ======
log "Node.js 2026-10-21 セキュリティリリースの影響確認を開始"

check_system_package
check_path_nodes
check_bundled_nodes
# ====== 影響確認ここまで ======

# ====== 更新の適用 ======
if [ "${mode}" = "apply" ] && [ "${system_vulnerable}" -eq 1 ]; then
    apply_system_update

    # 更新後に再確認
    vulnerable_count=0
    unknown_count=0
    checked_count=0
    system_vulnerable=0
    : > "${seen_file}"
    system_version=""

    check_system_package
    check_path_nodes
    check_bundled_nodes
fi
# ====== 更新の適用ここまで ======

# ====== 結果の表示 ======
printf '\n== 結果 ==\n'
printf '  確認数: %s\n' "${checked_count}"
printf '  脆弱:   %s\n' "${vulnerable_count}"
printf '  不明:   %s\n' "${unknown_count}"

if [ "${vulnerable_count}" -gt 0 ]; then
    if [ "${system_vulnerable}" -eq 1 ]; then
        printf '\n脆弱なNode.jsが残っている。システムパッケージは次のコマンドで更新する:\n'
        printf '  sudo %s --apply\n' "${0}"
    else
        printf '\nシステムパッケージは安全だが、同梱ランタイムが脆弱なまま。\n'
        printf '各ツールの提供元の更新手順に従って更新すること。\n'
    fi
    exit 1
fi

if [ "${unknown_count}" -gt 0 ]; then
    printf '\n判定不能なランタイムがある。各提供元の情報を確認すること。\n'
    exit 2
fi

printf '\n脆弱なNode.jsは検出されなかった。\n'
exit 0
# ====== 結果の表示ここまで ======

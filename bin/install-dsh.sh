#!/bin/sh

# シェルオプションの設定
set -eu

# ====== 変数の宣言 ======
script_name="$(basename "$0")"
channel="stable"
profile="pi-tui"
web_profile="web"
skip_acp="0"
skip_ja="0"
dsh_pkg="@deepseek-ai/dsh@latest"
tui_pkg="@xmoon76/dsh-pi-tui@latest"
ja_name="@fang2hou/dsh-locale-ja"
ja_pkg="${ja_name}@latest"
allow_scripts="@deepseek-ai/dsh-subprocess-local,koffi,node-pty,@google/genai,protobufjs,fs-ext"
dsh_home="${DSH_HOME:-${HOME}/.dsh}"
patch_tmp=""
# ====== 変数の宣言ここまで ======


# ====== 関数の宣言 ======
# 使い方の表示
print_usage() {
    cat <<USAGE_EOF
Usage: ${script_name} [--channel stable|next] [--profile NAME] [--web-profile NAME] [--skip-acp] [--skip-ja]

Options:
  --channel     stable (既定) / next (alpha + next 線)
  --profile     TUI 用 profile 名 (既定: pi-tui)
  --web-profile Web UI 用 profile 名 (既定: web)
  --skip-acp    ACP profile の検証省略
  --skip-ja     Web UI 日本語化の省略
  -h, --help    ヘルプの表示
USAGE_EOF
}

# 一時ファイルの後始末
cleanup() {
    if [ -n "${patch_tmp}" ]; then
        rm -f "${patch_tmp}"
    fi
}

# エラーメッセージの出力
print_error() {
    printf '%s\n' "$1" >&2
}

# 情報メッセージの出力
print_info() {
    printf '%s\n' "$1"
}
# ====== 関数の宣言ここまで ======

# 異常終了時の一時ファイル削除
trap cleanup EXIT
trap 'exit 1' INT TERM


# 引数の解析
while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --channel)
            if [ "${#}" -lt 2 ]; then
                print_error "引数値の不足"
                print_usage
                exit 1
            fi
            channel="${2}"
            shift 2
            ;;
        --profile)
            if [ "${#}" -lt 2 ]; then
                print_error "引数値の不足"
                print_usage
                exit 1
            fi
            profile="${2}"
            shift 2
            ;;
        --skip-acp)
            skip_acp="1"
            shift 1
            ;;
        --web-profile)
            if [ "${#}" -lt 2 ]; then
                print_error "引数値の不足"
                print_usage
                exit 1
            fi
            web_profile="${2}"
            shift 2
            ;;
        --skip-ja)
            skip_ja="1"
            shift 1
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            print_error "未知の引数: ${1}"
            print_usage
            exit 1
            ;;
    esac
done

# channel 値の検証
if [ "${channel}" != "stable" ] && [ "${channel}" != "next" ]; then
    print_error "channel 指定の不正: ${channel}"
    print_usage
    exit 1
fi

# next 線の package 切替
if [ "${channel}" = "next" ]; then
    dsh_pkg="@deepseek-ai/dsh@alpha"
    tui_pkg="@xmoon76/dsh-pi-tui@next"
fi


# Node.js 存在確認
if ! command -v node >/dev/null 2>&1; then
    print_error "Node.js の不在"
    exit 1
fi

# Node.js バージョン確認 (^22.19.0 || >=24)
node_ver="$(node -v)"
print_info "検出 Node.js: ${node_ver}"
node_ok="$(printf '%s' "${node_ver}" | awk '
/^v([0-9]+)\.([0-9]+)\.([0-9]+)/ {
    ver = substr($0, 2)
    n = split(ver, a, ".")
    major = a[1] + 0
    minor = a[2] + 0
    if (major > 24 || major == 24) { print "1"; exit }
    if (major == 22 && minor >= 19) { print "1"; exit }
    if (major == 23) { print "0"; exit }
    print "0"
    exit
}
{ print "0" }
')"
if [ "${node_ok}" != "1" ]; then
    print_error "Node.js バージョン不足 (要 ^22.19.0 || >=24): ${node_ver}"
    exit 1
fi

# pnpm 存在確認 (dsh plugin 内部使用)
if ! command -v pnpm >/dev/null 2>&1; then
    print_error "pnpm の不在 (dsh plugin が内部使用)"
    exit 1
fi


# dsh 本体の導入
print_info "dsh 本体の導入: ${dsh_pkg}"
npm install -g "--allow-scripts=${allow_scripts}" "${dsh_pkg}"

# dsh 起動確認
dsh --version

# TUI (dsh-pi-tui) の導入
print_info "TUI の導入: ${tui_pkg} -> profile ${profile}"
dsh plugin --profile "${profile}" -- add "${tui_pkg}"

# TUI profile 構成確認
dsh --profile "${profile}" --dump-config >/dev/null
print_info "TUI profile 検証の完了: ${profile}"

# ACP profile の検証 (同梱品、別途 npm 不要)
# deepseek-ai/dsh-acp 指定 = 本体同梱 packages/bundle/acp-app
if [ "${skip_acp}" = "0" ]; then
    print_info "ACP profile の検証 (同梱品)"
    dsh --profile acp --dump-config >/dev/null
    print_info "ACP profile 検証の完了"
fi


# 日本語化 (Web UI)
if [ "${skip_ja}" = "0" ]; then
    print_info "Web UI 日本語化: ${ja_pkg} -> profile ${web_profile}"

    # Web profile の初期化と日本語化プラグインの導入
    dsh plugin --profile "${web_profile}" -- add "${ja_pkg}"

    # 導入版と実行中の DSH 版の取得
    dsh_ver="$(dsh --version)"
    ja_pkg_json="${dsh_home}/profiles/${web_profile}/node_modules/${ja_name}/package.json"
    ja_ver="$(node -p "require('${ja_pkg_json}').version")"

    # peerDependencies の版レンジ不一致による読込スキップの回避 (版を限定した例外)
    print_info "互換性例外の付与: ${ja_name}@${ja_ver} / dsh ${dsh_ver}"
    dsh plugin --profile "${web_profile}" allow-version "${ja_name}@${ja_ver}" --dsh-version "${dsh_ver}" --accept-risk

    # 既定ロケールを日本語に固定 (既存の locale エントリを置換追記)
    patch_file="${dsh_home}/profiles/${web_profile}/cordis.patch.yml"
    patch_tmp="$(mktemp)"
    awk '
/^\[\]$/ { next }
/^- id: locale$/ { skip = 1; next }
/^- / { skip = 0 }
skip != 1 { print }
' "${patch_file}" > "${patch_tmp}"
    cat >> "${patch_tmp}" <<'LOCALE_EOF'
- id: locale
  name: "@deepseek-ai/dsh-client-locale"
  config:
    preference: ja
LOCALE_EOF
    cat "${patch_tmp}" > "${patch_file}"
    rm -f "${patch_tmp}"
    patch_tmp=""

    # Web profile 構成確認 (読込スキップの検出)
    verify_err="$(dsh --profile "${web_profile}" --dump-config 2>&1 >/dev/null)"
    if printf '%s\n' "${verify_err}" |
        grep -F "skipping profile bundle" >/dev/null 2>&1; then
        print_error "${verify_err}"
        print_error "日本語化プラグインの読込に失敗"
        exit 1
    fi
    print_info "Web profile 検証の完了: ${web_profile}"
fi


# 次手順の表示
cat <<NEXT_EOF
完了。次手順:
  1. API 鍵設定 (Web UI 不使用時): \$DSH_HOME/settings.yaml + .credentials.yaml
  2. TUI 起動: dsh --profile ${profile}
  3. ACP 起動: dsh --profile acp
  4. Web 起動: dsh web (UI は日本語)
NEXT_EOF

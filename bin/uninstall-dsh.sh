#!/bin/sh

# シェルオプションの設定
set -eu

# ====== 変数の宣言 ======
script_name="$(basename "$0")"
profile="pi-tui"
web_profile="web"
tui_pkg="@xmoon76/dsh-pi-tui"
keep_runtime="0"
# ====== 変数の宣言ここまで ======


# ====== 関数の宣言 ======
# 使い方の表示
print_usage() {
    cat <<USAGE_EOF
Usage: ${script_name} [--profile NAME] [--web-profile NAME] [--keep-runtime]

Options:
  --profile      TUI 用 profile 名 (既定: pi-tui)
  --web-profile  Web UI 用 profile 名 (既定: web)
  --keep-runtime dsh 本体のアンインストール省略
  -h, --help     ヘルプの表示
USAGE_EOF
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


# 引数の解析
while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --profile)
            if [ "${#}" -lt 2 ]; then
                print_error "引数値の不足"
                print_usage
                exit 1
            fi
            profile="${2}"
            shift 2
            ;;
        --keep-runtime)
            keep_runtime="1"
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


# dsh 存在確認
if ! command -v dsh >/dev/null 2>&1; then
    print_error "dsh コマンドの不在 (既に削除済みの可能性)"
else
    # TUI の除去
    print_info "TUI の除去: ${tui_pkg} <- profile ${profile}"
    if dsh plugin --profile "${profile}" -- list 2>/dev/null | grep -F "${tui_pkg}" >/dev/null 2>&1; then
        dsh plugin --profile "${profile}" -- remove "${tui_pkg}"
    else
        print_info "TUI 未検出のため除去省略"
    fi
fi


# dsh 本体の除去
if [ "${keep_runtime}" = "0" ]; then
    print_info "dsh 本体の除去"
    npm uninstall -g "@deepseek-ai/dsh" "${tui_pkg}" || npm uninstall -g "@deepseek-ai/dsh"
else
    print_info "本体除去の省略"
fi


# 残存物の表示 (自動削除なし)
cat <<LEFT_EOF
残存物 (必要なら手動削除):
  - TUI profile: \$DSH_HOME/profiles/${profile}
  - Web profile: \$DSH_HOME/profiles/${web_profile}
  - 互換性例外: \$DSH_HOME/profiles/${web_profile}/compatibility.json
  - 日本語化パッチ: \$DSH_HOME/profiles/${web_profile}/cordis.patch.yml
  - 設定: \$DSH_HOME/settings.yaml
  - 資格情報: \$DSH_HOME/.credentials.yaml
LEFT_EOF

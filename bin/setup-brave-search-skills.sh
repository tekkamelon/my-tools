#!/bin/sh
# Brave Search API 公式 skills のセットアップと動作確認
# pi の非対話的テストには --mode json を使用

set -eu

# ====== 変数の宣言 ======
BRAVE_SKILLS_URL="https://github.com/brave/brave-search-skills/archive/main.tar.gz"
SKILLS_DIR="${HOME}/.agents/skills"
BX_INSTALL_DIR="${HOME}/.local/bin"

# 環境変数から API key を取得
BRAVE_API_KEY="${BRAVE_API_KEY:-}"

# 動作確認用クエリ
TEST_QUERY="Brave Search API test"

# ====== 関数の宣言 ======

# ヘルプの表示
print_usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

  Brave Search API 公式 skills と bx CLI をセットアップし、動作を確認する。

Options:
  -k, --api-key KEY   Brave Search API key を直接指定
  -t, --test-only     セットアップをスキップし、テストのみ実行
      --skip-bx       bx CLI のインストールをスキップ
      --skip-pi       pi による非対話的テストをスキップ
  -h, --help          このヘルプを表示

Environment:
  BRAVE_API_KEY       Brave Search API key（優先して使用される）
EOF
}

# エラーメッセージを出力して終了
print_error() {
    printf '[ERROR] %s\n' "$*" >&2
}

# 情報メッセージを出力
print_info() {
    printf '[INFO] %s\n' "$*"
}

# 成功メッセージを出力
print_ok() {
    printf '[OK] %s\n' "$*"
}


# Brave API key の確認または要求
ensure_api_key() {
    if [ -z "${BRAVE_API_KEY}" ]; then
        print_error "BRAVE_API_KEY が設定されていません。"
        print_error "環境変数を設定するか、-k KEY オプションで指定してください。"
        exit 1
    fi
    print_ok "Brave API key が設定されています。"
}

# skills ディレクトリの作成と Brave skills の展開
install_brave_skills() {
    print_info "Brave Search skills を ${SKILLS_DIR} に展開します。"
    mkdir -p "${SKILLS_DIR}"

    if ! curl -sL "${BRAVE_SKILLS_URL}" \
        | tar -xz -C "${SKILLS_DIR}" --strip-components=2 brave-search-skills-main/skills; then
        print_error "Brave Search skills のダウンロードまたは展開に失敗しました。"
        exit 1
    fi

    print_ok "Brave Search skills の展開が完了しました。"
}

# bx CLI のインストール
install_bx() {
    if command -v bx >/dev/null 2>&1; then
        print_ok "bx CLI は既にインストールされています。"
        return 0
    fi

    print_info "bx CLI をインストールします。"
    mkdir -p "${BX_INSTALL_DIR}"
    if ! curl -fsSL https://raw.githubusercontent.com/brave/brave-search-cli/main/scripts/install.sh | sh; then
        print_error "bx CLI のダウンロードまたはインストールに失敗しました。"
        exit 1
    fi

    if ! command -v bx >/dev/null 2>&1; then
        print_error "bx CLI のインストールに失敗しました。"
        exit 1
    fi
    print_ok "bx CLI のインストールが完了しました。"
}

# bx CLI に API key を設定
configure_bx() {
    print_info "bx CLI に API key を設定します。"
    bx config set-key "${BRAVE_API_KEY}"
    print_ok "bx CLI の API key 設定が完了しました。"
}

# curl による Web Search API の動作確認
test_api_with_curl() {
    print_info "curl で Brave Web Search API をテストします。"

    if ! response=$(curl -s "https://api.search.brave.com/res/v1/web/search" \
        -H "Accept: application/json" \
        -H "X-Subscription-Token: ${BRAVE_API_KEY}" \
        -G \
        --data-urlencode "q=${TEST_QUERY}" \
        --data-urlencode "count=3"); then
        print_error "curl コマンドの実行に失敗しました。ネットワーク接続を確認してください。"
        exit 1
    fi

    if printf '%s' "${response}" | grep -F '"type":"search"' >/dev/null 2>&1; then
        print_ok "curl による Web Search API テストが成功しました。"
        return 0
    fi

    if printf '%s' "${response}" | grep -F '"code":"RATE_LIMITED"' >/dev/null 2>&1; then
        print_info "curl テストはレート制限のためスキップされました。"
        return 0
    fi

    print_error "curl による Web Search API テストが失敗しました。"
    printf '%s\n' "${response}" | head -n 5 >&2
    return 1
}

# bx web コマンドの動作確認
test_bx_web() {
    print_info "bx web コマンドをテストします。"

    if ! command -v bx >/dev/null 2>&1; then
        print_error "bx CLI がインストールされていません。"
        return 1
    fi

    response=$(bx web "${TEST_QUERY}" --count 3 2>&1 || true)

    if printf '%s' "${response}" | grep -F '"type":"search"' >/dev/null 2>&1; then
        print_ok "bx web コマンドのテストが成功しました。"
        return 0
    fi

    if printf '%s' "${response}" | grep -F '"code":"RATE_LIMITED"' >/dev/null 2>&1; then
        print_info "bx web テストはレート制限のためスキップされました。"
        return 0
    fi

    print_error "bx web コマンドのテストが失敗しました。"
    printf '%s\n' "${response}" | head -n 5 >&2
    return 1
}

# pi の非対話的テスト（--mode json）
test_pi_with_skill() {
    print_info "pi の非対話的テストを実行します。"

    if ! command -v pi >/dev/null 2>&1; then
        print_info "pi コマンドが見つからないため、pi テストをスキップします。"
        return 0
    fi

    if [ -z "${ANTHROPIC_API_KEY:-}" ] \
        && [ -z "${OPENAI_API_KEY:-}" ] \
        && [ -z "${PI_PROVIDER_API_KEY:-}" ]; then
        print_info "pi 用の API key が見つからないため、pi テストをスキップします。"
        return 0
    fi

    prompt="Use the web-search skill to search the web for '${TEST_QUERY}' and return only the title of the first result."

    response=$(pi --mode json --no-session --skill "${SKILLS_DIR}/web-search" "${prompt}" 2>&1 || true)

    # web-search skill を読み込み、Brave Search API を実際に呼び出したか確認
    read_skill=$(printf '%s' "${response}" | grep -F '"name":"read"' | grep -F 'web-search/SKILL.md' || true)
    brave_call=$(printf '%s' "${response}" | grep -F 'api.search.brave.com' || true)

    if [ -n "${read_skill}" ] && [ -n "${brave_call}" ]; then
        print_ok "pi の非対話的テストが成功しました（web-search skill を読み込み、Brave Search API を呼び出しました）。"
        return 0
    fi

    if printf '%s' "${response}" | grep -F '"code":"RATE_LIMITED"' >/dev/null 2>&1; then
        print_info "pi テストはレート制限のためスキップされました。"
        return 0
    fi

    print_error "pi の非対話的テストが失敗しました。"
    printf '%s\n' "${response}" | tail -n 20 >&2
    return 1
}

# ====== 引数の解析 ======
TEST_ONLY=0
SKIP_BX=0
SKIP_PI=0

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -k|--api-key)
            if [ "${#}" -lt 2 ]; then
                print_error "引数値の不足: ${1}"
                print_usage
                exit 1
            fi
            BRAVE_API_KEY="${2}"
            shift 2
            ;;
        -t|--test-only)
            TEST_ONLY=1
            shift
            ;;
        --skip-bx)
            SKIP_BX=1
            shift
            ;;
        --skip-pi)
            SKIP_PI=1
            shift
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

# ====== メイン処理 ======



ensure_api_key

if [ "${TEST_ONLY}" -eq 0 ]; then
    install_brave_skills

    if [ "${SKIP_BX}" -eq 0 ]; then
        install_bx
        configure_bx
    fi
else
    print_info "テストのみ実行します。"
fi

# 動作確認
test_api_with_curl
test_bx_web

if [ "${SKIP_PI}" -eq 0 ]; then
    test_pi_with_skill
fi

print_info "すべてのテストが完了しました。"

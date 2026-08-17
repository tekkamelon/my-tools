#!/bin/sh
set -eu

# デフォルトIFSの設定
IFS=$(printf '\n\t')

# ====== デフォルト値の宣言 ======
input_dir="."
output_dir="./flac"
compression_level="5"
recursive="0"
cover_image=""
auto_metadata="0"
global_metadata=""
error_count="0"
newline='
'

# ====== 関数の宣言 ======
usage() {
    cat <<EOF
Usage: $(basename "$0") [options] [WAV_FILE...]

WAV ファイルを FLAC に変換します。
ファイルを指定しない場合、入力ディレクトリ内の *.wav を処理します。

Options:
  -i DIR        入力ディレクトリ（デフォルト: .）
  -o DIR        出力ディレクトリ（デフォルト: ./flac）
  -l LEVEL      FLAC 圧縮レベル 0-12（デフォルト: 5）
  -r            入力ディレクトリを再帰的に検索
  -c IMAGE      カバー画像を埋め込む
  -M KEY=VALUE  全ファイルに共通のメタデータ（繰り返し指定可能）
  -a            ファイル名からトラック番号・タイトルを自動設定
                （例: 01_song_title.wav → track=1, title=song title）
  -h            このヘルプを表示

メタデータ:
  -M オプションで指定した値は全ファイルに適用されます。
  さらに各 WAV と同じディレクトリに "WAVファイル名.meta" がある場合、
  そちらもメタデータとして適用されます（後勝ち）。
  ファイル形式は KEY=VALUE のテキスト（UTF-8、# でコメント）です。

Examples:
  $(basename "$0") -a -M ARTIST=藍月なくる -M ALBUM=ふたりっきりの放課後ボイス
  $(basename "$0") -i ./wav -o ./flac -c cover.jpg -M GENRE=J-Pop
EOF
}

die() {
    printf '%s\n' "$*" >&2
    exit 1
}

# ====== 依存コマンドの確認 ======
command -v ffmpeg >/dev/null 2>&1 || die "ffmpeg がインストールされていません"

# ====== 引数の解析 ======
while [ "$#" -gt 0 ]; do
    case "$1" in
        -i)
            if [ "$#" -lt 2 ]; then
                die "-i にはディレクトリが必要です"
            fi
            input_dir="${2}"
            shift 2
            ;;
        -o)
            if [ "$#" -lt 2 ]; then
                die "-o にはディレクトリが必要です"
            fi
            output_dir="${2}"
            shift 2
            ;;
        -l)
            if [ "$#" -lt 2 ]; then
                die "-l には圧縮レベルが必要です"
            fi
            compression_level="${2}"
            shift 2
            ;;
        -r)
            recursive="1"
            shift
            ;;
        -c)
            if [ "$#" -lt 2 ]; then
                die "-c には画像ファイルが必要です"
            fi
            cover_image="${2}"
            shift 2
            ;;
        -M)
            if [ "$#" -lt 2 ]; then
                die "-M には KEY=VALUE が必要です"
            fi
            keyvalue="${2}"
            case "${keyvalue}" in
                *=*) ;;
                *) die "-M の形式が不正です: ${keyvalue}" ;;
            esac
            global_metadata="${global_metadata}${keyvalue}${newline}"
            shift 2
            ;;
        -a)
            auto_metadata="1"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            die "未知のオプション: $1"
            ;;
        *)
            break
            ;;
    esac
done

# ====== オプション値の検証 ======
if [ ! -d "${input_dir}" ]; then
    die "入力ディレクトリが存在しません: ${input_dir}"
fi

case "${compression_level}" in
    [0-9]|1[0-2]) ;;
    *) die "圧縮レベルは 0-12 の範囲で指定してください: ${compression_level}" ;;
esac

if [ -n "${cover_image}" ] && [ ! -f "${cover_image}" ]; then
    die "カバー画像が見つかりません: ${cover_image}"
fi

# ====== 処理対象ファイルの収集 ======
file_list=""
if [ "$#" -gt 0 ]; then
    # 引数でファイルが指定された場合はそれを使用
    for f in "$@"; do
        if [ -f "${f}" ]; then
            file_list="${file_list}${f}${newline}"
        else
            die "ファイルが存在しません: ${f}"
        fi
    done
elif [ "${recursive}" -eq 1 ]; then
    file_list=$(find "${input_dir}" -type f -name '*.wav')
else
    for f in "${input_dir}"/*.wav; do
        if [ -f "${f}" ]; then
            file_list="${file_list}${f}${newline}"
        fi
    done
fi

if [ -z "${file_list}" ]; then
    die "処理対象の WAV ファイルが見つかりません"
fi

# ====== 出力ディレクトリの作成 ======
mkdir -p "${output_dir}"

# ====== ファイル変換の実行 ======
IFS="${newline}"
for input_file in ${file_list}; do
    [ -n "${input_file}" ] || continue

    # 出力パスの計算（入力ディレクトリからの相対構造を維持）
    rel_path="${input_file#"${input_dir}/"}"
    out_subdir="${output_dir}/$(dirname "${rel_path}")"
    case "${out_subdir}" in
        */.) out_subdir="${out_subdir%/.}" ;;
    esac
    base_name=$(basename "${rel_path}" .wav)
    output_file="${out_subdir}/${base_name}.flac"

    mkdir -p "${out_subdir}"

    # ffmpeg 引数の組み立て
    set -- -hide_banner -loglevel error -stats -y
    set -- "$@" -i "${input_file}"

    has_cover="0"
    if [ -n "${cover_image}" ]; then
        set -- "$@" -i "${cover_image}"
        has_cover="1"
    fi

    set -- "$@" -map 0:a -c:a flac -compression_level "${compression_level}"

    if [ "${has_cover}" -eq 1 ]; then
        set -- "$@" -map 1 -c:v copy -disposition:v attached_pic -metadata:s:v comment="Cover (front)"
    fi

    # グローバルメタデータの適用
    if [ -n "${global_metadata}" ]; then
        IFS="${newline}"
        for meta_line in ${global_metadata}; do
            [ -n "${meta_line}" ] || continue
            set -- "$@" -metadata "${meta_line}"
        done
        IFS=$(printf '\n\t')
    fi

    # サイドカーメタデータファイルの適用
    sidecar_file="${input_file}.meta"
    if [ -f "${sidecar_file}" ]; then
        while IFS= read -r meta_line || [ -n "${meta_line}" ]; do
            case "${meta_line}" in
                ''|\#*) continue ;;
            esac
            case "${meta_line}" in
                *=*) ;;
                *) continue ;;
            esac
            set -- "$@" -metadata "${meta_line}"
        done < "${sidecar_file}"
    fi

    # ファイル名からの自動メタデータ
    if [ "${auto_metadata}" -eq 1 ]; then
        auto_track=$(printf '%s' "${base_name}" | sed -n 's/^\([0-9][0-9]*\)_.*$/\1/p')
        auto_title=$(printf '%s' "${base_name}" | sed -n 's/^[0-9][0-9]*_\(.*\)$/\1/p' | tr '_' ' ')
        if [ -n "${auto_track}" ]; then
            set -- "$@" -metadata "track=${auto_track}"
        fi
        if [ -n "${auto_title}" ]; then
            set -- "$@" -metadata "title=${auto_title}"
        fi
    fi

    set -- "$@" "${output_file}"

    printf 'Converting: %s -> %s\n' "${input_file}" "${output_file}"
    if ffmpeg "$@"; then
        printf 'OK: %s\n' "${output_file}"
    else
        printf 'ERROR: %s の変換に失敗しました\n' "${input_file}" >&2
        error_count=$((error_count + 1))
    fi
done
IFS=$(printf '\n\t')

if [ "${error_count}" -gt 0 ]; then
    die "${error_count} 件の変換でエラーが発生しました"
fi

printf '変換が完了しました。出力先: %s\n' "${output_dir}"

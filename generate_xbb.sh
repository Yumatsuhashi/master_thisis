#!/bin/bash
# ============================================================================
# generate_xbb.sh
# ============================================================================
# プロジェクト内の全 PNG/JPG/JPEG/GIF 画像に対して .xbb を生成するスクリプト
# dvipdfmx 環境で BoundingBox エラーを防ぐため、ビルド前に実行する
#
# 使い方:
#   ./generate_xbb.sh          # プロジェクトルートで実行
#   latexmk -pdfdvi thesis.tex # その後ビルド
# ============================================================================

set -e

# スクリプトのあるディレクトリを基準にする
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Generating .xbb files for bitmap images ==="

# 対象の拡張子（GIFはextractbbで処理できない場合があるため除外）
EXTENSIONS="png jpg jpeg"

# 生成数カウンター
count=0
errors=0

for ext in $EXTENSIONS; do
    # 大文字小文字両方を検索
    for img in $(find "$SCRIPT_DIR" -type f \( -iname "*.$ext" \) 2>/dev/null); do
        # .xbb ファイルのパス
        xbb="${img%.*}.xbb"
        
        # .xbb が存在しない、または画像より古い場合は生成
        if [ ! -f "$xbb" ] || [ "$img" -nt "$xbb" ]; then
            echo "  extractbb: $(basename "$img")"
            # extractbb はファイルと同じディレクトリで実行する必要がある
            if (cd "$(dirname "$img")" && extractbb -x "$(basename "$img")" 2>/dev/null); then
                count=$((count + 1))
            else
                echo "    -> skipped (extractbb failed)"
                errors=$((errors + 1))
            fi
        fi
    done
done

if [ $count -eq 0 ]; then
    echo "  All .xbb files are up-to-date."
else
    echo "  Generated $count .xbb file(s)."
fi

echo "=== Done ==="

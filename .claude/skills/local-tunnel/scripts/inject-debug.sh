#!/usr/bin/env bash
set -euo pipefail

# HTMLファイルにerudaデバッグツールを注入
# Usage: inject-debug.sh <html-file>

if [ $# -lt 1 ]; then
    echo "Error: HTMLファイルのパスが必要です"
    echo "Usage: $0 <html-file>"
    exit 1
fi

HTML_FILE="$1"

if [ ! -f "$HTML_FILE" ]; then
    echo "Error: ファイルが見つかりません: $HTML_FILE"
    exit 1
fi

# erudaスクリプトタグ
ERUDA_SCRIPT='<script src="https://cdn.jsdelivr.net/npm/eruda"></script><script>eruda.init();</script>'

# 既に注入済みかチェック
if grep -q "eruda" "$HTML_FILE"; then
    echo "✓ eruda is already injected in $HTML_FILE"
    exit 0
fi

# </head> の前に注入
if grep -q "</head>" "$HTML_FILE"; then
    # macOS用のsed（-i ''が必要）
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|</head>|  $ERUDA_SCRIPT\n</head>|" "$HTML_FILE"
    else
        sed -i "s|</head>|  $ERUDA_SCRIPT\n</head>|" "$HTML_FILE"
    fi
    echo "✓ eruda injected into $HTML_FILE"
elif grep -q "</body>" "$HTML_FILE"; then
    # </head>がない場合は</body>の前に注入
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|</body>|  $ERUDA_SCRIPT\n</body>|" "$HTML_FILE"
    else
        sed -i "s|</body>|  $ERUDA_SCRIPT\n</body>|" "$HTML_FILE"
    fi
    echo "✓ eruda injected into $HTML_FILE (before </body>)"
else
    echo "Warning: No </head> or </body> tag found in $HTML_FILE"
    echo "Please manually add eruda:"
    echo "$ERUDA_SCRIPT"
    exit 1
fi

#!/usr/bin/env bash
set -euo pipefail

# Wrangler dev を認証付きで起動
# Usage: start-wrangler.sh <project-dir>

if [ $# -lt 1 ]; then
    echo "Error: プロジェクトディレクトリが必要です"
    echo "Usage: $0 <project-dir>"
    exit 1
fi

PROJECT_DIR="$1"
ENTRY_FILE="_dev-entry.ts"
PID_FILE="/tmp/wrangler-tunnel.pid"

# wrangler の存在確認
if ! command -v wrangler &> /dev/null; then
    echo "Error: wrangler がインストールされていません"
    echo "インストール方法: npm install -g wrangler"
    exit 1
fi

# 既存のプロセスをクリーンアップ
if [ -f "$PID_FILE" ]; then
    OLD_PID=$(cat "$PID_FILE")
    if kill -0 "$OLD_PID" 2>/dev/null; then
        echo "Stopping existing wrangler process (PID: $OLD_PID)..."
        kill "$OLD_PID" 2>/dev/null || true
        sleep 2
    fi
    rm -f "$PID_FILE"
fi

# プロジェクトディレクトリに移動
cd "$PROJECT_DIR"

# エントリーファイルの存在確認
if [ ! -f "$ENTRY_FILE" ]; then
    echo "Error: $ENTRY_FILE が見つかりません"
    echo "create-dev-auth.sh を先に実行してください"
    exit 1
fi

echo "=== Starting Wrangler Dev ==="
echo "Entry: $ENTRY_FILE"
echo "Auth: hinata:****"
echo ""

# wrangler dev をバックグラウンドで起動
wrangler dev "$ENTRY_FILE" --remote > /tmp/wrangler.log 2>&1 &
WRANGLER_PID=$!
echo "$WRANGLER_PID" > "$PID_FILE"

echo "Wrangler started (PID: $WRANGLER_PID)"
echo "Waiting for deployment..."
sleep 5

# ログからURLを抽出
URL=""
for i in {1..20}; do
    if [ -f /tmp/wrangler.log ]; then
        # wrangler dev --remote のURL形式を抽出
        URL=$(grep -o 'https://[^[:space:]]*\.workers\.dev' /tmp/wrangler.log | head -1 || echo "")
        if [ -n "$URL" ]; then
            break
        fi
    fi
    sleep 1
done

if [ -z "$URL" ]; then
    echo "Warning: URLを自動取得できませんでした"
    echo "ログを確認してください: /tmp/wrangler.log"
    echo ""
    echo "=== Wrangler Log ==="
    cat /tmp/wrangler.log
    echo ""
    URL="(ログから確認してください)"
fi

echo ""
echo "=========================================="
echo "✓ Wrangler Dev is running!"
echo "=========================================="
echo ""
echo "URL: $URL"
echo "Basic Auth: hinata:0014"
echo ""
echo "=========================================="
echo ""
echo "Process ID: $WRANGLER_PID"
echo "Log file: /tmp/wrangler.log"
echo ""
echo "To stop:"
echo "  /wrangler-tunnel stop"
echo ""
echo "Press Ctrl+C in the original terminal to view logs"

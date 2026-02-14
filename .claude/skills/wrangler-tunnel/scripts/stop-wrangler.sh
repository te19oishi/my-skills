#!/usr/bin/env bash
set -euo pipefail

# Wrangler dev プロセスを停止
# Usage: stop-wrangler.sh

PID_FILE="/tmp/wrangler-tunnel.pid"

echo "=== Stopping Wrangler Dev ==="

if [ ! -f "$PID_FILE" ]; then
    echo "No running wrangler process found"
    exit 0
fi

WRANGLER_PID=$(cat "$PID_FILE")

if kill -0 "$WRANGLER_PID" 2>/dev/null; then
    echo "Stopping wrangler (PID: $WRANGLER_PID)..."
    kill "$WRANGLER_PID" 2>/dev/null || true
    sleep 1

    # 強制終了が必要な場合
    if kill -0 "$WRANGLER_PID" 2>/dev/null; then
        echo "Force killing..."
        kill -9 "$WRANGLER_PID" 2>/dev/null || true
    fi

    echo "✓ Wrangler stopped"
else
    echo "Process not running (PID: $WRANGLER_PID)"
fi

rm -f "$PID_FILE"

echo ""
echo "開発用ファイル (_dev-*.ts) は残っています"
echo "これらはデプロイ時に自動的に除外されます"

#!/usr/bin/env bash
set -euo pipefail

# ngrokトンネルとアプリケーションを停止
# Usage: stop-tunnel.sh

PID_DIR="/tmp/local-tunnel"
NGROK_PID_FILE="$PID_DIR/ngrok.pid"
APP_PID_FILE="$PID_DIR/app.pid"
URL_FILE="$PID_DIR/tunnel_url.txt"

echo "=== Stopping Local Tunnel ==="

STOPPED=0

# ngrokプロセスを停止
if [ -f "$NGROK_PID_FILE" ]; then
    NGROK_PID=$(cat "$NGROK_PID_FILE")
    if kill -0 "$NGROK_PID" 2>/dev/null; then
        echo "Stopping ngrok (PID: $NGROK_PID)..."
        kill "$NGROK_PID" 2>/dev/null || true
        STOPPED=1
    fi
    rm -f "$NGROK_PID_FILE"
fi

# アプリプロセスを停止
if [ -f "$APP_PID_FILE" ]; then
    APP_PID=$(cat "$APP_PID_FILE")
    if kill -0 "$APP_PID" 2>/dev/null; then
        echo "Stopping application (PID: $APP_PID)..."
        kill "$APP_PID" 2>/dev/null || true
        STOPPED=1
    fi
    rm -f "$APP_PID_FILE"
fi

# URLファイルを削除
rm -f "$URL_FILE"

if [ $STOPPED -eq 1 ]; then
    echo "✓ Tunnel stopped successfully"
else
    echo "No running tunnel found"
fi

#!/usr/bin/env bash
set -euo pipefail

# ngrokトンネルを起動してローカルアプリを外部公開
# Usage: start-tunnel.sh <port> [command] [--debug]
#   port: 公開するポート番号
#   command: (オプション) アプリケーション起動コマンド
#   --debug: デバッグモード（eruda統合）

if [ $# -lt 1 ]; then
    echo "Error: ポート番号が必要です"
    echo "Usage: $0 <port> [command] [--debug]"
    echo "Examples:"
    echo "  $0 3000                    # 既に起動中のポート3000を公開"
    echo "  $0 3000 'npm run dev'      # npm run dev を起動してポート3000を公開"
    echo "  $0 3000 --debug            # デバッグモードで公開"
    echo "  $0 3000 'npm run dev' --debug  # デバッグモード付きで起動"
    exit 1
fi

PORT="$1"
COMMAND=""
DEBUG_MODE=0

# 引数を解析
shift
while [ $# -gt 0 ]; do
    case "$1" in
        --debug)
            DEBUG_MODE=1
            shift
            ;;
        *)
            COMMAND="$1"
            shift
            ;;
    esac
done

# ngrokの存在確認
if ! command -v ngrok &> /dev/null; then
    echo "Error: ngrok がインストールされていません"
    echo "インストール方法: brew install ngrok"
    exit 1
fi

# Basic認証の設定
AUTH_USER="hinata"
AUTH_PASS="0014"

# プロセスIDファイル
PID_DIR="/tmp/local-tunnel"
mkdir -p "$PID_DIR"
NGROK_PID_FILE="$PID_DIR/ngrok.pid"
APP_PID_FILE="$PID_DIR/app.pid"
PROXY_PID_FILE="$PID_DIR/proxy.pid"
URL_FILE="$PID_DIR/tunnel_url.txt"

# デバッグモード用の設定
if [ $DEBUG_MODE -eq 1 ]; then
    PROXY_DIR="$PID_DIR/proxy"
    PROXY_HTML="$PROXY_DIR/index.html"
    PROXY_PORT=9999
fi

# クリーンアップ関数
cleanup() {
    echo ""
    echo "Cleaning up..."

    # ngrokプロセスを停止
    if [ -f "$NGROK_PID_FILE" ]; then
        NGROK_PID=$(cat "$NGROK_PID_FILE")
        if kill -0 "$NGROK_PID" 2>/dev/null; then
            kill "$NGROK_PID" 2>/dev/null || true
        fi
        rm -f "$NGROK_PID_FILE"
    fi

    # アプリプロセスを停止（コマンド指定時のみ）
    if [ -n "$COMMAND" ] && [ -f "$APP_PID_FILE" ]; then
        APP_PID=$(cat "$APP_PID_FILE")
        if kill -0 "$APP_PID" 2>/dev/null; then
            echo "Stopping application (PID: $APP_PID)..."
            kill "$APP_PID" 2>/dev/null || true
        fi
        rm -f "$APP_PID_FILE"
    fi

    # プロキシサーバーを停止（デバッグモード時のみ）
    if [ -f "$PROXY_PID_FILE" ]; then
        PROXY_PID=$(cat "$PROXY_PID_FILE")
        if kill -0 "$PROXY_PID" 2>/dev/null; then
            echo "Stopping proxy server (PID: $PROXY_PID)..."
            kill "$PROXY_PID" 2>/dev/null || true
        fi
        rm -f "$PROXY_PID_FILE"
    fi

    rm -f "$URL_FILE"
    echo "Cleanup complete"
}

# 既存のトンネルをクリーンアップ
cleanup

echo "=== Local Tunnel Setup ==="
echo "Port: $PORT"
echo "Basic Auth: ${AUTH_USER}:****"
if [ $DEBUG_MODE -eq 1 ]; then
    echo "Debug Mode: ENABLED (eruda)"
fi

# コマンド指定時: アプリケーションを起動
if [ -n "$COMMAND" ]; then
    echo "Starting application: $COMMAND"
    eval "$COMMAND" &
    APP_PID=$!
    echo "$APP_PID" > "$APP_PID_FILE"
    echo "Application started (PID: $APP_PID)"

    # アプリケーションの起動を少し待つ
    echo "Waiting for application to start..."
    sleep 3
fi

# デバッグモード: プロキシHTMLを作成してプロキシサーバーを起動
if [ $DEBUG_MODE -eq 1 ]; then
    echo ""
    echo "Setting up debug proxy..."
    mkdir -p "$PROXY_DIR"

    # プロキシHTMLを生成
    cat > "$PROXY_HTML" << 'EOFHTML'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Debug Proxy</title>
    <style>
        body { margin: 0; padding: 0; overflow: hidden; }
        iframe { position: fixed; top: 0; left: 0; width: 100%; height: 100%; border: none; }
    </style>
    <script src="https://cdn.jsdelivr.net/npm/eruda"></script>
    <script>eruda.init();</script>
</head>
<body>
    <iframe src="http://localhost:TARGET_PORT" allow="*"></iframe>
</body>
</html>
EOFHTML

    # ポート番号を置換
    sed -i.bak "s/TARGET_PORT/$PORT/g" "$PROXY_HTML"
    rm -f "$PROXY_HTML.bak"

    # プロキシサーバーを起動（Python簡易サーバー）
    echo "Starting proxy server on port $PROXY_PORT..."
    cd "$PROXY_DIR"
    python3 -m http.server "$PROXY_PORT" > /tmp/proxy.log 2>&1 &
    PROXY_PID=$!
    echo "$PROXY_PID" > "$PROXY_PID_FILE"
    echo "Proxy server started (PID: $PROXY_PID)"
    cd - > /dev/null

    # プロキシの起動を待つ
    sleep 2

    # ngrokはプロキシポートを公開
    TUNNEL_PORT=$PROXY_PORT
else
    TUNNEL_PORT=$PORT
fi

# ngrokトンネルをバックグラウンドで起動
echo ""
echo "Starting ngrok tunnel..."
ngrok http "$TUNNEL_PORT" --basic-auth="${AUTH_USER}:${AUTH_PASS}" --log=stdout > /tmp/ngrok.log 2>&1 &
NGROK_PID=$!
echo "$NGROK_PID" > "$NGROK_PID_FILE"

# ngrokの起動を待つ
echo "Waiting for ngrok to start..."
sleep 3

# ngrok APIからURLを取得
TUNNEL_URL=""
for i in {1..10}; do
    if TUNNEL_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o 'https://[^"]*\.ngrok-free\.app' | head -1); then
        if [ -n "$TUNNEL_URL" ]; then
            break
        fi
    fi
    sleep 1
done

if [ -z "$TUNNEL_URL" ]; then
    echo "Error: Failed to get tunnel URL"
    cleanup
    exit 1
fi

# URLをファイルに保存
echo "$TUNNEL_URL" > "$URL_FILE"

echo ""
echo "=========================================="
echo "✓ Tunnel is ready!"
echo "=========================================="
echo ""
echo "URL: $TUNNEL_URL"
echo "Basic Auth: ${AUTH_USER}:${AUTH_PASS}"
if [ $DEBUG_MODE -eq 1 ]; then
    echo ""
    echo "🐛 DEBUG MODE ENABLED"
    echo "- Tap the eruda button (bottom-right) to open console"
    echo "- View console.log, errors, network, and more"
    echo "- Original app on localhost:$PORT"
fi
echo ""
echo "=========================================="
echo ""
echo "Process IDs saved to:"
echo "  ngrok PID: $NGROK_PID_FILE"
if [ -n "$COMMAND" ]; then
    echo "  app PID: $APP_PID_FILE"
fi
echo ""
echo "To stop the tunnel, run:"
echo "  $0 stop"
echo ""
echo "Press Ctrl+C to stop (will clean up automatically)"
echo ""

# シグナルハンドリング
trap cleanup EXIT INT TERM

# バックグラウンドで実行し続ける
if [ -n "$COMMAND" ]; then
    # アプリプロセスが終了するまで待つ
    wait "$APP_PID" 2>/dev/null || true
else
    # ngrokプロセスが終了するまで待つ
    wait "$NGROK_PID" 2>/dev/null || true
fi

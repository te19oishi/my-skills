#!/usr/bin/env bash
set -euo pipefail

# デバッグ用プロキシHTMLを生成してngrokで公開
# Usage: create-debug-proxy.sh <target-port>

if [ $# -lt 1 ]; then
    echo "Error: ターゲットポート番号が必要です"
    echo "Usage: $0 <target-port>"
    exit 1
fi

TARGET_PORT="$1"
PROXY_PORT=9999
PROXY_DIR="/tmp/local-tunnel-proxy"
PROXY_HTML="$PROXY_DIR/index.html"

# プロキシディレクトリを作成
mkdir -p "$PROXY_DIR"

# プロキシHTMLを生成
cat > "$PROXY_HTML" << 'EOF'
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Debug Proxy</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            overflow: hidden;
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        #iframe-container {
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
        #debug-info {
            position: fixed;
            top: 10px;
            right: 10px;
            background: rgba(0, 0, 0, 0.8);
            color: white;
            padding: 10px;
            border-radius: 5px;
            font-size: 12px;
            z-index: 10000;
            max-width: 300px;
            max-height: 200px;
            overflow-y: auto;
        }
        .log-entry {
            margin: 5px 0;
            padding: 3px;
            border-left: 3px solid #4CAF50;
            padding-left: 8px;
        }
        .log-error {
            border-left-color: #f44336;
        }
        .log-warn {
            border-left-color: #ff9800;
        }
    </style>
    <!-- eruda: モバイルデバッグツール -->
    <script src="https://cdn.jsdelivr.net/npm/eruda"></script>
    <script>
        eruda.init();

        // コンソールログをキャプチャ
        const originalLog = console.log;
        const originalError = console.error;
        const originalWarn = console.warn;

        window.addEventListener('load', function() {
            const debugInfo = document.getElementById('debug-info');

            function addLog(message, type = 'log') {
                const entry = document.createElement('div');
                entry.className = 'log-entry log-' + type;
                entry.textContent = new Date().toLocaleTimeString() + ': ' + message;
                debugInfo.appendChild(entry);
                debugInfo.scrollTop = debugInfo.scrollHeight;
            }

            console.log = function(...args) {
                originalLog.apply(console, args);
                addLog(args.join(' '), 'log');
            };

            console.error = function(...args) {
                originalError.apply(console, args);
                addLog('ERROR: ' + args.join(' '), 'error');
            };

            console.warn = function(...args) {
                originalWarn.apply(console, args);
                addLog('WARN: ' + args.join(' '), 'warn');
            };

            // グローバルエラーをキャプチャ
            window.addEventListener('error', function(e) {
                addLog('ERROR: ' + e.message + ' at ' + e.filename + ':' + e.lineno, 'error');
            });

            // Promise rejection をキャプチャ
            window.addEventListener('unhandledrejection', function(e) {
                addLog('Promise Rejection: ' + e.reason, 'error');
            });

            addLog('Debug mode activated', 'log');
        });
    </script>
</head>
<body>
    <div id="debug-info">
        <strong>Debug Console</strong>
        <div style="font-size: 10px; opacity: 0.7;">Tap eruda button (bottom-right) for full console</div>
    </div>
    <div id="iframe-container">
        <iframe src="http://localhost:TARGET_PORT" allow="*"></iframe>
    </div>
</body>
</html>
EOF

# ポート番号を置換
sed -i.bak "s/TARGET_PORT/$TARGET_PORT/g" "$PROXY_HTML"
rm -f "$PROXY_HTML.bak"

echo "PROXY_PORT=$PROXY_PORT"
echo "PROXY_HTML=$PROXY_HTML"

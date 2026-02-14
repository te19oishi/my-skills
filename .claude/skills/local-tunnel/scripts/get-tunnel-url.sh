#!/usr/bin/env bash
set -euo pipefail

# 現在のトンネルURLを取得
# Usage: get-tunnel-url.sh

URL_FILE="/tmp/local-tunnel/tunnel_url.txt"

if [ ! -f "$URL_FILE" ]; then
    echo "No active tunnel found"
    exit 1
fi

URL=$(cat "$URL_FILE")
echo "Current tunnel URL: $URL"
echo "Basic Auth: hinata:0014"

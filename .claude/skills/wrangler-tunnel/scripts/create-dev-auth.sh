#!/usr/bin/env bash
set -euo pipefail

# 開発用の認証ミドルウェアを生成
# Usage: create-dev-auth.sh <project-dir>

if [ $# -lt 1 ]; then
    echo "Error: プロジェクトディレクトリが必要です"
    echo "Usage: $0 <project-dir>"
    exit 1
fi

PROJECT_DIR="$1"
AUTH_FILE="$PROJECT_DIR/_dev-auth.ts"
ENTRY_FILE="$PROJECT_DIR/_dev-entry.ts"

# 認証情報
AUTH_USER="hinata"
AUTH_PASS="0014"

echo "Creating development authentication middleware..."

# 認証ミドルウェアを生成
cat > "$AUTH_FILE" << 'EOF'
// 開発専用: Basic認証ミドルウェア
// このファイルは本番ビルドには含まれません

export function basicAuth(request: Request): Response | null {
  const authHeader = request.headers.get('Authorization');

  if (!authHeader || !authHeader.startsWith('Basic ')) {
    return new Response('Authentication required', {
      status: 401,
      headers: {
        'WWW-Authenticate': 'Basic realm="Development"',
      },
    });
  }

  const base64Credentials = authHeader.substring(6);
  const credentials = atob(base64Credentials);
  const [username, password] = credentials.split(':');

  const validUsername = 'AUTH_USER';
  const validPassword = 'AUTH_PASS';

  if (username !== validUsername || password !== validPassword) {
    return new Response('Invalid credentials', {
      status: 401,
      headers: {
        'WWW-Authenticate': 'Basic realm="Development"',
      },
    });
  }

  return null; // 認証成功
}
EOF

# 認証情報を置換
sed -i.bak "s/AUTH_USER/$AUTH_USER/g" "$AUTH_FILE"
sed -i.bak "s/AUTH_PASS/$AUTH_PASS/g" "$AUTH_FILE"
rm -f "$AUTH_FILE.bak"

echo "✓ Created: $AUTH_FILE"
echo "  Username: $AUTH_USER"
echo "  Password: ****"

# エントリーポイントのパスを取得
MAIN_ENTRY="src/index.ts"
if [ -f "$PROJECT_DIR/wrangler.toml" ]; then
    # wrangler.tomlからmainを取得
    MAIN_FROM_TOML=$(grep "^main" "$PROJECT_DIR/wrangler.toml" | sed 's/main *= *"\(.*\)"/\1/' || echo "")
    if [ -n "$MAIN_FROM_TOML" ]; then
        MAIN_ENTRY="$MAIN_FROM_TOML"
    fi
fi

# 拡張子を除去してモジュール名を取得
MAIN_MODULE=$(echo "$MAIN_ENTRY" | sed 's/\.[^.]*$//')

# 開発用エントリーポイントを生成
cat > "$ENTRY_FILE" << EOF
// 開発専用: 認証付きエントリーポイント
// このファイルは本番ビルドには含まれません

import { basicAuth } from './_dev-auth';
import worker from './${MAIN_MODULE}';

export default {
  async fetch(request: Request, env: any, ctx: any): Promise<Response> {
    // Basic認証チェック
    const authResponse = basicAuth(request);
    if (authResponse) {
      return authResponse;
    }

    // 元のWorkerを実行
    if (typeof worker === 'function') {
      return worker(request, env, ctx);
    } else if (worker.fetch) {
      return worker.fetch(request, env, ctx);
    } else {
      return new Response('Worker not found', { status: 500 });
    }
  },
};
EOF

echo "✓ Created: $ENTRY_FILE"
echo "  Wrapping: $MAIN_ENTRY"
echo ""
echo "=== Files Created ==="
echo "$AUTH_FILE"
echo "$ENTRY_FILE"

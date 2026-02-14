---
name: wrangler-tunnel
description: Cloudflare Workers開発用。wrangler dev --remoteでBasic認証付きトンネルを起動し、スマホなど外部から確認できるようにします
disable-model-invocation: false
allowed-tools: Bash, Read
---

# Wrangler Tunnel

Cloudflare Workers プロジェクトで `wrangler dev --remote` を使用し、Basic認証付きで外部公開します。

## 使用方法

### トンネルの起動
```
/wrangler-tunnel
```

### トンネルの停止
```
/wrangler-tunnel stop
```

## 実行手順

### ケース1: stop が指定された場合

```bash
`!scripts/stop-wrangler.sh`
```

wrangler プロセスを停止して終了します。

### ケース2: トンネルの起動

#### 2-1. プロジェクトの検証

現在のディレクトリが Cloudflare Workers プロジェクトか確認：
- `wrangler.toml` の存在をチェック
- wrangler コマンドのインストール確認

存在しない場合はエラーメッセージを表示して終了。

#### 2-2. 認証ミドルウェアの生成

```bash
`!scripts/create-dev-auth.sh .`
```

このスクリプトは以下のファイルを生成します：

**_dev-auth.ts**
- Basic認証のミドルウェア
- 認証情報: `hinata:0014`
- 認証失敗時は 401 を返す

**_dev-entry.ts**
- 元の Worker をラップするエントリーポイント
- 認証チェック後に元の Worker を実行
- `wrangler.toml` の `main` フィールドから元のエントリーを検出

**重要:**
- これらのファイルは開発専用
- `.gitignore` に `_dev-*.ts` を追加することを推奨
- 本番デプロイ時には自動的に除外される（wrangler が `_dev-entry.ts` を使わないため）

#### 2-3. Wrangler Dev の起動

```bash
`!scripts/start-wrangler.sh .`
```

**スクリプトの動作:**
1. 既存の wrangler プロセスをクリーンアップ
2. `wrangler dev _dev-entry.ts --remote` を実行
3. バックグラウンドで起動
4. ログからデプロイURLを抽出
5. プロセスIDを保存（/tmp/wrangler-tunnel.pid）

**出力例:**
```
=== Starting Wrangler Dev ===
Entry: _dev-entry.ts
Auth: hinata:****

Wrangler started (PID: 12345)
Waiting for deployment...

==========================================
✓ Wrangler Dev is running!
==========================================

URL: https://your-worker.your-subdomain.workers.dev
Basic Auth: hinata:0014

==========================================

Process ID: 12345
Log file: /tmp/wrangler.log

To stop:
  /wrangler-tunnel stop
```

#### 2-4. 結果の報告

ユーザーに以下を報告：

```
✓ Wrangler Tunnel が起動しました！

【アクセスURL】
https://your-worker.your-subdomain.workers.dev

【Basic認証】
ユーザー名: hinata
パスワード: 0014

【開発用ファイル】
以下のファイルが生成されました：
- _dev-auth.ts: 認証ミドルウェア
- _dev-entry.ts: 認証付きエントリーポイント

これらは開発専用で、本番デプロイには含まれません。
.gitignore に追加することを推奨します：
  echo "_dev-*.ts" >> .gitignore

【停止方法】
/wrangler-tunnel stop

【ログ確認】
/tmp/wrangler.log を参照
```

**注意事項も伝える:**
- Cloudflare Workers の無料プランの制限
- URLはワーカー名とアカウントに基づく固定URL
- 初回アクセス時に Basic 認証プロンプトが表示される
- バックグラウンドで実行中

### ケース3: エラーハンドリング

以下のエラーをチェック：

1. **wrangler.toml が見つからない**
   - Cloudflare Workers プロジェクトではないことを伝える
   - 汎用的なトンネルが必要な場合は `local-tunnel` スキルを推奨

2. **wrangler コマンドがインストールされていない**
   - インストール方法を案内: `npm install -g wrangler`

3. **認証ファイルの生成に失敗**
   - 書き込み権限を確認
   - エラー詳細を表示

4. **wrangler dev の起動に失敗**
   - ログファイルを確認するよう案内
   - 認証エラーの可能性（`wrangler login`）

5. **URLの取得に失敗**
   - ログファイルから手動で確認する方法を案内

## コンテキスト最適化

このスキルは以下の方針でコンテキストを最適化しています：
- 認証ミドルウェア生成と wrangler 実行は `scripts/` に分離
- SKILL.md にはプロジェクト検証と結果報告のロジックのみ記述
- バックグラウンド実行とプロセスID管理はスクリプトで処理
- `` `!command` `` 構文でスクリプトを実行

## 注意事項

- Cloudflare Workers プロジェクト専用です
- wrangler CLI がインストールされている必要があります（`npm install -g wrangler`）
- Cloudflare アカウントにログインしている必要があります（`wrangler login`）
- Basic認証は固定（hinata:0014）
- 開発用ファイル（`_dev-*.ts`）は `.gitignore` に追加することを推奨
- これらのファイルは本番デプロイには含まれません
- バックグラウンドで実行されるため、停止する場合は `/wrangler-tunnel stop` を実行してください
- Cloudflare Workers の無料プランの制限に注意（1日10万リクエストなど）

## local-tunnel との使い分け

**wrangler-tunnel を使う場合:**
- Cloudflare Workers プロジェクト
- Cloudflare の環境で動作確認したい
- Workers の機能（KV、Durable Objects など）を使用

**local-tunnel を使う場合:**
- 汎用的なWebアプリケーション
- Next.js、Vite、Expressなど
- デバッグモード（eruda）が必要

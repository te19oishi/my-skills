---
name: cf-auth-test
description: Cloudflare Access Service Tokenを使用してAPIアクセスをテストし、認証情報を安全に管理するスキル
disable-model-invocation: false
allowed-tools: Bash, Read, Write
---

# Cloudflare Access Service Token テスター

Cloudflare Access Service Tokenを使用したAPI認証のテストと管理を行うスキルです。

## 使用方法

### 基本的なテスト
```
/cf-auth-test
```

### Service Tokenの設定
```
/cf-auth-test setup
```

### 特定のエンドポイントをテスト
```
/cf-auth-test test <URL>
```

## 実行手順

### ケース1: setup が指定された場合

Service Tokenの設定を行います。

#### 1-1. 環境ファイルの確認

現在のディレクトリに `.env.cf-auth` ファイルが存在するか確認：

```bash
test -f .env.cf-auth && echo "exists" || echo "not found"
```

#### 1-2. Service Token情報の収集

ユーザーに以下の情報を質問：

1. **Service Token ID**: Cloudflare ZeroTrustダッシュボードから取得
2. **Service Token Secret**: トークン作成時に表示される秘密鍵
3. **Test URL (任意)**: テストしたいAPIエンドポイントのURL

**Service Tokenの取得方法を説明：**
```
Cloudflare Zero Trust > Access > Service Auth > Create Service Token

作成後、以下の情報が表示されます：
- Client ID (Service Token ID)
- Client Secret (Service Token Secret - 一度しか表示されないので注意)
```

#### 1-3. 環境ファイルの作成

`.env.cf-auth` ファイルを作成：

```bash
cat > .env.cf-auth << 'EOF'
# Cloudflare Access Service Token
CF_SERVICE_TOKEN_ID=your-client-id-here
CF_SERVICE_TOKEN_SECRET=your-client-secret-here

# Test endpoint (optional)
CF_TEST_URL=https://your-api.example.com/endpoint
EOF
```

ユーザーが提供した情報で置き換え。

#### 1-4. .gitignoreへの追加

`.env.cf-auth` が `.gitignore` に含まれているか確認：

```bash
grep -q ".env.cf-auth" .gitignore || echo ".env.cf-auth" >> .gitignore
```

#### 1-5. 結果の報告

```
✓ Service Token設定が完了しました

【設定ファイル】
.env.cf-auth

【セキュリティ】
- .gitignore に追加済み
- このファイルは絶対にコミットしないでください

【次のステップ】
Service Tokenをテストする場合：
  /cf-auth-test test

特定のURLをテストする場合：
  /cf-auth-test test <URL>
```

### ケース2: test が指定された場合

Service Tokenを使用してAPIアクセスをテストします。

#### 2-1. 環境ファイルの読み込み

`.env.cf-auth` ファイルが存在するか確認：

```bash
if [ ! -f .env.cf-auth ]; then
  echo "Error: .env.cf-auth not found"
  echo "Run: /cf-auth-test setup"
  exit 1
fi
```

環境変数を読み込み：

```bash
source .env.cf-auth
```

#### 2-2. テストURLの決定

1. コマンドライン引数で指定された場合: その URL を使用
2. 指定がない場合: `.env.cf-auth` の `CF_TEST_URL` を使用
3. どちらもない場合: ユーザーに URL を質問

#### 2-3. 認証ヘッダーの構築

Cloudflare Access Service Tokenは以下のヘッダーで送信：

```
CF-Access-Client-Id: ${CF_SERVICE_TOKEN_ID}
CF-Access-Client-Secret: ${CF_SERVICE_TOKEN_SECRET}
```

#### 2-4. APIリクエストの実行

```bash
curl -i \
  -H "CF-Access-Client-Id: ${CF_SERVICE_TOKEN_ID}" \
  -H "CF-Access-Client-Secret: ${CF_SERVICE_TOKEN_SECRET}" \
  "${TEST_URL}"
```

#### 2-5. 結果の解析と報告

**成功の場合 (HTTP 200-299):**
```
✓ 認証成功！

【リクエスト情報】
URL: ${TEST_URL}
Service Token ID: ${CF_SERVICE_TOKEN_ID:0:12}...

【レスポンス】
Status: 200 OK
[レスポンスボディの一部を表示]
```

**認証失敗の場合 (HTTP 401/403):**
```
✗ 認証失敗

【エラー詳細】
Status: 401 Unauthorized

【考えられる原因】
1. Service Tokenが無効または期限切れ
2. このService TokenにAPIへのアクセス権限がない
3. Cloudflare Access Policyが正しく設定されていない

【確認事項】
- Cloudflare Zero Trust > Access > Service Auth でTokenが有効か確認
- Access Policy でこのService Tokenが許可されているか確認
- Token ID/Secret に誤りがないか確認
```

**その他のエラー:**
```
✗ リクエスト失敗

【エラー詳細】
[エラーメッセージ]

【考えられる原因】
- URLが正しくない
- ネットワーク接続の問題
- APIエンドポイントが存在しない
```

### ケース3: 引数なし (デフォルト動作)

#### 3-1. 設定状況の確認

`.env.cf-auth` の存在を確認：

- 存在する → テストモードへ (ケース2と同じ)
- 存在しない → セットアップガイドを表示

**セットアップガイド:**
```
Cloudflare Access Service Tokenのテストツールへようこそ！

まだService Tokenが設定されていません。

【セットアップ方法】
/cf-auth-test setup

【Service Tokenとは】
Cloudflare Accessで保護されたAPIに、アプリケーションや
サービスからアクセスするための認証情報です。

人間のユーザー向けの認証とは異なり、サービス間通信に使用されます。

【詳細情報】
https://developers.cloudflare.com/cloudflare-one/identity/service-tokens/
```

### ケース4: エラーハンドリング

以下のエラーをチェック：

1. **curl コマンドがインストールされていない**
   - インストール方法を案内

2. **.env.cf-auth の形式が不正**
   - 必要な変数が設定されているか確認
   - 再セットアップを提案

3. **URL形式が不正**
   - 正しいURL形式の例を表示
   - https:// で始まる必要があることを説明

4. **ネットワークエラー**
   - 接続状況の確認を促す
   - DNS解決の確認方法を案内

## セキュリティのベストプラクティス

### 環境ファイルの管理

1. **.env.cf-auth は必ず .gitignore に追加**
   - このスキルは自動的に追加しますが、確認してください

2. **Service Secretは絶対に共有しない**
   - ログ出力時は最初の数文字のみ表示
   - エラーメッセージにも含めない

3. **定期的なローテーション**
   - Service Tokenは定期的に再生成することを推奨
   - 不要になったTokenは速やかに削除

### Access Policyの設定

1. **最小権限の原則**
   - Service Tokenには必要最小限のアクセス権限のみ付与
   - 特定のAPIエンドポイントのみに制限

2. **監査ログの確認**
   - Cloudflare Zero Trustダッシュボードでアクセスログを定期確認
   - 不審なアクセスがないかチェック

## 高度な使用例

### 複数の環境を管理

開発・ステージング・本番で異なるService Tokenを使用する場合：

```bash
# 開発環境
/cf-auth-test test --env .env.cf-auth.dev

# 本番環境
/cf-auth-test test --env .env.cf-auth.prod
```

### CI/CD統合

GitHub Actionsなどで使用する場合：

```yaml
- name: Test Cloudflare Access
  env:
    CF_SERVICE_TOKEN_ID: ${{ secrets.CF_SERVICE_TOKEN_ID }}
    CF_SERVICE_TOKEN_SECRET: ${{ secrets.CF_SERVICE_TOKEN_SECRET }}
    CF_TEST_URL: https://api.example.com/health
  run: |
    curl -f \
      -H "CF-Access-Client-Id: ${CF_SERVICE_TOKEN_ID}" \
      -H "CF-Access-Client-Secret: ${CF_SERVICE_TOKEN_SECRET}" \
      "${CF_TEST_URL}"
```

### カスタムヘッダーの追加

認証以外のヘッダーも送信したい場合：

```bash
curl -i \
  -H "CF-Access-Client-Id: ${CF_SERVICE_TOKEN_ID}" \
  -H "CF-Access-Client-Secret: ${CF_SERVICE_TOKEN_SECRET}" \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}' \
  "${TEST_URL}"
```

## トラブルシューティング

### 401 Unauthorized

**原因:**
- Service Token ID/Secretが間違っている
- Tokenが無効化されている
- Access Policyで許可されていない

**対処法:**
1. Cloudflare Zero Trust > Access > Service Auth でTokenの状態を確認
2. `.env.cf-auth` の値を確認
3. Access Policyの設定を確認

### 403 Forbidden

**原因:**
- Access Policyで明示的に拒否されている
- IPアドレス制限に引っかかっている

**対処法:**
1. Access Policyのルールを確認
2. IPアドレス制限がある場合は、現在のIPを許可リストに追加

### DNS解決エラー

**原因:**
- URLが間違っている
- DNS設定に問題がある

**対処法:**
1. URLをブラウザで開いて確認
2. `nslookup <domain>` でDNS解決を確認

## 関連情報

- [Cloudflare Access Service Tokens](https://developers.cloudflare.com/cloudflare-one/identity/service-tokens/)
- [Access Policies](https://developers.cloudflare.com/cloudflare-one/policies/access/)
- [Zero Trust Dashboard](https://dash.teams.cloudflare.com/)

## 注意事項

- Service Token Secret は一度しか表示されないため、作成時に必ず保存してください
- 本番環境のTokenは特に慎重に管理してください
- 定期的なTokenのローテーションを推奨します
- このスキルはテスト目的です。本番環境での使用は適切なセキュリティ対策を実施してください

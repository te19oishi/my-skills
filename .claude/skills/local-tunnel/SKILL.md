---
name: local-tunnel
description: ローカルで動作するアプリケーションをngrokでトンネル公開し、スマホなど外部から確認できるようにします
disable-model-invocation: false
allowed-tools: Bash
---

# Local Tunnel

ローカルで動作しているアプリケーションを ngrok 経由で外部公開し、スマホなどからアクセスできるようにします。

## 使用方法

### パターン1: 既に起動中のアプリを公開
```
/local-tunnel <port> [--debug]
```

### パターン2: アプリを起動して公開
```
/local-tunnel <port> <command> [--debug]
```

### トンネルの停止
```
/local-tunnel stop
```

### URL確認
```
/local-tunnel url
```

## 引数

- `<port>`: 公開するポート番号（例: 3000, 8080）
- `<command>`: アプリケーション起動コマンド（例: "npm run dev", "python app.py"）
- `--debug`: デバッグモードを有効化（eruda統合でスマホからコンソール確認可能）
- `stop`: トンネルを停止
- `url`: 現在のトンネルURLを確認

### 使用例

```bash
# 基本
/local-tunnel 3000

# デバッグモード付き
/local-tunnel 3000 --debug

# アプリ起動 + デバッグ
/local-tunnel 3000 "npm run dev" --debug

# 停止
/local-tunnel stop
```

## 実行手順

### ケース1: stop が指定された場合

```bash
`!scripts/stop-tunnel.sh`
```

トンネルとアプリケーションを停止して終了します。

### ケース2: url が指定された場合

```bash
`!scripts/get-tunnel-url.sh`
```

現在のトンネルURLとBasic認証情報を表示して終了します。

### ケース3: トンネルの起動

#### 3-1. 引数の解析

`$ARGUMENTS` から以下を判断：
- ポート番号を抽出（必須）
- 起動コマンドがあるかチェック（オプション）
- `--debug` フラグがあるかチェック（オプション）

**例:**
- `/local-tunnel 3000` → port=3000, command=なし, debug=なし
- `/local-tunnel 3000 --debug` → port=3000, command=なし, debug=あり
- `/local-tunnel 3000 "npm run dev"` → port=3000, command="npm run dev", debug=なし
- `/local-tunnel 3000 "npm run dev" --debug` → port=3000, command="npm run dev", debug=あり

#### 3-2. トンネルの起動

スクリプトでトンネルを起動します：

```bash
# 基本
`!scripts/start-tunnel.sh <port>`

# コマンド指定
`!scripts/start-tunnel.sh <port> "<command>"`

# デバッグモード
`!scripts/start-tunnel.sh <port> --debug`

# 全部入り
`!scripts/start-tunnel.sh <port> "<command>" --debug`
```

**スクリプトの動作:**
1. 既存のトンネルがあればクリーンアップ
2. コマンドが指定されていればアプリケーションをバックグラウンドで起動
3. **デバッグモード時**: eruda統合のプロキシHTMLを生成してプロキシサーバーを起動（ポート9999）
4. ngrok をバックグラウンドで起動（Basic認証: hinata:0014）
   - 通常モード: 元のポートを公開
   - デバッグモード: プロキシポート（9999）を公開
5. トンネルURLを取得して表示
6. プロセスIDをファイルに保存
7. バックグラウンドで実行し続ける

**デバッグモードの仕組み:**
- プロキシHTMLが eruda（モバイルデバッグツール）を読み込み
- プロキシ内の iframe で元のアプリを表示
- eruda がコンソール、ネットワーク、要素などを画面上に表示
- スマホで画面右下のボタンをタップしてデバッグパネルを開く

#### 3-3. 結果の報告

スクリプトの出力から以下の情報を抽出してユーザーに報告：

```
✓ トンネルが起動しました！

【アクセスURL】
https://xxxx-xx-xx-xxx-xxx.ngrok-free.app

【Basic認証】
ユーザー名: hinata
パスワード: 0014

【ポート】
localhost:3000

【起動コマンド】
npm run dev (指定された場合のみ)

【デバッグモード】
有効 (--debug指定時のみ表示)
🐛 画面右下のerudaボタンをタップしてデバッグパネルを開けます
- Console: console.log, errors, warnings
- Network: API リクエスト/レスポンス
- Elements: DOM 構造の確認
- Resources: localStorage, cookies など

【停止方法】
/local-tunnel stop
```

**重要な注意事項も伝える:**
- トンネルはバックグラウンドで実行中です
- 初回アクセス時に ngrok の警告ページが表示される場合があります（"Visit Site" をクリック）
- Basic認証のプロンプトが表示されたら、上記の認証情報を入力してください
- セッションは8時間まで有効です（無料プラン）
- URLは毎回ランダムに生成されます
- **デバッグモード時**: スマホでコンソールエラーやログを確認できます

### ケース4: エラーハンドリング

以下のエラーをチェック：
- ポート番号が指定されていない
- ngrok がインストールされていない
- アプリケーション起動に失敗
- トンネルURLの取得に失敗

エラー時は適切なメッセージを表示して終了します。

## デバッグモードについて

### eruda とは？

eruda は軽量なモバイルデバッグツールです。デスクトップブラウザの開発者ツールのような機能をスマホで利用できます。

### 機能

- **Console**: `console.log()`, `console.error()` などの出力を確認
- **Network**: HTTP リクエスト/レスポンスを監視
- **Elements**: DOM 構造とスタイルを確認
- **Resources**: localStorage, sessionStorage, cookies を確認
- **Sources**: ソースコードの確認
- **Info**: デバイス情報やブラウザ情報

### 使い方

1. `--debug` フラグ付きでトンネルを起動
2. スマホでURLにアクセス
3. 画面右下に表示される緑色のボタンをタップ
4. デバッグパネルが開きます

### 仕組み

デバッグモード時、スクリプトは以下を自動で行います：
1. プロキシHTML（eruda統合）を生成
2. プロキシサーバー（ポート9999）を起動
3. プロキシ内の iframe で元のアプリ（指定ポート）を表示
4. ngrok はプロキシポートを公開

これにより、アプリのコードを変更せずにデバッグ機能を追加できます。

## コンテキスト最適化

このスキルは以下の方針でコンテキストを最適化しています：
- ngrok コマンドの実行とプロセス管理は `scripts/` に分離
- デバッグ用プロキシの生成もスクリプトで処理
- SKILL.md には引数解析と結果報告のロジックのみ記述
- バックグラウンド実行とプロセスID管理はスクリプトで処理
- `` `!command` `` 構文でスクリプトを実行

## 注意事項

- ngrok がインストールされている必要があります（`brew install ngrok`）
- ngrok の authtoken が設定されている必要があります
- デバッグモード時は Python 3 が必要です（プロキシサーバー用）
- Basic認証は固定（hinata:0014）
- 無料プランでは同時に1つのトンネルのみ
- セッションは最大8時間
- トンネルURLは毎回ランダムに変わります
- バックグラウンドで実行されるため、停止する場合は `/local-tunnel stop` を実行してください
- アプリケーション起動コマンドを指定した場合、停止時にアプリも自動的に終了します
- デバッグモード時は iframe 内でアプリが動作するため、一部の機能（ポップアップなど）に制限がある場合があります

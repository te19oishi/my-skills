---
name: find-skills
description: Helps users discover and install agent skills when they ask questions like "how do I do X", "find a skill for X", "is there a skill that can...", or express interest in extending capabilities. This skill should be used when the user is looking for functionality that might exist as an installable skill.
disable-model-invocation: false
allowed-tools: Bash, Read, Glob
context: fork
---

# Find Skills

ユーザーのニーズに合ったスキルを my-skills カタログから検索し、プロジェクトにインストールします。
インストール完了後、このスキル自体は自動的に削除されます。

## 使用方法

```
/find-skills [query]
```

- `query`: (オプション) 探しているスキルのキーワード（例: "commit", "lint", "tunnel"）

## 実行手順

### 1. プラグインディレクトリの特定

このスキルがインストールされた元のプラグインディレクトリを特定します。

通常、プラグインは以下のいずれかに配置されています：
- `~/.claude/plugins/my-skills/`
- プロジェクトローカルのpluginディレクトリ

環境変数や設定から特定するか、一般的なパスを試行します。

### 2. 利用可能なスキルの一覧取得

```bash
`!scripts/list-available-skills.sh <plugin-dir>`
```

このスクリプトは以下を出力します：
- スキル名
- 説明（description）
- スクリプトの有無
- スキルのパス

### 3. プロジェクトコンテキストの分析

現在のプロジェクトを分析して、必要そうなスキルを判断します：

**分析項目:**
- `wrangler.toml` → Cloudflare Workers プロジェクト → wrangler-tunnel, commit-ja, pr-create
- `package.json` → TypeScript/JavaScript プロジェクト → lint-fix-parallel, local-tunnel
- `.git/` → Git リポジトリ → commit-ja, pr-create
- ユーザーのクエリ内容

**判断ロジック:**
1. ユーザーが明示的にリクエストした場合は、そのスキルを優先
2. **Cloudflare Workers プロジェクトの検出**:
   - `wrangler.toml` が存在 → `wrangler-tunnel` を推奨（`local-tunnel` の代わり）
3. プロジェクトタイプから推測:
   - TypeScript/JavaScript → `lint-fix-parallel`
   - Git リポジトリ → `commit-ja`, `pr-create`
   - 開発環境（Cloudflare以外） → `local-tunnel`
4. 汎用的に便利なスキルを提案（`skill-creator` など）

### 4. ユーザーへの提案

AIが選定したスキルをユーザーに提案します：

```
以下のスキルをインストールすることをおすすめします：

【推奨スキル】
1. commit-ja
   - Conventional Commits形式の日本語コミット
   - GitリポジトリなのでCommit作業に便利です

2. lint-fix-parallel
   - TypeScript lint/typecheckの並列自動修正
   - package.jsonにTypeScriptが含まれているため推奨

3. skill-creator
   - 新しいスキルを簡単に作成
   - 将来的にカスタムスキルを作る際に便利

【その他の利用可能なスキル】
- pr-create: Pull Request作成の自動化
- local-tunnel: ローカルアプリをスマホで確認（汎用）
- wrangler-tunnel: Cloudflare Workers開発用トンネル（wrangler.toml検出時）

インストールしたいスキルを選択してください（番号またはスキル名）。
「すべて」で推奨スキル全てをインストールします。
他のスキルについて詳細を聞きたい場合は、スキル名をお知らせください。

**注意:** Cloudflare Workers プロジェクトの場合、`local-tunnel` の代わりに `wrangler-tunnel` を推奨します。
```

### 5. スキルのインストール

ユーザーが選択したスキルをコピーします：

```bash
# 各スキルに対して実行
`!scripts/copy-skill.sh <plugin-dir> <skill-name> <current-project-dir>`
```

**処理内容:**
- プラグインの `.claude/skills/<skill-name>` をプロジェクトの `.claude/skills/` にコピー
- スクリプトファイルに実行権限を付与
- 既に存在する場合はスキップまたは上書き確認

### 6. インストール結果の確認

全てのスキルのコピーが完了したか確認します：

```bash
ls .claude/skills/
```

期待するスキルディレクトリが存在することを確認。

### 7. カスタムスキルの提案（オプション）

インストールした汎用スキルに加えて、このプロジェクト特化のカスタムスキルが有用か判断します。

**判断基準:**
- プロジェクトの特性（Cloudflare Workers、Next.js、モノレポなど）
- 繰り返し行われそうなタスク
- プロジェクト固有のワークフロー

**提案例:**

**Cloudflare Workers プロジェクトの場合:**
```
このプロジェクトに特化したカスタムスキルを作成しますか？

【提案】
- deploy-worker: wranglerでのデプロイとログ確認を自動化
- test-worker: ローカルテスト→デプロイ→動作確認の一連フロー

カスタムスキルを作成しますか？ (yes/no)
```

**Next.js プロジェクトの場合:**
```
【提案】
- new-page: Next.jsのページとAPIルートをテンプレートから生成
- deploy-vercel: ビルド→デプロイ→確認の自動化
```

**モノレポの場合:**
```
【提案】
- sync-packages: パッケージ間の依存関係を更新
- test-all: 全パッケージのテスト実行とレポート生成
```

**一般的なプロジェクト:**
提案なし（汎用スキルで十分な場合はスキップ）

**提案がある場合の処理:**

1. ユーザーに提案を表示
2. ユーザーが「yes」と回答 → `/skill-creator` を実行してカスタムスキル作成をガイド
3. ユーザーが「no」と回答 → スキップして次へ

**skill-creator への橋渡し:**
```
では、カスタムスキルを作成しましょう！
/skill-creator コマンドを実行します...

スキル名: deploy-worker
説明: Cloudflare Workerのデプロイとログ確認を自動化

このスキルでは以下を実行します：
1. wrangler deploy
2. デプロイ結果の確認
3. wrangler tail でログ監視

作成しますか？
```

### 8. find-skills 自体の削除

スキルインストール（とオプションのカスタムスキル作成）が完了したら、このスキル自体を削除します：

```bash
`!scripts/remove-self.sh <current-project-dir>`
```

**重要:** 削除前にユーザーに確認メッセージを表示：

```
✓ スキルのインストールが完了しました！

インストールされたスキル:
- commit-ja
- lint-fix-parallel
- skill-creator
- deploy-worker (カスタムスキル) ← 作成した場合のみ

find-skillsスキルはもう不要なため、自動的に削除されます。
よろしいですか？
```

ユーザーが承認したら削除を実行。

### 9. 完了報告

```
✓ インストール完了！

以下のスキルが使用可能になりました：
- /commit-ja: 日本語でConventional Commitsコミット
- /lint-fix-parallel: TypeScript lint/typecheckの並列修正
- /skill-creator: 新しいスキルを作成
- /deploy-worker: Workerデプロイ自動化 (カスタムスキル) ← 作成した場合

find-skillsスキルは削除されました。

【次のステップ】
1. 各スキルを試してみてください
2. カスタムスキルが必要になったら /skill-creator で作成
3. プロジェクトに応じてスキルをカスタマイズ

【プラグイン更新】
新しいスキルが追加されたら:
  /plugin update my-skills

【再インストール】
新しいプロジェクトで使う場合:
  /plugin marketplace add te19oishi/my-skills
  /plugin install my-skills
  /find-skills
```

## エラーハンドリング

以下のエラーケースに対応：

1. **プラグインディレクトリが見つからない**
   - 一般的なパスを試行
   - 見つからない場合はユーザーに手動でパスを入力してもらう

2. **スキルが既に存在する**
   - スキップするか上書きするか確認

3. **コピーに失敗**
   - エラーメッセージを表示
   - 権限エラーの可能性を案内

4. **削除に失敗**
   - find-skillsが残っても問題ないことを伝える
   - 手動削除の方法を案内

## コンテキスト最適化

このスキルは以下の方針でコンテキストを最適化しています：
- スキル一覧取得、コピー、削除は `scripts/` に分離
- SKILL.md にはプロジェクト分析とスキル選定のロジックのみ記述
- `context: fork` で独立した環境で実行
- `` `!command` `` 構文でスクリプトを実行

## 注意事項

- このスキルは my-skills プラグインの一部として配布されます
- プラグイン更新時に最新版が反映されます
- インストール後は自動的に削除されるため、再度必要な場合はプラグインを再インストール
- 複数回実行しても問題ありません（既存スキルはスキップ）
- スキルのコピーは物理コピーなので、元のプラグインを削除しても影響ありません
- Git管理下のプロジェクトの場合、インストールしたスキルもコミット対象になります

# My Skills

Personal Claude Code skills collection with automatic skill discovery and installation.

## 📦 インストール

```bash
# 1. マーケットプレイスを追加
/plugin marketplace add te19oishi/my-skills

# 2. プラグインをインストール
/plugin install my-skills

# 3. スキルを検索してインストール
/find-skills
```

## 🎯 利用可能なスキル

### skill-creator
新しいClaude Codeスキルを作成するためのスキル。

**機能:**
- SKILL.mdとスクリプトのテンプレート生成
- コンテキスト最適化の自動適用
- スクリプト分離の推奨

**使用方法:**
```bash
/skill-creator
```

### lint-fix-parallel
TypeScript lint/typecheckを実行し、エラー/警告を並列修正。

**機能:**
- eslint --fix で自動修正
- tsc で型チェック
- 問題のあるファイルを1ファイル1subagentで並列修正

**使用方法:**
```bash
/lint-fix-parallel
/lint-fix-parallel src/
```

### commit-ja
Conventional Commits形式の日本語コミット（Claude Code署名なし）。

**機能:**
- 変更内容を分析してコミットメッセージ生成
- 日本語で簡潔な説明
- スコープの自動判定

**使用方法:**
```bash
/commit-ja
```

### pr-create
Pull Request作成の自動化（Claude Code署名なし）。

**機能:**
- 変更内容からPRタイトルと本文を生成
- テンプレート形式（概要、変更内容、影響範囲、備考）
- Draft PR、Assignee、Reviewer、Label対応
- 自分をassigneeに設定する --assignee-me オプション

**使用方法:**
```bash
/pr-create
/pr-create main --assignee-me
/pr-create main --assignee-me --reviewer username
```

### local-tunnel
ngrok経由でローカルアプリを外部公開、スマホで確認。

**機能:**
- Basic認証付きトンネル（hinata:0014）
- デバッグモード（eruda統合）でスマホからコンソール確認
- アプリ起動とトンネル設定を同時実行

**使用方法:**
```bash
# 基本
/local-tunnel 3000

# アプリ起動 + トンネル
/local-tunnel 3000 "npm run dev"

# デバッグモード（スマホでコンソール確認可能）
/local-tunnel 3000 "npm run dev" --debug

# 停止
/local-tunnel stop
```

### find-skills
このスキル自体。プロジェクトを分析して必要なスキルを提案・インストール。

**機能:**
- プロジェクトタイプを自動判定
- 必要なスキルをAIが提案
- 選択したスキルを自動インストール
- インストール後に自己削除

**使用方法:**
```bash
/find-skills
/find-skills "commit用のスキルが欲しい"
```

## 🔄 更新

```bash
/plugin update my-skills
```

プラグインを更新すると、最新のスキルカタログが反映されます。

## 🏗️ アーキテクチャ

全てのスキルは以下の方針で設計されています：

- **コンテキスト最適化**: 定型処理は `scripts/` ディレクトリに分離
- **SKILL.mdには判断ロジックのみ**: AIによる分析・判断・対話のみを記述
- **署名なし**: commit-ja、pr-createはClaude Code署名を含めない
- **スクリプト実行**: `` `!command` `` 構文で動的に実行

## 📝 ライセンス

個人利用のため、ライセンス未設定。

## 👤 Author

te19oishi

---
name: pr-create
description: Pull Requestを作成します。変更内容を分析してPR説明を生成し、ユーザー確認後に作成します
disable-model-invocation: false
allowed-tools: Bash, Read
---

# Pull Request 作成

現在のブランチの変更内容を分析し、Pull Request を作成します。

## 使用方法

```
/pr-create [base-branch] [--draft] [--assignee user] [--assignee-me] [--reviewer user] [--label label]
```

**引数:**
- `base-branch`: マージ先のブランチ（省略時は main または master を自動判定）
- `--draft`: Draft PR として作成
- `--assignee <user>`: 担当者を指定
- `--assignee-me`: 自分を担当者に設定
- `--reviewer <user>`: レビュワーを指定
- `--label <label>`: ラベルを追加

**例:**
```
/pr-create
/pr-create develop
/pr-create main --draft
/pr-create main --assignee-me
/pr-create main --assignee-me --reviewer username --label enhancement
```

## 実行手順

### 1. ブランチ情報の取得

```
`!scripts/get-branch-info.sh $ARGUMENTS`
```

このスクリプトは以下を取得します：
- 現在のブランチ名
- ベースブランチ（main/master の自動判定）
- リモートへのプッシュ状況
- ベースブランチからのコミット履歴
- 変更内容の diff

出力から以下の情報を抽出：
- `CURRENT_BRANCH`: 現在のブランチ名
- `BASE_BRANCH`: ベースブランチ名
- `NEEDS_PUSH`: リモートへのプッシュが必要か（1=必要, 0=不要）

### 2. 変更内容の分析

コミット履歴と diff から以下を分析します：

#### タイトルの生成
- 全体の変更を端的に要約（50文字以内推奨）
- 複数の機能がある場合は最も重要なものを選択
- Conventional Commits 形式のコミットがあればそれを参考に

#### 本文の生成

以下のテンプレートで生成します：

```markdown
## 概要
[変更内容の簡潔な説明を1-2文で記述]

## 変更内容
- [主な変更点1]
- [主な変更点2]
- [主な変更点3]

## 影響範囲
[この変更が影響する部分を記述]

## 備考
[追加の注意事項や補足情報があれば記述]
```

**生成のポイント:**
- **概要**: 何を解決するのか、何を追加するのかを明確に
- **変更内容**: 具体的な変更を箇条書きで（3-5項目程度）
- **影響範囲**: ユーザー、API、データベース、パフォーマンスなど
- **備考**: Breaking Changes、マイグレーション、追加作業など

### 3. ユーザー確認

生成した PR の内容をユーザーに提示：

```
以下の内容で Pull Request を作成します：

【タイトル】
[生成したタイトル]

【ベースブランチ】
[BASE_BRANCH] ← [CURRENT_BRANCH]

【本文】
[生成した本文]

【その他のオプション】
- Draft: [yes/no]
- Assignee: [指定されていれば表示。--assignee-me の場合は「自分」と表示]
- Reviewer: [指定されていれば表示]
- Label: [指定されていれば表示]

よろしければ「はい」と答えてください。
修正したい場合は修正内容をお知らせください。
```

### 4. リモートへのプッシュ

`NEEDS_PUSH=1` の場合、create-pr.sh スクリプトが自動的に `git push -u origin [branch]` を実行します。

### 5. PR の作成

ユーザーが承認したら、スクリプトで PR を作成：

```bash
`!scripts/create-pr.sh "タイトル" "本文" [base-branch] [オプション...]`
```

**重要**: このスクリプトは Claude Code の署名を含めずに PR を作成します。

スクリプトの引数例：
```bash
# 基本
scripts/create-pr.sh "feat: 新機能を追加" "## 概要\n..."

# ベースブランチ指定
scripts/create-pr.sh "feat: 新機能を追加" "## 概要\n..." develop

# 自分をassigneeに設定
scripts/create-pr.sh "feat: 新機能を追加" "## 概要\n..." main --assignee-me

# 複数オプション付き
scripts/create-pr.sh "feat: 新機能を追加" "## 概要\n..." main --draft --assignee-me --reviewer username
```

### 6. 結果の報告

PR が作成されたら、以下を報告します：
- PR の URL
- PR 番号
- タイトルとベースブランチの確認

## コンテキスト最適化

このスキルは以下の方針でコンテキストを最適化しています：
- Git コマンドと gh コマンドの実行は `scripts/` に分離
- SKILL.md には変更内容の分析と PR 説明文の生成ロジックのみ記述
- ユーザーとの対話は SKILL.md で処理
- `` `!command` `` 構文でスクリプト出力を動的に注入

## 注意事項

- GitHub CLI (`gh`) がインストールされている必要があります
- `gh auth login` で GitHub にログインしている必要があります
- このスキルは Claude Code の署名を含めません
- リモートにプッシュされていない場合、自動的にプッシュします
- ベースブランチは main または master を自動判定しますが、引数で上書き可能です
- Draft PR、Assignee、Reviewer、Label などのオプションをサポートします

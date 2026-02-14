---
name: lint-fix-parallel
description: Run lint and typecheck for TypeScript, auto-fix what's possible, then fix remaining errors/warnings in parallel using subagents
disable-model-invocation: false
allowed-tools: Task, Read, Edit, Bash, Grep
---

# Lint & Typecheck Parallel Fix

TypeScript プロジェクトの lint とtype check を実行し、エラーや警告を並列で修正します。

## 使用方法

```
/lint-fix-parallel [path]
```

- `path`: チェック対象のパス（省略時はプロジェクト全体）

## 実行手順

### 1. Lint & Typecheck の実行

まず、自動修正可能なものを修正し、残りの問題をスキャンします：

```
`!scripts/run-lint-typecheck.sh $ARGUMENTS`
```

このスクリプトは以下を実行します：
1. `eslint --fix` で自動修正可能な問題を修正
2. `tsc --noEmit` で型エラーをチェック
3. 問題があるファイルのリストを出力

### 2. 結果の分析

スクリプト出力から、問題があるファイルのリストを取得します。
出力形式: `ファイルパス|問題の種類と件数`

例:
```
src/components/Button.tsx|eslint:2errors,1warnings;tsc:1errors
src/utils/helper.ts|tsc:3errors
```

### 3. 並列修正の実行

問題があるファイルごとに、**1ファイル1subagent** で並列に修正します。

重要な実装ルール：
- 全てのファイルを **同時に並列実行** する（順次実行しない）
- 1つのメッセージで複数の Task tool を呼び出す
- 各 subagent には以下を指示：
  - 対象ファイルを Read で読み込む
  - eslint/tsc のエラーメッセージを確認（該当部分を grep）
  - エラー/警告を修正
  - 修正内容を簡潔に報告

### 4. 並列実行の例

```
ファイルが3つある場合、1つのメッセージで3つの Task を同時実行：
```

**Task 1**: Fix src/components/Button.tsx
- Read the file
- Check eslint/tsc errors for this file
- Edit to fix issues
- Report changes

**Task 2**: Fix src/utils/helper.ts
- Read the file
- Check eslint/tsc errors for this file
- Edit to fix issues
- Report changes

**Task 3**: Fix src/types/index.ts
- Read the file
- Check eslint/tsc errors for this file
- Edit to fix issues
- Report changes

### 5. 結果の確認

全ての subagent が完了したら：
1. 各ファイルの修正内容をまとめて報告
2. 再度 lint & typecheck を実行して改善を確認
3. 残っている問題があれば報告

## コンテキスト最適化

このスキルは以下の方針でコンテキストを最適化しています：
- Lint/typecheck の実行とファイル集計は `scripts/` ディレクトリのスクリプトに分離
- SKILL.md には並列実行のロジックとsubagent起動の判断のみを記述
- 実際の修正作業は各 subagent に委譲して並列実行
- `` `!command` `` 構文でスクリプト出力を動的に注入

## 注意事項

- `eslint` と `tsc` がプロジェクトにインストールされている必要があります
- 大量のファイルがある場合、並列実行によりシステムリソースを多く使用します
- 各 subagent は独立して動作するため、ファイル間の依存関係に注意が必要です
- 自動修正後も問題が残る場合のみ、subagent による修正を行います

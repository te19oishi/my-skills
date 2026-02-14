---
name: skill-creator
description: Creates a new Claude Code skill with proper structure and templates
disable-model-invocation: false
allowed-tools: Write, Bash, Read
---

# Skill Creator

このスキルは新しいClaude Codeスキルを作成します。

## 使用方法

`/skill-creator <skill-name> <description>`

## 実行手順

1. ユーザーから以下の情報を収集します：
   - スキル名（kebab-case形式）
   - スキルの説明
   - 使用を許可するツール（オプション）
   - subagentで実行するか（オプション）

   **重要：** 引数で提供されていない情報や、スキルの目的が不明確な場合は、必ずユーザーに質問して明確化してください。推測で進めないでください。

2. スキルの設計を分析します：
   - スクリプト化可能な処理があるかを判断
   - 定型的な処理やファイル操作はスクリプトに分離
   - LLMの推論が必要な部分のみSKILL.mdに記述

3. スキルディレクトリを作成します：
   - `.claude/skills/<skill-name>/`ディレクトリを作成
   - `SKILL.md`ファイルを作成
   - スクリプトが必要な場合は`scripts/`ディレクトリを作成
   - 必要に応じて`templates/`ディレクトリを作成

4. SKILL.mdの内容を生成します：
   - 適切なYAML frontmatterを含める
   - 簡潔な説明と使用方法を記述
   - スクリプトがある場合は`` `!scripts/script-name.sh` ``構文で呼び出し
   - テンプレートファイル[skill-template.md](templates/skill-template.md)を参照

5. スクリプトファイルを作成します（必要な場合）：
   - シェルスクリプト、Python、Node.jsなど適切な言語を選択
   - 実行権限を付与（`chmod +x`）
   - エラーハンドリングを含める

6. 作成したスキルの場所とslashコマンド名をユーザーに報告します。

## 注意事項

- スキル名は小文字とハイフンのみ使用
- `name`フィールドがslashコマンド名になります
- `description`は自動起動の判断に使用されます
- プロジェクト固有のスキルは`.claude/skills/`に配置
- 個人用スキルは`~/.claude/skills/`に配置

## コンテキスト最適化ルール

**スクリプト化すべきもの：**
- ファイル操作（作成、移動、削除）
- テキスト変換（sed、awk的な処理）
- 定型的なコマンド実行
- データの整形や集計
- gitコマンドのシーケンス

**SKILL.mdに残すべきもの：**
- コンテキストに基づく判断
- コード分析や理解が必要な処理
- ユーザーとの対話
- 複雑な意思決定

スクリプトは`` `!command` ``構文で呼び出し、出力を動的にSKILL.mdに注入できます。

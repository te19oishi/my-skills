---
name: {{SKILL_NAME}}
description: {{SKILL_DESCRIPTION}}
disable-model-invocation: false
{{#IF_ALLOWED_TOOLS}}allowed-tools: {{ALLOWED_TOOLS}}{{/IF_ALLOWED_TOOLS}}
{{#IF_CONTEXT_FORK}}context: fork{{/IF_CONTEXT_FORK}}
{{#IF_AGENT}}agent: {{AGENT}}{{/IF_AGENT}}
---

# {{SKILL_TITLE}}

{{SKILL_DESCRIPTION}}

## 使用方法

`/{{SKILL_NAME}} [arguments]`

## 実行手順

1. 最初のステップを記述
2. 次のステップを記述
3. 最終的な出力や結果を記述

{{#IF_HAS_SCRIPT}}
## スクリプトによる処理

定型的な処理は以下のスクリプトで実行されます：

```
`!scripts/{{SCRIPT_NAME}}.sh $ARGUMENTS`
```

スクリプトの出力を基に、必要な判断や追加処理を行います。
{{/IF_HAS_SCRIPT}}

## 引数

- `$ARGUMENTS` - スキル実行時に渡される引数

## 注意事項

- このスキルの使用上の注意点を記述
- 制限事項があれば記載

## コンテキスト最適化

このスキルは以下の方針でコンテキストを最適化しています：
- 定型処理は `scripts/` ディレクトリのスクリプトに分離
- SKILL.mdには判断ロジックと対話部分のみを記述
- `` `!command` `` 構文で動的にスクリプト出力を注入

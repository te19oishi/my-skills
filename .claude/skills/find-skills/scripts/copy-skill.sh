#!/usr/bin/env bash
set -euo pipefail

# スキルをターゲットプロジェクトにコピー
# Usage: copy-skill.sh <plugin-dir> <skill-name> <target-dir>

if [ $# -lt 3 ]; then
    echo "Error: 引数が不足しています"
    echo "Usage: $0 <plugin-dir> <skill-name> <target-dir>"
    exit 1
fi

PLUGIN_DIR="$1"
SKILL_NAME="$2"
TARGET_DIR="$3"

SOURCE_SKILL="$PLUGIN_DIR/.claude/skills/$SKILL_NAME"
TARGET_SKILL="$TARGET_DIR/.claude/skills/$SKILL_NAME"

# ソーススキルの存在確認
if [ ! -d "$SOURCE_SKILL" ]; then
    echo "Error: スキルが見つかりません: $SOURCE_SKILL"
    exit 1
fi

# find-skills自体はコピーできない
if [ "$SKILL_NAME" = "find-skills" ]; then
    echo "Error: find-skillsスキル自体はコピーできません"
    exit 1
fi

# ターゲットディレクトリの作成
mkdir -p "$TARGET_DIR/.claude/skills"

# 既に存在する場合は確認
if [ -d "$TARGET_SKILL" ]; then
    echo "Warning: スキルは既に存在します: $TARGET_SKILL"
    echo "上書きしますか？ (スクリプト内では自動スキップ)"
    exit 2
fi

# スキルをコピー
echo "Copying $SKILL_NAME..."
cp -r "$SOURCE_SKILL" "$TARGET_SKILL"

# 実行権限を付与（scriptsディレクトリがある場合）
if [ -d "$TARGET_SKILL/scripts" ]; then
    chmod +x "$TARGET_SKILL/scripts"/*.sh 2>/dev/null || true
fi

echo "✓ Successfully copied: $SKILL_NAME"
echo "  Source: $SOURCE_SKILL"
echo "  Target: $TARGET_SKILL"

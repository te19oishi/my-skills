#!/usr/bin/env bash
set -euo pipefail

# find-skillsスキル自体を削除
# Usage: remove-self.sh <target-dir>

if [ $# -lt 1 ]; then
    echo "Error: ターゲットディレクトリが必要です"
    echo "Usage: $0 <target-dir>"
    exit 1
fi

TARGET_DIR="$1"
FIND_SKILLS_DIR="$TARGET_DIR/.claude/skills/find-skills"

if [ ! -d "$FIND_SKILLS_DIR" ]; then
    echo "Info: find-skillsは既に削除されています"
    exit 0
fi

echo "Removing find-skills from project..."
rm -rf "$FIND_SKILLS_DIR"

echo "✓ find-skills has been removed"
echo ""
echo "インストールされたスキルは以下で確認できます:"
echo "  ls $TARGET_DIR/.claude/skills/"

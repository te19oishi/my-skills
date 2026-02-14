#!/usr/bin/env bash
set -euo pipefail

# 利用可能なスキル一覧を取得
# Usage: list-available-skills.sh <plugin-dir>

if [ $# -lt 1 ]; then
    echo "Error: プラグインディレクトリが必要です"
    echo "Usage: $0 <plugin-dir>"
    exit 1
fi

PLUGIN_DIR="$1"
SKILLS_DIR="$PLUGIN_DIR/.claude/skills"

if [ ! -d "$SKILLS_DIR" ]; then
    echo "Error: スキルディレクトリが見つかりません: $SKILLS_DIR"
    exit 1
fi

echo "=== Available Skills ==="
echo ""

# 各スキルの情報を収集
for skill_dir in "$SKILLS_DIR"/*; do
    if [ -d "$skill_dir" ]; then
        skill_name=$(basename "$skill_dir")

        # find-skills自体はスキップ
        if [ "$skill_name" = "find-skills" ]; then
            continue
        fi

        skill_md="$skill_dir/SKILL.md"

        if [ -f "$skill_md" ]; then
            # YAMLフロントマターから説明を抽出
            description=""
            if grep -q "^description:" "$skill_md"; then
                description=$(grep "^description:" "$skill_md" | sed 's/^description: *//' | tr -d '"')
            fi

            # スクリプトの有無をチェック
            has_scripts="no"
            if [ -d "$skill_dir/scripts" ] && [ -n "$(ls -A "$skill_dir/scripts" 2>/dev/null)" ]; then
                has_scripts="yes"
            fi

            echo "[$skill_name]"
            echo "  Description: $description"
            echo "  Has Scripts: $has_scripts"
            echo "  Path: $skill_dir"
            echo ""
        fi
    fi
done

echo "=== End of List ==="

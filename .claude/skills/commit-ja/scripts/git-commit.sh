#!/usr/bin/env bash
set -euo pipefail

# Conventional Commits形式でコミットを実行（Claude Code署名なし）
# Usage: git-commit.sh "<commit-message>"

if [ $# -lt 1 ]; then
    echo "Error: コミットメッセージが指定されていません"
    echo "Usage: $0 '<commit-message>'"
    exit 1
fi

COMMIT_MESSAGE="$1"

# コミットを実行（Claude Code署名を含めない）
# メッセージを二重引用符で囲んで特殊文字に対応
git commit -m "${COMMIT_MESSAGE}"

echo "✓ コミット完了"

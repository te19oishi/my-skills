#!/usr/bin/env bash
set -euo pipefail

# git status と diff の情報を取得
# Usage: get-git-status.sh

echo "=== Git Status ==="
git status

echo ""
echo "=== Staged Changes ==="
if git diff --cached --quiet; then
    echo "No staged changes"
    STAGED=0
else
    git diff --cached --name-status
    echo ""
    git diff --cached --stat
    STAGED=1
fi

echo ""
echo "=== Unstaged Changes ==="
if git diff --quiet; then
    echo "No unstaged changes"
    UNSTAGED=0
else
    git diff --name-status
    echo ""
    git diff --stat
    UNSTAGED=1
fi

echo ""
echo "=== Untracked Files ==="
UNTRACKED_FILES="$(git ls-files --others --exclude-standard)"
if [ -z "$UNTRACKED_FILES" ]; then
    echo "No untracked files"
    UNTRACKED=0
else
    echo "$UNTRACKED_FILES"
    UNTRACKED=1
fi

echo ""
echo "=== Summary ==="
echo "STAGED=$STAGED"
echo "UNSTAGED=$UNSTAGED"
echo "UNTRACKED=$UNTRACKED"

# 変更内容の詳細を取得（AIの分析用）
if [ $STAGED -eq 1 ]; then
    echo ""
    echo "=== Staged Diff ==="
    git diff --cached
fi

if [ $UNSTAGED -eq 1 ]; then
    echo ""
    echo "=== Unstaged Diff ==="
    git diff
fi

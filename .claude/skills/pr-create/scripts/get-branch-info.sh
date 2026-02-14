#!/usr/bin/env bash
set -euo pipefail

# ブランチ情報と変更内容を取得
# Usage: get-branch-info.sh [base-branch]

BASE_BRANCH="${1:-}"

echo "=== Current Branch ==="
CURRENT_BRANCH=$(git branch --show-current)
echo "Current: $CURRENT_BRANCH"

# ベースブランチの判定
if [ -z "$BASE_BRANCH" ]; then
    # main または master を探す
    if git show-ref --verify --quiet refs/heads/main; then
        BASE_BRANCH="main"
    elif git show-ref --verify --quiet refs/heads/master; then
        BASE_BRANCH="master"
    elif git show-ref --verify --quiet refs/remotes/origin/main; then
        BASE_BRANCH="origin/main"
    elif git show-ref --verify --quiet refs/remotes/origin/master; then
        BASE_BRANCH="origin/master"
    else
        echo "Error: Could not determine base branch (main/master not found)"
        exit 1
    fi
fi

echo "Base: $BASE_BRANCH"

# リモートの状態をチェック
echo ""
echo "=== Remote Status ==="
if git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
    echo "Remote tracking branch exists"
    TRACKING_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u})
    echo "Tracking: $TRACKING_BRANCH"

    # リモートと同期しているか確認
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})

    if [ "$LOCAL" = "$REMOTE" ]; then
        echo "Status: Up to date with remote"
        NEEDS_PUSH=0
    else
        echo "Status: Local changes not pushed"
        NEEDS_PUSH=1
    fi
else
    echo "No remote tracking branch"
    NEEDS_PUSH=1
fi

echo ""
echo "=== Commit History ==="
echo "Commits since $BASE_BRANCH:"
git log --oneline "$BASE_BRANCH..HEAD"

echo ""
echo "=== Diff Summary ==="
git diff "$BASE_BRANCH...HEAD" --stat

echo ""
echo "=== Full Diff ==="
git diff "$BASE_BRANCH...HEAD"

echo ""
echo "=== Summary ==="
echo "CURRENT_BRANCH=$CURRENT_BRANCH"
echo "BASE_BRANCH=$BASE_BRANCH"
echo "NEEDS_PUSH=$NEEDS_PUSH"

#!/usr/bin/env bash
set -euo pipefail

# Pull Requestを作成（Claude Code署名なし）
# Usage: create-pr.sh <title> <body> [base-branch] [--draft] [--assignee user|@me] [--reviewer user] [--label label]

if [ $# -lt 2 ]; then
    echo "Error: タイトルと本文が必要です"
    echo "Usage: $0 '<title>' '<body>' [base-branch] [--draft] [--assignee user] [--reviewer user] [--label label]"
    exit 1
fi

TITLE="$1"
BODY="$2"
shift 2

BASE_BRANCH=""
DRAFT=""
ASSIGNEES=""
REVIEWERS=""
LABELS=""

# オプション引数を解析
while [ $# -gt 0 ]; do
    case "$1" in
        --draft)
            DRAFT="--draft"
            shift
            ;;
        --assignee)
            ASSIGNEES="--assignee $2"
            shift 2
            ;;
        --assignee-me)
            ASSIGNEES="--assignee @me"
            shift
            ;;
        --reviewer)
            REVIEWERS="--reviewer $2"
            shift 2
            ;;
        --label)
            LABELS="--label $2"
            shift 2
            ;;
        *)
            if [ -z "$BASE_BRANCH" ]; then
                BASE_BRANCH="--base $1"
            fi
            shift
            ;;
    esac
done

# gh コマンドの存在確認
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) がインストールされていません"
    echo "インストール方法: https://cli.github.com/"
    exit 1
fi

# リモートにプッシュされているか確認
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} &>/dev/null; then
    echo "リモートブランチが存在しません。プッシュします..."
    CURRENT_BRANCH=$(git branch --show-current)
    git push -u origin "$CURRENT_BRANCH"
fi

# PR を作成（署名なし）
echo "Creating pull request..."
gh pr create \
    --title "$TITLE" \
    --body "$BODY" \
    $BASE_BRANCH \
    $DRAFT \
    $ASSIGNEES \
    $REVIEWERS \
    $LABELS

echo ""
echo "✓ Pull Request created successfully"

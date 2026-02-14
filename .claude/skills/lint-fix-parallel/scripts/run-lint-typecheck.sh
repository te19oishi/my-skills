#!/usr/bin/env bash
set -euo pipefail

# TypeScript lint & typecheck を実行し、エラー/警告をファイル別に集計
# Usage: run-lint-typecheck.sh [path]

TARGET_PATH="${1:-.}"

echo "=== Running ESLint ==="
# eslint を実行（auto-fix可能なものは修正）
if command -v eslint &> /dev/null; then
    eslint "$TARGET_PATH" --fix --format json > /tmp/eslint-result.json 2>&1 || true
    echo "ESLint auto-fix completed"
else
    echo "Warning: eslint not found, skipping lint"
    echo "[]" > /tmp/eslint-result.json
fi

echo ""
echo "=== Running TypeScript Compiler ==="
# tsc でtype checkを実行
if command -v tsc &> /dev/null; then
    tsc --noEmit --pretty false 2>&1 | tee /tmp/tsc-result.txt || true
    echo "TypeScript check completed"
else
    echo "Warning: tsc not found, skipping typecheck"
    touch /tmp/tsc-result.txt
fi

echo ""
echo "=== Aggregating Results ==="

# エラー/警告があるファイルのリストを作成
declare -A file_issues

# ESLintの結果を解析
if [ -f /tmp/eslint-result.json ]; then
    # jqが使える場合はJSON解析、なければgrepで代用
    if command -v jq &> /dev/null; then
        jq -r '.[] | select(.errorCount > 0 or .warningCount > 0) | "\(.filePath)|\(.errorCount)|\(.warningCount)"' \
            /tmp/eslint-result.json 2>/dev/null | while IFS='|' read -r file errors warnings; do
            if [ -n "$file" ]; then
                file_issues["$file"]="eslint:${errors}errors,${warnings}warnings"
            fi
        done || true
    else
        # jqがない場合は単純にファイルパスを抽出
        grep -o '"filePath":"[^"]*"' /tmp/eslint-result.json 2>/dev/null | \
            cut -d'"' -f4 | sort -u | while read -r file; do
            if [ -n "$file" ]; then
                file_issues["$file"]="eslint:issues"
            fi
        done || true
    fi
fi

# tscの結果を解析（format: "path/to/file.ts(line,col): error TS1234: message"）
if [ -f /tmp/tsc-result.txt ]; then
    grep -oP '^[^(]+(?=\([0-9]+,[0-9]+\):)' /tmp/tsc-result.txt 2>/dev/null | sort -u | while read -r file; do
        if [ -n "$file" ] && [ -f "$file" ]; then
            count=$(grep -c "^${file}(" /tmp/tsc-result.txt || echo "0")
            existing="${file_issues[$file]:-}"
            if [ -n "$existing" ]; then
                file_issues["$file"]="${existing};tsc:${count}errors"
            else
                file_issues["$file"]="tsc:${count}errors"
            fi
        fi
    done
fi

# 結果を出力
echo ""
echo "=== Files with Issues ==="
if [ ${#file_issues[@]} -eq 0 ]; then
    echo "No issues found!"
    exit 0
fi

for file in "${!file_issues[@]}"; do
    echo "$file|${file_issues[$file]}"
done | sort

echo ""
echo "Total files with issues: ${#file_issues[@]}"

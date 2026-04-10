#!/usr/bin/env bash
# scan-claude-assets.sh — Rescan workspace for Claude-related assets
# Run from: /home/yuji/Desktop/Yuji Project/
# Output: prints a summary to stdout

set -euo pipefail

ROOT="${1:-$(pwd)}"
echo "=== Claude Asset Scan ==="
echo "Root: $ROOT"
echo "Date: $(date -I)"
echo ""

echo "--- CLAUDE.md files ---"
find "$ROOT" -maxdepth 4 -name "CLAUDE.md" -o -name "claude.md" 2>/dev/null | grep -v node_modules | sort
echo ""

echo "--- Agent directories ---"
find "$ROOT" -maxdepth 4 -type d -name "agents" 2>/dev/null | grep -v node_modules | sort
echo ""

echo "--- Skill directories ---"
find "$ROOT" -maxdepth 4 -type d -name "skills" 2>/dev/null | grep -v node_modules | sort
echo ""

echo "--- Prompt/context files ---"
find "$ROOT" -maxdepth 4 -type f \( -name "prompt.md" -o -name "AGENTS.md" \) 2>/dev/null | grep -v node_modules | sort
echo ""

echo "--- prd.json files ---"
find "$ROOT" -maxdepth 4 -name "prd.json" 2>/dev/null | grep -v node_modules | sort
echo ""

echo "--- progress.txt files ---"
find "$ROOT" -maxdepth 4 -name "progress.txt" 2>/dev/null | grep -v node_modules | sort
echo ""

echo "--- Shell scripts ---"
find "$ROOT" -maxdepth 4 -name "*.sh" -type f 2>/dev/null | grep -v node_modules | grep -v .next | sort
echo ""

echo "--- Hook configs ---"
find "$ROOT" -maxdepth 4 -name "hooks.json" 2>/dev/null | grep -v node_modules | sort
echo ""

echo "=== Scan complete ==="

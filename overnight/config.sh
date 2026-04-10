#!/bin/bash
# Overnight Loop — Shared Configuration

# Paths
OVERNIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$OVERNIGHT_DIR/../.." && pwd)"
STATE_DIR="$OVERNIGHT_DIR/state"
INBOX_DIR="$STATE_DIR/inbox"
LOG_FILE="$STATE_DIR/log.jsonl"
STATUS_FILE="$STATE_DIR/status.txt"
CYCLE_FILE="$STATE_DIR/cycle.txt"
BRIEF_FILE="$OVERNIGHT_DIR/brief.md"
PROJECTS_JSON="$WORKSPACE_DIR/ai-core/configs/projects.json"

# Loop settings
MAX_CYCLES="${MAX_CYCLES:-10}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

# Models per agent role
MODEL_SCOUT="${MODEL_SCOUT:-opus}"
MODEL_BUILDER_LEAN="${MODEL_BUILDER_LEAN:-sonnet}"

# ── Project resolution ────────────────────────────

# Map friendly names to projects.json keys
normalize_project_key() {
  local name="$1"
  case "$name" in
    ALLOK8R|allok8r|Allok8r)                         echo "allok8r" ;;
    TLE|tle|the-life-experiment|The-Life-Experiment)  echo "the_life_experiment" ;;
    freqtrade|Freqtrade|FREQTRADE|ft)                  echo "freqtrade" ;;
    polymarketbot|polymarket-bot|polymarket|pmbot)     echo "polymarket_bot" ;;
    yujidashboard|YujiDashboard|dashboard)             echo "lldashboard" ;;
    yujielectron|YujiElectron|electron)                echo "yujielectron" ;;
    *)                                                echo "$name" ;;
  esac
}

# Get project path from projects.json
resolve_project_path() {
  local key
  key="$(normalize_project_key "$1")"
  jq -r ".projects.${key}.path // empty" "$PROJECTS_JSON"
}

# Parse brief.md to extract project list
# Returns lines like: ALLOK8R|/path/to/allok8r|Focus description
parse_brief_projects() {
  if [ ! -f "$BRIEF_FILE" ]; then
    echo ""
    return
  fi

  # Extract lines from ## Projects section that match "- KEY: "description""
  local in_section=false
  while IFS= read -r line; do
    if echo "$line" | grep -q "^## Projects"; then
      in_section=true
      continue
    fi
    if echo "$line" | grep -q "^## " && [ "$in_section" = true ]; then
      break
    fi
    if [ "$in_section" = true ]; then
      # Match: - KEY: "description" or - KEY: description (KEY can contain hyphens)
      if echo "$line" | grep -qE '^\s*-\s+[A-Za-z0-9_-]+:'; then
        local project_name
        project_name="$(echo "$line" | sed -E 's/^\s*-\s+([A-Za-z0-9_-]+)\s*:.*/\1/')"
        local focus
        focus="$(echo "$line" | sed -E 's/^\s*-\s+[A-Za-z0-9_-]+\s*:\s*//' | sed 's/^"//;s/"$//')"
        local project_path
        project_path="$(resolve_project_path "$project_name")"

        if [ -n "$project_path" ] && [ -d "$project_path" ]; then
          echo "${project_name}|${project_path}|${focus}"
        fi
      fi
    fi
  done < "$BRIEF_FILE"
}

# Extract brief sections (excluding Projects) as text
# Used to pass Do NOT Touch, Constraints, Context, Success to agents
parse_brief_global() {
  if [ ! -f "$BRIEF_FILE" ]; then
    echo ""
    return
  fi

  local in_projects=false
  while IFS= read -r line; do
    if echo "$line" | grep -q "^## Projects"; then
      in_projects=true
      continue
    fi
    if echo "$line" | grep -q "^## " && [ "$in_projects" = true ]; then
      in_projects=false
    fi
    if [ "$in_projects" = false ]; then
      echo "$line"
    fi
  done < "$BRIEF_FILE"
}

# Legacy single-project support
TARGET_PROJECT="${TARGET_PROJECT:-ALLOK8R}"
PROJECT_PATH="$(resolve_project_path "$TARGET_PROJECT")"

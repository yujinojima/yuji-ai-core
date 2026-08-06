#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
GLOBAL_AGENTS="$CODEX_HOME/AGENTS.md"
USER_SKILLS="$HOME/.agents/skills"
SKILL_TARGET="$USER_SKILLS/yuji-builder"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$CODEX_HOME" "$USER_SKILLS"

START_MARKER="<!-- BEGIN YUJI BUILDER -->"
END_MARKER="<!-- END YUJI BUILDER -->"

if [[ -f "$GLOBAL_AGENTS" ]] && grep -Fq "$START_MARKER" "$GLOBAL_AGENTS"; then
  echo "Yuji Builder working agreements already exist in $GLOBAL_AGENTS"
elif [[ -f "$GLOBAL_AGENTS" ]]; then
  cp "$GLOBAL_AGENTS" "$GLOBAL_AGENTS.backup-$TIMESTAMP"
  {
    printf "\n%s\n" "$START_MARKER"
    cat "$ROOT_DIR/global/AGENTS.md"
    printf "\n%s\n" "$END_MARKER"
  } >> "$GLOBAL_AGENTS"
  echo "Appended working agreements; backup created at $GLOBAL_AGENTS.backup-$TIMESTAMP"
else
  {
    printf "%s\n" "$START_MARKER"
    cat "$ROOT_DIR/global/AGENTS.md"
    printf "\n%s\n" "$END_MARKER"
  } > "$GLOBAL_AGENTS"
  echo "Created $GLOBAL_AGENTS"
fi

if [[ -d "$SKILL_TARGET" ]]; then
  mv "$SKILL_TARGET" "$SKILL_TARGET.backup-$TIMESTAMP"
  echo "Backed up existing skill to $SKILL_TARGET.backup-$TIMESTAMP"
fi

cp -R "$ROOT_DIR/.agents/skills/yuji-builder" "$SKILL_TARGET"

echo "Installed Yuji Builder at $SKILL_TARGET"
echo "Restart Codex, then invoke: \$yuji-builder"

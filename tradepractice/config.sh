#!/bin/bash
# TradePractice — Configuration
# Runs every open usage window to optimise trading strategies

TRADE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "$TRADE_DIR/../.." && pwd)"
STATE_DIR="$TRADE_DIR/state"
INBOX_DIR="$STATE_DIR/inbox"
LOG_FILE="$STATE_DIR/log.jsonl"
STATUS_FILE="$STATE_DIR/status.txt"
CYCLE_FILE="$STATE_DIR/cycle.txt"
BRIEF_FILE="$TRADE_DIR/brief.md"
KNOWLEDGE_DIR="$TRADE_DIR/knowledge"

# Projects
FREQTRADE_DIR="$WORKSPACE_DIR/freqtrade"
POLYMARKET_DIR="$WORKSPACE_DIR/polymarket-bot"

# Loop settings
MAX_CYCLES="${MAX_CYCLES:-4}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

# Models — Opus for research/analysis, Sonnet for implementation
MODEL_ANALYST="${MODEL_ANALYST:-sonnet}"
MODEL_IMPLEMENTER="${MODEL_IMPLEMENTER:-sonnet}"

# Token-saving: terse mode
TERSE_RULES="CRITICAL OUTPUT RULES:
- No preamble. No filler. No meta-commentary.
- Never say 'I will now...' or 'Let me...' — just do it.
- Output format only. Let code and data speak.
- Technical terms, code, paths, numbers: exact. Prose: minimal."

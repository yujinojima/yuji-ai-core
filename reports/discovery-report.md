# Discovery Report

**Generated:** 2026-04-06
**Workspace:** /home/yuji/Desktop/Yuji Project

---

## Projects Found

| Project | Path | Type | Claude Material |
|---------|------|------|-----------------|
| ALLOK8R | ./ALLOK8R | Full-stack SaaS (Next.js 15 + Supabase) | CLAUDE.md, prd.json, progress.txt |
| The-Life-Experiment | ./The-Life-Experiment | Full-stack web app (Nuxt 4 + Vue 3) | CLAUDE.md, prd.json, progress.txt |
| YujiElectron | ./YujiElectron | Desktop app (Electron) | None |
| ralph | ./ralph | AI agent automation framework | CLAUDE.md, AGENTS.md, skills/, ralph.sh |
| everything-claude-code | ./everything-claude-code | Agent framework resource library | CLAUDE.md, 36 agents, 150 skills, 68 commands, hooks, scripts |

---

## CLAUDE.md Files Found

| Path | Purpose | Scope |
|------|---------|-------|
| `ALLOK8R/CLAUDE.md` | Ralph agent instructions for ALLOK8R | Project-specific |
| `ALLOK8R/allok8r/CLAUDE.md` | Placeholder (`@AGENTS.md`) | Project-specific |
| `everything-claude-code/CLAUDE.md` | Plugin project overview | Project-specific |
| `everything-claude-code/examples/CLAUDE.md` | Example template | Template/reference |
| `ralph/CLAUDE.md` | Generic Ralph agent instructions | Globally reusable |
| `The-Life-Experiment/CLAUDE.md` | Ralph agent instructions for TLE | Project-specific |

## Agent Directories Found

| Path | Count | Scope |
|------|-------|-------|
| `everything-claude-code/agents/` | 36 agents | Globally reusable |
| `everything-claude-code/.kiro/agents/` | Kiro framework agents | Platform-specific |
| `everything-claude-code/.codex/agents/` | Codex framework agents | Platform-specific |

## Skills Directories Found

| Path | Count | Scope |
|------|-------|-------|
| `everything-claude-code/skills/` | 150 skills | Globally reusable |
| `everything-claude-code/.agents/skills/` | 30 curated skills | Globally reusable |
| `everything-claude-code/.claude/skills/` | Claude-specific skills | Globally reusable |
| `everything-claude-code/.cursor/skills/` | Cursor-adapted skills | Platform-specific |
| `everything-claude-code/.kiro/skills/` | Kiro-adapted skills | Platform-specific |
| `ralph/skills/` | 2 skills (ralph, prd) | Globally reusable |

## Scripts & Automation

| Path | Purpose | Scope |
|------|---------|-------|
| `ralph/ralph.sh` | Autonomous agent loop runner | Globally reusable |
| `everything-claude-code/scripts/` | 80+ Node.js utilities | Globally reusable |
| `everything-claude-code/hooks/hooks.json` | 25+ hook definitions | Template (needs project config) |

## Prompt / Workflow Files

| Path | Purpose | Scope |
|------|---------|-------|
| `ralph/prompt.md` | Amp tool instructions | Globally reusable |
| `everything-claude-code/contexts/dev.md` | Development context mode | Globally reusable |
| `everything-claude-code/contexts/research.md` | Research context mode | Globally reusable |
| `everything-claude-code/contexts/review.md` | Review context mode | Globally reusable |

---

## Recommended Actions

### Copy to ai-core (globally reusable)
- `ralph/skills/ralph/SKILL.md` -> `ai-core/skills/ralph.md`
- `ralph/skills/prd/SKILL.md` -> `ai-core/skills/prd.md`
- `ralph/ralph.sh` -> `ai-core/scripts/ralph.sh`
- `everything-claude-code/contexts/*.md` -> `ai-core/prompts/contexts/`

### Reference only (too large to copy, use in-place)
- `everything-claude-code/agents/` — 36 agents, reference from ai-core
- `everything-claude-code/skills/` — 150 skills, reference from ai-core
- `everything-claude-code/scripts/` — 80+ scripts, reference from ai-core

### Leave in place (project-specific)
- All prd.json files
- All progress.txt files
- Project CLAUDE.md files
- Project source code

### Ignore
- `everything-claude-code/.kiro/`, `.cursor/`, `.codex/`, `.opencode/` — platform-specific adapters
- `YujiElectron/` — minimal, no Claude material
- `node_modules/` directories

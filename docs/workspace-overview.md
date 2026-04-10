# Workspace Overview

**Root:** `/home/yuji/Desktop/Yuji Project/`

This is a multi-project AI operations workspace. Claude sessions launched from the root can access shared agent instructions, skills, memory, logs, and orchestration files across all projects.

## Structure

```
Yuji Project/
├── ai-core/                    # Shared AI infrastructure
│   ├── agents/                 # Workspace-level agents (tron, epistem)
│   ├── skills/                 # Consolidated reusable skills
│   ├── memory/                 # Persistent memory across sessions
│   ├── logs/                   # Session and operation logs
│   ├── configs/                # Project registry and shared config
│   ├── scripts/                # Shared automation scripts
│   ├── prompts/                # Prompt templates and context modes
│   ├── reports/                # Discovery, migration, and status reports
│   ├── templates/              # Reusable file templates
│   └── docs/                   # Workspace documentation
├── projects/                   # Project reference stubs (docs, not source)
│   ├── ALLOK8R/
│   ├── The-Life-Experiment/
│   └── YujiElectron/
├── ALLOK8R/                    # Actual project source
├── The-Life-Experiment/        # Actual project source
├── YujiElectron/               # Actual project source
├── ralph/                      # Ralph automation framework
├── everything-claude-code/     # Agent/skill resource library (150 skills, 36 agents)
└── CLAUDE.md                   # Root entry point for Claude sessions
```

## Key Principles

1. **ai-core is shared infrastructure** — workspace-level agents, configs, and docs live here.
2. **Project source stays in place** — actual code lives in its original directory. `projects/` contains reference stubs only.
3. **everything-claude-code is a library** — 36 agents, 150 skills, 68 commands. Reference in-place, don't copy the whole thing.
4. **Ralph is the build pattern** — ALLOK8R and The-Life-Experiment both use Ralph's autonomous agent loop.
5. **Read before you write** — always check a project's CLAUDE.md and prd.json before making changes.

## Projects

| Project | Type | Ralph-enabled | Status |
|---------|------|---------------|--------|
| ALLOK8R | SaaS web app | Yes | Active |
| The-Life-Experiment | Fitness coach app | Yes | Active |
| YujiElectron | Desktop app | No | Dormant |
| ralph | Automation framework | N/A (is Ralph) | Active |
| everything-claude-code | Resource library | No | Active |

# Useful Agents from everything-claude-code

Source: `everything-claude-code/agents/`
Total agents: 36

---

## Orchestration

| Agent | Source | What it does | Why useful here |
|-------|--------|--------------|-----------------|
| **chief-of-staff** | `agents/chief-of-staff.md` | Triages email, Slack, LINE, Messenger into 4 priority tiers | Multi-channel communication management |
| **loop-operator** | `agents/loop-operator.md` | Monitors autonomous agent loops, intervenes when stalled | Essential for Ralph loops |
| **harness-optimizer** | `agents/harness-optimizer.md` | Tunes agent config for reliability, cost, throughput | Workspace optimization |

## Coding / Building

| Agent | Source | What it does | Why useful here |
|-------|--------|--------------|-----------------|
| **planner** | `agents/planner.md` | Breaks features into actionable implementation plans | Use before any complex feature work |
| **architect** | `agents/architect.md` | System design, scalability, technical decisions | Architecture decisions across projects |
| **build-error-resolver** | `agents/build-error-resolver.md` | Fixes build/TypeScript errors with minimal diffs | Quick build fixes |
| **typescript-reviewer** | `agents/typescript-reviewer.md` | TS/JS type safety, async, Node/web security | ALLOK8R and TLE are both TypeScript |
| **database-reviewer** | `agents/database-reviewer.md` | PostgreSQL query optimization, schema design | Both apps use databases |

## Testing / QA

| Agent | Source | What it does | Why useful here |
|-------|--------|--------------|-----------------|
| **tdd-guide** | `agents/tdd-guide.md` | Enforces write-tests-first, 80%+ coverage | All projects should use TDD |
| **e2e-runner** | `agents/e2e-runner.md` | E2E testing with Playwright/Vercel Agent Browser | Critical user flow testing |
| **code-reviewer** | `agents/code-reviewer.md` | General code quality, patterns, best practices | Use after every code change |
| **security-reviewer** | `agents/security-reviewer.md` | OWASP Top 10, secrets, injection, unsafe crypto | Before any commit |

## Documentation

| Agent | Source | What it does | Why useful here |
|-------|--------|--------------|-----------------|
| **doc-updater** | `agents/doc-updater.md` | Updates codemaps, READMEs, guides | Keep workspace docs current |
| **docs-lookup** | `agents/docs-lookup.md` | Fetches current library docs via Context7 MCP | Quick framework reference |

## Research

| Agent | Source | What it does | Why useful here |
|-------|--------|--------------|-----------------|
| **performance-optimizer** | `agents/performance-optimizer.md` | Bottleneck identification, profiling, optimization | App performance tuning |

## Content / Marketing

No dedicated content agents in ECC. Consider creating custom agents for:
- Content writing (for The-Life-Experiment brand)
- Social media management
- SEO optimization

Relevant ECC **skills** exist: `article-writing`, `content-engine`, `brand-voice`, `crosspost`.

## Operations

| Agent | Source | What it does | Why useful here |
|-------|--------|--------------|-----------------|
| **refactor-cleaner** | `agents/refactor-cleaner.md` | Dead code removal using knip, depcheck, ts-prune | Code maintenance |

## Automation

| Agent | Source | What it does | Why useful here |
|-------|--------|--------------|-----------------|
| **gan-planner** | `agents/gan-planner.md` | Expands prompts into full product specs with evaluation criteria | Rapid prototyping |
| **gan-generator** | `agents/gan-generator.md` | Implements features, iterates on evaluator feedback | Autonomous building |
| **gan-evaluator** | `agents/gan-evaluator.md` | Tests live apps via Playwright, scores against rubric | Quality automation |
| **opensource-forker** | `agents/opensource-forker.md` | Forks projects for open-sourcing, strips secrets | If open-sourcing any project |
| **opensource-sanitizer** | `agents/opensource-sanitizer.md` | Scans for leaked secrets, PII, internal references | Pre-release safety |

---

## Recommendation Summary

### Use immediately (high value)
- planner, architect, tdd-guide, code-reviewer, security-reviewer, build-error-resolver, e2e-runner

### Use as needed (medium value)
- typescript-reviewer, database-reviewer, doc-updater, docs-lookup, performance-optimizer, refactor-cleaner, loop-operator

### Use for specific workflows (situational)
- gan-planner/generator/evaluator (autonomous building)
- chief-of-staff (communication triage)
- opensource-* (open-source pipeline)

### Remain source-only (reference from ECC path)
All agents should be referenced from `everything-claude-code/agents/` rather than copied, since they are actively maintained in that project.

# Agent Registry

## Team Hierarchy

```
                          Director (Opus)
                     Strategic leadership
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
          Ideator          Tron          Behaviour Manager
         (Opus)          (Sonnet)            (Opus)
        Ideas &        Chief of staff     Monitors all agents
       possibilities   & orchestrator     Learning & scoring
              │               │            Functional audit
              └───────┬───────┘               │
                      │                       │ observes
        ┌─────────────┼─────────────┐         │ everything
        ▼             ▼             ▼         ▼
   Knowledge     Content Team    Building    ───────
       │              │              │
   ┌───┴───┐    ┌─────┼─────┐   ┌───┴───┐
   ▼       ▼    ▼     ▼     ▼   ▼       ▼
Epistem  Rsrchr CSM  Copy  Video FE     BE
                      Writer Prod Builder Builder
   │
   ▼
Fitness Coach       UX Researcher
(domain specialist) (domain specialist)
```

## Workspace Agents (ai-core/agents/)

### Executive / Leadership

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| **director** | `director.md` | Opus | Strategic director. Sets priorities, makes trade-offs, defines "done." Top of hierarchy. |
| **tron** | `tron.md` | Sonnet | Chief of staff / orchestrator. Translates decisions into tasks, coordinates agents, tracks status. |
| **ideator** | `ideator.md` | Opus | Idea generation. Turns todo lists and raw thoughts into structured possibilities for Director. |

### Behaviour & Quality

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| **behaviour-manager** | `behaviour-manager.md` | Opus | Monitors user and agent behaviours. Continuous learning, performance scoring, functional audit. Cross-cutting oversight across all teams. |

### Knowledge & Research

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| **epistem** | `epistem.md` | Sonnet | Teaching and relevance agent. Explains why things matter using layered responses. |
| **researcher** | `researcher.md` | Sonnet | General research — market, competitive analysis, technology scouting, deep investigation. |

### Domain Specialists

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| **fitness-coach** | `fitness-coach.md` | Sonnet | Evidence-based training advisor. Programming, periodization, coaching interaction design. |
| **ux-researcher** | `ux-researcher.md` | Sonnet | Usability analysis, user journey mapping, heuristic evaluation, accessibility review. |

### Content Team (reports to Content Strategist)

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| **content-strategist** | `content-strategist.md` | Sonnet | Team lead. Content strategy, calendar, platform planning. Routes work to the team. |
| **copywriter** | `copywriter.md` | Sonnet | Articles, scripts, landing pages, newsletters, brand voice. All written content. |
| **video-producer** | `video-producer.md` | Sonnet | Video editing, animation (Manim/Remotion), AI media gen, multi-format output. |
| **social-media-manager** | `social-media-manager.md` | Sonnet | Platform-native posting, cross-posting, distribution, audience growth, analytics. |

### Building Team

| Agent | File | Model | Purpose |
|-------|------|-------|---------|
| **frontend-builder** | `frontend-builder.md` | Sonnet | Writes frontend code following project conventions. Components, pages, styles. |
| **backend-builder** | `backend-builder.md` | Sonnet | Writes server-side code. APIs, schemas, business logic, auth. |

## ECC Agents (everything-claude-code/agents/)

36 specialized dev agents. Key ones for this workspace:

### High Priority (use regularly)
| Agent | Purpose |
|-------|---------|
| planner | Implementation planning for complex features |
| architect | System design and architectural decisions |
| tdd-guide | Test-driven development enforcement |
| code-reviewer | Code quality review after changes |
| security-reviewer | Security vulnerability detection |
| build-error-resolver | Fix build/type errors quickly |
| e2e-runner | End-to-end testing |

### Medium Priority (use as needed)
| Agent | Purpose |
|-------|---------|
| typescript-reviewer | TypeScript/JavaScript specific review |
| database-reviewer | PostgreSQL/Supabase optimization |
| doc-updater | Documentation maintenance |
| docs-lookup | Live framework docs via Context7 |
| performance-optimizer | Bottleneck identification |
| refactor-cleaner | Dead code removal |
| loop-operator | Autonomous loop monitoring |
| harness-optimizer | Agent harness configuration audit |

### Situational (specific workflows)
| Agent | Purpose |
|-------|---------|
| gan-planner / gan-generator / gan-evaluator | Autonomous build pipeline |
| chief-of-staff | Communication triage |
| opensource-forker / sanitizer / packager | Open-source release pipeline |

## ECC Skills Referenced by Workspace Agents

### Content Team Skills
| Skill | Referenced by | Use for |
|-------|--------------|---------|
| `content-engine` | Social Media Manager | Platform-native content systems |
| `article-writing` | Copywriter | Long-form content with distinctive voice |
| `brand-voice` | Copywriter | Voice profile extraction and maintenance |
| `crosspost` | Social Media Manager | Multi-platform distribution |
| `x-api` | Social Media Manager | X/Twitter API integration |
| `video-editing` | Video Producer | Full video editing pipeline |
| `remotion-video-creation` | Video Producer | Programmatic video in React |
| `manim-video` | Video Producer | Technical explainer animations |
| `videodb` | Video Producer | Video ingest, indexing, search |
| `fal-ai-media` | Video Producer | AI image/video/audio generation |
| `frontend-slides` | Copywriter | HTML presentations |
| `investor-materials` | Copywriter | Pitch decks, memos |
| `investor-outreach` | Copywriter | Investor communications |
| `lead-intelligence` | Social Media Manager | Social graph analysis |
| `market-research` | Social Media Manager | Competitive content analysis |

### Behaviour Manager Skills
| Skill | Use for |
|-------|---------|
| `continuous-learning-v2` | Instinct-based learning with confidence scoring |
| `eval-harness` | Formal evaluation framework |
| `click-path-audit` | Trace touchpoints through state changes |
| `verification-loop` | Comprehensive verification system |
| `santa-method` | Multi-agent adversarial verification |
| `gan-style-harness` | Generator-Evaluator quality patterns |
| `agent-harness-construction` | Agent action space optimization |
| `enterprise-agent-ops` | Long-lived agent observability |

## Decision Flow

```
Todo list / rough idea / observation
  │
  ▼
Ideator ──── generates 5-10 possibilities, grades each
  │
  ▼
Director ─── filters to 1-3 priorities, defines "done"
  │
  ▼
Tron ─────── creates task briefs, routes to right team
  │
  ├──▶ Content Team (content-strategist → copywriter / video / social)
  ├──▶ Building Team (frontend-builder / backend-builder)
  ├──▶ Knowledge (epistem / researcher)
  ├──▶ Specialists (fitness-coach / ux-researcher)
  └──▶ ECC Agents (planner / architect / tdd / reviewers)
  
  ◄── Behaviour Manager observes all of the above
      scores performance, extracts learnings, flags drift
```

## Adding New Agents

1. Create a markdown file in `ai-core/agents/` with YAML frontmatter:
   ```yaml
   ---
   name: agent-name
   description: One-line description
   tools: ["Read", "Write", "Edit", "Bash", "Grep", "Glob"]
   model: claude-sonnet-4-6
   ---
   ```
2. Include: role, responsibilities, inputs, outputs, working style, guardrails
3. Update this registry
4. Reference from root CLAUDE.md if it's a primary agent
5. Place in the hierarchy — who does it report to? Who does it coordinate with?

## Agent Conventions

- Agents don't modify code directly unless they are builder/developer agents
- Always read project CLAUDE.md before routing work to a project
- Use `ai-core/configs/projects.json` for project paths
- Prefer parallel execution for independent tasks
- Log significant actions to `ai-core/logs/`
- Behaviour Manager observes all agents — don't bypass the quality layer

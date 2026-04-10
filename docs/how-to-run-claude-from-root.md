# How to Run Claude from Root

## Starting a Session

Launch Claude Code from the workspace root:

```bash
cd "/home/yuji/Desktop/Yuji Project"
claude
```

The root `CLAUDE.md` will be loaded automatically, giving Claude context about the workspace structure, available agents, and project registry.

## Working with a Specific Project

Tell Claude which project you're targeting:

```
"Work on ALLOK8R — I want to add a new feature"
"Check the status of The-Life-Experiment"
"What's the current state across all projects?"
```

Claude will:
1. Read `ai-core/configs/projects.json` for the project path
2. Read the project's `CLAUDE.md` for local instructions
3. Check `prd.json` and `progress.txt` if Ralph-enabled

## Using Tron (Orchestrator)

Ask Tron to coordinate work:

```
"Tron, summarize status across all projects"
"Tron, create a task brief for adding auth to ALLOK8R"
"Tron, what did the last session accomplish?"
```

## Using Epistem (Teacher)

Ask Epistem to explain concepts:

```
"Epistem, why does RAG matter?"
"Epistem, is this foundational or just a trend?"
"Epistem, how does this connect to systems thinking?"
```

## Using ECC Agents

Reference agents from everything-claude-code:

```
"Use the planner agent to break down this feature"
"Run code-reviewer on my recent changes"
"Use tdd-guide for this new feature"
```

## Context Modes

Switch context modes using prompts from `ai-core/prompts/contexts/`:

- **dev.md** — Active development, code-first, working solutions
- **research.md** — Deep analysis, reference gathering
- **review.md** — Quality checking, security auditing

## Running Ralph Loops

For autonomous building on a Ralph-enabled project:

```bash
cd "/home/yuji/Desktop/Yuji Project/ALLOK8R"
bash ../ai-core/scripts/ralph.sh
```

Or from the project's own directory using ralph directly.

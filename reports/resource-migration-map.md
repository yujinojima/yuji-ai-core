# Resource Migration Map

Files copied into ai-core from their original locations.

| Original Path | New Path | Purpose |
|---------------|----------|---------|
| `ralph/skills/ralph/SKILL.md` | `ai-core/skills/ralph.md` | PRD-to-prd.json converter skill |
| `ralph/skills/prd/SKILL.md` | `ai-core/skills/prd.md` | PRD generator from feature descriptions |
| `ralph/ralph.sh` | `ai-core/scripts/ralph.sh` | Autonomous agent loop runner |
| `everything-claude-code/contexts/dev.md` | `ai-core/prompts/contexts/dev.md` | Development context mode |
| `everything-claude-code/contexts/research.md` | `ai-core/prompts/contexts/research.md` | Research context mode |
| `everything-claude-code/contexts/review.md` | `ai-core/prompts/contexts/review.md` | Review context mode |

## Referenced but not copied (use in-place)

These resources are too large or tightly coupled to copy. Reference them at their original paths.

| Resource | Path | Reason |
|----------|------|--------|
| 36 ECC agents | `everything-claude-code/agents/` | Large collection, actively maintained upstream |
| 150 ECC skills | `everything-claude-code/skills/` | Large collection, actively maintained upstream |
| 68 ECC commands | `everything-claude-code/commands/` | Large collection, actively maintained upstream |
| 80+ ECC scripts | `everything-claude-code/scripts/` | Complex dependencies, Node.js ecosystem |
| Hook system | `everything-claude-code/hooks/` | Needs project-specific configuration |

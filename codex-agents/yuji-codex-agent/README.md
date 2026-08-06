# Yuji Codex Agent

A Codex configuration that turns Yuji's thinking philosophy into an operational software-building workflow.

It combines:

- a concise `AGENTS.md` for durable working agreements;
- an installable `yuji-builder` skill for the full reasoning and implementation cycle;
- a recursive build-state template;
- a system-level review protocol.

## What makes it different

The agent does not simply translate a request into a feature list. It:

1. expands the strongest coherent interpretation;
2. maps Episteme, Psyche, Praxis, and Time;
3. makes states, transitions, feedback, support, and friction explicit;
4. builds one real vertical slice;
5. tests the mechanism;
6. updates its model from evidence;
7. audits the result for reductionism.

## Install globally

This makes the working agreements and skill available across repositories.

```bash
cd yuji-codex-agent
chmod +x install-global.sh
./install-global.sh
```

The installer:

- adds the working agreements to `~/.codex/AGENTS.md`;
- installs the skill at `~/.agents/skills/yuji-builder`;
- backs up an existing skill before replacement;
- does not overwrite unrelated existing global instructions.

Restart Codex after installation.

Confirm the global instructions:

```bash
codex --ask-for-approval never "Summarize the current instructions."
```

List or invoke the skill:

```text
/skills
$yuji-builder
```

Example:

```text
Use $yuji-builder.

I want a study system that does not merely track completed tasks. It should model what I can do, what is active today, what support I used, the friction that blocked initiation, and what changed after feedback. Build the first coherent vertical slice.
```

## Install in one repository

Copy these into the repository root:

```bash
cp AGENTS.md /path/to/repo/AGENTS.md
mkdir -p /path/to/repo/.agents/skills
cp -R .agents/skills/yuji-builder /path/to/repo/.agents/skills/
```

Merge the supplied `AGENTS.md` manually when the repository already has one.

## Files

```text
AGENTS.md
global/AGENTS.md
.agents/skills/yuji-builder/
├── SKILL.md
├── agents/openai.yaml
└── references/
    ├── YUJI_BUILD_STATE_TEMPLATE.md
    └── REVIEW_PROTOCOL.md
install-global.sh
```

## Recommended use

Invoke `$yuji-builder` explicitly for:

- new products;
- ambiguous or concept-heavy ideas;
- architecture;
- workflow systems;
- complex features;
- meaningful refactors;
- design-to-code work;
- reviews where conceptual fidelity matters.

Tiny mechanical edits should remain direct.

# Prim Template

> Copy this when creating a new trading primitive (situation-based).
> A pattern is an agent-driven situation, not a visual chart shape.
> A pattern is not valid until its reaction is observed.

```markdown
---
name: [short descriptive name]
level: [naive | intermediate | sophisticated]
project: [freqtrade | polymarket]
parent_prim: [what simpler prim this refines, or "none"]
created: [YYYY-MM-DD]
last_validated: [YYYY-MM-DD]
reaction_validated: [assumed | observed-once | observed-repeatedly]
---

## Situation

### Setup
[Market condition creating potential. What structure exists before the trigger?]

### Trigger
[Event or change that forces a decision. What happens?]

### Reaction
[How agents actually respond. This MUST be observed, not assumed.]
- **Accepted:** [what acceptance looks like — price holds, volume confirms]
- **Rejected:** [what rejection looks like — price reverses, trapped agents exit]
- **Unclear:** [what ambiguity looks like — mixed signals, low volume]

### Agent Behaviour
- **Who is acting:** [institutional, retail, algorithmic — and what are they doing?]
- **Who is trapped:** [late longs, late shorts, breakout chasers — who must exit?]
- **Who is wrong:** [which side provides fuel for the other?]

### Outcome
- **If accepted:** [continuation bias — target, expectation]
- **If rejected:** [reversal bias — target, expectation]
- **If unclear:** [no action — wait for clarity]

## Rule
[The conditional trading rule in plain language. NOT deterministic.]
[e.g., "If breakout is accepted (3-bar hold + volume), continuation bias toward X."]

## Mechanism
[WHY does this work? What agent behaviour does it exploit?]
[Focus on who is forced to act and why, not on indicator mechanics.]

## Conditions
- **Works when:** [specific market conditions + regime]
- **Fails when:** [specific market conditions + regime]
- **Best pairs:** [or "all tested pairs"]
- **Best timeframe:** [1h, 15m, 4h, etc.]
- **Best regime:** [trending | ranging | volatile | low-vol]

## Evidence

### Source Quality
- **Source:** [anecdote | backtest | paper | forward-test]
- **Certainty:** [guess | hypothesis | evidence | proven]
- **Scope:** [one pair | asset class | universal]
- **Falsifiable:** [untested | tested-pass | tested-fail]
- **Reaction observed:** [yes/no — how many times?]

### Data
[Backtest results, paper citations, or forward-test data]
- Period: [date range]
- Trades: [count]
- Win rate: [%]
- Profit: [%]
- Max drawdown: [%]
- Sharpe: [ratio]
- Acceptance rate: [% of triggers where reaction was "accepted"]
- Rejection rate: [% of triggers where reaction was "rejected"]
- Unclear rate: [% of triggers where reaction was ambiguous]

## Limitations
[Known failure modes. When NOT to use this.]
[Which agent behaviour assumptions break down?]

## Implementation
- **File:** [path to strategy file]
- **Parameter:** [specific parameter name and value]
- **Code:** [brief code snippet or line reference]
- **Reaction detection:** [how the code identifies accepted vs rejected vs unclear]

## Situation Log
[Each observed instance of this situation, with reaction and outcome.]

| Date | Pair | TF | Setup | Trigger | Reaction | Outcome | Notes |
|------|------|----|-------|---------|----------|---------|-------|
| [date] | [pair] | [tf] | [brief] | [brief] | [accepted/rejected/unclear] | [result] | [what was learned] |

## Refinement History
- [date]: Created as [level] prim from [source]
- [date]: Reaction first observed: [accepted/rejected] under [conditions]
- [date]: Refined to [level] after [finding about agent behaviour]
- [date]: Invalidated under [conditions] — [which agents behaved differently than expected]
```

# Yuji Builder Review Protocol

Use this review after implementation or when reviewing a pull request.

## Conceptual fidelity

- State the deeper transformation this change claims to enable.
- Identify the code path that implements the transformation.
- Flag any feature that appears present in the interface but has no underlying mechanism.

## Mechanism trace

Trace one real example through:

`input → interpretation → state transition → persistence/integration → feedback`

Identify missing links, hidden state, or behaviour that exists only by convention.

## Four-layer review

### Episteme
- Are domain claims and invariants explicit?
- Is uncertainty represented honestly?
- Are derived outputs traceable to evidence?

### Psyche
- Can the user initiate, understand, persist, and recover?
- Is friction handled mechanically rather than blamed on the user?
- Are support and underlying capability kept distinct?

### Praxis
- Are actions and transitions observable and testable?
- Are failure and reversal paths coherent?

### Time
- Does sequence matter?
- Is history lost?
- Are recurrence, delay, decay, or versioning mishandled?

## Reductionism review

Flag:

- one score replacing several causal dimensions;
- one boolean replacing a state machine;
- one table replacing a domain model;
- latest-state storage where history matters;
- observed behaviour treated as intent or capability;
- assisted success treated as durable learning;
- generic abstractions erasing domain distinctions.

## Evidence review

- Match each major claim to a test, runtime observation, schema constraint, or repository fact.
- Distinguish verified behaviour from inference.
- Report tests not run and why.

## Recursive gateway

Conclude with the next unresolved relation revealed by the change. Do not automatically implement it unless it belongs to the current task.

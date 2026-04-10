# Epistemic Index — Trading Knowledge Primitives

> Based on diSessa's p-prims and Louca et al.'s epistemic cognition framework.
> Knowledge evolves: naive intuitions → contextual understanding → sophisticated models.
> Each primitive is testable, falsifiable, and has documented activation conditions.
>
> **Core principle**: Patterns are agent-driven situations, not visual chart shapes.
> Edge comes from modelling agent behaviour and mistakes, not detecting patterns.

## Framework

### What is a Pattern?

A pattern is NOT a chart shape. A pattern is a **situation** with participants:

```
Setup → Trigger → Reaction → Outcome
```

- **Setup**: Market condition creating potential (e.g., compression near resistance)
- **Trigger**: Event that forces a decision (e.g., breakout candle, news catalyst)
- **Reaction**: How agents actually respond — accepted, rejected, or unclear
- **Outcome**: What follows the reaction — continuation, reversal, or no-trade

**A pattern is not valid until its reaction is observed.**
"Breakout" is not a signal. "Accepted breakout" or "rejected breakout" is.

### Reaction-First Epistemic Rule

No signal is deterministic. Every trigger produces one of three reactions:

| Reaction | Meaning | Bias |
|----------|---------|------|
| **Accepted** | Price holds, volume confirms, no immediate reversal | Continuation |
| **Rejected** | Price reverses through trigger, trapped agents exit | Reversal |
| **Unclear** | Mixed signals, low volume, no conviction | No action |

Signals are **probabilistic, context-dependent, and revisable**.
Confirmation comes from **observed behaviour**, not assumption.

### Agent Behaviour Model

For every situation, ask:
- **Who is acting?** (institutional, retail, algorithmic)
- **Who is trapped?** (late longs, late shorts, breakout chasers)
- **Who is wrong?** (the side that must exit, creating fuel for the other side)

Edge = understanding which agents are forced to act and in which direction.

### Levels

| Level | What it means | Trading example |
|-------|--------------|-----------------|
| **Naive** | Simple rule. One variable. No context. Often partially correct but brittle. | "RSI < 30 = buy" |
| **Intermediate** | Contextual rule. Multiple variables. Accounts for regime, reaction, and agent behaviour. | "RSI < 30 + uptrend + volume acceptance at support = buy (trapped shorts providing fuel)" |
| **Sophisticated** | Full situation model. Regime-aware, reaction-confirmed, agent-mapped, knows its own failure modes. | "RSI divergence + price at VAL + trigger candle accepted (no wick rejection within 3 bars) + trapped late shorts (OI spike pre-move) + trending regime (ADX>25) = high-conviction long" |

### Epistemic Quality (Louca et al.)

Each prim is rated on epistemic maturity:

| Dimension | Question | Scale |
|-----------|----------|-------|
| **Source** | Where did this knowledge come from? | anecdote → backtest → paper → forward-test |
| **Certainty** | How sure are we? | guess → hypothesis → evidence → proven |
| **Scope** | How broadly does it apply? | one pair → asset class → universal |
| **Falsifiability** | Can we disprove it? | unfalsifiable → testable → tested |
| **Limitations** | Do we know when it breaks? | unknown → suspected → documented |
| **Reaction validated?** | Has the reaction been observed? | assumed → observed-once → observed-repeatedly |

### Refinement Path

```
Naive prim: "breakout = buy"
    ↓ observed: breakouts get rejected 40% of the time
Intermediate: "accepted breakout (hold above level + volume) = continuation bias"
    ↓ observed: acceptance rate depends on who is trapped
Sophisticated: "breakout + acceptance (3-bar hold, no wick > 50%) + trapped shorts (OI spike, funding flip) + trending regime = high-conviction long. Rejected breakout (immediate wick-back + volume) = reversal bias targeting trapped longs."
    ↓ forward-tested, reaction rates documented per regime
```

### Conditional Rules (replacing deterministic rules)

Never use deterministic rules like "breakout = buy". Always use conditional:

| Old (deterministic) | New (conditional) |
|---------------------|-------------------|
| Breakout = buy | Accepted breakout → continuation bias |
| Support bounce = long | Accepted support (volume + hold) → long bias |
| Divergence = reversal | Divergence + rejection reaction → reversal bias |
| Any signal = action | Unclear reaction → no action |

### Learning Loop

Every situation is stored with:
1. **Setup** — what conditions existed
2. **Trigger** — what event occurred
3. **Reaction** — accepted / rejected / unclear
4. **Agent behaviour** — who acted, who was trapped, who was wrong
5. **Outcome** — continuation / reversal / no-trade / stopped out
6. **Context tags** — regime, timeframe, pair, volatility

Over time, evaluate: which reactions lead to reliable outcomes under specific contexts?

---

## Freqtrade Prims

### Naive
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [rsi-oversold-mean-reversion](freqtrade/prims/naive/rsi-oversold-mean-reversion.md) | RSI(14) < 30 → long if reaction accepted | guess | assumed | YujiMultiSignalStrategy.py buy_1; YujiRegimeStrategy.py range_entry |
| [ema-pullback-dynamic-support](freqtrade/prims/naive/ema-pullback-dynamic-support.md) | EMA alignment >= 3 + price touches 21 EMA + bullish candle + MACD hist rising → long if held | guess | assumed | YujiTrendRiderStrategy.py buy_pullback (lines 184–192) |
| [liquidity-sweep-reversal](freqtrade/prims/naive/liquidity-sweep-reversal.md) | Wick below swing low + close back above + bullish candle + CVD positive → long if accepted | guess | assumed | YujiSmartMoneyStrategy.py (lines 179–187) |

### Intermediate
<!-- Auto-populated by tradepractice analyst -->

### Sophisticated
<!-- Auto-populated by tradepractice analyst -->

---

## Polymarket Prims

### Naive
<!-- Auto-populated by tradepractice analyst -->

### Intermediate
<!-- Auto-populated by tradepractice analyst -->

### Sophisticated
<!-- Auto-populated by tradepractice analyst -->

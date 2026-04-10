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
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [rsi-oversold-mean-reversion](freqtrade/prims/intermediate/rsi-oversold-mean-reversion.md) | RSI(14) < 30 + RANGING regime (ADX < 20) + price > 1h EMA200 + confirming oscillator + volume → long to BB middle. **Does NOT work in trending crypto markets.** | hypothesis | assumed | YujiRegimeStrategy.py range_entry (lines 185–194) |
| [ema-pullback-dynamic-support](freqtrade/prims/intermediate/ema-pullback-dynamic-support.md) | EMA alignment >= 3 + ADX 25–35 (rising) + first/second pullback to 21 EMA + 4h bullish + bullish candle + MACD hist rising → long. **TRENDING regime only. Mirror complement to RSI mean reversion.** | hypothesis | assumed | YujiTrendRiderStrategy.py buy_pullback (lines 193–202) |
| [liquidity-sweep-reversal](freqtrade/prims/intermediate/liquidity-sweep-reversal.md) | Wick >= 0.3% below swing low + close above + CVD divergence + near VP level (POC/VAL) + volume spike + **RANGING-TO-MILD-TREND regime (ADX < 30)**. Exploits trapped breakout shorts at structural levels. | hypothesis | assumed | YujiSmartMoneyStrategy.py (lines 188–197) |

### Sophisticated
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [rsi-oversold-mean-reversion](freqtrade/prims/sophisticated/rsi-oversold-mean-reversion.md) | RSI(14) **25–35 plateau** (NOT magic threshold) + RANGING (ADX < 20 AND BBW pctl < 40) + price > 1h EMA200 + confirming oscillator + volume > 0.8x SMA + BTC/ETH 4h primary + **fee+slippage-adjusted edge > 2x friction** + parameter plateau verified → long to BB middle. **RANGING only. 8-source (2 academic) evidence base. Ungated: −97.5pp vs B&H (PMC9920669). 4h regime-gated: Sharpe 5.13, WR 60%, PF 2.09. Friction erodes Sharpe ~47%. OOS > 30% degradation = reject. Sub-1h TF lethal.** | evidence | assumed | YujiRegimeStrategy.py range_entry; YujiMultiSignalStrategy.py buy_1 (needs regime gate) |
| [ema-pullback-dynamic-support](freqtrade/prims/sophisticated/ema-pullback-dynamic-support.md) | EMA alignment >= 3 + ADX 25–35 (rising) + **first pullback to 21 EMA only** + 4h bullish + bullish candle + MACD hist rising + RSI 40–65 + volume > 0.8x SMA + fixed stop below swing low → long. **TRENDING only. 8-source evidence base. PF ~2.0, WR ~48%, 25–50% OOS degradation expected. ATR trailing stop DESTROYS edge (PF 0.603).** | evidence | assumed | YujiTrendRiderStrategy.py buy_pullback |
| [liquidity-sweep-reversal](freqtrade/prims/sophisticated/liquidity-sweep-reversal.md) | Wick >= 0.3% below swing low + bullish close + next-candle confirmation + CVD divergence (filter only) + volume > 1.2x SMA + within 2% of VP POC/VAL + ADX < 30 + BTC/ETH + fixed stop below wick low + R:R >= 1:2 → long. **RANGING-TO-MILD-TREND only. 9-source evidence base. WR 68% n=2,847 (BTC/ETH/alts 2022–2025), PF 1.92. Realistic live WR 55–62% after OOS degradation. CVD alone underperforms; strong trend = genuine breakdown.** | evidence | assumed | YujiSmartMoneyStrategy.py buy_sweep |

---

## Polymarket Prims

### Naive
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [binary-arb-completeness](polymarket/prims/naive/binary-arb-completeness.md) | YES+NO < $0.995 → buy both sides for risk-free profit if both fill | hypothesis | assumed | src/strategies/arb.py |
| [spread-capture-market-making](polymarket/prims/naive/spread-capture-market-making.md) | Spread $0.03–$0.15 + liquidity >= $5k → place inside-spread limit orders on both sides to capture spread | guess | assumed | src/strategies/spread.py |
| [ensemble-forecast-edge](polymarket/prims/naive/ensemble-forecast-edge.md) | GFS ensemble prob - market price >= 8% → buy the mispriced bracket, sized via fractional Kelly | guess | assumed | src/weather/strategy.py |
| [fractional-kelly-sizing](polymarket/prims/naive/fractional-kelly-sizing.md) | ~~Size = 15% of full Kelly × bankroll, capped at min(5% bankroll, $100)~~ — **SUPERSEDED** by intermediate | hypothesis | assumed | src/weather/strategy.py |

### Intermediate
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [spread-capture-market-making](polymarket/prims/intermediate/spread-capture-market-making.md) | Inside-spread maker quotes + **fee-aware category filter** (geopolitics=0% > sports=3% > politics=4% > weather=5%) + **Avellaneda-Stoikov reservation price in logit space** (r_x = x_mid - q*gamma*sigma_b^2*(T-t)) + **inventory limits** (\|q\| < 5% bankroll/price) + **T-t > 24h** filter + **500ms refresh cycle** + adverse selection guard (cancel on >3% move/min). Industry benchmark: ~0.2% of volume captured as profit; $150-300/day per liquid market at professional scale. | hypothesis | assumed | src/strategies/spread.py |
| [fractional-kelly-sizing](polymarket/prims/intermediate/fractional-kelly-sizing.md) | Fraction tier: 0.50 Kelly (calibrated edge, Brier ≤ 0.30) or 0.25 Kelly (uncalibrated). Concurrent-bet scalar: 1/sqrt(N). 20% drawdown circuit-breaker halves sizes. Fee-adjusted odds formula. 5% bankroll cap (replaces $100 hard cap). | evidence | assumed | src/weather/strategy.py → src/risk/kelly.py |

### Sophisticated
<!-- Auto-populated by tradepractice analyst -->

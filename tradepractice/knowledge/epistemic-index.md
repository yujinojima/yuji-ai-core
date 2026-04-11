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
| [bullish-rsi-divergence](freqtrade/prims/naive/bullish-rsi-divergence.md) | ~~Price rolling-low LL + RSI(14) rolling-low HL (>= 5pt) + RSI < 40 + close < BB mid + stoch turning up → long. **PMC9920669 rates it LEAST EFFECTIVE RSI variant; counterproductive on rising BTC/ETH.**~~ — **SUPERSEDED** by intermediate | guess→hypothesis | assumed | YujiDivergenceStrategy.py (lines 107–190) |
| [hidden-bullish-rsi-divergence](freqtrade/prims/naive/hidden-bullish-rsi-divergence.md) | ~~Confirmed uptrend (EMA50>EMA200, ADX≥20) + price HL + RSI(14) LL on same pivot pair (5–30 candle separation, gap ≥3pt) + close holds pivot-2 low → long to prior swing high.~~ — **SUPERSEDED** by intermediate | guess→hypothesis | assumed | YujiDivergenceStrategy.py |
| [capitulation-exhaustion-reversal](freqtrade/prims/naive/capitulation-exhaustion-reversal.md) | ~~N ≥ 5 consecutive red candles + volume > 3× SMA + RSI(14) < 20 + MFI(14) < 12 + reversal candle (bullish close after red run) + price below 2.5σ BB → long to BB middle. **Wyckoff Selling Climax / ABA Extinction Burst. 6th regime axis: panic capitulation. No regime gate in current code. Parameters untuned. No peer-reviewed crypto anchor.**~~ — **SUPERSEDED** by intermediate | guess→hypothesis | untested | YujiExtinctionBurstStrategy.py (lines 194–206) |

### Intermediate
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [rsi-oversold-mean-reversion](freqtrade/prims/intermediate/rsi-oversold-mean-reversion.md) | RSI(14) < 30 + RANGING regime (ADX < 20) + price > 1h EMA200 + confirming oscillator + volume → long to BB middle. **Does NOT work in trending crypto markets.** | hypothesis | assumed | YujiRegimeStrategy.py range_entry (lines 185–194) |
| [ema-pullback-dynamic-support](freqtrade/prims/intermediate/ema-pullback-dynamic-support.md) | EMA alignment >= 3 + ADX 25–35 (rising) + first/second pullback to 21 EMA + 4h bullish + bullish candle + MACD hist rising → long. **TRENDING regime only. Mirror complement to RSI mean reversion.** | hypothesis | assumed | YujiTrendRiderStrategy.py buy_pullback (lines 193–202) |
| [liquidity-sweep-reversal](freqtrade/prims/intermediate/liquidity-sweep-reversal.md) | Wick >= 0.3% below swing low + close above + CVD divergence + near VP level (POC/VAL) + volume spike + **RANGING-TO-MILD-TREND regime (ADX < 30)**. Exploits trapped breakout shorts at structural levels. | hypothesis | assumed | YujiSmartMoneyStrategy.py (lines 188–197) |
| [bullish-rsi-divergence](freqtrade/prims/intermediate/bullish-rsi-divergence.md) | ~~**True 5-bar pivot** (10–60 candle separation) + **REQUIRED double divergence** + regime exclusion + next-candle structure break + volume declining + 4h primary + divergence throttle + R:R ≥ 1:2.~~ — **SUPERSEDED** by sophisticated | hypothesis | no | YujiDivergenceStrategy.py (lines 107–190) |
| [hidden-bullish-rsi-divergence](freqtrade/prims/intermediate/hidden-bullish-rsi-divergence.md) | ~~**EMA ribbon ≥ 3 aligned** + ADX 20–45 rising + **true 5-bar pivot** HL/LL pair (8–40 candles, RSI LL **≥ 30**) + **Fib pullback ≤ 50%** + **MACD hist ≥ 0** + **volume declining** + **next-candle confirmation** + **hard mutual exclusivity** + 4h primary + R:R ≥ 1:1.5 → long to prior swing high.~~ — **SUPERSEDED** by sophisticated | hypothesis | no | YujiDivergenceStrategy.py |
| [capitulation-exhaustion-reversal](freqtrade/prims/intermediate/capitulation-exhaustion-reversal.md) | ~~**Prior trend gate** (price > EMA200_1h.shift(20) AND 4h EMA200 slope ≥ 0 in last 30 bars) + **speed gate** (≥ 15% decline from 20-bar high in ≤ 5 bars) + ADX_4h < 40 + N ≥ 5 consecutive reds + volume > 3× SMA + RSI < 20 + MFI < 12 + **next-candle confirmation** + **fixed stop** below wick low → long. **Panic capitulation regime only. Single-tier. Requires prior uptrend per Wyckoff SC mechanism.**~~ — **SUPERSEDED** by sophisticated | hypothesis | no | YujiExtinctionBurstStrategy.py (extinction_burst tier, lines 194–206) |

### Sophisticated
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [rsi-oversold-mean-reversion](freqtrade/prims/sophisticated/rsi-oversold-mean-reversion.md) | RSI(14) **25–35 plateau** (NOT magic threshold) + RANGING (ADX < 20 AND BBW pctl < 40) + price > 1h EMA200 + confirming oscillator + volume > 0.8x SMA + BTC/ETH 4h primary + **fee+slippage-adjusted edge > 2x friction** + parameter plateau verified → long to BB middle. **RANGING only. 8-source (2 academic) evidence base. Ungated: −97.5pp vs B&H (PMC9920669). 4h regime-gated: Sharpe 5.13, WR 60%, PF 2.09. Friction erodes Sharpe ~47%. OOS > 30% degradation = reject. Sub-1h TF lethal.** | evidence | assumed | YujiRegimeStrategy.py range_entry; YujiMultiSignalStrategy.py buy_1 (needs regime gate) |
| [ema-pullback-dynamic-support](freqtrade/prims/sophisticated/ema-pullback-dynamic-support.md) | EMA alignment >= 3 + ADX 25–35 (rising) + **first pullback to 21 EMA only** + 4h bullish + bullish candle + MACD hist rising + RSI 40–65 + volume > 0.8x SMA + fixed stop below swing low → long. **TRENDING only. 8-source evidence base. PF ~2.0, WR ~48%, 25–50% OOS degradation expected. ATR trailing stop DESTROYS edge (PF 0.603).** | evidence | assumed | YujiTrendRiderStrategy.py buy_pullback |
| [liquidity-sweep-reversal](freqtrade/prims/sophisticated/liquidity-sweep-reversal.md) | Wick >= 0.3% below swing low + bullish close + next-candle confirmation + CVD divergence (filter only) + volume > 1.2x SMA + within 2% of VP POC/VAL + ADX < 30 + BTC/ETH + fixed stop below wick low + R:R >= 1:2 → long. **RANGING-TO-MILD-TREND only. 9-source evidence base. WR 68% n=2,847 (BTC/ETH/alts 2022–2025), PF 1.92. Realistic live WR 55–62% after OOS degradation. CVD alone underperforms; strong trend = genuine breakdown.** | evidence | assumed | YujiSmartMoneyStrategy.py buy_sweep |
| [bullish-rsi-divergence](freqtrade/prims/sophisticated/bullish-rsi-divergence.md) | True 5-bar pivot (10–60 candle separation) + **REQUIRED double divergence** (RSI HL AND MACD-hist HL) + regime exclusion (NOT persistent uptrend: EMA200 slope > 0 AND ADX > 35) + next-candle structure break + volume declining + 4h primary + divergence throttle + **fee+slippage-adjusted edge ≥ 2× friction** + parameter plateau verified (PF variance < 25% across 5×4 grid) + CPCV+DSR multiple-testing correction + BTC/ETH whitelist excludes uptrend phase + R:R ≥ 1:2. **EXHAUSTION/LATE-BEAR only. 11-source basis with PUBLISHED NEGATIVE EVIDENCE at parent root (PMC9920669 LEAST EFFECTIVE RSI variant). WR ladder: naive 33% → confluence 65% → MACD+RSI double 73% (equity n=235) → realistic crypto target 52–58% → live lower bound 48–52%. Friction Sharpe erosion ~47%; sub-1h lethal. Sophisticated tier means failure modes are quantified and falsification path is exact, NOT that the prim works. If plateau test fails, mark as anti-prim.** | evidence (negative-anchored) | no | YujiDivergenceStrategy.py (12 implementation gaps inc. plateau test + DSR correction) |
| [hidden-bullish-rsi-divergence](freqtrade/prims/sophisticated/hidden-bullish-rsi-divergence.md) | **EMA ribbon ≥ 3 aligned** + ADX 20–45 rising + price > 1h EMA200 + **true 5-bar pivot** HL/LL pair (8–40 candles, RSI LL **≥ 30**) + **Fib pullback ≤ 50% of prior impulse** + **MACD hist ≥ 0 at pivot-2** + **volume at pivot-2 ≤ 50% of impulse peak** (Wyckoff test) + **next-candle confirmation** + **hard mutual exclusivity** + 4h primary + **fee+slippage-adjusted edge > 2× friction** + **parameter plateau verified** (PF variance < 25% across 28-cell grid) + **CPCV + DSR correction applied** + **R:R ≥ 1:2** → long to prior swing high. **TRENDING MOMENTUM only. Trend-continuation mirror of sister prim; covers regime sister EXCLUDES. 13-source basis. NO published negative evidence (unlike sister). Mechanistic alignment with PMC9920669 WINNING side (RSI>50 momentum: +498pp vs B&H). Expected live WR 55–62% (50–55% post-OOS) — premium over sister's 52–58% from trend-continuation vs reversal mechanism. Signal < 0.5% of candles. Friction erodes Sharpe ~47%. 28-cell plateau test mandatory; CPCV+DSR required. Anti-prim if plateau fails OR head-to-head shows hidden WR ≤ regular WR in trend regime.** | hypothesis (no counter-evidence; no positive peer-reviewed anchor) | no | YujiDivergenceStrategy.py (12 implementation gaps inc. BLOCKING plateau test + DSR correction) |
| [capitulation-exhaustion-reversal](freqtrade/prims/sophisticated/capitulation-exhaustion-reversal.md) | **Prior trend gate** + **dual speed gate** (10%/≤5 bars mature-market OR 15%/≤10 bars legacy) + ADX_4h < 40 + N ≥ 5 reds + volume > 3× SMA + RSI < 20 + MFI < 12 + next-candle confirmation + **dynamic position sizing** (2% bankroll / |entry − wick_low|) + **5-pair pool** (BTC, ETH + 3 correlated majors) + R:R ≥ 1:3. **PANIC CAPITULATION only. 6th regime axis. 8-source basis (ZERO peer-reviewed crypto anchor at any tier). Signal frequency: 1-2/year BTC alone; 5-10/year 5-pair pool; N_eff ≈ 1.3 per panic event (ρ≈0.90). Statistical floor: n_eff=50 requires 4-8 year multi-asset deployment. Crash amplitude declining per cycle (87%→84%→77%→50%) — structural anti-prim risk if BTC matures past threshold. Friction ~47% Sharpe erosion; slippage-dominant. 27-cell plateau test mandatory; DSR required. THREE anti-prim escape hatches: (A) frequency collapse n<15 in 5y, (B) speed plateau fails, (C) live WR < 48%.** | hypothesis (zero positive quantitative anchor; structured failure modes) | no | YujiExtinctionBurstStrategy.py (9 implementation gaps inc. dual speed gate, dynamic sizing, multi-asset whitelist) |

---

## Polymarket Prims

### Naive
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [binary-arb-completeness](polymarket/prims/naive/binary-arb-completeness.md) | ~~YES+NO < $0.995 → buy both sides for risk-free profit if both fill~~ — **SUPERSEDED** by intermediate | hypothesis | assumed | src/strategies/arb.py |
| [spread-capture-market-making](polymarket/prims/naive/spread-capture-market-making.md) | ~~Spread $0.03–$0.15 + liquidity >= $5k → place inside-spread limit orders on both sides to capture spread~~ — **SUPERSEDED** by intermediate | guess | assumed | src/strategies/spread.py |
| [obi-informed-directional](polymarket/prims/naive/obi-informed-directional.md) | ~~IR = (V_bid−V_ask)/(V_bid+V_ask) > +0.65 → BUY YES; IR < −0.65 → BUY NO. Hold until IR < 0.30 or 30min. **5th prim: pure CLOB microstructure directional. Complementary to spread-capture (activates when MM exits). 58% accuracy at IR>0.65 (Bawa, arxiv 2603.03152). No own-data backtest. Wash-trading contamination is #1 risk (20–60% of Polymarket volume).**~~ — **SUPERSEDED** by intermediate | hypothesis | untested | src/strategies/obi.py |
| [ensemble-forecast-edge](polymarket/prims/naive/ensemble-forecast-edge.md) | ~~GFS ensemble prob - market price >= 8% → buy the mispriced bracket, sized via fractional Kelly~~ — **SUPERSEDED** by intermediate | guess | assumed | src/weather/strategy.py |
| [fractional-kelly-sizing](polymarket/prims/naive/fractional-kelly-sizing.md) | ~~Size = 15% of full Kelly × bankroll, capped at min(5% bankroll, $100)~~ — **SUPERSEDED** by intermediate | hypothesis | assumed | src/weather/strategy.py |

### Intermediate
| Name | Rule | Certainty | Reaction Validated | File |
|------|------|-----------|-------------------|------|
| [binary-arb-completeness](polymarket/prims/intermediate/binary-arb-completeness.md) | ~~Category-fee-adjusted gap (`2 × fee_rate × p × (1−p) + buffer`) + gap age <90s + binary-only (no neg_risk) + less-liquid-leg-first execution + 5s second-leg timeout + cancel-and-unwind on partial fill. Geopolitics 0% fee → pure gap; sports 3% → need 2%+ gap; crypto 7.2% → need 4%+ gap. Lockup cost: 0.0137%/day.~~ — **SUPERSEDED** by sophisticated | hypothesis | no | src/strategies/arb.py |
| [spread-capture-market-making](polymarket/prims/intermediate/spread-capture-market-making.md) | ~~Inside-spread maker quotes + fee-aware category filter + A-S reservation price in logit space + inventory limits + T-t > 24h filter + 500ms refresh cycle + adverse selection guard.~~ — **SUPERSEDED** by sophisticated | hypothesis | assumed | src/strategies/spread.py |
| [fractional-kelly-sizing](polymarket/prims/intermediate/fractional-kelly-sizing.md) | ~~Fraction tier: 0.50 Kelly (calibrated edge, Brier ≤ 0.30) or 0.25 Kelly (uncalibrated). Concurrent-bet scalar: 1/sqrt(N). 20% drawdown circuit-breaker halves sizes. Fee-adjusted odds formula. 5% bankroll cap (replaces $100 hard cap).~~ — **SUPERSEDED** by sophisticated | evidence | assumed | src/weather/strategy.py → src/risk/kelly.py |
| [ensemble-forecast-edge](polymarket/prims/intermediate/ensemble-forecast-edge.md) | ~~≥ 2 NWP model consensus (GFS + ECMWF) + Gaussian bracket Φ-formula (not raw member count) + horizon-gated edge (5% day 1–2, 10% day 3–5) + station-gridpoint nearest-neighbor correction + model staleness guard (< 6h) + fee-adjusted net edge computation.~~ — **SUPERSEDED** by sophisticated | hypothesis | assumed | src/weather/strategy.py |
| [obi-informed-directional](polymarket/prims/intermediate/obi-informed-directional.md) | ~~**Wash-adjusted IR**: `IR_clean = (V_bid_5s − V_ask_5s)/(V_bid_5s + V_ask_5s)` (orders resting ≥ 5s; wash traders cancel in ms) + **liquidity-tiered threshold**: thin ($2k–$5k) IR_clean > 0.80; mid ($5k–$50k) IR_clean > 0.65; skip >$50k (bots <200ms) + **category-specific hold**: politics/finance 15–30min; geopolitics 30–60min + **sports/crypto excluded** (sports 45% wash; crypto 7.2% fee). 4-source basis: Columbia 25% avg wash, arxiv 2507.22712 filtration, arxiv 2603.03152 VR drift, Bawa 58% mid-liquidity claim. Minimum liquidity raised to $2k. State machine: activates when MM prim exits at |IR| ≥ 0.65.~~ — **SUPERSEDED** by sophisticated | hypothesis | no | src/strategies/obi.py |

## Polymarket Prims — Sophisticated

| Prim | Rule Summary | Certainty | Reaction Validated | Implementation |
|------|-------------|-----------|-------------------|----------------|
| [fractional-kelly-sizing](polymarket/prims/sophisticated/fractional-kelly-sizing.md) | α tier from calibration RMSE: <5% (N≥50)→0.50; 5–12% (N≥30)→0.25; >12% or N<30→0.10 (analytically derived from KL-divergence loss Δg≈ε²/2p(1−p)). Portfolio N_eff=N/(1+(N−1)·ρ̄) replaces 1/sqrt(N). Horizon discount: edge_adj=edge_gross−0.05·T/365. Circuit-breaker NORMAL/REDUCED/PAUSED (persisted). No dollar cap — 5% bankroll cap scales with actual USDC balance. | evidence | assumed→untested | src/risk/kelly.py |
| [spread-capture-market-making](polymarket/prims/sophisticated/spread-capture-market-making.md) | A-S logit-space with **dynamic σ_b²=p(1−p)** + **γ(t) ∝ 1/(T−t)** + **Kyle λ maturation gate** (reject λ>0.05) + **category-specific adverse selection windows** (sports <5min, politics 15–60min) + **inventory decay Position(t)=Initial×sqrt(T_remaining/T_initial)** + **maker rebate model (40–60% of revenue)** + 50% wash-trading haircut. Target: Sharpe 2.0–2.8, $200–800/day at $10k capital, 52–58% WR. 10-source evidence base (3 academic). | evidence | assumed→untested | src/strategies/spread.py |
| [ensemble-forecast-edge](polymarket/prims/sophisticated/ensemble-forecast-edge.md) | **ECMWF+GFS consensus** (directional gap ≤ 2°C) + model run < 6h + **ensemble_std ≤ 3°C** + **station distance ≤ 15km** (≤ 5km complex terrain) + **EMOS-calibrated** Φ (or 1.2× fallback) + **horizon-gated net edge** (≥ 7% day 1–2, ≥ 12% day 3–5, skip day 6+) + **market efficiency clear** (skip if liq > $50k AND spread < $0.02) + WR gate ≥ 58% + Kelly sizing. WR ladder: Day 1 ~85% → Day 2 ~75% → Day 3 ~65% → Day 4–5 ~55% → Day 6+ ~50%. Friction: 5% fee, 0% rebate → min WR 52.5%. GEFS seasonal cold bias −0.5–1°C summer continental. 9-source basis. Edge compressing ~30%/yr (competition). Anti-prim if rolling edge < 5% (market saturation) or own-data WR < 55% (day 1–2). | hypothesis | no | src/weather/strategy.py (8 implementation gaps) |
| [binary-arb-completeness](polymarket/prims/sophisticated/binary-arb-completeness.md) | **APY-gated edge floor** (`max(2×fee_rate×p(1−p)+0.005, 0.24×T_days/365)`) + **tiered gap age** (<30s=tier-1; 30–90s=tier-2 depth-verify; >90s=reject) + binary-only (neg_risk=False) + **depth ceiling** (min(depth_yes,depth_no)×0.90) + less-liquid leg first + 5s timeout + cancel-and-unwind + **combinatorial scope** (multi-market exhaustive sets ΣP<$0.995). Median gap age 2026: 2.7s (from 12.3s 2024); 73% profits by <100ms bots. Viable window: tier-2 structural illiquidity. Anti-prim if median gap age < 3s AND >80% close in <5s. 6-source basis ($40M extracted Apr2024–Apr2025, IMDEA arxiv 2508.03474). | hypothesis | no | src/strategies/arb.py (9 implementation gaps) |
| [obi-informed-directional](polymarket/prims/sophisticated/obi-informed-directional.md) | **Parent-order lifetime filter** (order tracked via CLOB WS: resting ≥ 5s AND modification_count ≤ 2; "parent-order filtration = systematically stronger" vs "aggregate filtration = modest") + **persistent-OBI targeting** (NOT first-mover; 3–5 consecutive 10s snapshots = 30–50s sustained = residual after HFT consumed initial signal; latency rank, not magnitude, determines OBI profit) + **λ-adaptive confirmation** (mature λ<0.05: 3 snapshots; thin λ>0.05: 5 snapshots) + **IR_clean > 0.70** mid-liquidity (raised from 0.65 for Paradigm double-count correction; 25% conservative wash floor) + geopolitics/politics only; sports/crypto excluded. EV: 0% fee → +0.16/unit at 58% WR; 4% fee → +0.12/unit. 3 anti-prim escape hatches (latency saturation; category wash contamination; taker delay removal). 8-source basis (2 academic on OBI latency/filtration). | hypothesis | no | src/strategies/obi.py (7 implementation gaps; parent-order tracking BLOCKING) |

### Sophisticated
<!-- Auto-populated by tradepractice analyst -->

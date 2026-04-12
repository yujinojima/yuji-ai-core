---
prim: realized-volatility-term-structure
project: freqtrade
level: intermediate
cycle: 103
axis: 14th regime axis
signal-class: volatility regime classifier via RV term structure slope (meta-signal)
parent: freqtrade/prims/naive/realized-volatility-term-structure.md
created: 2026-04-12
superseded-by: null
---

# Realized Volatility Term Structure (Intermediate)

## Mechanism

Crypto perpetuals exhibit GARCH-persistent volatility clustering: Bitcoin GARCH(1,1) α+β = 0.968 (Katsiampa 2017), near-unit-root. Vol shocks diffuse into the term structure non-uniformly — short-window RV responds immediately to shocks, long-window RV adjusts slowly. The slope of the realized vol curve (`RV_S / RV_L`) is therefore a stable, lagging indicator of vol regime state.

**Contango slope** (`RV_ratio < threshold`): short vol has subsided faster than long-run RV can adjust. The vol surface is compressing. In the presence of an established uptrend (agents have directional conviction), compression precedes expansion in the trend direction — the spring-load mechanism. In the absence of a trend, compression is ambiguous (type-B: downtrend congestion) or null (type-C: 2019-style low-vol drift with no expansion forthcoming).

**Inverted slope** (`RV_ratio > threshold`): short vol exceeds long-run RV. A recent vol event has occurred. HAR-RV theory (Corsi 2009) predicts mean reversion in vol. Price mean reversion is NOT guaranteed — it depends on whether the vol event was trend-creating (ADX rising = trending crash, no suppression) or oscillation-amplifying (ADX falling = overextension, suppress longs).

**Core intermediate insight**: the naive prim treated coiling as directionally unambiguous. It is not. The same `RV_ratio < 0.60` occurs in three regimes:
- **(A)** Uptrend coiling → breakout in trend direction (valid amplification)
- **(B)** Downtrend congestion → breakdown, not coiling (opposite of intended)
- **(C)** Low-vol drift, no trend → no vol expansion forthcoming for weeks (null signal)

The prior 4h EMA200 slope gate is the **mechanism-activating precondition** — not a refinement. Without it, type-B and type-C contaminate the signal pool. This is structurally identical to the prior-uptrend gate in capitulation-exhaustion-reversal: the gate is what makes the mechanism fire, not a filter on an already-firing mechanism.

## Signal Definition

As established in naive:
- `RV_S` = `std(log(close / close.shift(1)), window=24) * sqrt(365 * 24)` (1h bars, 24-bar ≈ 1-day annualised)
- `RV_L` = same formula, `window=168` (7-day annualised)
- `RV_ratio` = `RV_S / RV_L`

Hyperopt parameter ranges (to be plateau-verified at sophisticated tier):
- `rv_coiling_threshold` ∈ [0.40, 0.70], default 0.60
- `rv_hot_threshold` ∈ [1.30, 1.80], default 1.50
- `rv_hot_rsi_threshold` ∈ [30, 45], default 40
- **NEW: `rv_coiling_slope_bars`** ∈ [2, 5], default 3 — bars over which ratio must be declining to qualify as "actively compressing" vs stable plateau

## Entry Conditions (Intermediate)

### A. Coiling regime → sister prim amplification

ALL of:
1. `RV_ratio < rv_coiling_threshold` (contango: short vol compressed vs long-run)
2. `rv_ratio.shift(rv_coiling_slope_bars) > rv_ratio` — ratio DECLINING (compression deepening, not plateauing)
3. **`ema_200_4h > ema_200_4h.shift(20)`** — 4h EMA200 slope positive (prior uptrend gate, MANDATORY)
4. `adx_4h < 40` — not parabolic
5. Coiling episode persistence: `rv_ratio < rv_coiling_threshold` for ≥ 5 consecutive bars (prevents false-alarm entries from 1–2 bar ratio dips)

**→ Effect:** Amplify all sister prim long entries 1.15× for 24h (meta-signal; does NOT generate standalone entries at intermediate tier)

**BBW dual-confirmation rule:** If bollinger-squeeze-breakout axis is simultaneously active (`bbw_pctl < 0.20` with ≥ 8-bar squeeze), apply amplification to the squeeze prim's entry signal specifically (1.15× additional to any existing squeeze prim weight). The two axes independently confirm vol compression from different measurement frameworks (log-return SD ratio vs price SD percentile rank) — convergence strengthens the release signal.

**Hard exclusion:** If `rv_regime_coiling = 1` AND `rv_regime_hot = 1` simultaneously (should not occur given thresholds, but guard against NaN/warmup distortion), take NO action and log anomaly.

### B. Hot regime → sister prim suppression

ALL of:
1. `RV_ratio > rv_hot_threshold` (inverted: short vol elevated vs long-run)
2. `RSI_14 < rv_hot_rsi_threshold` (price already distressed — not in active impulse)
3. `ADX_4h < 35` — oscillation, not trending crash (see exception below)
4. NOT capitulation-exhaustion-reversal conditions active (hard exclusion: CER takes priority in panic regimes; do not double-suppress)

**→ Effect:** Suppress sister prim long entries 0.85× for 24h

**ADX exception (trending crash bypass):** If `RV_ratio > rv_hot_threshold` AND `ADX_4h ≥ 35`, do NOT apply suppression. High vol in a strong directional move is trend-creating (vol is expanding in the direction of the trend). Suppression would cause missed recovery entries after the trend exhausts. CER and capitulation signals handle this case.

## Agent Behaviour Model

### Coiling regime
- **Short-term traders:** reduced activity as tight range offers insufficient intrabar R:R; vol sellers dominate, compressing realised vol below long-run average
- **Positioning agents:** accumulating at structural levels while price oscillates in tight range; stops cluster near range extremes
- **Market makers:** tight spreads → passive LP concentration at key levels → any directional break triggers cascading stop fills
- **Who is trapped when coiling breaks:** agents who placed tight stops near range centre (the majority in low-vol regimes); they must exit, providing fuel for the initial move
- **Signal quality:** highest in trending coiling (type-A) because trapped agents are on ONE side (trend-against positions); lowest in neutral coiling (type-C) where trapped agents are balanced on both sides

### Hot regime
- **Vol sellers:** covering short-vol positions after being caught by vol expansion → pushes short-window RV above long-run level
- **Late retail:** chasing momentum into the vol spike; late entries in RSI-oversold zone
- **Liquidation cascade agents (OI):** overlaps with OI-price divergence prim's mechanism
- **Who is wrong:** late retail longs in the distressed RSI zone provide mean-reversion fuel; the vol spike has already run its course when `RV_ratio > 1.5 AND RSI < 40`

## Academic Anchors

**1. Corsi (2009) Journal of Financial Econometrics — HAR-RV**  
The Heterogeneous Autoregressive model of Realized Volatility decomposes RV into daily, weekly, and monthly components — equivalent to measuring the slope of the RV term structure at multiple horizons. The daily/weekly RV ratio (our `RV_S / RV_L` at 24/168 bars) is Corsi's primary in-sample predictor of the next-period vol regime. R² = 0.47 (daily prediction), 0.65 (weekly), 0.71 (monthly). This is the primary theoretical mandate: term structure slope is not a heuristic indicator but a statistically grounded regime classifier with documented predictive power in volatility dynamics.

**2. Andersen, Bollerslev, Diebold & Labys (2001) JASA — RV distributional properties**  
Established that realised volatility is approximately lognormal, exhibits long-memory (fractional integration), and that the term structure slope (`RV_short / RV_long`) is autocorrelated with half-life ≈ 5–10 days for equities. The implication for crypto (α+β=0.968): contango episodes persist 10–20 days before breaking, and inverted episodes mean-revert similarly slowly. This is the quantitative basis for the 5-bar persistence requirement in condition A5 — a 1–2 bar ratio dip is within the noise band of the lognormal distribution, not a genuine regime.

**3. Bollerslev, Tauchen & Zhou (2009) Review of Financial Studies — Variance risk premium**  
Documents that the variance risk premium (implied vol > realised vol) is elevated following hot-regime vol spikes and predicts positive forward returns 1–3 months in equities. The inverse relationship: vol spike → agents overpay for variance insurance → vol mean-reverts → prices stabilise → mean-reversion bias in subsequent price action. This is the mechanism underlying the hot-regime suppression signal: `RV_ratio > 1.5` marks the peak of the variance overpayment cycle, after which the edge is on mean reversion, not continuation. Primary equity mechanism; crypto analog structurally plausible given institutional crypto options expansion post-Deribit 2022 becoming liquid.

**4. Katsiampa (2017) Finance Research Letters — Bitcoin GARCH(1,1)**  
BTC: α=0.149, β=0.820, α+β=0.968 (near unit-root volatility). Half-life of vol shock: ≈ 23 trading days (vs 10–14 for equities). Direct implications for this prim: (a) contango episodes persist longer — G1 frequency scan should show coiling periods of 10–25+ days; (b) hot-regime vol spikes overshoot further from long-run mean, making mean-reversion expectation stronger; (c) the compression→expansion transition is sharper in amplitude when it fires, justifying 1.15× amplification (not just 1.05×).

**5. Bekaert & Hoerova (2014) Journal of Monetary Economics — VIX term structure as regime classifier**  
Documents that the slope of the VIX term structure (short-dated vs long-dated implied vol) classifies macroeconomic regimes (inverted = crisis, contango = stable) and is used directly in central bank risk monitoring. This is the theoretical template establishing that vol term structure slope → regime classification is a cross-asset, institutionally-validated methodology — not an analogy imported from equity price patterns. The mechanism (short vol elevated in crisis = risk-off agents paying for near-term protection) is the same as `RV_ratio > 1.5` = recent vol event compressed into short window.

## BBW Independence Argument (Theoretical; G4 Empirical Confirmation at Sophisticated)

The two axes diverge in two scenarios that establish mechanistic distinctness:

**Scenario A: Post-crash stabilisation (disagreement direction: RV hot, BBW neutral)**
- Crash completes; price stops falling, oscillates in tight range
- BBW: fell from crash-elevated reading → now 30th–50th pctl (not squeeze territory; no BBW signal)
- `RV_ratio`: still > 1.50 (24-bar window still contains the crash vol; hasn't decayed out)
- Disagreement: BBW says "neutral regime"; RV says "hot regime, suppress longs 0.85×"
- The RV axis provides regime context that BBW cannot: the crash's short-window vol echo is still present and mean reversion is the expected path, regardless of price oscillation compression

**Scenario B: Low-vol drift (disagreement direction: RV coiling, BBW neutral)**
- BTC 2019-style grind: price trends upward slowly with minimal intrabar oscillation
- BBW: 35th–45th pctl (moderate; no squeeze threshold triggered)
- `RV_ratio`: 0.42 (clear contango — short vol has dropped well below long-run average)
- Prior trend gate: 4h EMA200 slope positive (type-A, not type-C)
- Disagreement: BBW says "neutral"; RV says "coiling + uptrend = amplify entries 1.15×"
- BBW misses this episode entirely; the RV axis captures the vol surface compression that doesn't appear in price SD terms

Theoretical Spearman ρ(RV_coiling, BBW_squeeze) estimate: < 0.50, based on these divergence scenarios and the distinct measurement frameworks (log-return SD ratio vs price SD percentile rank). G4 empirical confirmation required at sophisticated elevation (threshold: ρ < 0.70 for axis independence).

## Implementation Changes from Naive

| Gap | Naive code | Intermediate code |
|---|---|---|
| Prior trend gate | None | `ema_200_4h > ema_200_4h.shift(20)` hard gate on coiling amplification |
| Compression momentum | None | `rv_ratio.shift(rv_coiling_slope_bars) > rv_ratio` (declining ratio required) |
| Episode persistence | None | `rv_ratio < rv_coiling_threshold` for ≥ 5 consecutive bars (prevents 1–2 bar false alarms) |
| Hot-regime ADX exception | None | `adx_4h < 35` required for suppression; skip entirely if ADX_4h ≥ 35 |
| CER hard exclusion | None | `NOT (caper_signal_active == 1)` on hot suppression |
| BBW dual-confirmation | None | If `bbw_squeeze_active = 1` simultaneously → amplify squeeze prim 1.15× (not independent entry) |
| Entry architecture | Standalone (naive) | Meta-signal only — no standalone entries at intermediate tier |
| Warmup NaN guard | None | `if dataframe['rv_long'].isna().sum() > 5: dataframe['rv_regime_coiling'] = 0` |

```python
# Intermediate implementation additions (in populate_indicators() after naive code)

# Warmup guard
warmup_mask = dataframe['rv_long'].isna() | (dataframe['rv_long'] < 1e-9)
dataframe.loc[warmup_mask, 'rv_regime_coiling'] = 0
dataframe.loc[warmup_mask, 'rv_regime_hot'] = 0

# Declining ratio gate (compression momentum)
dataframe['rv_ratio_declining'] = (
    dataframe['rv_ratio'].shift(self.rv_coiling_slope_bars.value) > dataframe['rv_ratio']
).astype(int)

# Episode persistence: rolling 5-bar count of coiling bars
dataframe['rv_coiling_persistent'] = (
    dataframe['rv_regime_coiling'].rolling(5).sum() >= 5
).astype(int)

# Final intermediate coiling gate (used in sister prim amplification)
# ema_200_4h populated via informative_pairs 4h
dataframe['rv_coiling_int'] = (
    dataframe['rv_coiling_persistent'] &
    dataframe['rv_ratio_declining'] &
    (dataframe['ema_200_4h'] > dataframe['ema_200_4h'].shift(20)) &
    (dataframe['adx_4h'] < 40)
).astype(int)

# Hot regime with ADX exception
dataframe['rv_hot_int'] = (
    dataframe['rv_regime_hot'] &
    (dataframe['rsi'] < self.rv_hot_rsi_threshold.value) &
    (dataframe['adx_4h'] < 35)  # skip in trending crash
).astype(int)
```

**Sister prim amplification in `populate_entry_trend()` (example, YujiRegimeStrategy.py):**
```python
# RV coiling amplification — apply 1.15x to signal weight where coiling active
# (implementation: multiply or add to entry score, not position size)
if 'rv_coiling_int' in dataframe.columns:
    amplify_mask = dataframe['rv_coiling_int'] == 1
    dataframe.loc[amplify_mask, 'entry_score'] *= 1.15
    # BBW dual-confirmation: if squeeze also active, apply to squeeze prim row
    dual_confirm = amplify_mask & (dataframe['bbw_pctl'] < 0.20)
    dataframe.loc[dual_confirm, 'squeeze_entry_score'] *= 1.15
```

## Failure Modes (Intermediate)

**F1: Sustained contango drift (HIGH severity)**  
BTC 2019-style grind: `RV_ratio < 0.60` for 60–90+ consecutive days. Amplification fires repeatedly; no vol expansion follows because regime is pure drift, not coiling before expansion. Mitigation: cap at 5 consecutive coiling episodes (rolling 14-day window) before suspending amplification for 7-day cooldown. `cumulative_coiling_episodes_14d > 5 → suspend`.

**F2: Type-C drift misclassified as type-A (HIGH severity)**  
4h EMA200 slope gate catches most, but if trend started recently (slope just crossed positive), the slope may be positive but weak. Add secondary check: `close > ema_200_4h` (price above EMA200, not just slope) as belt-and-suspenders against shallow positive-slope downtrends.

**F3: Fake compression then immediate rebound (MEDIUM severity)**  
`RV_ratio` declines for `rv_coiling_slope_bars` → amplification fires → ratio reverses above threshold next bar. Not a real compression episode. The 5-bar persistence requirement (A5) addresses this by requiring the below-threshold state to be sustained, but the `rv_ratio_declining` gate can fire without persistence. Ensure `rv_coiling_int` requires BOTH `rv_ratio_declining AND rv_coiling_persistent`.

**F4: Warmup NaN artifact (LOW severity — implementation)**  
First 168 bars of strategy runtime: `rv_long` is NaN. All bars appear as `RV_ratio = NaN → coiling`. The warmup guard in implementation resolves this, but must be applied BEFORE the rolling and shift operations.

## Blocking Gates for Sophisticated Elevation

**G1 (BLOCKING — frequency scan)**  
Target: how often does the refined coiling condition (`rv_ratio < 0.60 AND declining ≥ 3 bars AND 4h EMA200 slope positive AND 5-bar persistence`) fire on BTC/USDT:USDT 1h 2022–2026?  
Pass criterion: ≥ 15 qualifying episodes/year → n ≥ 60 over 4-year IS window.  
Measurement: `freqtrade download-data --pairs BTC/USDT:USDT --timeframe 1h` then offline scan.  
Fail → frequency collapse; relax `rv_coiling_slope_bars` to 2 and `persistence` to 3 bars, rescan. If still fails → type-A (uptrend coiling) is too rare for a standalone regime axis; collapse into BBW prim gate.

**G2 (BLOCKING — forward return test)**  
For each coiling episode onset bar t: compute 12h, 24h, 48h forward mean returns on BTC/USDT:USDT 1h vs unconditional forward returns in same-uptrend-slope periods.  
Pass criterion: Mann-Whitney U p < 0.05 at ≥ 1 horizon (primary: 24h). Null: coiling episodes show no difference vs baseline uptrend periods.  
Fail → no forward return uplift; RV coiling is not predictive of forward returns even in uptrend; retire as standalone amplification; relegate to decorative signal only.

**G3 (CONFIRMING — cross-pair generalisation)**  
Run G1 scan separately on BTC, ETH, SOL, BNB 1h 2022–2026.  
Pass criterion: `rv_coiling_threshold` requires ≤ ±0.15 adjustment from default 0.60 to maintain n ≥ 10/year per pair.  
Fail → threshold is pair-specific; narrow scope claim to BTC/ETH only (remove "asset class" scope claim; update Epistemic Status).

**G4 (CONFIRMING — BBW axis independence)**  
Compute Spearman ρ between `rv_coiling_int` binary signal and `bbw_squeeze` binary signal (BBW < 20th pctl for ≥ 8 bars) on BTC 1h 2022–2026.  
Pass criterion: ρ < 0.70.  
Fail (ρ ≥ 0.70) → signals are redundant; do NOT maintain axis 14 separately; collapse RV ratio into bollinger-squeeze-breakout prim as a secondary vol-surface gate (use as additional confirmation for BBW squeeze, not independent axis).

## Epistemic Status

- **Source:** theoretical — Corsi 2009 HAR-RV + 4 supporting academic anchors; no own crypto backtest
- **Certainty:** hypothesis (elevated from "guess" at naive; 5 academic anchors, 2 with direct vol-term-structure mechanism; no empirical validation)
- **Scope:** BTC/ETH perps, 1h bars, 2022–2026 regime (G3 cross-pair confirmation pending)
- **Falsifiability:** G1 n < 15/year → frequency collapse (anti-prim); G2 p ≥ 0.05 → no forward return anomaly (anti-prim); G4 ρ ≥ 0.70 → axis redundant (collapse into BBW prim)
- **Limitations:** RV is backward-looking (not implied vol); no crypto options pipeline; ratio unstable at near-zero vol floors (divide-near-zero → NaN guard essential); direction requires trend confirmation; not tested on assets other than BTC; entry architecture is meta-signal (no IS backtest of standalone edge yet)

## Refinement History

- **Cycle 101 (2026-04-12):** Created as naive prim; 14th regime axis; RV term structure slope classifier; code skeleton added to `YujiRegimeStrategy.py`; 4 blocking gates G1–G4 identified
- **Cycle 103 (2026-04-12):** Elevated to intermediate; prior trend gate added as MANDATORY mechanism precondition (not filter); declining ratio momentum gate formalised; 5-bar episode persistence requirement; hot-regime ADX exception (trending crash bypass); BBW dual-confirmation architecture; meta-signal structure adopted (no standalone entries — same pattern as funding-rate-crowding-reversal); 5 academic anchors (Corsi 2009, ABDL 2001, BTZ 2009, Katsiampa 2017, Bekaert-Hoerova 2014); 4 failure modes documented; G1–G4 blocking gates quantified with pass/fail criteria; warmup guard added

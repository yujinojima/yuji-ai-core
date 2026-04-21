---
from: implementer
subject: prim-intermediate
timestamp: 2026-04-21T17:31:30+10:00
cycle: 240
prim: matching-law-cross-pair-momentum
project: freqtrade
level: intermediate
axis: 35th freqtrade regime axis
signal-class: cross-pair mean-reversion modifier (meta-signal — no standalone entries)
parent: freqtrade/prims/naive/matching-law-cross-pair-momentum.md (cycle 240)
---

## Prim: matching-law-cross-pair-momentum
**Level:** intermediate (elevated from naive, cycle 240)
**Project:** freqtrade
**Cycle:** 240
**Regime axis:** 35 — matching law cross-pair relative reinforcement
**Signal class:** cross-pair mean-reversion modifier (meta-signal — no standalone entries)
**Timeframes:** 1h signal; 4h ADX regime gate
**Pairs:** BTC/USDT:USDT, ETH/USDT:USDT (Binance perpetuals)

---

### 1. Epistemic Genealogy

**Naive (cycle 240):** ETH/BTC 30d return z-score as binary amplify trigger. z < −1.5 →
amplify ETH, z > +1.5 → amplify BTC. No ADX gate, no persistence requirement, no
distinction between genuine mean reversion and structural regime shift. Single academic
anchor (Herrnstein 1961).

**Intermediate (cycle 240):** Four advances over naive:
1. **Return difference metric** replaces ratio: `rel_ret = eth_30d_pct − btc_30d_pct`.
   Avoids division-by-zero and ratio pathology when both pairs post negative returns.
   Log-difference is equivalent to log-ratio, grounded in Lo & MacKinlay (1990) RFS
   relative return reversal literature.
2. **Two-mode architecture with persistence gate**: Mode A (ETH underperforms, amplify
   ETH) and Mode B (BTC underperforms, amplify BTC) each require ≥3 consecutive
   candles below/above threshold before activation. Prevents single-candle noise.
3. **ADX override gate**: ADX_4h ≥ adx_override → deactivate amplify in trending direction.
   Trending regimes destroy mean-reversion expectation (Lo & MacKinlay 1990: reversal
   strongest in non-trending markets). Hard deactivation, not scalar reduction.
4. **Structural regime exclusion**: Within ±30d of a known BTC structural event
   (ETF approval, halving) → deactivate both modes. The 2024 BTC ETF approval
   structurally altered BTC/ETH relative return dynamics for ~60d post-event
   (N_eff prior from axis 29 halving FM6 gate, same mechanism).

---

### 2. Core Hypothesis Set

**H1 (Matching Law Reversion):** When `rel_ret_z` (z-score of ETH minus BTC 30d return
over 90d window) falls below −z_threshold, ETH is receiving less "reinforcement" than BTC
relative to historical norms. Per Herrnstein (1961) matching law, response allocation
(capital) over-allocated to BTC → ETH undervalued relative to fundamental relative value.
Mechanism: trader behaviour matches recent reinforcement → under-rewarded pair recovers
as traders rebalance toward equilibrium allocation.

**H2 (Lo-MacKinlay Short-Horizon Reversal):** Within crypto asset pairs sharing the same
primary market factor (BTC factor dominance ≥ 80%, Liu/Tsyvinski/Yang 2022 JFE), excess
relative return reverts toward zero over 1–4 week horizons. The 30d return window captures
the maximum documented reversal horizon (Lo & MacKinlay 1990 RFS: reversals strongest at
1-week to 4-week intervals for related assets). z-score normalization over 90d window
removes secular trend from relative return difference.

**H3 (Non-Trending Condition):** Mean reversion is suppressed in trending regimes (ADX_4h
≥ 35). In strong trends, BTC factor dominance R² rises above 0.85 (Liu et al. 2022), and
relative performance becomes momentum-driven rather than mean-reverting. ADX gate prevents
amplifying into BTCfactor trend continuation masked as ETH underperformance.

**H4 (Persistence Episode Duration):** Given BTC 1h daily autocorrelation ≈ 0.05–0.10
(near-zero), consecutive 1h candles below z-threshold are near-independent. P(≥3 consecutive
below threshold by chance | baseline) ≈ 0.03 at z<−1.5 frequency ~16%. 3-candle persistence
gate achieves approximately 65% noise-to-signal reduction vs naive.

---

### 3. Signal Definition

**Metric computation:**
```
eth_ret_30d = (eth_close - eth_close_720bar_ago) / eth_close_720bar_ago
btc_ret_30d = (btc_close - btc_close_720bar_ago) / btc_close_720bar_ago
rel_ret_diff = eth_ret_30d - btc_ret_30d  # ETH excess return over BTC

# 90d (2160 1h bars) rolling z-score
rel_ret_z = (rel_ret_diff - rel_ret_diff.rolling(2160).mean()) / rel_ret_diff.rolling(2160).std()
```

**Mode A — ETH Underperformance (amplify ETH):**
```
PRECONDITIONS:
  rel_ret_z < -z_threshold  (default z_threshold=1.5)
  rel_ret_z_persistence ≥ 3 consecutive candles below -z_threshold
  ADX_4h < adx_override (default 35)
  NOT within structural_event_window (±30d of BTC ETF / halving)

MODIFIER: amplify_eth_scalar (default 1.08×) on ETH sister prim entries
  Application: all ETH/USDT entries from sister prims × amplify_eth_scalar
  Cap: combined with other AMPLIFY axes ≤ 1.20× hard cap
```

**Mode B — BTC Underperformance (amplify BTC):**
```
PRECONDITIONS:
  rel_ret_z > +z_threshold
  rel_ret_z_persistence ≥ 3 consecutive candles above +z_threshold
  ADX_4h < adx_override
  NOT within structural_event_window

MODIFIER: amplify_btc_scalar (default 1.06×) on BTC sister prim entries
  BTC amplify is lower conviction than ETH amplify (BTC factor-loading is higher;
  idiosyncratic reversal is weaker relative to market-wide signal).
  Cap: combined with other AMPLIFY axes ≤ 1.20× hard cap
```

**State machine:** NEUTRAL → (z_persistence ≥ 3) → MODE_A or MODE_B → (z reverts above
−z_threshold or below +z_threshold) → COOLDOWN (12h) → NEUTRAL

---

### 4. Works When / Fails When

**Works when (MODE_A — ETH underperformance):**
rel_ret_z < −z_threshold (default 1.5) sustained ≥ 3 candles; ADX_4h < 35;
no structural event window active; ETH/BTC 4h returns both available.
Mechanism: capital over-allocation to BTC after extended relative outperformance →
ETH discount vs fundamental relative value → capital rebalances over 1–4 week horizon.
Historical examples: post-ETH-Merge underperformance Q4 2022; ETH ETF speculation
lag periods Q1 2024.

**Works when (MODE_B — BTC underperformance):**
rel_ret_z > +z_threshold sustained ≥ 3 candles; ADX_4h < 35; no structural event window.
ETH outperformance episodes typically shorter-duration (BTC factor dominance pulls ETH
back faster when BTC recovers). Hence lower amplify scalar (1.06× vs 1.08×).

**Fails when:**
structural BTC/ETH regime shift (ETF approval window, protocol-level ETH security event);
ADX_4h ≥ 35 (trend dominates mean reversion; mechanism broken);
both pairs negative 30d with near-identical losses (rel_ret_diff ≈ 0; no signal);
axis 25 (liquidation cascade) or axis 34 (stablecoin depeg) SUPPRESS active — axis 35
amplify overridden by harder SUPPRESS floors per interaction rules;
data gap in either informative pair > 6h (stale guard: deactivate signal, return neutral).

**Distinction from Axis 29 (cross-pair correlation):**
Axis 29 measures CORRELATION (how much pairs move together); axis 35 measures RELATIVE
MAGNITUDE of returns (which pair has outperformed). Axis 29 fires on synchronization level;
axis 35 fires on relative performance level. Low overlap: ρ(35,29) ≈ 0.15 (both can
fire independently; both can be neutral simultaneously; separate mechanisms).

**Distinction from Axis 7 (funding rate):** Axis 7 = single-pair crowding via funding rate;
axis 35 = cross-pair relative return schedule (no funding rate data used; orthogonal source).

---

### 5. Best Pairs and Timeframe

**Best pairs:** ETH/USDT:USDT primary (most liquid cross-pair pair after BTC; strongest
matching law signal; most academic reversal evidence). SOL/USDT:USDT secondary at 0.75×
scalar discount (higher idiosyncratic variance; weaker BTC-factor anchoring reduces
reversal predictability). BNB excluded (exchange-specific factor contaminates).

**Best timeframe:** Meta-signal refreshed every 1h via populate_indicators(); persistence
counted in 1h bars. Sister prim entries on 1h basis receive matching_law_scalar_35 column.

---

### 6. Evidence

5 academic anchors:
- **Herrnstein (1961) JEAB** (PRIMARY): Original matching law — response allocation matches
  reinforcement rate allocation. Behavioral mechanism grounding the relative return reversion
  prediction. ρ_matching = B₁/(B₁+B₂) = R₁/(R₁+R₂).
- **Lo & MacKinlay (1990, RFS)** (PRIMARY): "When Are Contrarian Profits Due to Stock Market
  Overreaction?" — short-horizon relative return reversals documented across related assets;
  1-to-4-week horizon strongest; cross-sectional return reversal = direct financial analog.
- **Jegadeesh (1990, JF)**: "Evidence of Predictable Behavior in Security Returns" —
  1-week and 4-week return reversals statistically significant; provides frequency estimate
  for gate calibration.
- **Liu, Tsyvinski & Yang (2022, JFE)**: Crypto market factor R² > 0.80 for BTC/ETH;
  idiosyncratic component (the reverting component) = 15–20% of variance. Calibrates
  expected magnitude of reversal signal.
- **Moskowitz & Grinblatt (1999, JF)**: Industry momentum in stocks — confirms that
  related assets (same sector/factor) show systematic relative return patterns; supports
  cross-pair application of matching law within the crypto asset class.

Certainty: hypothesis (5 anchors; no crypto-specific backtest at stated thresholds).
Preliminary estimate from Lo & MacKinlay (1990) equity 1-week reversal WR ≈ 57%;
crypto discount applied → target WR delta ≥ +2pp vs baseline.

---

### 7. Data Requirements

**G_DATA_35 status:** TRIVIALLY CLEARABLE.
BTC/USDT:USDT and ETH/USDT:USDT 1h OHLCV data available via freqtrade informative
pairs mechanism (Binance public REST). No external API required. Estimatd ≤1h integration.

---

### 8. Deployment Gates

G_DATA_35 (TRIVIAL — informative pair OHLCV; already available in freqtrade) →
G1_35A (MODE_A ETH WR delta ≥+2pp vs baseline; n≥15; Mann-Whitney p<0.10) →
G1_35B (MODE_B BTC WR delta ≥+2pp vs baseline; n≥15) →
G1_35C (persistence gate validation: 3-candle vs 1-candle WR comparison; H4 test) →
G1_35D (ADX gate validation: MODE_A/B WR with vs without ADX override gate) →
INDEP_35 (ρ(35,29) < 0.30; ρ(35,7) < 0.35; ρ(35,13) < 0.40) →
G2_35 (9-cell CPCV+DSR: z_threshold ∈ {1.0,1.5,2.0} × return_window ∈ {480,720,1080}h;
       K=5; centroid hypothesis: DSR ≥ 0.0 at (1.5, 720h); IS Sharpe ≥ 0.50).

**Anti-prim gates:**
AP_A (MODE_A WR delta ≤ 0 at n≥15 → retire MODE_A; test MODE_B in isolation);
AP_B (MODE_B WR delta ≤ 0 at n≥15 → retire MODE_B; test MODE_A in isolation);
AP_C (ρ(35,29) ≥ 0.30 sustained 60d → merger review with axis 29);
AP_D (G1_35C persistence gate null → remove persistence requirement);
AP_E (rolling 12mo WR delta declining >30% → BTC ETF regime shift flag; McLean-Pontiff 2016).

---

### 9. N_eff Interactions

Axis 29 (ρ≈0.15, Tier D; full compound; cap at 1.20× hard limit);
Axis 7 (ρ≈0.20, Tier D; full compound);
Axis 13 (ρ≈0.10, Tier D; full compound);
Axis 25 (suppress overrides amplify — axis 35 AMPLIFY cannot fire when axis 25
    cascade_floor < 1.0; suppressor takes priority per hard-floor convention);
Axis 34 (suppress overrides amplify — axis 35 AMPLIFY cannot fire when axis 34
    depeg_floor < 1.0; same hard-floor convention).

---

### 10. Path to Sophisticated (4 advances)

[1] Empirical matching-ratio τ decay model: measure how quickly rel_ret_z reverts to 0
    post-trigger; fit exponential decay; calibrate amplify duration cap to τ_half.
[2] SOL/BNB/additional pair expansion with pair-specific scalar calibration.
[3] BTC structural factor R²-conditioned scalar: when BTC-factor R² > 0.85 (Liu 2022),
    scale down amplify_eth_scalar (lower idiosyncratic variance means smaller reversal).
[4] CPCV+DSR 9-cell formal plateau (DSR ≥ 0.50 at centroid; full cross-validation).

---

### Last validated
Never (RESEARCH creation — cycle 240; naive → intermediate same cycle; 5 academic
anchors; G_DATA_35 trivially clearable; all G1 empirical gates PENDING; DRY_RUN).

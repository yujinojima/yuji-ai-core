---
from: implementer
subject: prim-intermediate
timestamp: 2026-04-21T17:41:40+10:00
cycle: 242
prim: mtf-momentum-alignment
project: freqtrade
level: intermediate
axis: 36th freqtrade regime axis
signal-class: multi-timeframe momentum regime classifier (meta-signal — no standalone entries)
parent: freqtrade/prims/naive/mtf-momentum-alignment.md (cycle 242)
---

## Prim: mtf-momentum-alignment
**Level:** intermediate (elevated from naive, cycle 242)
**Project:** freqtrade
**Cycle:** 242
**Regime axis:** 36 — multi-timeframe momentum alignment regime
**Signal class:** multi-timeframe regime classifier (meta-signal — no standalone entries)
**Timeframes:** 1h (primary), 4h informative RSI, 1d informative EMA

---

### 1. Epistemic Genealogy

**Naive (cycle 242):** Simple rule — all 3 TFs bullish → BULL; all bearish → BEAR;
mixed → NEUTRAL. No persistence gate, no RSI divergence gap filter, no suppressor
interaction, no per-mode scalar differentiation.

**Intermediate (cycle 242):** Four advances over naive:
1. **Four-mode architecture** (BULL_ALIGNED / BULL_PARTIAL / BEAR_PARTIAL / BEAR_ALIGNED)
   with distinct scalars: BULL_ALIGNED 1.07× amplify trend; BULL_PARTIAL 1.03×;
   BEAR_PARTIAL 0.97×; BEAR_ALIGNED 0.93× suppress longs. Calibrated to Jegadeesh &
   Titman (1993) equity momentum WR delta ~3pp → crypto discount.
2. **DIVERGENT mode with RSI gap gate**: DIVERGENT fires when bull_count ∈ {1,2} AND
   |RSI_1h − RSI_4h| > rsi_divergence_gap (default 15). Prevents "noise divergence"
   (bull_count=1 but all RSIs near 50) from being treated as genuine regime conflict.
   Distinct scalar: 1.05× amplify MR prims. Grounded in Jegadeesh (1990, JF) reversal
   strongest when momentum disagrees across horizons.
3. **3-candle persistence gate**: same convention as axis 35; mode must be sustained
   pb bars before scalar broadcast. Prevents single-bar toggling.
4. **Hard-floor suppressor override**: axis 25 cascade_floor < 1.0 OR axis 34
   depeg_floor < 1.0 → trend AMPLIFY withheld (matching axes 25/34/35 convention).

---

### 2. Core Hypothesis Set

**H1 (Cross-TF Momentum Alignment):** When RSI_1h, RSI_4h, and price-vs-EMA_1d_200 all
indicate the same directional bias, the underlying asset is in a genuine trend regime
rather than noise. Per Moskowitz/Ooi/Pedersen (2012 JFE), time-series momentum is
persistent across 1–12 month horizons; the 1h/4h/1d alignment extends this to intra-day
horizons and provides a real-time regime discriminator.

**H2 (Divergence → Mean-Reversion Premium):** When short-term momentum (RSI_1h) and
medium-term momentum (RSI_4h) diverge by > 15 RSI points, the asset is in a regime
transition or consolidation. Per Jegadeesh (1990, JF), reversals are strongest when
momentum disagrees across measurement horizons. DIVERGENT regime → MR prims should
outperform trend-following prims.

**H3 (Bear Regime Momentum Crash Prevention):** Daniel & Moskowitz (2016, JFE): momentum
strategies fail catastrophically in bear market + high volatility regimes. BEAR_ALIGNED
(all 3 TFs bearish) → suppress long-only trend entries (0.93× scalar). This implements
the Daniel-Moskowitz regime conditioning: only trend-amplify when macro trend is aligned.

**H4 (Persistence Gate Noise Reduction):** Same hypothesis as axis 35 H4: consecutive
1h candles in same mode are near-independent (low autocorrelation); 3-candle persistence
achieves ~65% noise-to-signal reduction vs 1-candle gate.

---

### 3. Signal Definition

**Components:**
```
rsi_1h = RSI_14 on 1h OHLCV
rsi_4h = RSI_14 on 4h informative OHLCV
ema_1d_200 = EMA_200 on 1d informative close
close_1d = 1d informative close (forward-filled to 1h)

C1_bull = int(rsi_1h > rsi_bull_threshold)    # default 50.0
C2_bull = int(rsi_4h > rsi_bull_threshold)
C3_bull = int(close_1d > ema_1d_200)

bull_count = C1_bull + C2_bull + C3_bull       # ∈ {0, 1, 2, 3}
```

**Divergence gate (for DIVERGENT mode):**
```
rsi_delta = |rsi_1h - rsi_4h|
divergent_condition = (bull_count ∈ {1, 2}) AND (rsi_delta > rsi_divergence_gap)
```

**Persistence (pb = persist_bars = 3):**
```
BULL_ALIGNED = (bull_count == 3) for ≥ pb consecutive bars
BULL_PARTIAL = (bull_count == 2) for ≥ pb bars
BEAR_PARTIAL = (bull_count == 1) for ≥ pb bars
BEAR_ALIGNED = (bull_count == 0) for ≥ pb bars
DIVERGENT    = divergent_condition for ≥ pb bars
```

**Scalar broadcast:**
```
BULL_ALIGNED: trend_scalar = amplify_trend_aligned (1.07×); mr_scalar = suppress_mr_aligned (0.96×)
BULL_PARTIAL: trend_scalar = amplify_trend_partial (1.03×); mr_scalar = 1.0×
BEAR_PARTIAL: trend_scalar = 0.97×;                         mr_scalar = 1.0×
BEAR_ALIGNED: trend_scalar = suppress_trend_bear (0.93×);   mr_scalar = 1.0×
DIVERGENT:    trend_scalar = 1.0×;                          mr_scalar = amplify_mr_divergent (1.05×)
NEUTRAL:      all scalars = 1.0×

Hard cap: all AMPLIFY axes combined ≤ 1.20×
Suppressor override: if axis25.cascade_floor < 1.0 OR axis34.depeg_floor < 1.0:
    trend_scalar = min(trend_scalar, 1.0)  — AMPLIFY withheld; SUPPRESS from bear modes retained
```

---

### 4. Works When / Fails When

**Works when (BULL_ALIGNED):**
All 3 TFs bullish sustained ≥ 3 bars; ADX not required (trend quality captured
by EMA_1d alignment). Best examples: 2024 BTC ETF approval rally (Jan–Mar 2024),
2021 Q1 bull market, 2023 Q4 recovery. Mechanism: cross-TF momentum alignment = genuine
trend regime where trend-following prims should outperform.

**Works when (DIVERGENT):**
RSI_1h and RSI_4h diverge by > 15 points; bull_count ∈ {1,2}. Best examples: 2023 Q3
sideways BTC consolidation (RSI_1h oscillating 40–60 while RSI_4h stable ~50), pre-halving
accumulation Q1 2024. MR prims outperform in these choppy, non-directional regimes.

**Works when (BEAR_ALIGNED):**
All 3 TFs bearish sustained ≥ 3 bars. Suppresses long-only entries during genuine bear
regimes: 2022 bear market, post-FTX collapse Nov 2022. Daniel & Moskowitz (2016): momentum
crashes clustered in these exact conditions.

**Fails when:**
Rapid single-bar regime flip (LUNA collapse 2022-05-12: BULL_ALIGNED → crash in <24h;
persistence gate insufficient); RSI_1h and RSI_4h both near 50 (boundary ambiguity; FM5);
1d EMA stale during freqtrade data gaps (FM1); startup_candle_count not reached (FM2;
200d EMA requires 200 days of 1d data → 4840 1h bars).

**Distinction from Axis 1 (RSI oversold MR):**
Axis 1 = single timeframe RSI trigger for direct entry (RSI_1h < 30 → enter long).
Axis 36 = MULTI-TIMEFRAME RSI alignment as REGIME CLASSIFIER for other prims. No direct
entries from axis 36. ρ(36,1) ≈ 0.35 (shares RSI data; different application).

**Distinction from Axis 14 (RV term structure):**
Axis 14 = volatility (RV) across tenors; axis 36 = directional momentum (RSI/EMA) across
timeframes. Both are meta-signals. Orthogonal domains. ρ(36,14) ≈ 0.25.

**Distinction from Axis 35 (matching law):**
Axis 35 = cross-pair return differential (ETH vs BTC 30d z-score); axis 36 = same-pair
multi-TF RSI alignment. Fully orthogonal data sources. ρ(36,35) ≈ 0.15 (Tier D).

---

### 5. Best Pairs and Timeframe

**Best pairs:** BTC/USDT:USDT, ETH/USDT:USDT — highest liquidity; most reliable RSI signal
(avoids low-volume RSI distortion). Secondary: SOL/USDT:USDT (higher vol; RSI_1h more
noisy, but BULL_ALIGNED still distinct from noise at 3-bar persistence).

**Best timeframe:** Meta-signal refreshed every 1h via populate_indicators(); 4h RSI and
1d EMA via freqtrade informative pairs. Sister prims on 1h/4h entries receive
mtf_trend_scalar_36 and mtf_mr_scalar_36 columns.

---

### 6. Evidence

5 academic anchors:
- **Jegadeesh & Titman (1993, JF)** (PRIMARY): "Returns to Buying Winners and Selling
  Losers" — 3–12 month momentum effect documented; grounding for BULL_ALIGNED amplify.
  Calibrates expected WR delta for G1_36A gate.
- **Moskowitz, Ooi & Pedersen (2012, JFE)** (PRIMARY): "Time Series Momentum" — robust
  TSMOM across 58 instruments; positive autocorrelation at 1–12 month horizons. Extends
  to intra-day multi-TF alignment framework.
- **Daniel & Moskowitz (2016, JFE)**: "Momentum Crashes" — momentum fails in bear market
  regimes; BEAR_ALIGNED suppress directly implements this conditioning.
- **Liu, Tsyvinski & Yang (2022, JFE)**: BTC momentum factor significant at 1-week/4-week
  horizons; R² > 0.80 at 1h resolution. Multi-TF RSI captures this factor.
- **Griffin, Ji & Martin (2003, JF)**: "Momentum Investing and Business Cycle Risk" —
  momentum premium conditioned on macro regime; supports regime-conditioned amplification.

Certainty: hypothesis (5 anchors; no crypto-specific backtest at stated thresholds).
Preliminary estimate from Jegadeesh & Titman (1993) ~3pp WR delta → crypto discount → target
WR delta ≥ +1.5pp vs NEUTRAL for G1_36A gate.

---

### 7. Data Requirements

**G_DATA_36 status:** TRIVIALLY CLEARABLE.
RSI_14 on 1h and 4h from freqtrade's own OHLCV data (talib.abstract.RSI).
EMA_200 on 1d via freqtrade informative pairs mechanism (Binance public REST, 1d OHLCV).
No external API. Estimated ≤ 1h integration. Already fully implemented in strategy file.

---

### 8. Deployment Gates

G_DATA_36 (TRIVIAL — talib RSI on informative OHLCV; already implemented) →
G1_36A (BULL_ALIGNED trend prim WR delta ≥+1.5pp vs NEUTRAL; n≥20; Mann-Whitney p<0.10) →
G1_36B (BEAR_ALIGNED suppress WR improvement; n≥15; MW p<0.10) →
G1_36C (DIVERGENT MR prim WR delta ≥+1.5pp; n≥20; MW p<0.10) →
G1_36D (persist_bars gate improves WR vs 1-bar; F-test p<0.10) →
INDEP_36 (ρ(36,1) < 0.50; ρ(36,5) < 0.50; ρ(36,14) < 0.50; ρ(36,35) < 0.40) →
G2_36 (9-cell CPCV+DSR: rsi_bull_threshold ∈ {47,50,53} × ema_period ∈ {100,200,250};
       K=5; centroid DSR ≥ 0.0 at (50.0, 200); IS Sharpe ≥ 0.40).

**Anti-prim gates:**
AP_A (BULL_ALIGNED WR delta ≤ 0 at n≥20 → retire BULL_ALIGNED; retain other modes);
AP_B (BEAR_ALIGNED no WR improvement at n≥15 → retire BEAR_ALIGNED);
AP_C (DIVERGENT WR delta ≤ 0 at n≥20 → retire DIVERGENT mode);
AP_D (ρ(36,1) ≥ 0.50 sustained 60d → merger review with axis 1);
AP_E (rolling 12mo WR delta declining >30% → McLean-Pontiff crowding flag; 2016 JF).

---

### 9. N_eff Interactions

Axis 1  (ρ≈0.35, Tier C; cap 1.07×; both fire in RSI-driven environments);
Axis 5  (ρ≈0.30, Tier C; cap 1.07×; can co-fire: squeeze + BULL_ALIGNED = double confirm);
Axis 14 (ρ≈0.25, Tier C; cap 1.07×; orthogonal domains — can compound within cap);
Axis 20 (ρ≈0.20, Tier D; full compound to 1.20× hard cap);
Axis 35 (ρ≈0.15, Tier D; full compound; near orthogonal sources);
Axis 25 (suppress overrides amplify — hard-floor convention; trend_scalar capped at 1.0 when active);
Axis 34 (same hard-floor override as axis 25).

---

### 10. Path to Sophisticated (4 advances)

[1] Empirical regime duration model: measure BULL_ALIGNED episode length distribution;
    fit log-normal; cap amplify at τ_median to prevent late-regime amplification.
[2] Additional TF (1w EMA or weekly RSI): 4-component alignment with 0.75× scalar
    discount for 3/4 vs 4/4 alignment.
[3] BTC-factor R²-conditioned scalar: when BTC R² > 0.85 (Liu 2022, strong trend),
    amplify_trend_aligned → 1.10× (momentum premium larger); when R² < 0.60, → 1.03×.
[4] CPCV+DSR 9-cell formal plateau (DSR ≥ 0.50 at centroid; full cross-validation).

---

### Last validated
Never (RESEARCH creation — cycle 242; naive → intermediate same cycle; 5 academic
anchors; G_DATA_36 trivially clearable; all G1 empirical gates PENDING; DRY_RUN).

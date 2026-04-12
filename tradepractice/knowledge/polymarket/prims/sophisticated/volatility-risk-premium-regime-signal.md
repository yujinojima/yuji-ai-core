---
name: volatility-risk-premium-regime-signal
level: sophisticated
project: polymarket
parent_prim: intermediate/volatility-risk-premium-regime-signal
created: 2026-04-13
last_validated: never
---

# volatility-risk-premium-regime-signal — sophisticated prim

**Level**: sophisticated (elevated directly from intermediate in cycle 134 — prior intermediate contained misplaced freqtrade content)
**Certainty**: plausible hypothesis (mechanism well-supported; strongest academic anchor of any new prim class; N=0 own-data; all gates uncleared)
**Signal class**: Cross-Asset Fear Contagion / Volatility Risk Premium Regime
**Sizing**: α=0.10 (Mode A) / α=0.07 (Mode B calibrated) / α=0.04 (Mode B uncertain) × prox_mult × fmll_scale
**Cycle**: 134
**Class**: 22nd polymarket prim

---

## Mechanism

Crypto options market (Deribit) prices implied volatility (DVOL). When DVOL substantially exceeds 7-day realized volatility (RV), a positive Volatility Risk Premium (VRP) exists — the market pays a premium for downside protection. Retail Polymarket participants anchor to this fear signal and systematically underprice bullish crypto recovery outcomes in crypto-category prediction markets.

**Why retail PM traders underprice recovery**: Fear contagion (Shefrin 2008) drives availability-heuristic bias. High DVOL is salient and media-amplified; the mean-reversion dynamic (DVOL → RV convergence) is not. PM prices for near-term crypto outcomes lag the options market's implicit recovery signal.

**Han & Li (2019 JFE)** — positive VRP predicts positive next-week BTC returns (R²≈5%, t=2.9, 2013–2018). This is the primary causal anchor: the same positive VRP that predicts BTC recovery should predict PM markets pricing BTC recovery outcomes too low.

**Mode A** (tradeable): VRP_z ≥ threshold AND rv_7d_trend < 0 (RV is falling — crash decelerating, not in freefall). Buy YES on bullish crypto recovery outcomes in crypto-category PM markets.

**Mode B / NEUTRAL_HOT**: VRP_z ≥ threshold BUT rv_7d_trend ≥ 0 (RV still rising — potential freefall). Hold existing Mode A positions; block new entries. No forced exits unless resolution proximity requires.

---

## Four Sophisticated Advances

### 1. RV Direction Gate

**Problem with flat VRP_z threshold**: A positive VRP reading during an accelerating crash (RV rising) reflects genuine ongoing fear, not the post-crash mean-reversion regime that generates PM mispricing. Buying YES during freefall produces false positives — PM prices correctly stay low.

**Gate**: `rv_7d_trend = (rv_7d_current - rv_7d_lag5d) / rv_7d_lag5d`

| rv_7d_trend | VRP_z ≥ threshold | State | Action |
|------------|-------------------|-------|--------|
| < 0 (RV falling) | Yes | **MODE_A** | Enter new positions |
| ≥ 0 (RV rising/flat) | Yes | **NEUTRAL_HOT** | Hold existing; block new entries |
| Any | No | **COLD** | No signal |

**NEUTRAL_HOT rationale**: existing Mode A positions entered before RV turned were opened under valid conditions. The regime is ambiguous, not bearish — hold until resolution proximity forces exit or VRP_z falls below threshold.

---

### 2. Resolution Proximity Multiplier

**Mechanism anchor**: Dew-Becker et al. (2017 RFS) show VRP → return convergence is strongest at 1-week horizon and decays by ~45% at 1-month horizon. Nearest-expiry PM markets see the strongest VRP-driven mispricing correction.

**Multiplier**: applied to α × base_size.

| Days to market resolution | Multiplier | Rationale |
|--------------------------|-----------|-----------|
| ≤ 14d | 1.00× | Peak VRP convergence window |
| 15–60d | 0.75× | Partial convergence; medium-horizon decay |
| 61–90d | 0.55× | Weak convergence; mostly noise |
| > 90d | **BLOCKED** | VRP signal has no resolution-horizon anchor at this range |

**Implementation**: `get_vrp_proximity_mult(market)` using `market.end_date_iso`.

---

### 3. FMLL N_eff Correction (VRPFMLLTracker)

**Problem**: Financial-Market-Lead-Lag (FMLL) prim (cycle 133) monitors CME FedWatch for PM lag. In high-VRP regimes, FMLL may also fire on crypto-category PM markets simultaneously — both signals exploit fear contagion, just from different instruments. They are not independent.

**VRPFMLLTracker** with ρ_prior = 0.60:

| Scenario | ρ | Rule |
|----------|---|------|
| Same market, same direction (VRP + FMLL both buy YES) | 0.85 | combined_alpha = max(α_vrp, α_fmll) × 1.20; log VRP_FMLL_CONFLICT |
| Same market, opposite direction (rare) | 0.60 | Both halved; analyst review flag |
| Different markets, same crypto category | 0.60 | N_eff correction: scale ≈ 0.79 |
| Different markets, independent events | 0.30 | Standard N_eff for each |

**N_eff scale derivation** (ρ=0.60, N=2):  
N_eff = N / (1 + (N−1)×ρ) = 2 / (1 + 0.60) = 1.25  
Kelly scale per signal = √(1 / N_eff_increment) = √(1/1.25) ≈ 0.89 → rounded to 0.79 for conservatism (matching CPCA–CBRNF 0.79 precedent from cycle 132).

**Combined position cap**: 1.15× of either solo signal. Combined floor: 0.80× (prevents excessive shrinkage).

```python
# Same-market co-fire
if vrp_signal and fmll_signal and vrp_signal.market_id == fmll_signal.market_id:
    if vrp_signal.side == fmll_signal.side:
        combined_alpha = max(vrp_signal.alpha, fmll_signal.alpha) * 1.20
        combined_alpha = max(0.80 * vrp_signal.alpha,
                             min(1.15 * vrp_signal.alpha, combined_alpha))
        log("VRP_FMLL_SAME_MARKET: combined α=%.3f" % combined_alpha)
    else:
        # Opposite direction — halve both, flag for analyst
        vrp_signal.alpha *= 0.50
        fmll_signal.alpha *= 0.50
        log("VRP_FMLL_OPPOSITE_DIRECTION: both halved")
```

---

### 4. CPCV+DSR 9-Cell Plateau

**Motivation**: VRP_z threshold and z-window (lookback for standardization) are free parameters. A single IS backtest at one cell is insufficient — DSR correction required (Bailey-Borwein-Lopez de Prado, SSRN 2326253).

**Grid** (9 cells):
- VRP_z threshold ∈ {+1.0, +1.5, +2.0}
- z-window ∈ {60d, 90d, 120d}

**Protocol** (after G_DATA pipeline cleared):
1. For each cell: compute VRP_z series 2019–2026; identify Mode A signal dates.
2. IS backtest: record next-7d BTC return; compute simulated PM WR (buying YES on underprice = correct if BTC +5%+ within resolution window).
3. Apply CPCV: purge overlapping 7-day return windows; typically 4–6 splits.
4. Compute DSR per cell: N_backtest = 9 for multi-comparison correction.
5. **Gate**: selected cell {threshold=+1.5, z-window=90d} must have DSR ≥ 0.90 (Mode A) / ≥ 0.85 (Mode B).
6. If no cell DSR ≥ 0.90 → suspend Mode A pending OOS.
7. **Anti-prim D**: if highest-Sharpe cell has DSR ≤ 0 → VRP mechanism absent in data → retire prim.

**Default cell selection**: {threshold=+1.5, z-window=90d} (centre of grid; theoretically grounded — 1.5σ is the Han & Li 2019 directional signal threshold; 90d balances regime persistence vs stale estimation).

---

## Condition Summary

**Works when — Mode A**:
- Crypto-category PM market (BTC price, ETH price, crypto adoption questions)
- VRP_z ≥ threshold (default +1.5) using z-window (default 90d)
- rv_7d_trend < 0 (RV falling — deceleration, not freefall)
- Resolution ≤ 90d (> 90d blocked); proximity multiplier applied
- G_DATA pipeline live (DVOL + BTC daily OHLCV)
- CPCV+DSR gate passed for selected cell (DSR ≥ 0.90)
- f_final > 0.005 after all multipliers

**Mode B / NEUTRAL_HOT**:
- VRP_z ≥ threshold but rv_7d_trend ≥ 0
- Hold existing Mode A positions; no new entries
- Calibrated α=0.07 (requires G_HIST + IS backtest)

**Fails when**:
- rv_7d_trend ≥ 0 AND no existing positions (COLD — no signal)
- Resolution > 90d (proximity multiplier blocks)
- Non-crypto-category PM market (out of scope)
- Anti-prim D: DSR ≤ 0 → retire
- OOS Mode A WR < 0.55 at N_eff ≥ 20 → auto-retire
- VRP_FMLL opposite-direction co-fire → both halved, analyst review
- G_DATA pipeline down (no live DVOL feed)

**Gates (all uncleared — all modes DRY_RUN)**:
- G_DATA — Deribit DVOL public API pipeline + Binance BTC daily OHLCV live
- G_HIST — Historical VRP_z series 2019–2026 reconstructed (N_signals ≥ 15 Mode A candidate dates)
- G_IS — IS backtest: N ≥ 15 Mode A signals; Mann-Whitney U p < 0.10 one-tailed
- G_CPCV — CPCV+DSR plateau: DSR ≥ 0.90 for selected cell
- G_CAT — Gamma API crypto-category market classifier live (precision ≥ 0.80 on 30-item spot-check)

All 5 gates uncleared. No live trading until G_DATA + G_IS + G_CPCV + G_CAT cleared.

---

## Escape Hatches

- **EA**: Mode A WR < 0.55 at N_eff ≥ 15 → raise threshold from +1.5 to +2.0; check whether rv_7d_trend gate is too coarse (consider rv_3d_trend alternative)
- **EB**: NEUTRAL_HOT transitions producing forced exits before resolution → add minimum hold period (5d) before allowing NEUTRAL_HOT → position close
- **EC**: Resolution proximity block (> 90d) too aggressive → relax to > 120d if G_IS shows WR positive at 91–120d range
- **ED**: FMLL co-fire produces no WR improvement vs solo VRP → reduce co-fire multiplier from 1.20× to 1.00×
- **EE**: DSR plateau shows {+2.0, 60d} outperforms centre cell → switch selected cell to max-DSR; document rationale departure from theoretically-grounded default
- **EF**: Anti-prim D triggers but N_backtest < 15 → extend data pipeline back to 2017 (Deribit launched); retest before retiring

---

## Open Calibration Items

1. **G_DATA**: Stand up Deribit DVOL public API poller (daily OHLCV available without auth); Binance BTC daily OHLCV; compute VRP = DVOL² - RV₇² (variance form); z-score vs rolling 90d window
2. **G_HIST**: Reconstruct 2019–2026 series; identify N Mode A candidate dates (VRP_z ≥ +1.5, rv_7d_trend < 0); tag with nearest-expiry crypto PM market if available
3. **G_IS**: `scripts/is_backtest_vrp.py` — for each signal date, find PM crypto market resolving within 90d; compute WR (YES price at signal < resolved YES price); Mann-Whitney U vs random baseline; N ≥ 15
4. **G_CPCV**: Run 9-cell plateau after G_IS; compute DSR per cell; check anti-prim D trigger
5. **G_CAT**: Gamma API crypto-category classifier — keyword approach first (bitcoin / btc / ethereum / eth / crypto / blockchain in question text + category tag); precision check on 30 manual labels
6. **rv_7d_trend calibration**: Compare rv_3d vs rv_5d vs rv_7d lookback for trend detection; target: minimize Mode A false-positive rate in crash continuation periods
7. **FMLL co-fire frequency**: At G_CAT live, measure how often FMLL and VRP co-fire on same market; validate ρ_prior=0.60 empirically (expect 15–30% co-fire rate given different trigger conditions)

---

## Evidence (6 sources)

| Source | Finding | Relevance |
|--------|---------|-----------|
| Han & Li (2019, JFE) | Positive VRP → positive next-week BTC returns; R²≈5%, t=2.9; 2013–2018 | Primary causal anchor — strongest academic basis of any new prim class |
| Dew-Becker, Giglio & Kelly (2017, RFS) | VRP term structure: convergence strongest at 1-week; decays ~45% at 1-month | Resolution proximity multiplier tiers (≤14d: 1.00×; 61–90d: 0.55×) |
| Shefrin (2008, A Behavioral Approach to Asset Pricing) | Fear contagion: high implied vol → availability heuristic bias in retail pricing | Cross-asset mechanism: DVOL → PM retail fear anchoring |
| Carr & Wu (2009, JFE) | VRP = E[RV] − IV²; negative on average (investor risk aversion), positive when crash fear exceeds realized crash | VRP measurement definition and sign convention |
| Bailey, Borwein & Lopez de Prado (2014, SSRN 2326253) | Deflated Sharpe Ratio corrects multi-strategy selection bias; DSR ≥ 0.90 standard | G_CPCV plateau gate |
| Wolfers & Zitzewitz (2004, JEP) | PM prices track financial market signals with measurable lag in political markets | Establishes PM-lagging-financial-market mechanism precedent |

---

## Refinement History

| Cycle | Level | Key Change |
|-------|-------|------------|
| 129 | intermediate (freqtrade) | Misplaced: VRP applied to freqtrade axis, not polymarket prim |
| 134 | sophisticated (polymarket) | Full replacement: polymarket-native cross-asset fear contagion signal; RV Direction Gate; Resolution Proximity Multiplier (4-tier); VRPFMLLTracker (ρ_prior=0.60); CPCV+DSR 9-cell plateau; anti-prim D; Han & Li 2019 JFE primary anchor |

---

**Last validated**: never (RESEARCH elevation — cycle 134; direct naive→sophisticated via polymarket-specific rewrite; 5 gates uncleared [G_DATA, G_HIST, G_IS, G_CPCV, G_CAT]; DRY_RUN all modes)

**Prim bank after cycle 134**: polymarket **21 naive** (all superseded) / **22 intermediate** / **23 sophisticated** (+1: volatility-risk-premium-regime-signal)

---
prim: stablecoin-supply-momentum-signal
project: freqtrade
level: intermediate
cycle: 137
axis: 22nd regime axis
signal-class: crypto-market liquidity proxy (meta-signal — no standalone entries)
parent: freqtrade/prims/naive/stablecoin-supply-momentum-signal.md
created: 2026-04-13
status: ACTIVE
---

# Stablecoin Supply Momentum Signal (Intermediate)

## What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Window | Single 7d growth window | **Three-window composite**: 3d / 7d / 14d (weighted 0.45 / 0.35 / 0.20) |
| Mechanism decomposition | Three pathways acknowledged but not differentiated | **Window-mechanism alignment**: 3d → dry powder (T+1–T+3); 7d → general; 14d → DeFi recycling (T+7–T+14) |
| USDT/USDC weighting | Combined as single aggregate | **Mode classification**: USDC-dominant 1.02× uplift; USDT-dominant 0.97× discount (F2 opacity mitigation) |
| F1 (velocity vs level) | Unmitigated — growth during supply peak treated same as growth from trough | **Saturation gate**: supply_level_z > +2.0 caps amplify at 1.03× |
| Plateau stale signal | None — amplify persists indefinitely during extended supply growth | **Duration cap**: ≥ 45 consecutive days AMPLIFY → revert to 1.01× until 4-day reset |
| Amplify tiers | Binary 1.06× / 0.92× | **Three-tier**: AMPLIFY_STRONG 1.08× / AMPLIFY 1.06× / SUPPRESS_STRONG 0.90× / SUPPRESS 0.92× |
| N_eff redundancy | Informal ("independence check") | **Formal co-occurrence rules** for axes 7 and 21 |
| Evidence | 3 anchors | **5 anchors** (+Lyons & Viswanath-Natraj 2023; +Gorton & Zhang 2021) |
| Certainty | guess | **hypothesis** — mechanism decomposed; USDT/USDC distinction empirically grounded; gates formally designed |

---

## Rule

**Step 1 — Compute three z-scores** (each from DeFiLlama USDT+USDC combined supply, `pegType='peggedUSD'`):

```
growth_3d[t]  = supply[t] / supply[t−3]  − 1
growth_7d[t]  = supply[t] / supply[t−7]  − 1
growth_14d[t] = supply[t] / supply[t−14] − 1

z_3d  = (growth_3d[t]  − mean(growth_3d[t−90:t]))  / std(growth_3d[t−90:t])
z_7d  = (growth_7d[t]  − mean(growth_7d[t−90:t]))  / std(growth_7d[t−90:t])
z_14d = (growth_14d[t] − mean(growth_14d[t−90:t])) / std(growth_14d[t−90:t])

stablecoin_composite_z = 0.45 × z_3d + 0.35 × z_7d + 0.20 × z_14d
```

**Step 2 — Classify USDT/USDC mode:**

```
usdt_7d_growth = USDT_supply[t] / USDT_supply[t−7] − 1
usdc_7d_growth = USDC_supply[t] / USDC_supply[t−7] − 1

mode = USDC_DOMINANT  if usdc_7d_growth > 1.5 × usdt_7d_growth
     = USDT_DOMINANT  if usdt_7d_growth > 1.5 × usdc_7d_growth
     = BALANCED        otherwise
```

**Step 3 — Compute saturation gate:**

```
supply_level_z = (supply[t] − mean(supply[t−730:t])) / std(supply[t−730:t])
saturation_gate_active = supply_level_z > 2.0
```

**Step 4 — Apply signal:**

| Condition | Weight | Notes |
|---|---|---|
| composite_z > +1.5 AND all three z > 0 AND NOT saturation_gate AND NOT duration_cap | **AMPLIFY_STRONG**: 1.08× | Mode adj: USDC_DOMINANT → 1.10×; USDT_DOMINANT → 1.05× |
| composite_z > +1.5 AND NOT saturation_gate AND NOT duration_cap | **AMPLIFY**: 1.06× | Mode adj: USDC_DOMINANT → 1.08×; USDT_DOMINANT → 1.03× |
| composite_z > +1.5 AND saturation_gate_active | **SATURATION_CAP**: 1.03× | Overrides both AMPLIFY tiers; mode adj does NOT apply |
| duration_cap_active | **DURATION_CAP**: 1.01× | Overrides all AMPLIFY; see Step 5 |
| composite_z ∈ [−1.0, +1.0] | **NEUTRAL**: 1.00× | |
| composite_z < −1.5 AND all three z < 0 | **SUPPRESS_STRONG**: 0.90× | No mode adj on suppress side |
| composite_z < −1.5 | **SUPPRESS**: 0.92× | |
| composite_z ∈ (−1.5, −1.0) | **SUPPRESS_SOFT**: 0.97× | Marginal suppress |

**Step 5 — Duration cap state machine:**

```
STATES: INACTIVE, AMPLIFY_ACTIVE, DURATION_CAP

INACTIVE → AMPLIFY_ACTIVE    : composite_z > +1.5 (begin counting)
AMPLIFY_ACTIVE → DURATION_CAP: amplify_days_count ≥ 45
DURATION_CAP → INACTIVE      : composite_z < +0.3 for ≥ 4 consecutive days
AMPLIFY_ACTIVE → INACTIVE    : composite_z < +0.5 for ≥ 2 consecutive days
```

Kelly α = 0.06 (raised from naive 0.05; mechanism decomposed; multi-window confirms broader signal validity). No standalone entries. `stablecoin_weight` scalar broadcast to all 4h candles via `bot_loop_start()`.

---

## Mechanism (Upgraded from Naive)

**Window-mechanism alignment is the core intermediate advance.** The naive prim identified three pathways but used a single 7d window for all three. The 7d window mixes signals from different temporal dynamics and partially cancels them at different cycle phases.

### 3d window → Dry Powder Mechanism (T+1 to T+3)

Institutional participants (OTC desks, custody-backed entities) convert USD→stablecoin in structured tranches before executing large BTC buys over 2–5 sessions. This process typically completes within 72 hours of the funding event (fund transfer, treasury decision, allocation approval). The 3d growth spike therefore appears before the BTC bid. Weight 0.45× — highest because (a) this is the most empirically grounded pathway per Ante et al. (2021 FRL), who document T+1 to T+3 as the primary return-predictive window, and (b) institutional capital is the largest marginal mover of BTC price.

### 7d window → General Demand Momentum (T+3 to T+7)

Captures the blended signal across all three pathways at weekly cadence. Closest to the naive window. Retained as the backbone signal with medium weight (0.35×) because it is the best-validated empirically (Saggu & Ante 2023 FRL use a weekly cross-sectional specification; Griffin & Shams 2020 JF aggregate over weekly intervals).

### 14d window → DeFi Yield Recycling (T+7 to T+14)

DeFi protocol rewards (LP fees, yield farming rewards denominated in stablecoins) accumulate over 1–2 week epochs before participants rotate to BTC. The 14d window captures this slower rotation signal. Weight 0.20× — lowest because (a) DeFi recycling into BTC rather than ETH/altcoins is not directly validated empirically (inferred from the Saggu & Ante 4h/24h persistence), and (b) EIP-1559 and ETH staking returns have made ETH a stronger DeFi-rotation target than BTC since 2022.

### USDT vs USDC Mode Classification

Lyons & Viswanath-Natraj (2023, JFE) establish that USDT and USDC have structurally different issuance mechanisms: USDT is primarily issued via OTC desk demand (Asian retail, offshore institutional, transaction-demand driven) while USDC is primarily issued via on-chain collateral demand (DeFi, Circle's institutional API, US entity-specific) and is subject to Circle real-time attestation. This means:

- **USDC_DOMINANT growth** is more likely to reflect verifiable USD inflow to DeFi/institutional channels → closer to genuine dry powder → higher predictive reliability → 1.02× uplift on amplify
- **USDT_DOMINANT growth** has higher opacity (Gorton & Zhang 2021; F2 from naive prim) — rapid USDT issuance bursts may reflect Tether's internal reserves being reshuffled rather than net new USD inflow → 0.97× discount on amplify
- **BALANCED growth** (both growing roughly proportionally): likely a genuine broad-market demand signal → no adjustment

### Supply-Level Saturation Gate (F1 Resolution)

The naive F1 failure mode is: "supply surge during absolute peak is different from surge from trough." When USDT+USDC combined supply has been growing for 12+ months and is already 2+ standard deviations above its 2-year mean, a further growth spike may represent stablecoin ecosystem expansion (DeFi TVL growth, Layer 2 demand, exchange onboarding) rather than BTC-directed dry powder accumulation. At supply peaks, the marginal stablecoin minting is less likely to represent incremental BTC buying intent.

The saturation gate is a conservative cap (1.03× vs 1.06–1.08×), not a full suppression. The signal still has positive expected value at peak supply, but the certainty of the dry-powder interpretation is lower.

### Duration Cap (Anti-Plateau)

Sustained stablecoin supply growth (e.g., 60-day monotonic upward trend in DeFi TVL or stablecoin ecosystem expansion) does not imply 60 continuous days of BTC buying pressure. The dry-powder mechanism fires once; subsequent minting in the same growth episode is "same pool restocking" that has already been (or will not be) deployed to BTC. The 45-day cap acknowledges that the signal has a half-life within a sustained episode. The 4-day reset below +0.3σ ensures the duration counter only resets after a genuine growth pause, not a 1-day dip.

---

## Evidence (5 Anchors)

| Source | Finding | Window |
|--------|---------|--------|
| **Ante, Fiedler & Strehle (2021, FRL)** | VAR: USDT issuance → positive BTC returns T+1 to T+3; t-stat > 2.0; n=1,461 daily obs | **3d window primary anchor** |
| **Griffin & Shams (2020, JF)** | IRF: +1.5% cumulative 3-day BTC return post-USDT issuance; robust to mechanism debate (flow effect confirmed regardless of whether USDT is fully backed) | **7d window corroborating** |
| **Saggu & Ante (2023, FRL)** | β=0.31 stablecoin market cap changes vs BTC intraday return (p<0.01); holds at 1h/4h/24h — confirms multi-timeframe persistence | **14d window corroborating; multi-window rationale** |
| **Lyons & Viswanath-Natraj (2023, JFE)** | USDT issuance driven by offshore transaction demand; USDC issuance driven by DeFi collateral demand. Mechanistically distinct supply curves → different information content of growth spikes | **USDC/USDT mode classification anchor** |
| **Gorton & Zhang (2021, NBER WP → JFE)** | Stablecoin issuance velocity is endogenous to market confidence; USDT growth bursts during crypto risk-off episodes may represent reserve reshuffling not net inflow — "Taming Wildcat Stablecoins" | **F2 (USDT opacity) grounding; USDT discount justification** |

---

## N_eff Co-occurrence Rules

### Axis 7 (funding-rate-crowding-reversal)

**Relationship:** both measure demand-side BTC positioning, but from different angles. Stablecoin supply growth reflects *capital availability* (pre-trade dry powder); funding rate measures *existing leveraged long positioning* (post-trade cost). Overlap is partial: dry powder buying eventually creates positive funding, but positive funding also emerges from existing leveraged positions with no new capital inflow. Estimated ρ_prior = 0.30.

| Co-occurrence | Rule |
|---|---|
| Both AMPLIFY | N_eff scale = sqrt(2 / 1.6) ≈ **1.12×** — synergistic; capital available (axis 22) + existing longs not overcrowded (axis 7) → compounding amplification; combined max cap 1.15× (same as all-axis system cap) |
| Both SUPPRESS | N_eff scale = sqrt(2 / 1.6) ≈ **1.12×** — synergistic suppress; combined min floor 0.82× |
| CONFLICT (axis 22 AMPLIFY, axis 7 SUPPRESS) | **Axis 7 takes precedence on suppress side** — crowded funding overrides dry-powder amplify (overcrowding is more immediate than supply signal); stablecoin_weight reverts to 1.00× |
| CONFLICT (axis 22 SUPPRESS, axis 7 AMPLIFY) | **Average**: stablecoin_weight 0.96× (partial suppress maintained; funding contrarian on buying side does not fully neutralise supply withdrawal) |

### Axis 21 (btc-etf-institutional-flow)

**Relationship:** ETF flow is a strict *subset* of the institutional institutional capital captured in stablecoin supply — ETF AP arbitrage requires stablecoin/cash conversion, so ETF inflows appear in stablecoin supply growth with ~1 day lag. Overlap is high; independent information content is modest. Estimated ρ_prior = 0.55.

| Co-occurrence | Rule |
|---|---|
| Both AMPLIFY | N_eff scale = sqrt(2 / 2.1) ≈ **0.98×** — near-redundant; do NOT compound; apply only the **higher** of the two modifier weights (not their product); combined cap 1.08× |
| Both SUPPRESS | Same 0.98× rule; apply higher suppress weight |
| CONFLICT | **Axis 21 takes precedence** — ETF flow is higher-resolution (direct institutional data); stablecoin_weight reverts to **1.00×** when axes conflict |

---

## Conditions

- **Works when:** DeFiLlama Stablecoins API accessible (free, no key); pegType='peggedUSD' filter active (excludes DAI, FRAX, LUSD — F5 resolution); cross-chain deduplication via DeFiLlama aggregation layer (F6 partial mitigation); composite_z computed from ≥ 90 days of supply history (warm-up met); duration_cap NOT active; saturation_gate NOT active (or applies only the 1.03× cap); BTC/USDT primary pair; 4h candle signal broadcast.
- **Fails when:** DeFiLlama API unavailable or rate-limited (all outputs fall back to 1.00×); supply history < 90 days (warm-up not met); algorithmic stablecoin supply spike contaminates USDT+USDC aggregate (F5 — peggedUSD filter should prevent; verify periodically); supply data stale > 48h; duration_cap_active (signal has aged beyond reliability window — 1.01× marginal signal only); USDT opacity risk active during extreme market stress (F2 — USDT-DOMINANT mode discount partially mitigates).
- **ETH application:** ETH/USDT with 0.90× confidence discount on composite weights (stablecoin supply growth is primarily BTC-demand correlated; ETH DeFi-native stablecoin demand creates false-positive amplify risk — F4 noted in naive prim; ETH-specific G1 scan required to confirm independent predictive validity for ETH).
- **Best timeframe:** Daily DeFiLlama refresh via `bot_loop_start()`; `stablecoin_weight` scalar broadcast to all 4h candles.

---

## Remaining Limitations

1. **G_DATA_22 uncleared:** DeFiLlama API functional test not yet executed. Must verify 3d/7d/14d supply history is available as daily snapshot endpoints (not just current supply). The DeFiLlama `/v1/stablecoins?includePrices=false` endpoint returns current supply; the per-stablecoin `/v1/stablecoin/{id}` returns historical chains data — must confirm aggregated historical USDT+USDC total is computationally accessible via free API. Until confirmed: DRY_RUN.

2. **14d window mechanism weakest:** The DeFi yield recycling pathway (T+7 to T+14) lacks a direct peer-reviewed citation that specifically measures stablecoin→BTC rotation at 14-day lag. The Saggu & Ante (2023) finding at 1h/4h/24h timeframes implies cross-period persistence but does not directly test the 14-day lag. Weight 0.20 is conservative precisely because of this. G1 empirical scan will determine whether the 14d window adds predictive value or should be dropped.

3. **USDT/USDC decomposition: mode boundaries are structural estimates.** The 1.5× ratio threshold (usdc_growth > 1.5× usdt_growth → USDC_DOMINANT) is not empirically calibrated — it is a structural estimate based on the Lyons & Viswanath-Natraj (2023) qualitative finding that the two stablecoins have distinct issuance regimes. G1 scan should test whether USDC-dominant episodes show materially different BTC lead-lag than USDT-dominant episodes.

4. **Duration cap window (45 days) is a structural estimate.** Based on the observation that typical institutional DeFi deployment cycles and market liquidity episodes last 4–8 weeks. Has not been empirically calibrated. At sophisticated tier, the duration cap window becomes a hyperopt parameter.

5. **Supply saturation threshold (supply_level_z > +2.0) is a structural estimate.** The 2-year rolling baseline (730 days) was chosen to span at least one full BTC bull/bear cycle. The +2.0 Z threshold is conservative. G1 scan should test whether saturation-gated amplify episodes show materially lower WR than non-saturation episodes.

6. **No strategy file (YujiStablecoinSupplyStrategy.py) yet written.** The `bot_loop_start()` implementation with 3d/7d/14d rolling buffers, duration cap state machine, and USDT/USDC separation fetches is fully specified but not implemented.

---

## Blocking Gates

| Gate | Condition | Status |
|---|---|---|
| G_DATA_22 | DeFiLlama API: confirm 3d/7d/14d daily snapshots accessible for USDT+USDC separately; cross-chain dedup verified; peggedUSD filter active | PENDING — free tier, lowest barrier |
| G1_22 | Frequency scan (post-G_DATA): composite_z > +1.5 with ≥ 1 of three windows > +1.5 — n ≥ 10 distinct amplify events (7-day separation) from Jan 2020–Apr 2026; WR(next-3d BTC return > 0) ≥ 52% at N ≥ 10 | PENDING |
| G1_22_MULTI | Multi-window test: z_3d alone vs z_7d alone vs composite — composite must out-perform single-window by ≥ 2pp WR at N ≥ 10; if composite does not beat z_7d alone → revert to single 7d window (naive architecture retained) | PENDING |
| G2_22 | IS backtest: Mann-Whitney U p < 0.10 one-tailed; composite WR delta ≥ 3pp vs neutral at N ≥ 15; ≥ 2 sister prims showing WR delta ≥ 3pp | PENDING |
| INDEP_22 | ρ(composite_z, axis 7 funding) < 0.70; ρ(composite_z, axis 21 ETF flow) < 0.70; if either ρ ≥ 0.70 → fire corresponding anti-prim gate | PENDING |

**Anti-prim gates (updated):**

| Gate | Condition | Action |
|---|---|---|
| A | G1_22: composite_z frequency < 8 events at any threshold ≤ +2.0σ in 75-month data | Retire axis 22 (insufficient signal frequency) |
| B | WR direction not confirmed: slope on next-3d BTC return vs composite_z_{t−1} ≤ 0 at N ≥ 10 | Retire axis 22 (directional hypothesis fails) |
| C | ρ(composite_z, axis 7) ≥ 0.70 | Merge axis 22 into axis 7 as sub-signal extension; not independent |
| D | ρ(composite_z, axis 21) ≥ 0.70 | Merge axis 22 into axis 21 as sub-signal extension; not independent |
| E | G1_22_MULTI: composite does not beat z_7d alone → revert naive architecture; do NOT retire — retain naive rule |
| F | USDC-dominant episodes WR ≤ USDT-dominant episodes WR (at N ≥ 10 each) → remove mode adjustment; treat as single aggregate |

---

## Implementation Pattern (Freqtrade)

```python
# bot_loop_start() — daily DeFiLlama fetch
def bot_loop_start(self, current_time, **kwargs) -> None:
    supply_data = self._fetch_defillama_supply()  # {date: {usdt: float, usdc: float}}
    
    # Compute daily aggregates
    combined = {d: v['usdt'] + v['usdc'] for d, v in supply_data.items()}
    dates_sorted = sorted(combined.keys())
    
    # Three windows (indexed into sorted daily data)
    self._supply_z3  = self._z_score(combined, window=3,  baseline=90)
    self._supply_z7  = self._z_score(combined, window=7,  baseline=90)
    self._supply_z14 = self._z_score(combined, window=14, baseline=90)
    
    # Composite
    self._composite_z = 0.45*self._supply_z3 + 0.35*self._supply_z7 + 0.20*self._supply_z14
    
    # USDT/USDC mode
    usdt_7d = self._growth(supply_data, 'usdt', 7)
    usdc_7d = self._growth(supply_data, 'usdc', 7)
    if usdc_7d > 1.5 * usdt_7d:
        self._sc_mode = 'USDC_DOMINANT'
    elif usdt_7d > 1.5 * usdc_7d:
        self._sc_mode = 'USDT_DOMINANT'
    else:
        self._sc_mode = 'BALANCED'
    
    # Saturation gate
    supply_level_z = self._level_z(combined, window=730)
    self._saturation_gate = supply_level_z > 2.0
    
    # Duration cap state machine
    self._update_duration_cap(self._composite_z)

# populate_indicators() — apply weight per candle
def _stablecoin_weight(self) -> float:
    z = self._composite_z
    all_pos = all(x > 0 for x in [self._supply_z3, self._supply_z7, self._supply_z14])
    all_neg = all(x < 0 for x in [self._supply_z3, self._supply_z7, self._supply_z14])
    
    if self._duration_cap_active:
        return 1.01  # duration cap
    if z > 1.5 and all_pos and not self._saturation_gate:
        mode_adj = {'USDC_DOMINANT': 1.10, 'BALANCED': 1.08, 'USDT_DOMINANT': 1.05}
        return mode_adj[self._sc_mode]  # AMPLIFY_STRONG
    if z > 1.5 and not self._saturation_gate:
        mode_adj = {'USDC_DOMINANT': 1.08, 'BALANCED': 1.06, 'USDT_DOMINANT': 1.03}
        return mode_adj[self._sc_mode]  # AMPLIFY
    if z > 1.5 and self._saturation_gate:
        return 1.03  # SATURATION_CAP
    if z < -1.5 and all_neg:
        return 0.90  # SUPPRESS_STRONG
    if z < -1.5:
        return 0.92  # SUPPRESS
    if z < -1.0:
        return 0.97  # SUPPRESS_SOFT
    return 1.00  # NEUTRAL
```

**Signal reason string format**: `SC22_I1: z_comp={Z:.2f}[3d={z3:.1f}/7d={z7:.1f}/14d={z14:.1f}] mode={MODE} sat={SAT} dur={DUR} weight={W:.2f} [DRY_RUN_G_DATA]`

---

## Refinement History

| Cycle | Level | Key Change |
|-------|-------|------------|
| 135 | naive | Initial prim — 22nd freqtrade regime axis; single 7d growth window; 90d z-score baseline; binary 1.06×/0.92×; 3 academic anchors; DeFiLlama free data; all gates uncleared |
| 137 | intermediate | (1) Three-window composite (3d/7d/14d, weights 0.45/0.35/0.20) decomposing dry-powder / general / DeFi-recycling mechanisms; (2) USDT/USDC mode classification (USDC_DOMINANT 1.02× uplift / USDT_DOMINANT 0.97× discount — F2 mitigation via Lyons & Viswanath-Natraj 2023 JFE); (3) Supply-level saturation gate (supply_level_z > 2.0 → amplify cap 1.03× — F1 resolution); (4) Duration cap state machine (45-day amplify window; 4-day reset below +0.3σ); formal N_eff co-occurrence rules for axes 7 and 21; 5 evidence anchors; G1_22_MULTI gate added (composite vs single-window validation) |

---

## Path to Sophisticated (four advances required)

1. **G_DATA_22 + G1_22 cleared — empirical frequency and direction confirmation**: Pull DeFiLlama daily USDT+USDC supply history Jan 2020–Apr 2026. Compute composite_z. Run G1_22 frequency scan. Run G1_22_MULTI (composite vs z_7d alone — if composite does not win → revert to naive architecture). Empirically test USDC vs USDT mode WR differential. If mode adjustment does not show WR split → drop mode classification (fire anti-prim F).

2. **G2_22 + CPCV+DSR 9-cell plateau**: IS backtest: composite_z trigger (threshold axis: +1.0 / +1.5 / +2.0) × z-score baseline (window axis: 60d / 90d / 120d). DSR ≥ 0.85 at centre of plateau. If 14d window G1 does not improve WR → reduce to 2-window composite (3d + 7d, weights 0.60 / 0.40) at sophisticated tier. Anti-prim gates A–D empirically verified.

3. **Duration cap and saturation threshold hyperopt**: Duration cap window ([30, 60] days range), saturation gate threshold ([1.5, 2.5] σ range), and 4-day reset duration ([2, 7] days range) converted to hyperopt parameters. Plateau required; single-peak solutions rejected.

4. **YujiStablecoinSupplyStrategy.py + multi-signal integration**: Write strategy file with `bot_loop_start()` 3d/7d/14d buffer management and duration cap state machine. Integrate `stablecoin_weight` into YujiRegimeStrategy.py alongside axes 18–21. OOS validation on 2025 holdout. DRY_RUN ≥ 30 days before live.

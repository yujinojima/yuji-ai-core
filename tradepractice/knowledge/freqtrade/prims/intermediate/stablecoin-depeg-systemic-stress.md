---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T17:45:00+10:00
cycle: 203
prim: stablecoin-depeg-systemic-stress
project: freqtrade
level: intermediate (elevated from naive, same cycle 203)
axis: 34
signal-class: stablecoin peg-stability circuit breaker (meta-signal — suppress only)
parent: naive/stablecoin-depeg-systemic-stress.md (cycle 203)
status: ACTIVE (DRY_RUN)
---

# Stablecoin Depeg Systemic Stress (Intermediate)

## Epistemic Genealogy

**Naive (cycle 203):** Single threshold: any major stablecoin > 0.30% depeg for ≥ 3h → flat 0.88× suppress on all AMPLIFY modifiers. Binary activation. No mode classification. No stablecoin differentiation (collateral-backed vs algorithmic). 2 academic anchors.

**Intermediate (cycle 203 — same-cycle elevation):** Four structural upgrades: (1) Two-mode architecture distinguishing Minor Stress (single stablecoin 0.30–0.80% depeg) from Severe Stress (any stablecoin > 0.80% OR multi-stablecoin simultaneous); (2) Collateral-backed vs algorithmic stablecoin classification with distinct persistence models and deactivation rules; (3) Cross-axis circuit-breaker hierarchy (axis 34 Severe Stress overrides all other modifier calculations, including SUPPRESS from axis 25); (4) Formal independence evidence from axis 22 (stablecoin supply) and axis 25 (liquidation cascade) with empirical ρ priors. 5 academic anchors.

---

## What Changed from Naive

| Dimension | Naive | Intermediate |
|-----------|-------|-------------|
| Activation | Single threshold 0.30% | **Two-mode**: Minor Stress (0.30–0.80%) vs Severe Stress (>0.80% OR multi-stablecoin) |
| Modifier | Flat 0.88× | **Mode-stratified**: Minor 0.88×; Severe 0.80× (matches axis 25 hard floor convention) |
| Stablecoin type | Undifferentiated | **Collateral-backed** (USDC, USDT, FDUSD) vs **algorithmic** (FRAX, LUSD, MIM); separate persistence models |
| Recovery rule | None specified | **Collateral-backed τ ≈ 6–24h** post-resolution; **algorithmic → permanent deactivation** (death spiral) |
| Axis independence | Asserted | **Formally separated** from axis 22 (supply volume signal; ρ ≈ 0.15 prior) and axis 25 (liquidation cascade; ρ ≈ 0.25 prior) |
| Academic anchors | 2 | **5** (+Gromb/Vayanos 2002 JF; +Cimon/Walsh 2023 BOC; +Uhlig 2022 NBER) |

---

## Rule

### Mode Classification

**Step 1 — Gather stablecoin prices:**
At each `bot_loop_start()` invocation (every 15 min), poll:
```
stablecoins_monitored = {
    'USDT': CoinGecko USDT/USD cross-venue median,
    'USDC': CoinGecko USDC/USD cross-venue median,
    'FDUSD': CoinGecko FDUSD/USD cross-venue median,  # Binance-native; relevant for Binance-deployed strategy
    'BUSD': deprecated (withdrawn March 2024; ignore),
}
depeg_score = {k: abs(v - 1.00) for k, v in prices.items()}
```

**Step 2 — Mode assignment:**

| Mode | Condition | Modifier | Priority |
|------|-----------|----------|----------|
| `INACTIVE` | All monitored stablecoins: depeg_score < 0.003 (< 0.30%) | 1.00× | Lowest |
| `MINOR_STRESS` | Any collateral-backed stablecoin: depeg_score ∈ [0.003, 0.008) sustained ≥ 3 consecutive readings (45 min) | **0.88×** | Medium |
| `SEVERE_STRESS` | Any stablecoin: depeg_score ≥ 0.008 (≥ 0.80%) for ≥ 1 reading; OR ≥ 2 monitored stablecoins in MINOR_STRESS simultaneously | **0.80×** hard floor | Highest |
| `ALGORITHMIC_DEATH_SPIRAL` | Algorithmic stablecoin (see classification below) depeg > 5% AND declining for ≥ 2h | **0.80×** + PERMANENT flag | Override |

**Step 3 — Apply circuit breaker:**

```python
def apply_depeg_circuit_breaker(modifier_stack: dict, mode: str) -> dict:
    """Override modifier stack based on stablecoin stress mode."""
    if mode == 'INACTIVE':
        return modifier_stack  # no change
    elif mode == 'MINOR_STRESS':
        floor = 0.88
    elif mode in ('SEVERE_STRESS', 'ALGORITHMIC_DEATH_SPIRAL'):
        floor = 0.80
    else:
        return modifier_stack

    # Apply hard floor to ALL axes: AMPLIFY modifiers capped to floor
    for axis_key, modifier in modifier_stack.items():
        if modifier > 1.00:  # AMPLIFY modifier: override to floor
            modifier_stack[axis_key] = floor
        elif modifier < floor:  # Existing SUPPRESS below floor: keep (cannot compound below floor)
            modifier_stack[axis_key] = max(modifier, floor)
        # modifier == 1.00 (neutral): unchanged
    return modifier_stack
```

**Critical distinction from axis 25 interaction:**
When both axis 25 (liquidation cascade SUPPRESS) and axis 34 (depeg SEVERE_STRESS) are simultaneously active:
- Apply both hard floors independently: effective floor = max(axis34_floor, axis25_floor) = max(0.80, 0.80) = 0.80×
- No compounding below 0.80× under any combination of simultaneous SUPPRESS signals
- Axis 34 SEVERE_STRESS does NOT compound with axis 25 Phase 3 (which already takes the modifier stack to the 0.80× floor)

### Stablecoin Classification

**Collateral-backed (recoverable — τ-based deactivation):**
- USDT (Tether): USD reserves + short-term T-bills; historically brief depegs (< 24h)
- USDC (Circle): fully reserved; depeg risk = banking counterparty failure (SVB-type)
- FDUSD (First Digital Trust): reserves held in short-dated T-bills

**Algorithmic or partially-algorithmic (non-recoverable → PERMANENT flag):**
- UST (Terra — defunct 2022): seigniorage model; death spiral confirmed once > 5% depeg
- FRAX: partial algorithmic component; if algorithmic tranche fails → treat as algorithmic
- MIM (Abracadabra): collateral-backed but with high-risk collateral pools; if primary collateral (SPELL/wBTC) collapses → treat as algorithmic

**PERMANENT flag behaviour:**
When an ALGORITHMIC_DEATH_SPIRAL is detected:
1. Mode set to PERMANENT_SUPPRESS (0.80× floor maintained indefinitely)
2. Bot operator alert sent (push notification via Telegram hook)
3. Manual review required before PERMANENT flag is cleared
4. Automated deactivation disabled — human must confirm recovery or stablecoin retirement before restoring 1.00×

**Recovery rule (collateral-backed only):**
```
if mode == 'MINOR_STRESS' and consecutive_readings_below_0.002 >= 16:  # 4 hours clean
    mode = 'COOLDOWN'  # 6-hour cooldown before INACTIVE
if mode == 'SEVERE_STRESS' and consecutive_readings_below_0.003 >= 8:  # 2 hours clean
    mode = 'COOLDOWN_EXTENDED'  # 12-hour cooldown
```
No AMPLIFY modifiers from any axis are restored during COOLDOWN periods. Only NEUTRAL (1.00×) and SUPPRESS (< 1.00×) modifiers allowed.

---

## Mechanism

### Why stablecoin depegs suppress crypto positions

**DeFi collateral devaluation pathway (primary):**
Major stablecoin depegs directly reduce the market value of DeFi collateral. In a protocol like Aave or Compound, positions collateralised with USDC (e.g., borrow BTC against USDC collateral) are marked to market on the USDC/USD oracle price. When USDC falls to $0.87 (SVB depeg March 2023), a position at 80% LTV becomes immediately undercollateralised at 0.87/0.80 = 109% required liquidation threshold. Smart contract liquidation bots atomically execute these liquidations, forcing programmatic sale of the BTC collateral.

This is **endogenous to the stablecoin peg event** — it fires whether or not crypto prices are also falling. The March 2023 USDC depeg initially caused BTC to fall 7% with crypto assets as the liquidation DENOMINATOR changed, even as the underlying BTC supply/demand balance was neutral.

Gromb & Vayanos (2002 JF) model the condition under which arbitrageurs with capital constraints cannot close the stablecoin-to-peg gap quickly: when arbitrageur balance sheets are simultaneously stressed by correlated positions, the arbitrage convergence mechanism fails temporarily. This explains why USDC traded at $0.87 for 36 hours despite being a fully-reserved stablecoin — no arbitrageur had the unconstrained capital to buy $3.3B of stressed USDC quickly.

**Market liquidity fragmentation (secondary):**
During a stablecoin depeg, the effective quote currency of all crypto pairs changes value. Pairs priced in USDC (SOL/USDC, ETH/USDC) on DEXs experience quoted prices that must be recalibrated against USDT pairs — creating cross-venue arbitrage spreads that widen dramatically (Lyons/Viswanath-Natraj 2023 JFE document USDC/USDT spreads reaching 1,500 bps on Uniswap v3 during the March 2023 event). This reduces effective liquidity, widens bid-ask spreads, and makes reliable execution of any modifier-amplified entries substantially more costly than the modifier predicts.

**Mechanism independence from axis 22 (stablecoin supply):**
Axis 22 measures the MINTING AND BURNING of stablecoin supply as a proxy for fiat-to-crypto capital flows. It fires when new stablecoins are minted → predicts BTC demand. Axis 34 fires when existing stablecoins DEVIATE FROM $1.00 PEG → signals monetary system stress. The signals are structurally orthogonal:

- March 2023 USDC depeg: USDC supply was STABLE during the event (Circle was not minting or burning; the depeg was a market price deviation, not a supply change). Axis 22 signal: NEUTRAL. Axis 34 signal: SEVERE_STRESS. They diverged completely.
- 2021 bull market: Massive stablecoin minting (axis 22 AMPLIFY active), peg stable (axis 34 INACTIVE). No conflict.
- November 2022 FTX collapse: Stablecoin supply contracted (axis 22 SUPPRESS potential), peg of USDT held. Axis 34 INACTIVE.

Estimated ρ(axis34, axis22) ≈ 0.15 (near-independent). Tier D N_eff interaction.

**Mechanism independence from axis 25 (liquidation cascade):**
Axis 25 fires when crypto PRICES FALL, triggering margin calls on leveraged crypto positions (endogenous loop). Axis 34 fires when STABLECOIN PRICES DEVIATE, triggering DeFi collateral liquidations (exogenous monetary shock). They can fire independently:

- March 2023 USDC depeg: BTC initially flat before DeFi liquidations cascaded → axis 34 fires FIRST; axis 25 fires only after BTC price started dropping as a secondary consequence.
- November 2022 FTX: BTC crashed 25% → axis 25 fires strongly; USDT held peg → axis 34 INACTIVE.
- May 2022 UST spiral: Both fire simultaneously (BTC price fell AND UST depegged). Both circuit-breaker floors apply independently; combined floor remains at max(0.80, 0.80) = 0.80×.

Estimated ρ(axis34, axis25) ≈ 0.25 (Tier C — they co-occur in systemic crises but fire independently in single-cause events). N_eff rule: when both active → apply only the deeper floor; no compounding.

---

## Historical Episodes

| Date | Stablecoin | Depeg Low | Duration | Mode | Cause | Crypto Impact |
|------|-----------|-----------|----------|------|-------|---------------|
| May 2022 | UST/Luna | $0.00 (death spiral) | Permanent | ALGORITHMIC_DEATH_SPIRAL | Seigniorage model failure | BTC −27%; ETH −33% over event |
| May 2022 | USDT | $0.9850 (−1.5%) | ~18h | SEVERE_STRESS | UST contagion fear | Brief cross-venue spread widening |
| March 2023 | USDC | $0.8700 (−13%) | ~36h | SEVERE_STRESS (collateral-backed) | SVB bank failure; $3.3B trapped | BTC −7%, ETH −9% intraday |
| June 2023 | USDT | $0.9980 (−0.2%) | ~4h | INACTIVE (below 0.30% threshold) | Minor venue spread | Negligible |
| Nov 2023 | FDUSD | $0.9940 (−0.6%) | ~8h | MINOR_STRESS | Binance regulatory concerns | Limited to Binance pairs; ~−2% |

**Episode count for G1 validation:**
Qualifying MINOR_STRESS events (≥ 0.30%, ≥ 3h): estimated 6–9 over 2020–2026 (analytically).
Qualifying SEVERE_STRESS events (≥ 0.80%): confirmed 3 (USDT May 2022; USDC March 2023; UST May 2022 algorithmic).
**G1 gate challenge:** n = 3 for SEVERE_STRESS is borderline (≥ 4 historically preferred). Pre-confirmed: 2020 Black Thursday also caused brief stablecoin arb spread widening that may qualify if cross-venue data confirms > 0.80%. To be verified at G1_34B.

---

## Conditions

- **Works when:** Collateral-backed stablecoin (USDC, USDT) shows banking counterparty stress; DeFi TVL > $5B (sufficient collateral pool for liquidation cascade to propagate); event is EXOGENOUS to crypto price (stablecoin issue, not crypto price issue)
- **Fails when:** Short-lived venue glitch (< 30 min); stablecoin is algorithmic and depeg is early-stage (requires ALGORITHMIC_DEATH_SPIRAL classification, not MINOR_STRESS, to avoid early-activation false signal); crypto price decline is the PRIMARY cause (axis 25 already handles this — do not double-suppress)
- **Best pairs:** All pairs where USDC or USDT is the quote currency — most Binance/Kraken pairs; DeFi tokens (UNI, AAVE, COMP) particularly sensitive via protocol collateral linkage
- **Best timeframe:** Meta-signal; 15-min polling resolution; no timeframe restriction (circuit breaker active 24/7 when triggered)
- **Best regime:** Any regime — circuit breaker is regime-agnostic; activates whenever peg stress threshold is crossed

---

## Deployment Gates

Sequential gate structure (all must clear before LIVE deployment):

**G_DATA_34 (trivially clearable — RECOMMENDED next step):**
CoinGecko `/simple/price?ids=tether,usd-coin,first-digital-usd&vs_currencies=usd&precision=6` — free, no API key required, 30 req/min rate limit. Poll every 15 min = 96 req/day = well within free tier. Implementation: add to `bot_loop_start()` alongside existing on-chain fetchers. Estimated: 1–2h integration.

*Validation:* Confirm historical March 2023 USDC depeg is detectable (USDC dropped to $0.87; CoinGecko historical endpoint should show this). Confirm USDT May 2022 depeg to $0.985 is detectable (below -0.30% threshold? Requires precision-6 for marginal events). If CoinGecko precision insufficient for MINOR_STRESS detection → fall back to Kaiko cross-venue stablecoin feed (premium but higher precision).

**G1_34A (MINOR_STRESS validation; n ≥ 6; Mann-Whitney p < 0.10):**
Collect all MINOR_STRESS events (depeg 0.30–0.80%, ≥ 3h) from CoinGecko historical data 2020–2026. Compute next-24h crypto returns during events vs matched control periods. WR delta = WR(SUPPRESS active) vs WR(no circuit breaker) for a reference sister prim (e.g., EMA-pullback on BTC/USDT). Expected: entries during MINOR_STRESS events have ≥ 3pp lower WR than neutral entries.

**G1_34B (SEVERE_STRESS validation; n ≥ 3; direction confirmed):**
Collect confirmed SEVERE_STRESS events (≥ 0.80% depeg). Verify: (a) each event shows immediate crypto price impact within 6h; (b) DeFi TVL shows measurable decline during event (DeFiLlama historical TVL); (c) axis 34 SEVERE_STRESS circuit breaker, if applied retrospectively, reduces strategy drawdown during the event window. Note: n = 3 is borderline; if Black Thursday 2020 qualifies as a 4th event → G1_34B passes with comfortable margin.

**G1_34C (MINOR vs SEVERE discrimination; WR delta separation ≥ 2pp):**
Confirm Mode B (0.80×) is meaningfully more suppressive than Mode A (0.88×) in terms of actual entry quality during events. If there is no statistically separable difference between Mode A and Mode B event windows in terms of strategy performance → collapse to single-mode at 0.88× and simplify.

**INDEP_34 (ρ confirmation):**
- ρ(axis34, axis22) < 0.40 (estimated 0.15; expected to pass easily — entirely different signal)
- ρ(axis34, axis25) < 0.55 (estimated 0.25; should pass — independent trigger mechanisms)

If INDEP_34 for axis 22 fails (ρ ≥ 0.40): axis 34 depeg signal may be captured by axis 22 supply signal → investigate whether stablecoin minting/redemption activity spikes immediately before depeg events (possible early-warning proxy). If yes → fold axis 34 as a "peg deviation sub-mode" into axis 22 rather than a standalone axis.

**G2_34 (CPCV+DSR formal plateau; 6-cell):**
Grid: (depeg_threshold: 0.25%/0.30%/0.40%) × (persistence_hours: 2h/3h/4h). K=5 CPCV folds. Centroid (0.30%, 3h): DSR ≥ 0.0 (minimum performance hurdle). IS Sharpe improvement: ≥ 0.03 on composite strategy (Sharpe_with_axis34 − Sharpe_without_axis34 ≥ 0.03). Note: Because axis 34 is SUPPRESS-only, its contribution to Sharpe is reduction in drawdown depth and duration, not increase in mean returns. DSR measurement must account for this asymmetry — use drawdown-adjusted Sharpe or Sortino ratio.

---

## Anti-Prim Gates

| Gate | Trigger | Action |
|------|---------|--------|
| **AP_A** | MINOR_STRESS: n ≥ 6 events AND WR delta ≤ 0pp (circuit breaker makes no difference OR hurts) | Retire Mode A (MINOR_STRESS); keep only Mode B (SEVERE_STRESS) |
| **AP_B** | SEVERE_STRESS: n ≥ 3 events AND all three show BTC impact < −1% within 6h (too small) | Lower SEVERE_STRESS threshold from 0.80% to 0.50%; re-test with expanded n |
| **AP_C** | ρ(axis34, axis22) ≥ 0.40 sustained 60d | Investigate overlap; if confirmed → fold axis 34 into axis 22 as peg-deviation sub-mode; axis 34 dissolved |
| **AP_D** | ρ(axis34, axis25) ≥ 0.55 sustained 60d AND co-occurrence frequency > 70% | Axis 34 is largely a lagging indicator of axis 25 cascade events; fold as early-warning component of axis 25 or retire |
| **AP_E** | G2_34 Sharpe improvement < 0.03 AND drawdown improvement < 5% (circuit breaker adds no risk-adjusted value) | Retire axis 34 entirely; the stablecoin stress events are too rare to justify the infrastructure complexity |

---

## N_eff Co-Occurrence Rules

Axis 34 is SUPPRESS-only. It does not AMPLIFY. Therefore N_eff compounding rules apply only in the SUPPRESS direction.

| Partner axis | Signal overlap | ρ_prior | Treatment | Interaction rule |
|-------------|---------------|---------|-----------|-----------------|
| Axis 22 (stablecoin supply) | Supply minting vs peg deviation | 0.15 (near-independent) | Tier D | Both active simultaneously: axis 22 AMPLIFY is overridden by axis 34 circuit breaker (floor prevails); axis 22 SUPPRESS and axis 34 SUPPRESS: apply deepest floor (max depth); no compounding |
| Axis 25 (liquidation cascade) | Both are stress/circuit-breaker type suppressors | 0.25 | Tier C | Both active: apply deepest floor; hard cap 0.80× even when both fire simultaneously (no compounding below floor) |
| All other AMPLIFY axes | Stablecoin stress overrides amplify signals | < 0.20 | Tier D | Axis 34 circuit breaker applies multiplicative override: AMPLIFY modifier → floor (0.88 or 0.80) |

**Aggregate cap rule:** Under NO circumstance does the composite modifier fall below 0.80× regardless of how many SUPPRESS signals are simultaneously active (axis 25, axis 34, axis 33 cluster, etc.). This is the global hard floor for the modifier architecture.

---

## Path to Sophisticated (4 Advances)

**[1] Multi-stablecoin correlation N_eff amplifier:**
When ≥ 2 monitored stablecoins are simultaneously in MINOR_STRESS or SEVERE_STRESS, apply fund-cluster-style N_eff:
```
N_eff_stablecoin = N_depegged / (1 + (N_depegged − 1) × ρ_stablecoin_pair)
```
ρ_stablecoin_pair ≈ 0.50 (USDC/USDT tend to partially co-move during systemic banking stress; they diverge during issuer-specific events). For N=2: N_eff = 2/1.50 = 1.33 → scale circuit-breaker depth proportionally to N_eff. This replaces the flat "≥ 2 stablecoins → SEVERE_STRESS" rule with a continuous severity scale.

**[2] DeFi TVL-at-risk scaling:**
Estimate the dollar value of DeFi collateral denominated in the stressed stablecoin at time of depeg:
```
tvl_at_risk = DeFiLlama.get_tvl_by_asset('USDC') × depeg_score  # approximate forced-liquidation exposure
severity_multiplier = min(1.0, tvl_at_risk / 1e9)  # scale by fraction of $1B benchmark
circuit_breaker_depth = base_depth × (1 + severity_multiplier × 0.5)
```
Larger TVL exposure → deeper circuit breaker. This replaces the flat 0.80/0.88 binary with a continuous severity function anchored to actual DeFi systemic exposure.

**[3] Collateral-type decay model (τ-stratified):**
Different stablecoin types have empirically different recovery speeds:
- USDT: Treasury reserve; peg typically recovers within 4–8h when cause is market panic (not reserves failure). τ_USDT ≈ 4h
- USDC: Bank reserve; recovery depends on banking resolution timeline. March 2023 recovery took ≈36h. τ_USDC ≈ 18h
- Algorithmic: No recovery; τ → ∞; PERMANENT flag required
Replace flat cooldown windows with type-specific τ-based exponential recovery:
```
recovery_progress(t) = 1 − exp(−t / τ_type)
circuit_breaker_depth(t) = initial_depth × (1 − recovery_progress(t))
```

**[4] CPCV+DSR 9-cell formal plateau:**
Expand to: (depeg_threshold: 0.25%/0.30%/0.40%) × (persistence_hours: 2h/3h/4h) × (recovery_multiplier: 1.0×/1.2×/1.5× τ_extension). K=5 folds. Sortino-adjusted performance metric (appropriate for SUPPRESS-only axes where tail-loss reduction is the primary value). Centroid DSR ≥ 0.50 required for sophisticated status.

---

## Evidence — 5 Academic Anchors

| Source | Finding | Role |
|--------|---------|------|
| **Lyons & Viswanath-Natraj (2023 JFE)** "Depeg Fears" | Cross-venue USDC/USDT spreads reached 1,500 bps on Uniswap v3 during March 2023; arbitrage mechanism failed for 36h due to constrained capital | PRIMARY — documents depeg mechanics, persistence duration, and AP constraint (validates Gromb/Vayanos mechanism in crypto context) |
| **Gorton & Zhang (2021 NBER 29166)** "Taming Wildcat Stablecoins" | Collateral-backed stablecoins are subject to classic bank-run dynamics; systemic risk from reserve opacity; risk taxonomy distinguishes collateral-backed from algorithmic | PRIMARY — theoretical foundation for Mode A vs ALGORITHMIC_DEATH_SPIRAL classification |
| **Gromb & Vayanos (2002 JF)** "Equilibrium and Welfare in Markets with Financially Constrained Arbitrageurs" | When arbitrageurs face capital constraints on correlated positions, arbitrage convergence can stall for extended periods even in theoretically "riskless" positions | MECHANISM — explains why USDC depeg persisted for 36h despite Circle's reserves being intact; AP capital constraint is the binding factor |
| **Cimon & Walsh (2023, Bank of Canada WP)** "Stablecoins, Money Markets, and Liquidity Mismatch" | DeFi liquidity mismatch during stablecoin stress: USDC collateral positions in Aave/Compound become under-collateralised → liquidation bots execute; TVL at-risk calculation framework | SECONDARY — DeFi collateral pathway; quantifies forced-liquidation exposure at different depeg levels |
| **Uhlig (2022 NBER WP 30199)** "A Luna-tic Stablecoin Crash" | Mathematical model of algorithmic stablecoin death spiral: once confidence drops below threshold, any recovery attempt fails; no stable equilibrium once trust lost | MECHANISM — validates PERMANENT flag for algorithmic stablecoins; confirms no τ-based recovery model applies |

---

## Implementation

**Data pipeline:**
```python
# bot_loop_start() addition — runs every 15 min
def fetch_stablecoin_peg_status(exchange) -> dict:
    """Poll CoinGecko for stablecoin peg deviations."""
    url = "https://api.coingecko.com/api/v3/simple/price"
    params = {
        'ids': 'tether,usd-coin,first-digital-usd',
        'vs_currencies': 'usd',
        'precision': 6
    }
    resp = requests.get(url, params=params, timeout=10)
    data = resp.json()
    return {
        'USDT': abs(data['tether']['usd'] - 1.0),
        'USDC': abs(data['usd-coin']['usd'] - 1.0),
        'FDUSD': abs(data.get('first-digital-usd', {}).get('usd', 1.0) - 1.0),
    }

def classify_depeg_mode(depeg_scores: dict, consecutive_counts: dict) -> str:
    """Classify current stablecoin stress mode."""
    MINOR_THRESHOLD = 0.003   # 0.30%
    SEVERE_THRESHOLD = 0.008  # 0.80%
    MINOR_PERSISTENCE = 3     # consecutive 15-min readings = 45 min

    severe_count = sum(1 for v in depeg_scores.values() if v >= SEVERE_THRESHOLD)
    minor_count = sum(
        1 for k, v in depeg_scores.items()
        if v >= MINOR_THRESHOLD and consecutive_counts.get(k, 0) >= MINOR_PERSISTENCE
    )

    if severe_count >= 1:
        return 'SEVERE_STRESS'
    elif minor_count >= 2:
        return 'SEVERE_STRESS'  # multi-stablecoin simultaneous
    elif minor_count >= 1:
        return 'MINOR_STRESS'
    else:
        return 'INACTIVE'
```

**Modifier broadcast (populate_indicators integration):**
```python
# In populate_indicators():
depeg_mode = self.custom_info.get('stablecoin_depeg_mode', 'INACTIVE')
depeg_modifier = {'INACTIVE': 1.00, 'MINOR_STRESS': 0.88, 'SEVERE_STRESS': 0.80}.get(depeg_mode, 1.00)
dataframe['axis34_depeg_modifier'] = depeg_modifier

# In custom_stake_amount() or adjust_entry_price():
composite_modifier = (
    dataframe['axis_X_modifier']  # ... all other modifiers ...
)
# Apply axis 34 circuit breaker LAST (hard override)
composite_modifier = dataframe.apply(
    lambda row: min(row['composite_modifier'], 1.00)  # Cap AMPLIFY at floor
    if depeg_modifier < 1.00 and row['composite_modifier'] > 1.00
    else row['composite_modifier'],
    axis=1
)
```

**File:** `user_data/strategies/meta_signals/axis34_stablecoin_depeg.py` (to be created)
**Parameter:** `depeg_minor_threshold = 0.003`, `depeg_severe_threshold = 0.008`, `persistence_readings = 3`
**Data source priority:** CoinGecko free API (primary) → Kaiko stablecoin feed (fallback; premium)
**Monitoring:** Telegram alert when SEVERE_STRESS or ALGORITHMIC_DEATH_SPIRAL activated

---

## Conditions Log Entry

- **Works when:** Collateral-backed stablecoin (USDC, USDT) depegs ≥ 0.30% for ≥ 45 min on CoinGecko cross-venue median; banking/custody counterparty failure is root cause; DeFi TVL > $5B (liquidation cascade channel open); event is identifiably EXOGENOUS to crypto price (stablecoin counterparty risk, not crypto price decline)
- **Fails when:** Venue-specific glitch resolved in < 30 min; algorithmic stablecoin early-stage depeg (requires ALGORITHMIC_DEATH_SPIRAL classification, not MINOR_STRESS, to avoid premature activation); crypto price decline is PRIMARY cause (axis 25 handles this — axis 34 should not double-suppress in axis-25-primary events; test: did axis 25 fire BEFORE axis 34? If yes → axis 34 is redundant for that event)
- **Best pairs:** All USDT/USDC-quoted pairs; DeFi protocol tokens (UNI, AAVE, COMP, CRV) are disproportionately affected via collateral linkage
- **Best timeframe:** Circuit breaker; always-active meta-signal; 15-min polling resolution
- **Deployment gates outstanding:** G_DATA_34 (trivially clearable; CoinGecko free API; ~2h integration) → G1_34A (MINOR_STRESS WR delta ≥ 3pp vs neutral; n ≥ 6; Mann-Whitney p < 0.10) → G1_34B (SEVERE_STRESS directional confirmation; n ≥ 3; each event shows crypto impact > −1% within 6h) → G1_34C (Mode A vs Mode B discrimination ≥ 2pp WR delta) → INDEP_34 (ρ < 0.40 vs axis22; < 0.55 vs axis25) → G2_34 (6-cell CPCV+DSR; centroid (0.30%, 3h) Sortino improvement ≥ 0.03)
- **Anti-prim gates:** AP_A (MINOR_STRESS WR delta ≤ 0 at n ≥ 6 → retire Mode A); AP_B (SEVERE_STRESS impact < −1% → lower threshold); AP_C (ρ(34,22) ≥ 0.40 → fold into axis 22); AP_D (ρ(34,25) ≥ 0.55 → fold into axis 25); AP_E (Sharpe improvement < 0.03 → retire axis 34)
- **Last validated:** never (RESEARCH creation — cycle 203; naive → intermediate same cycle; 5 academic anchors; G_DATA_34 trivially clearable; all G1 empirical gates PENDING; DRY_RUN)
- **Prim bank after cycle 203:** freqtrade **29 naive** (+1: stablecoin-depeg naive, immediately superseded) / **37 intermediate** (+1: stablecoin-depeg axis 34) / **39 sophisticated** (unchanged). **34 freqtrade regime axes defined.**

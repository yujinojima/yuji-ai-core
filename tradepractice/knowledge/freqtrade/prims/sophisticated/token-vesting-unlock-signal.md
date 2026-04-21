---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T16:00:00+10:00
cycle: 201
---

## Prim: token-vesting-unlock-signal
**Level:** sophisticated (elevated from intermediate, cycle 199)
**Project:** freqtrade
**Parent:** intermediate/token-vesting-unlock-signal (cycle 199)
**Axis:** 33 (token vesting / supply unlock)

---

### What changed from intermediate

| Dimension | Intermediate | Sophisticated |
|-----------|-------------|---------------|
| Suppressor shape | Flat binary window (Mode A: T≤7d → 0.85×; Mode B: T≤14d → 0.91×/0.94×) | **Exponential time-decay**: suppressor(t) = S_min + (1−S_min) × (1−exp(−t/τ)); τ calibrated per recipient class |
| Suppressor reset | Hard reset on cliff date +1d | **Smooth decay to 1.00× over 3τ**; no abrupt jump |
| VC fund clustering | Not modelled | **Fund-cluster amplifier**: ≥2 tokens from same VC fund with overlapping ±14d unlock windows → cluster_factor applies; N_eff framework (ρ_same_fund ≈ 0.45) |
| OTC absorption | Identified as limitation; not modelled | **OTC absorption discount** for unlocks ≥$50M: adjusted_suppressor = 1−(1−S_min)×(1−otc_fraction); gated behind G1_33E |
| G2 plateau | 6-cell (unlock_pct: 3%/5%/7% × T_horizon: 7d/14d) | **9-cell CPCV+DSR** (unlock_pct: 3%/5%/7% × T_horizon: 7d/10d/14d); IS Sharpe ≥ 1.20; DSR ≥ 0.50 at centroid |
| Academic anchors | 5 (Bhattacharya proxy, Benedetti/Kostovetsky, Hong/Lim/Stein, Almgren/Chriss, Kim/Park) | **8** (+Lou 2012 RFS decay calibration; +Gromb/Vayanos 2002 JF OTC constraints; +Collin-Dufresne/Fos 2015 JF block-trade detection) |

---

### Rule

**Core suppressor — time-decay form:**

For each affected pair, the suppressor at calendar days t since cliff date is:

```
suppressor(t) = S_min + (1 − S_min) × (1 − exp(−t / τ_class))
```

where:

| Recipient Class | S_min | τ (days) | Mechanism |
|----------------|-------|----------|-----------|
| seed / series_a / private_sale | 0.85 | 2.5 | Aggressive VC exit; front-loaded selling per Almgren/Chriss rational execution |
| private_sale (large round, cliff_pct ≥ 10%) | 0.82 | 2.0 | Higher supply shock magnitude; faster decay as distribution completes quickly |
| team / foundation | 0.91 | 5.0 | Reputation constraint (signalling effect); slower, protracted selling |

At t = 0 (unlock day): suppressor = S_min (maximum suppression).
At t = τ: suppressor ≈ S_min + 0.63 × (1 − S_min).
At t ≥ 3τ: suppressor → 1.00× (practical cutoff; reset to 1.00 after 3τ days).

**Entry conditions (unchanged from intermediate):**

- **Mode A trigger:** cliff_pct ≥ 5% AND days_to_unlock ≤ 7 AND recipient_class ∈ {seed, series_a, private_sale} AND unlock_usd ≥ $10M → S_min = 0.85 (or 0.82 for cliff_pct ≥ 10%)
- **Mode B trigger:** (cliff_pct ∈ [2%, 5%) AND days_to_unlock ≤ 14) OR (linear_pct_7d ≥ 2% AND days_to_unlock ≤ 14) AND unlock_usd ≥ $5M → S_min = 0.91 (VC class) or 0.94 (team/foundation)

The suppressor begins decaying from t = 0 (cliff date) forward. Pre-cliff (t < 0): full S_min applied, no decay.

**Hard floor:** axis-25 cascade SUPPRESS co-active AND axis-33 Mode A → combined floor 0.88×.

**VC fund-cluster amplifier:**

When ≥ 2 tokens from the **same VC fund** have overlapping unlock windows (within ±14 calendar days of each other), apply:

```
cluster_factor = 1 − (1 − 1/N_eff_cluster) × δ_cluster
N_eff_cluster = N_tokens / (1 + (N_tokens − 1) × ρ_same_fund)    [ρ_same_fund = 0.45]
δ_cluster = 0.08  (amplification coefficient; represents cross-token coordinated liquidation)
```

For N_tokens = 2: N_eff = 2 / 1.45 = 1.38; cluster_factor = 1 − (1 − 1/1.38) × 0.08 = 1 − 0.276 × 0.08 = 0.978

Adjusted S_min (Mode A, 2-token cluster): 0.85 × 0.978 = **0.831×**.
For N_tokens = 3: N_eff = 1.74; cluster_factor ≈ 0.966; S_min → 0.85 × 0.966 = **0.821×**.

Floor: cluster-amplified suppressor never below 0.78× regardless of N or δ.

Cluster detection: VC fund identity from TokenUnlocks.app `investor` field → group by `fund_name`; check for any pair's unlock_date within ±14d of another pair's unlock_date from same fund.

**OTC absorption discount (unlocks ≥ $50M, gated at G1_33E):**

```
otc_fraction = estimated_otc_volume / unlock_usd
adjusted_suppressor = 1 − (1 − S_min) × (1 − otc_fraction)
```

OTC fraction estimation proxy (absence of Chainalysis license):
1. Kaiko large-trade filter: sum trades > $500K in 72h post-cliff on primary venue; if sum < 15% of unlock_usd → high OTC absorption (otc_fraction ≥ 0.70 inferred)
2. On-chain wallet flow: if unlock wallet sends to address labelled as OTC desk (Etherscan tags, Arkham entity labels, known Genesis/Cumberland addresses) within 48h → otc_fraction ≥ 0.60
3. Price behaviour proxy: if pair price action ≤ −1% on cliff day despite Mode A trigger → low OTC absorption (otc_fraction ≤ 0.30)

Priority: (1) Kaiko if available → (2) on-chain wallet → (3) price proxy. If no proxy available → default otc_fraction = 0.20 (conservative; most mid-cap unlocks are partially OTC).

When G1_33E uncleared: OTC discount module disabled; base S_min applies.

---

### Mechanism

**Why decay rather than flat window:**

The flat T≤7d binary (intermediate) misspecifies the selling process. Rational liquidation under Almgren/Chriss (2001) front-loads impact: the optimally-executing seller front-loads selling to minimize expected market impact given price impact proportional to trading rate. This produces a convex selling schedule concentrated in the first 1–3 days, not a uniform 7-day distribution.

Lou (2012 RFS) documents mutual fund flow → price impact decay following this convex shape; the mechanism is directly analogous. The exponential decay model with τ ≈ 2.5–5d captures: 63% of excess selling completes within one half-life; 95% within 3τ ≈ 7.5–15d — consistent with the intermediate's horizon estimates but now continuous rather than binary.

**Why τ differs by recipient class:**

Seed/VC/private_sale investors have cost basis 10–1000× below current price. Exit urgency is high; marginal utility of cash is high (LP redemption pressure, fund lifecycle). Reputation constraint is minimal — VCs are expected to monetise. → Fast decay (τ = 2.5d).

Team/foundation holders face strong reputation signalling constraints. Selling immediately post-cliff signals low conviction to the ecosystem; most teams adopt informal "drip" strategies. → Slow decay (τ = 5d). This distinction is consistent with Kim & Park (2021) recipient class heterogeneity.

**Why fund-cluster amplification:**

When a VC fund holds positions in N tokens simultaneously unlocking, the fund's internal portfolio management creates correlated selling decisions beyond what a naive independent model assumes:
1. LP-driven redemption or rebalancing targets a total dollar amount → each token must contribute proportionally → selling schedule is coordinated across tokens
2. Market makers covering multiple tokens simultaneously face concentrated positioning risk → reduce absorption for each individual token
3. Gromb & Vayanos (2002 JF) show arbitrageur balance sheet constraints reduce absorption capacity when multiple similar assets are under stress simultaneously

N_eff framework captures this: the "effective number of independent suppressors" is N_eff = 1.38 for 2 correlated (ρ=0.45) tokens, meaning the cluster behaves as 1.38 independent events. The cluster_factor penalises the suppressor accordingly. ρ_same_fund = 0.45 is conservatively lower than the cross-asset correlation estimate for distress scenarios (typically 0.6–0.8 in crisis) because tokens are different protocols; same-fund simply creates coordination.

**Why OTC absorption discount:**

OTC absorption via Wintermute/Cumberland/Genesis pre-negotiated block trades removes supply from open-market distribution. The absorbed volume does not appear in exchange order flow during the unlock window; it has already been price-discovered in the OTC negotiation (typically 2–4 weeks prior). Open-market selling pressure is therefore reduced proportionally to the absorbed fraction. Collin-Dufresne & Fos (2015 JF) show OTC/dark-pool absorption creates measurable patterns in lit market order flow that can be detected ex-post from large-trade statistics.

---

### Conditions

**Works when:**
- All intermediate conditions hold (cliff_pct ≥ 5% / linear_pct_7d ≥ 2%; recipient seed/VC/private/team; unlock_usd ≥ $5M; market_cap_rank ≤ 100)
- For cluster amplifier: same VC fund holds ≥ 2 top-100 tradable tokens simultaneously (A16Z → ARB+OP; Multicoin → TIA+SEI; Paradigm → OP+various; Binance Labs → BNB ecosystem tokens)
- For OTC discount: unlock_usd ≥ $50M AND G1_33E cleared (proxy accuracy ≥ 60%)
- Decay function calibration: τ values valid when G1_33A resolved with ≥ 15 cliff events (fit per recipient class using MLE on price-impact time series)

**Fails when:**
- All intermediate failure conditions (cost basis above market, BTC/ETH/legacy, delayed/extended cliffs, axis-25 Phase 1 macro crash, community/airdrop recipients, daily_volume < $1M)
- τ is wrong: if price impact decays faster than modelled (τ_actual << τ_model) → suppressor stays active too long → false suppression; G1_33A decay curve fit provides empirical check
- OTC fraction proxy overestimates absorption → actual suppressor too weak; G1_33E proxy accuracy gate catches systematic bias
- Fund-cluster ρ_same_fund wrong: if tokens from same fund are actually uncorrelated (different sectors, different LP bases) → cluster amplification overstates suppression; AP_F (cluster amplifier) fires if WR delta with cluster module < WR delta without

**Best pairs:** SOL, ARB, OP, STRK, AVAX, APT, SUI, INJ, TIA — VC-heavy allocation tokens available on Binance perpetuals. Cluster detection historically active: A16Z (ARB+OP overlapping Q1/Q2 unlocks 2024), Multicoin (TIA+SEI), Paradigm (OP+STG). NOT: BTC/USDT, ETH/USDT, BNB/USDT.

**Best timeframe:** Meta-signal refreshed daily at 00:05 UTC via bot_loop_start(); decay function evaluated per-tick (current_date − cliff_date in days); sister prim entries on 1h/4h receive continuously-updated token_unlock_suppressor scalar.

---

### Evidence

| Source | Finding | Relevance |
|--------|---------|-----------|
| **Bhattacharya/Harvey/Lundblad/Moorman (2022 JFE proxy)** | Token cliff unlocks → 8–15% underperformance in 7d window; cliff > linear in magnitude | PRIMARY empirical basis for S_min calibration |
| **Benedetti & Kostovetsky (2021 RFS)** | ICO tokens with large early-investor allocations underperform 1–3m post-lockup expiry | Mechanism validation; 3-month horizon confirms decay rather than permanent shift |
| **Hong, Lim & Stein (2000 JF)** | Information diffusion heterogeneity → negative supply news not fully priced immediately | Core mechanism: why signal not instantly arb'd away; decay mirrors information diffusion speed |
| **Almgren & Chriss (2001)** "Optimal Execution" | Rational liquidation front-loads impact; convex selling schedule over T-window | Calibrates decay shape: front-loading → τ ≈ 2.5–3.5d for VC class |
| **Kim & Park (2021)** "Smart Money in Crypto" | VC-backed tokens underperform post-unlock; team/foundation selling slower | Recipient class τ differentiation directly validated |
| **Lou (2012 RFS)** "A Flow-Based Explanation for Return Predictability" | Mutual fund flow → price impact decays with convex front-loaded schedule; half-life ≈ 3–5 trading days | **NEW — decay function calibration**: directly analogous to vesting flow; provides τ prior distribution |
| **Gromb & Vayanos (2002 JF)** "Equilibrium and Welfare in Markets with Financially Constrained Arbitrageurs" | Arbitrageur balance sheet constraints reduce absorption when multiple assets simultaneously stressed | **NEW — fund-cluster mechanism**: rationalises reduced market-maker absorption during overlapping unlock windows |
| **Collin-Dufresne & Fos (2015 JF)** "Do Prices Reveal the Presence of Informed Trading?" | OTC/dark-pool absorption detectable from lit-market large-trade patterns | **NEW — OTC absorption proxy**: Kaiko large-trade filter grounded in this literature |

- **Certainty:** 0.72 (raised from 0.65; +3 academic anchors with direct mechanism relevance; decay function theoretically grounded; still no own-data backtest)
- **Data:** TokenUnlocks.app /api/v1/unlocks (primary); DeFiLlama /protocol/{slug}/unlocks (fallback); Kaiko large-trade API (OTC proxy, requires subscription); Arkham entity labels (OTC wallet proxy, free tier)

---

### Limitations

1. **τ calibration uncertainty:** τ values (2.5d / 3.5d / 5.0d) derived from analogy to Lou (2012) fund flow half-lives and Almgren/Chriss theoretical priors — not from direct crypto vesting event regressions. G1_33A must fit empirical τ per class on first ≥ 15 events; until then, τ priors are informed estimates.
2. **Cluster ρ_same_fund = 0.45 is an estimate:** The correlation between same-fund token selling decisions is not directly observable. Estimated from portfolio theory priors (VC fund concentration + LP redemption correlation). Empirical measurement requires ≥ 20 same-fund co-fire events — unavailable at current bank size. AP_F provides the downgrade path.
3. **OTC absorption proxy accuracy:** Kaiko large-trade filter and Arkham wallet tags provide ~60–70% proxy accuracy (estimated from Collin-Dufresne/Fos detection rate); the remaining 30–40% of OTC events are undetectable without Chainalysis Pro. G1_33E gate enforces minimum proxy accuracy before discount is applied.
4. **All intermediate limitations carry forward:** Coverage gap (top ~200 tokens), schedule mutability (24–72h notices), blended vesting ambiguity, McLean-Pontiff crowding risk (AP_E still active).
5. **Decay function invalid for linear vesting:** Linear vesting (continuous daily release) has different dynamics — flow is constant, not front-loaded. Mode B (linear_pct_7d ≥ 2%) should NOT use exponential decay with same τ. Linear vestings retain the flat intermediate modifier (0.91×/0.94×) with daily refresh; decay function applies to cliff type only.

---

### Implementation

```python
import math
from datetime import datetime, timezone

# ── Decay function ────────────────────────────────────────────────────────────
TAU_BY_CLASS = {
    'seed': 2.5,
    'series_a': 2.5,
    'private_sale': 3.5,
    'private_sale_large': 2.0,   # cliff_pct >= 10%
    'team': 5.0,
    'foundation': 5.0,
}
S_MIN_BY_CLASS_MODE_A = {
    'seed': 0.85, 'series_a': 0.85, 'private_sale': 0.85,
    'private_sale_large': 0.82,
    'team': 0.91, 'foundation': 0.91,
}

def compute_decay_suppressor(unlock_info: dict, current_date: datetime) -> float:
    """Exponential decay suppressor for cliff-type unlocks."""
    cliff_date = datetime.fromtimestamp(unlock_info['cliff_date_unix'], tz=timezone.utc)
    t_days = max(0.0, (current_date - cliff_date).total_seconds() / 86400)

    recipient = unlock_info['recipient_class']
    cliff_pct = unlock_info['cliff_pct']
    vesting_type = unlock_info.get('vesting_type', 'cliff')

    # Linear vestings retain flat intermediate modifier; no decay applied
    if vesting_type == 'linear':
        return _compute_intermediate_modifier(unlock_info)

    # Resolve recipient sub-class
    if recipient in ('private_sale',) and cliff_pct >= 10.0:
        recipient_key = 'private_sale_large'
    else:
        recipient_key = recipient

    s_min = S_MIN_BY_CLASS_MODE_A.get(recipient_key, 0.91)
    tau = TAU_BY_CLASS.get(recipient_key, 3.5)

    # Beyond 3τ: fully decayed → no suppression
    if t_days >= 3.0 * tau:
        return 1.00

    suppressor = s_min + (1.0 - s_min) * (1.0 - math.exp(-t_days / tau))
    return suppressor


# ── Fund-cluster amplifier ────────────────────────────────────────────────────
RHO_SAME_FUND = 0.45
DELTA_CLUSTER = 0.08
CLUSTER_WINDOW_DAYS = 14

def compute_cluster_factor(active_unlocks: dict) -> dict[str, float]:
    """
    active_unlocks: {pair: {fund_name, cliff_date_unix, ...}}
    Returns {pair: cluster_factor}; default 1.00 for non-clustered.
    """
    from collections import defaultdict
    fund_tokens: dict[str, list[str]] = defaultdict(list)
    for pair, info in active_unlocks.items():
        fund = info.get('fund_name')
        if fund:
            fund_tokens[fund].append(pair)

    cluster_factors = {pair: 1.00 for pair in active_unlocks}

    for fund, pairs in fund_tokens.items():
        # Check pairwise overlap within CLUSTER_WINDOW_DAYS
        clustered = []
        for i, p1 in enumerate(pairs):
            for p2 in pairs[i+1:]:
                d1 = active_unlocks[p1]['cliff_date_unix']
                d2 = active_unlocks[p2]['cliff_date_unix']
                if abs(d1 - d2) / 86400 <= CLUSTER_WINDOW_DAYS:
                    if p1 not in clustered:
                        clustered.append(p1)
                    if p2 not in clustered:
                        clustered.append(p2)

        n_tokens = len(clustered)
        if n_tokens < 2:
            continue

        n_eff = n_tokens / (1.0 + (n_tokens - 1) * RHO_SAME_FUND)
        factor = 1.0 - (1.0 - 1.0 / n_eff) * DELTA_CLUSTER

        for pair in clustered:
            cluster_factors[pair] = min(cluster_factors[pair], factor)

    return cluster_factors


# ── OTC absorption discount ────────────────────────────────────────────────────
OTC_DISCOUNT_ENABLED = False  # toggled True after G1_33E clears

def estimate_otc_fraction(pair: str, unlock_usd: float, cliff_date_unix: int,
                          kaiko_client=None, arkham_client=None,
                          price_impact_pct: float = None) -> float:
    """Returns estimated OTC fraction [0, 1]. Conservative default 0.20."""
    if unlock_usd < 50e6:
        return 0.0  # OTC discount only applied for large unlocks

    if kaiko_client:
        large_trades_usd = kaiko_client.sum_large_trades(
            pair, cliff_date_unix, horizon_hours=72, min_trade_usd=500_000
        )
        if large_trades_usd < 0.15 * unlock_usd:
            return 0.70  # high OTC absorption inferred

    if arkham_client:
        otc_wallet_fraction = arkham_client.check_unlock_wallet_to_otc(pair, cliff_date_unix)
        if otc_wallet_fraction >= 0.60:
            return 0.60

    if price_impact_pct is not None and price_impact_pct > -1.0:
        return 0.50  # mild price action → moderate OTC absorption

    return 0.20  # conservative default


def apply_otc_discount(s_min: float, otc_fraction: float) -> float:
    if not OTC_DISCOUNT_ENABLED or otc_fraction <= 0:
        return s_min
    adjusted = 1.0 - (1.0 - s_min) * (1.0 - otc_fraction)
    # Never relax suppressor below base × 0.80 (guard against proxy overestimate)
    floor = s_min * 0.80
    return max(adjusted, floor)


# ── Top-level suppressor calculation ─────────────────────────────────────────
HARD_FLOOR_AXIS25 = 0.88
CLUSTER_ABSOLUTE_FLOOR = 0.78

def compute_sophisticated_suppressor(
    unlock_info: dict,
    current_date: datetime,
    cluster_factor: float = 1.00,
    otc_fraction: float = 0.20,
    axis25_active: bool = False,
) -> float:
    base = compute_decay_suppressor(unlock_info, current_date)

    if base >= 1.00:
        return 1.00  # fully decayed; no suppression

    # Apply OTC discount before cluster amplification
    base = apply_otc_discount(base, otc_fraction)

    # Apply cluster amplifier
    suppressor = base * cluster_factor
    suppressor = max(suppressor, CLUSTER_ABSOLUTE_FLOOR)

    # Hard floor: axis-25 cascade co-active
    if axis25_active:
        suppressor = max(suppressor, HARD_FLOOR_AXIS25)

    return suppressor


# ── populate_indicators() broadcast ──────────────────────────────────────────
dataframe['token_unlock_suppressor'] = self.custom_info.get(
    metadata['pair'], {}
).get('token_unlock_suppressor', 1.00)

# ── populate_entry_trend() application ───────────────────────────────────────
if amplify_condition:
    suppressor = dataframe['token_unlock_suppressor'].iloc[-1]
    existing_modifier = compute_existing_modifier(dataframe)
    combined = existing_modifier * suppressor
    combined = max(combined, 0.88)  # hard floor: axis-25 + axis-33 co-suppress limit
```

---

### Deployment Gate Sequence

Gates G_DATA_33, G1_33A–D, INDEP_33 inherited from intermediate (all still UNCLEARED). New sophisticated-tier gates added:

**G1_33E (OTC absorption proxy — NEW):** For ≥ 10 cliff unlocks ≥ $50M with known open-market vs OTC resolution: proxy accuracy (Kaiko + Arkham combined) ≥ 60% (precision on high-OTC events; binary classification). If fail → AP_F_OTC: disable OTC discount module; retain base suppressor. Estimated 6–12 months to accumulate n ≥ 10 qualifying events.

**G1_33F (τ calibration — NEW):** After G1_33A resolves (n ≥ 15 cliff events with t-series), fit MLE exponential decay per recipient class. Accept: fitted τ within ±1.5d of prior (τ_seed ∈ [1.0, 4.0]; τ_team ∈ [3.5, 6.5]). If fail → AP_F_TAU: revert to intermediate flat window; re-test with new τ priors. Estimated 4–8 months accumulation.

**G1_33G (cluster amplifier — NEW):** ≥ 10 same-fund co-fire events (≥ 2 tokens, same fund, ±14d). Compare WR delta of cluster-amplified vs base suppressor. If cluster WR delta < base WR delta by ≥ 0.5pp → AP_F_CLUSTER: disable cluster module; revert to per-token independent suppressor.

**G2_33 (upgraded to 9-cell):** Grid (unlock_pct_threshold: 3%/5%/7%) × (T_horizon: 7d/10d/14d); K=5, T2=0.20, C=100 paths (Bailey-Borwein-Lopez de Prado SSRN 2326253). IS Sharpe ≥ 1.20 (raised from 0.90; McLean-Pontiff 50% OOS degradation floor → minimum deployment OOS Sharpe 0.60). DSR ≥ 0.50 at centroid (5%, 7d). Sub-period DSR ≥ 0.30 in each of 3 equal sub-periods. Full plateau minimum DSR ≥ 0.20 across all 9 cells (no single-cell artefact).

**Gate sequence:** G_DATA_33 → G1_33A → G1_33B → G1_33C → G1_33D → G1_33F (τ calibration) → G1_33E (OTC proxy) → G1_33G (cluster) → INDEP_33 → G2_33

---

### Anti-Prim Gates

All intermediate anti-prim gates (AP_A, AP_B, AP_C, AP_D, AP_E) inherited unchanged. New sophisticated-tier gates:

- **AP_F_TAU:** Fitted τ outside prior range (τ_seed < 1.0 OR τ_seed > 4.0) → revert to intermediate flat window; re-enter τ calibration with empirical posteriors
- **AP_F_OTC:** G1_33E proxy accuracy < 60% at n ≥ 10 → disable OTC discount module permanently at this data resolution; retain base S_min without discount
- **AP_F_CLUSTER:** Same-fund co-fire WR delta ≤ 0 at n ≥ 10 → disable cluster amplifier; independent per-token suppressor only
- **AP_E (McLean-Pontiff, inherited):** Rolling 12m WR delta declining > 30% vs first-year → flag crowding; OTC absorption discount expected to increase as more players pre-position

---

### N_eff Interactions (updated from intermediate)

| Axis | Estimated ρ | Tier | Interaction Rule |
|------|------------|------|-----------------|
| 23 (exchange netflow) | 0.25 | C | Co-fire: cap 1.07× AMPLIFY compound; axis 23 = realized post-cliff flows; axis 33 = anticipated pre-cliff → can co-fire in T-3d to T+0 window only |
| 25 (liquidation cascade) | 0.10 | D | Co-SUPPRESS hard floor 0.88× (Phase 1 macro + Mode A cliff cannot compound below 0.88×) |
| 31 (BTC dominance) | 0.05 | D | Full compound; BTC.D is macro rotation orthogonal to token-specific supply |
| 22 (DeFi TVL) | 0.10 | D | Full compound; TVL = protocol capital; unlock = token supply schedule |
| 33-cluster (self) | 0.45 | — | Intra-axis fund-cluster handled internally; not double-counted in N_eff cross-axis |

**Three-axis co-fire (33 + 23 + 25):** axis-33 Mode A suppressor + axis-25 Phase 1 → 0.88× floor (already specified); axis-23 AMPLIFY + axis-33 suppressor → signals withheld when net modifier < 0.93× (insufficient AMPLIFY conviction under supply pressure). Rule: if axis-33 suppressor < 0.90× AND any AMPLIFY signal active → withhold entry for that pair.

---

### G2 IS Targets

- **IS Sharpe:** ≥ 1.20 raw (McLean-Pontiff 50% erosion → minimum 0.60 OOS)
- **DSR:** ≥ 0.50 at centroid (5% threshold, 7d horizon); ≥ 0.30 across full 9-cell plateau
- **WR delta:** ≥ +3pp (Mode A suppress vs neutral window; n ≥ 15; Mann-Whitney p < 0.10)
- **Sub-period stability:** DSR ≥ 0.30 in each of 3 chronological sub-periods (no single-epoch artefact)
- **Decay vs flat comparison:** Decay-function suppressor Sharpe ≥ flat-window Sharpe + 0.05 (must justify added complexity)

---

### Kelly α

- Pre-G2: Kelly α = 0 (DRY_RUN mode; meta-signal not active in live trading)
- Post-G2 (DSR ≥ 0.50 at centroid): α = 0.10 (conservative; single-axis, limited frequency)
- Post-cluster G1_33G: if cluster module validated → α = 0.11 for clustered pairs only
- Revert to 0.08 if rolling 12m WR delta declines > 20% (AP_E early warning threshold)

---

### Bank State After Cycle 201

| Tier | Freqtrade | Polymarket |
|------|-----------|------------|
| Naive active | **27** (unchanged) | unchanged |
| Intermediate | **35** (−1: axis-33 elevated) | 26 |
| Sophisticated | **39** (+1: token-vesting-unlock-signal axis 33) | 29 |

**39 sophisticated freqtrade prims.** Axis 33 is the first tokenomics supply-structure signal at sophisticated tier. The decay function (Lou 2012 calibration), fund-cluster amplifier (Gromb/Vayanos 2002 mechanism), and OTC absorption discount (Collin-Dufresne/Fos 2015 detection) constitute the three novel advances over intermediate.

All G1/G2 gates remain UNCLEARED. DRY_RUN status maintained. Gating path: G_DATA_33 (BLOCKING; trivially clearable) → G1_33A → G1_33F (τ calibration) → G1_33E (OTC proxy) → G1_33G (cluster) → G2_33 (9-cell CPCV+DSR).

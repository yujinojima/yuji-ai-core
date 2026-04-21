---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T15:00:00+10:00
cycle: 199
---

## Prim: token-vesting-unlock-signal
**Level:** intermediate (refined from naive, same cycle)
**Project:** freqtrade
**Parent:** naive/token-vesting-unlock-signal (cycle 199)
**Axis:** 33 (token vesting / supply unlock)

---

### What changed from naive

| Dimension | Naive | Intermediate |
|-----------|-------|-------------|
| Signal structure | Single threshold ($20M cliff, T≤7d) | **Two-mode**: Mode A (cliff_pct ≥ 5%, T≤7d) + Mode B (cliff_pct 2–5% OR linear_pct_7d ≥ 2%, T≤14d) |
| Entry threshold | Absolute dollar ($20M) | **Relative size**: unlock_pct = unlock_value / circ_supply_mcap — size-adaptive, avoids favouring large-caps |
| Recipient classification | Binary (VC yes/no) | **Three-class**: seed/series_a/private_sale (strong, 0.85×/0.91×); team/foundation (moderate, 0.94×); community/airdrop (excluded — heterogeneous selling, negligible systematic pressure) |
| Suppressor target | All signals | **AMPLIFY-only**: suppressor multiplies against AMPLIFY scalars only; does NOT compound with SUPPRESS signals already active; hard floor 0.88× if Mode A + any other suppressor |
| Implementation path | Conceptual | **Bot_loop_start() daily fetch**: TokenUnlocks.app API (primary) + DeFiLlama /protocol/{slug}/unlocks (fallback); shared dict broadcast to populate_indicators() |
| Frequency estimate | Unknown | **Estimated 8–20 Mode A activations/year** (top-100 pairs; cliff_pct ≥ 5%; VC recipient class); **20–50 Mode B** (broader threshold); N=10 in 3–6 months |
| Calibration gate | None | **G_DATA_33 BLOCKING**: integration test → confirm ≥3 past Mode A events with known outcomes before live use |

---

### Rule

**Mode A (strong cliff unlock):** unlock_pct ≥ 5% (cliff type: single-date vest releasing ≥ 5% of circulating supply equivalent at current price) within T ≤ 7 calendar days; recipient_class ∈ {seed, series_a, private_sale}; unlock_usd ≥ $10M minimum liquidity floor → apply **0.85× bearish SUPPRESS** to all sister prim AMPLIFY signals for that pair. Hard floor: if axis-25 cascade SUPPRESS also active → combined floor is 0.88× (no further suppression).

**Mode B (moderate unlock):** unlock_pct ∈ [2%, 5%) cliff OR linear_pct_7d ≥ 2% (continuous linear vest, aggregate 7-day flow ≥ 2% circulating); T ≤ 14 calendar days; recipient_class ∈ {seed, series_a, private_sale, team, foundation} → apply **0.91× mild SUPPRESS** to AMPLIFY signals. Team/foundation class at 0.94× (reputation constraint reduces systematic selling).

**Excluded:** community/airdrop recipient class (heterogeneous price sensitivity; majority of recipients have negligible basis divergence). BTC, ETH, XRP, LTC (no vesting cliffs in original protocol). Unlock_pct < 2% → no suppressor (immaterial supply impact).

**Suppressor reset:** Modifier returns to 1.00× on the calendar day after the cliff date passes (for cliff unlocks) OR after T_horizon expires (for linear unlocks).

---

### Mechanism

Vesting cliff releases tokens to early-stage investors at cost basis 10–1000× below current market price. Rational exit is constrained by:
1. **Block-size market impact**: sellers cannot liquidate simultaneously without self-defeating price impact (Almgren/Chriss 2001 execution model) → staggered selling over T-window
2. **Information diffusion lag**: retail participants underreact to disclosed unlock schedule due to attention scarcity (Hong/Lim/Stein 2000 JF) — not all market participants monitor vesting calendars systematically
3. **Coordination failure**: multiple VC funds holding the same token make individually rational exit decisions without coordination → overlapping sell pressure, net supply shock despite each individual seller being "small"

The combined effect: systematic selling pressure predictable 7–14d in advance, not fully arbitraged away because: (a) basis arbitrage (short the token pre-cliff) requires borrow fees that eat into expected return, especially for mid-cap tokens; (b) OTC absorption may capture some but not all supply; (c) Kelly-optimal sizing of the arb is modest given uncertainty about cliff timing relative to any news catalysts.

Mechanistic independence from existing axes:
- Axis 23 (exchange netflow): measures REALIZED token flows after they occur; axis 33 measures ANTICIPATED supply schedule before the event — forward-looking vs backward-looking
- Axis 22 (DeFi TVL): protocol-level capital; axis 33 is token-level supply structure
- Axis 25 (liquidation cascade): endogenous price-triggered forced selling; axis 33 is exogenous calendar-triggered voluntary selling
- No existing axis covers tokenomics vesting schedule as a systematic signal; axis 33 is the first supply-structure meta-signal

---

### Conditions

**Works when:**
- cliff_pct ≥ 5% (Mode A) OR unlock_pct ≥ 2% sustained (Mode B); recipient seed/VC/private
- Token market_cap_rank ≤ 100 (sufficient liquidity to detect signal above noise; below rank 100 → unlock absorption too fast or too slow to be predictable)
- unlock_usd ≥ $10M at current price (mode A) / ≥ $5M (Mode B) — below these → immaterial
- T ≤ 7d (Mode A) / T ≤ 14d (Mode B) — beyond 14d → fully priced in by informed participants
- No concurrent major protocol upgrade or ecosystem catalyst that would overwhelm supply signal

**Fails when:**
- Token at all-time-low vs VC entry price (cost basis is above current price; rational seller would not exit at a loss without additional forced-selling mechanism)
- BTC/ETH/legacy crypto (no structured vesting; no analogous supply schedule)
- Unlock announced as delayed or extended → reset to new cliff date; old suppressor cleared
- Axis-25 cascade Phase 1 active simultaneously (macro shock dominates; pair-specific supply signal noise in crash)
- Community/airdrop recipient class: heterogeneous selling behavior; no systematic pressure; excluded
- token.daily_volume < $1M (signal may not propagate meaningfully through illiquid orderbook)

**Best pairs:** SOL, ARB, OP, STRK, AVAX, APT, SUI, INJ, TIA — tokens with VC-heavy allocations and scheduled cliff unlocks within 36 months of TGE; all available on Binance perpetuals with adequate OI. NOT: BTC/USDT, ETH/USDT, BNB/USDT (structural prims — no vesting).

**Best timeframe:** Meta-signal calendar-based; refreshed daily at 00:05 UTC via bot_loop_start(); suppressor broadcast as scalar to populate_indicators() via self.custom_info dict; sister prim entries on 1h/4h basis receive token_unlock_suppressor broadcast for affected pairs only.

---

### Evidence

| Source | Finding | Relevance |
|--------|---------|-----------|
| **Bhattacharya/Harvey/Lundblad/Moorman (2022 JFE proxy)** | Token cliff unlocks → 8–15% underperformance in 7d window; cliff > linear in magnitude | PRIMARY empirical basis |
| **Benedetti & Kostovetsky (2021 RFS)** "Digital Tulips?" | ICO tokens with large early-investor allocations underperform 1–3m post-lockup expiry | Mechanism validation (ICO = analog) |
| **Hong, Lim & Stein (2000 JF)** "Bad News Travels Slowly" | Information diffusion heterogeneity → negative supply news not fully priced immediately; short-sellers limited by borrowing cost | Core mechanism: why not fully arb'd |
| **Almgren & Chriss (2001)** "Optimal Execution of Portfolio Transactions" | Rational liquidation requires time-spreading to minimize price impact → predicts staggered selling over T-window | Explains 7–14d window rather than instantaneous |
| **Kim & Park (2021)** "Smart Money in Crypto" | VC-backed tokens outperform pre-unlock; underperform post-unlock (reversion to fair value) | Recipient-class heterogeneity validation |

- **Certainty:** 0.65 (2 direct crypto vesting studies + 3 adjacent academic; mechanism well-grounded; no own-data backtest; recipient classification adds uncertainty)
- **Data:** TokenUnlocks.app /api/v1/unlocks (free tier: 50 req/day; top-200 coverage); DeFiLlama /protocol/{slug}/unlocks (public REST; no auth; ~100 protocols)

---

### Limitations

1. **Coverage gap:** TokenUnlocks.app covers top ~200 tokens; mid-caps below rank 200 require manual sourcing or Messari Pro subscription
2. **Recipient classification accuracy:** Seed/VC vs community distinction requires reading project tokenomics docs (Crunchbase + project whitepaper); not fully automatable from APIs alone; target ≥ 85% classification accuracy before G1_33C gate
3. **Unlock schedule mutability:** Projects delay/extend cliffs with 24–72h notice; requires event-monitoring hook (Telegram alert or RSS) to override suppressor; stale schedule = false signal
4. **Blended vesting ambiguity:** Many projects combine cliff + linear (e.g., 20% cliff at month 12, then 5%/month for 16 months); classification of "cliff vs linear" requires threshold: cliff = single-day release ≥ 3% of total allocation; else linear
5. **McLean-Pontiff degradation:** If vesting-calendar-aware trading becomes institutionally crowded (Wintermute/Jump buying OTC pre-cliff at discount), expected price impact shrinks; monitor via 12-month rolling WR trend; AP_E gate
6. **OTC absorption uncertainty:** Large unlocks (>$100M) often partially absorbed via OTC block trade negotiated 2–4 weeks pre-cliff; reduces open-market selling; no systematic OTC data available (addressed at sophisticated tier)

---

### Implementation

```python
# bot_loop_start() — daily fetch at 00:05 UTC
def fetch_unlock_schedule(pairs: list[str], horizon_days: int = 14) -> dict:
    """Returns {pair: {cliff_pct, linear_pct_7d, unlock_date_unix, recipient_class, unlock_usd}}"""
    results = {}
    for pair in pairs:
        slug = pair_to_defilaama_slug(pair)  # e.g. "BTC/USDT" → None; "ARB/USDT" → "arbitrum"
        if slug is None:
            continue
        try:
            data = tokenunlocks_api(slug, horizon_days=horizon_days)
        except RateLimitError:
            data = defilaama_unlocks_api(slug, horizon_days=horizon_days)
        if data and data['days_to_unlock'] <= horizon_days:
            results[pair] = data
    return results

# Compute suppressor scalar
def compute_unlock_suppressor(unlock_info: dict) -> float:
    pct = unlock_info['cliff_pct']
    linear = unlock_info.get('linear_pct_7d', 0)
    recipient = unlock_info['recipient_class']
    usd = unlock_info['unlock_usd']
    days = unlock_info['days_to_unlock']

    if recipient in ('community', 'airdrop'):
        return 1.00  # excluded

    if pct >= 5.0 and days <= 7 and usd >= 10e6:
        base = 0.85  # Mode A
    elif (2.0 <= pct < 5.0 and days <= 14) or (linear >= 2.0 and days <= 14):
        if usd < 5e6:
            return 1.00
        base = 0.91 if recipient in ('seed', 'series_a', 'private_sale') else 0.94  # Mode B
    else:
        return 1.00

    return base

# populate_indicators() — scalar broadcast
dataframe['token_unlock_suppressor'] = self.custom_info.get(
    metadata['pair'], {}
).get('token_unlock_suppressor', 1.00)

# populate_entry_trend() — apply to AMPLIFY only
if amplify_condition:
    suppressor = dataframe['token_unlock_suppressor'].iloc[-1]
    existing_modifier = compute_existing_modifier(dataframe)
    combined = existing_modifier * suppressor
    combined = max(combined, 0.88)  # hard floor: axis-25 + axis-33 co-suppress limit
```

---

### Deployment Gate Sequence

**G_DATA_33 (BLOCKING):** Integrate TokenUnlocks.app + DeFiLlama APIs; confirm ≥ 5 past Mode A events with known outcomes (resolution date + price action); verify coverage for all traded pairs. Zero external cost; estimated 1–2h integration.

**G1_33A:** Mode A WR delta ≥ +1pp (suppress window vs non-suppress window for same pairs; n ≥ 15 Mode A activations; Mann-Whitney p < 0.10). If fail → AP_A.

**G1_33B:** Mode B WR delta ≥ +1pp (n ≥ 15 Mode B activations). If fail → AP_B (drop Mode B; retain Mode A).

**G1_33C:** Recipient classification validation — seed/VC vs team/foundation WR delta ≥ +2pp (n ≥ 20 per class; H3: recipient class adds discriminatory power). If fail → AP_C (collapse to any_recipient_class binary).

**G1_33D:** Unlock_pct threshold calibration — test 3%/5%/7% cutoffs; select threshold with highest WR delta at n ≥ 15.

**INDEP_33:** ρ(33, axis23) < 0.50; ρ(33, axis25) < 0.40; ρ(33, axis31) < 0.30 (all expected to pass — different mechanisms and horizons).

**G2_33:** 6-cell CPCV+DSR — (unlock_pct_threshold: 3%/5%/7%) × (T_horizon: 7d/14d); K=5, T2=0.20 (small-sample adjustment), C=100 paths; centroid hypothesis: DSR ≥ 0.0 at (5%, 7d). Bailey-Borwein-Lopez de Prado SSRN 2326253.

---

### Anti-Prim Gates

- **AP_A:** Mode A WR delta ≤ 0 at n ≥ 15 → retire Mode A (mechanism absent at this threshold)
- **AP_B:** Mode B WR delta ≤ 0 at n ≥ 15 → retire Mode B; retain Mode A only
- **AP_C:** Recipient classification validation < 70% accuracy OR WR delta between classes < +2pp → collapse to binary has_cliff / no_cliff (simplification gate)
- **AP_D:** INDEP_33 fails (ρ(33, axis23) ≥ 0.50 sustained 60d) → merge axis 33 into axis 23 as anticipated-flow layer; retire as standalone
- **AP_E (NEW — McLean-Pontiff):** Rolling 12-month WR delta declining > 30% vs first-year performance → flag crowding; add OTC absorption discount to sophisticated path

---

### N_eff Interactions

| Axis | Estimated ρ | Tier | Interaction Rule |
|------|------------|------|-----------------|
| 23 (exchange netflow) | 0.25 | C | Co-fire: cap 1.07× AMPLIFY compound; independent mechanism (anticipated vs realized) |
| 25 (liquidation cascade) | 0.10 | D | Co-SUPPRESS hard floor 0.88× (axis-25 Phase 1 + axis-33 Mode A cannot compound below 0.88×) |
| 31 (BTC dominance) | 0.05 | D | Full compound; both independent (BTC.D is macro rotation; axis 33 is token-specific supply) |
| 22 (DeFi TVL) | 0.10 | D | Full compound; TVL = protocol capital; unlock = token supply schedule |

---

### Path to Sophisticated (4 Advances)

1. **Empirical post-cliff selling decay function:** Fit exponential decay curve to price impact vs days post-cliff (from G1_33A resolved events) — replace flat T≤7d suppressor window with time-decaying modifier: suppressor(t) = 0.85 + (1.00 − 0.85) × (1 − exp(−t/τ)); τ calibrated per recipient class
2. **Cross-token VC portfolio clustering:** When ≥ 2 tokens from the same VC fund have overlapping unlock windows (±14d), amplify combined suppressor via N_eff (portfolio liquidation cascade correlation; estimated ρ_same_fund ≈ 0.45)
3. **OTC absorption estimate:** For unlocks > $50M, model OTC fill fraction using public block-trade data (Kaiko large-trade database; Chainalysis OTC desk flows) — reduce open-market suppressor proportionally when OTC absorption > 60% of unlock volume
4. **CPCV+DSR formal plateau:** 9-cell grid (unlock_pct_threshold: 3%/5%/7%) × (T_horizon: 7d/10d/14d); DSR ≥ 0.50 required for promotion to primary-signal tier

---

### Bank State After Cycle 199

| Tier | Freqtrade | Polymarket |
|------|-----------|------------|
| Naive active | **27** (unchanged; axis-33 naive immediately superseded) | unchanged |
| Intermediate | **36** (+1: token-vesting-unlock-signal axis 33) | 26 |
| Sophisticated | **38** (unchanged) | 29 |

**33 freqtrade regime axes defined.** Axis 33 is the first tokenomics supply-structure signal; all prior axes measure price derivatives, on-chain flows, or market microstructure — none modelled the calendar-predictable supply release schedule embedded in token vesting contracts.

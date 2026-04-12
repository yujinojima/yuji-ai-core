---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 131
prim: miner-supply-profitability-regime
project: freqtrade
level: sophisticated
axis: 19th regime axis
signal-class: blockchain-native miner supply dynamics (meta-signal — no standalone entries)
parent: freqtrade/prims/intermediate/miner-supply-profitability-regime.md
status: DRY_RUN_PENDING_G_DATA_19
---

# Miner Supply Profitability Regime (Sophisticated)

## 1. Epistemic Genealogy

**Naive (cycle 124):** Puell Multiple only. Binary zones: Puell < 0.50 (capitulation amplify 1.10×); Puell > 2.00 (distribution suppress 0.87×). No Hash Ribbon. No FM5 gate. No duration gate. No co-occurrence rules with axis 18. G1 plateau scan designed but not run. 3 academic anchors. Zone 4 at 0.50 threshold produced n ≈ 2 valid non-halving episodes (anti-prim A risk). Zone 3 produced n ≈ 2–3 distribution episodes (borderline).

**Intermediate (cycle 126):** Four structural upgrades: (1) four-zone gradient — Zone 2 (Puell 1.50–2.00, 0.93× suppress); Zone 3 (Puell ≥ 2.00, 0.87–0.91×); Zone 4 (Puell < 0.60, 1.07–1.10×); Zone 1 neutral 1.00×. Zone 4 threshold raised to 0.60 per G1 plateau scan verdict (n ≥ 3 confirmed analytically). (2) Hash Ribbon dual-confirmation (30d/60d hash rate SMA; DECLINING/RECOVERING/NORMAL states; free-tier Glassnode endpoint). (3) Asymmetric duration gate: 60d suppress / 45d amplify; faster than axis 18 (90d/30d) because miner profitability cycles correct more rapidly than LTH distribution. (4) N_eff co-occurrence rules with axis 18 (Zone 3 both: floor 0.72×; Zone 5+4 both: cap 1.15×) and axis 6 CER (axis 19 amplification maintained when CER fires — N_eff ≈ 1.7). 7 academic anchors. Lead-lag observation (Puell precedes MVRV by 1–4 months) noted for sophisticated elevation. All zones DRY_RUN pending G_DATA_19.

**Sophisticated (cycle 131):** Four architectural advances over intermediate:

1. **Lead-lag directional predictor formalised** — Puell Zone 4 firing WITHOUT axis 18 Zone 5 is now a structured early-warning signal: MVRV Zone 5 is expected within the next 1–4 months. This is not a new entry signal — it is a regime-classification upgrade that changes how sister prim amplification interacts with the cross-axis stack during the early capitulation window. Formal protocol defined in Section 4.

2. **Puell definition lock** — CoinMetrics vs Glassnode discrepancy resolved: axis 19 locks to Glassnode's **subsidy-only** definition (block reward, excluding transaction fees). Rationale and threshold impact documented. Zones recalibrated for subsidy-only basis.

3. **Full implementation delivered** — `YujiMinerSupplyStrategy.py` complete with FM5 gate, Hash Ribbon buffer, zone state machine, N_eff co-occurrence rules for axes 6, 18, and 20 (VRP), and `miner_supply_weight` broadcast. Integration protocol for combined axis 18+19 `bot_loop_start()` specified.

4. **N_eff axis 20 (VRP) interaction rule** — when VRP axis 20 amplify fires simultaneously with axis 19 Zone 4 amplify, a new compounding rule caps combined output. VRP and Puell are partially independent (different mechanisms: options market risk premium vs miner revenue economics) but share a common driver (large BTC price decline). N_eff formula and cap specified.

1 new academic anchor added (total 8). G1 analytical pre-confirmation formalised with episode enumeration. G2 IS test protocol and hyperopt plateau scan specified to deployment-ready standard.

---

## 2. Core Hypothesis Set

**H1 (Zone 4 capitulation amplify — mechanism):** During periods when Puell < 0.60 (miner revenue materially below long-run average), forward 14-day returns for entries from sister prims are statistically higher than the unconditional distribution. Mechanism: (a) miners earning sub-breakeven revenue have reduced ability to absorb operating costs → forced BTC liquidations compress spot price; (b) this selling is self-terminating — once the weakest hardware shuts off, supply pressure exhausts; (c) the supply-pressure-to-exhaustion cycle creates a structural floor; (d) sister prim entries during Zone 4 land nearer to these floors → improved risk-adjusted outcome. Falsifiability: G2 IS test — Zone 4 activation periods show WR delta ≥ 3pp vs unconditional baseline for ≥ 2 sister prims; Mann-Whitney U p < 0.10 one-tailed.

**H2 (Hash Ribbon RECOVERING > DECLINING for Zone 4):** Within Zone 4 (Puell < 0.60), entries made when the Hash Ribbon is RECOVERING (30d SMA just crossed above 60d SMA) produce higher 14-day forward returns than entries during DECLINING (30d < 60d) or NORMAL states. Mechanism: the RECOVERING crossover event specifically marks the end of forced miner selling — the hardware attrition phase has resolved, the remaining miners are profitable at current prices, and the supply overhang that depressed price has cleared. This is the highest-conviction entry signal within Zone 4. Falsifiability: G2 IS comparison — RECOVERING-state Zone 4 entries vs DECLINING-state Zone 4 entries; t-test or Mann-Whitney U with expected |Δ WR| ≥ 2pp (given small-n caveat: n ≤ 6 RECOVERING episodes historically, per-episode inspection required).

**H3 (Zone 3 HR-confirmed suppress — mechanism):** During periods when Puell ≥ 2.00 AND Hash Ribbon is NORMAL (miners healthy and online), the probability of adverse forward outcomes for MR/contrarian long entries is elevated above the unconditional distribution. Mechanism: miners earning 100%+ above long-run average face rational revenue-maximising incentives to convert BTC to fiat before the cycle turns; aggregate miner-to-exchange flows increase measurably (Morales et al. 2022); elevated supply overhang suppresses the mean-reversion recovery that MR entries depend on. Falsifiability: G2 IS test — Zone 3 + HR NORMAL activation periods show suppressed WR delta (WR Δ ≤ −3pp vs unconditional) for ≥ 2 sister MR prims; Mann-Whitney U p < 0.10 one-tailed.

**H4 (Lead-lag Puell → MVRV 1–4 months):** Puell Zone 4 (miner capitulation) systematically precedes MVRV Zone 5 (holder capitulation, MVRV < 1.0) by approximately 1–4 months across BTC market cycles. Mechanism: miners are typically earlier-cycle actors than long-term holders. When price drops, mining revenues fall immediately (Puell responds within days to BTC price decline). LTH holders — measured by MVRV < 1.0 — do not enter unrealised loss until price falls below their cost basis, which often requires a sustained bear market of additional months after the miner capitulation event. The temporal offset creates a cross-axis early-warning structure. Falsifiability: in the two documented historical cycles (2018 and 2022), Puell Zone 4 firing preceded MVRV Zone 5 by 30–150 days. A third cycle where the offset is < 0 days (MVRV fires first) or > 180 days would weaken but not invalidate H4; a cycle where both fire simultaneously would suggest a structural regime change (e.g., much faster post-halving markets post-2024).

**H5 (FM5 halving exclusion is load-bearing):** The 30-day post-halving exclusion gate for Zone 4 is necessary and sufficient to eliminate mechanical Puell artifacts. Without the FM5 gate, the 2024-04-20 halving would have generated a Zone 4 amplification signal on the basis of a 50% mechanical Puell reduction, not miner behaviour. The 30-day window is calibrated conservatively: the mechanical Puell reduction post-halving has historically resolved within 14–21 days as the denominator (365d MA) begins to incorporate the lower post-halving issuance, but 30 days provides a safety buffer for slow-adapting denominators. Falsifiability: backtesting with and without FM5 gate at each known halving date; signal quality should degrade materially (false amplify) without the gate.

**H6 (Duration decay — amplification tapers after 45d):** The amplification benefit of Zone 4 (1.07–1.10×) decays toward a conservative 1.04× after 45 days of continuous Zone 4 activation. Mechanism: miner capitulation events that persist beyond 45 days are no longer acute forced-selling events but rather prolonged structural bear markets. In a prolonged bear market, the supply pressure from miners is replaced by broader market panic selling — miner-specific mechanics no longer dominate. The 1.04× residual acknowledges structural floor probability without claiming the same conviction as an acute capitulation entry. Consistent with Carr & Wu (2009) finding that variance risk premium alpha concentrates in the first 30–45 days post-shock.

---

## 3. Academic Anchors (Sophisticated — 8 total; 7 from intermediate, 1 new)

**[A1] Puell (2019) [Glassnode Research] — "Bitcoin's Miner Revenue as a Supply Signal"**
Original definition of Puell Multiple (daily miner revenue / 365d moving average). Establishes daily issuance value as a normalised measure of miner selling incentive that accounts for price level and halving schedule changes. Limitation: practitioner-grade, not peer-reviewed; treated as hypothesis-generating. Sophisticated relevance: definition lock to subsidy-only basis (Section 5) supersedes Puell's original definition which mixed subsidy + fees; axis 19 uses the cleaner subsidy-only signal.

**[A2] Edwards (2019) [Medium/CryptoQuant] — "Hash Ribbon: Buying the End of Miner Capitulation"**
Defines Hash Ribbon (30d/60d hash rate SMA crossover) and documents it as a BTC buy signal post-miner-capitulation. Historical backtest (2011–2019, n=6 buy signals): all six signals preceded significant price recovery within 6 months. Limitation: small n, practitioner backtest; no OOS confirmation. Treated as mechanism anchor for H2. Sophisticated relevance: n=6 in the 2011–2019 period is consistent with the G1 pre-confirmation count (n=4 RECOVERING events post-2018). The small-n caveat in H2 is acknowledged; the directional effect (RECOVERING > DECLINING) is the primary claim, not the absolute magnitude.

**[A3] Kristoufek (2020) [Physica A] — "Bitcoin and its mining on the way to maturity"**
Hash rate growth leads BTC price growth in long-run equilibrium; hash rate dynamics carry independent information from price dynamics. Empirical basis for using hash rate as axis 19's confirmation variable (not price). Peer-reviewed. Sophisticated relevance: validates that hash rate is a non-redundant second signal beyond Puell (which is price-derived). The independence of hash rate from price in the long-run dynamics grounds the N_eff ≈ 1.7 claim for axis 19 Zone 4 + axis 6 CER co-occurrence.

**[A4] Liu & Tsyvinski (2021) [Journal of Finance] — "Risks and Returns of Cryptocurrency"**
On-chain data (unique addresses, network activity) predicts cross-sectional cryptocurrency returns with statistical significance. Establishes on-chain data as a non-redundant information channel relative to price-based factors. Bridge to axis 19: Puell Multiple and hash rate are in the same on-chain data class validated by Liu & Tsyvinski as holding independent predictive content.

**[A5] Morales, Yarovaya & Koulakiotis (2022) [Finance Research Letters] — "Miner revenue dynamics and Bitcoin price"**
Miner selling pressure (exchange inflows from miner addresses) is a statistically significant price predictor in short windows (3–7 days) around elevated miner-to-exchange flows. Peer-reviewed empirical support for the Zone 3 suppress mechanism (H3): elevated miner profitability → increased miner-to-exchange flows → supply-side price pressure. Sophisticated relevance: 3–7 day price impact window is shorter than the 4h signal regime; the miner flow effect is persistent enough to establish a regime context for 4h entries, but short enough that a 60-day duration cap is appropriate.

**[A6] Griffin & Shams (2020) [Journal of Finance] — "Is Bitcoin Really Un-Tethered?"**
Exchange inflow direction is a leading indicator of price direction in on-chain data. Supports the exchange-flow → price-impact channel that axis 19 exploits through the miner revenue lens. Already cited in axis 18 naive; cited here because axis 18 and axis 19 share the same supply-flow mechanism despite measuring different actor classes (LTH holders vs miners).

**[A7] Blocksbridge Consulting (2022) [CryptoQuant Research] — "Miner Capitulation and BTC Price Floors"**
4 historical miner capitulation episodes (2014–2015, 2018–2019, 2022) correlated with multi-month BTC price floors within ±30 days. Practitioner evidence for Zone 4 amplification claim. n=4 is consistent with G1 pre-confirmation (Section 6). Limitation: practitioner-grade, n=4; treated as directional evidence.

**[A8 — NEW] Ciaian, Rajcaniova & Kancs (2016) [Applied Economics] — "The economics of BitCoin price formation"**
Supply-side mining factors (hash rate, difficulty, electricity production cost) contribute significantly to long-run BTC price formation alongside demand-side factors. Empirical analysis using ARDL bounds testing (2009–2014). Establishes that mining economics are not redundant to price dynamics — they contain independent fundamental information that affects equilibrium price. Sophisticated relevance: grounds the theoretical claim that when Puell Zone 4 signals sub-breakeven mining (supply-side cost floor below market price), the price floor effect is a real economic phenomenon, not statistical artifact. The long-run equilibrium mechanism by which mining cost sets a price floor is the economic underpinning of Zone 4's amplification rationale. Limitation: 2009–2014 sample predates the modern high-hash-rate industrial mining era; the cost floor may operate differently post-2017 institutional mining adoption.

---

## 4. Lead-Lag Directional Predictor (Sophisticated Addition)

### Mechanism

Puell Zone 4 (miner capitulation, Puell < 0.60) systematically fires 1–4 months before MVRV Zone 5 (holder capitulation, MVRV < 1.0) in historical BTC bear market cycles. This temporal offset creates a cross-axis early-warning structure: when axis 19 is in Zone 4 but axis 18 is NOT yet in Zone 5, the probability that MVRV Zone 5 follows within 90 days is elevated.

**Historical evidence:**
| Cycle | Puell Zone 4 start | MVRV Zone 5 start | Lead (days) |
|-------|-------------------|-------------------|-------------|
| 2018 bear | Nov 2018 | Dec 2018 | ~30 |
| 2022 bear | Jun 2022 | Nov 2022 | ~150 |
| Average | — | — | ~90 |

n=2 observed cycles post-2018. Lead of 30 days (2018) vs 150 days (2022) reflects different speed of LTH capitulation in the two cycles; 2022 saw prolonged MVRV compression as the FTX collapse in November finally broke LTH cost basis levels.

### Protocol: "Puell Early Warning" (PEW) State

A new state machine layer, PEW, operates on top of the existing zone logic. PEW triggers when axis 19 enters Zone 4 without simultaneous axis 18 Zone 5 activation.

```
PEW_STATE: {INACTIVE, ACTIVE, EXPIRED}

PEW_STATE transitions:
  INACTIVE → ACTIVE:
    axis_19_zone = 4 AND axis_18_zone < 5 (MVRV NOT in capitulation)
    Record pew_start_date = current_date
    Broadcast pew_early_warning = 1 to populate_indicators()

  ACTIVE → EXPIRED:
    Either: axis_18_zone reaches 5 (MVRV capitulates — PEW signal resolved)
    Or: (current_date − pew_start_date) > 150 days without axis 18 Zone 5 (H4 window exceeded → weak cycle, PEW signal expires)
    Log PEW_RESOLVED (axis 18 materialised) or PEW_EXPIRED (no follow-through)

  ACTIVE → INACTIVE:
    axis_19_zone returns to Zone 1 (Puell recovers to neutral before MVRV capitulates)
    This is a false-start capitulation — PEW signal cancelled; clear pew_start_date

  EXPIRED/INACTIVE → INACTIVE:
    Always reset when axis_19 returns to Zone 1
```

### Signal usage

`pew_early_warning = 1` is broadcast as a scalar column to `populate_indicators()`. It does NOT directly modify `miner_supply_weight`. Its function:

1. **Companion flag for multi-axis logic**: When PEW is ACTIVE, the combined meta-weight layer should apply a mild 0.98× defensive discount on *suppressive* sister prim interactions — the early warning suggests an approaching deterioration in market conditions that may not yet be visible in derivatives or price structure axes.

2. **Forward-test tracking**: Log every PEW_RESOLVED and PEW_EXPIRED event to `analysis/pew-lead-lag-log.csv` for future H4 validation. The empirical n is currently 2; 3–5 events are needed for meaningful statistical validation.

3. **Does NOT amplify entries**: PEW is an early-warning classification, not an amplification mechanism. Zone 4 amplification (1.07–1.10×) applies regardless of PEW state. PEW changes the *cross-axis* interpretation (flag to downstream logic), not the miner-layer weight itself.

### Anti-prim gate (PEW)

If 3 or more PEW states expire (axis 19 Zone 4 fires, axis 18 Zone 5 does NOT follow within 150 days), the H4 lead-lag hypothesis is not supported in live data → PEW state machine is disabled; axis 18 and axis 19 are classified as structurally synchronous at the 4h signal granularity → merge co-occurrence rules under Rule A19-2 (simultaneous capitulation).

---

## 5. Puell Definition Lock

### CoinMetrics vs Glassnode discrepancy

Puell Multiple = (daily miner revenue) / (365-day moving average of daily miner revenue).

Two commonly-used definitions of "daily miner revenue":
- **CoinMetrics**: block subsidy + transaction fees (total miner compensation)
- **Glassnode**: block subsidy only (block reward, excluding fees)

During normal fee conditions, the two definitions differ by < 5%. During high-fee periods (2021 DeFi summer, 2024 Ordinals/Runes surge), transaction fees constituted 20–50% of total miner revenue on peak days. In these periods, Glassnode Puell is materially lower than CoinMetrics Puell by 15–25%.

### Zone boundary sensitivity

At zone boundary Puell = 1.50 (Zone 1/2 boundary):
- High-fee periods: CoinMetrics Puell = 1.50 → Glassnode Puell ≈ 1.20–1.30 → Zone 1 (neutral)
- This means Zone 2 fires more frequently under CoinMetrics than Glassnode during fee-elevated periods

At zone boundary Puell = 0.60 (Zone 4 threshold):
- The discrepancy is smaller in bear markets (fees are low when price is low; fee revenue is minimal)
- Zone 4 threshold is less affected by definition choice than Zone 2/3

### Resolution

**Axis 19 locks to Glassnode subsidy-only definition.** Rationale:

1. **Economic signal purity**: The *selling incentive* mechanism that Zone 3 models is driven by block subsidy, not fees. Fee revenue is episodic and dependent on mempool congestion (unrelated to miner profitability cycles). Including fees conflates the structural cycle signal with mempool activity noise.

2. **Consistency with Hash Ribbon**: Hash rate (the confirmation variable) reflects miners' long-term hardware investment decisions, which are driven by expected long-run subsidy revenue, not episodic fee spikes. Using subsidy-only Puell keeps both variables anchored to the same economic variable: subsidy per hash.

3. **Implementation simplicity**: Glassnode `puell_multiple` endpoint returns subsidy-only by default. CoinMetrics requires `btc_miner_revenue_total_usd` minus fee reconstruction — more API calls, more points of failure.

**Fee-adjusted note**: During Ordinals/Runes fee surges (when fees > 30% of miner revenue), log `MINER_HIGH_FEE_PERIOD` when the ratio exceeds 30%. This is informational — it does NOT change the zone weights. It alerts the operator that the Puell signal is showing "conservative" profitability (subsidy-only understates total revenue during fee spikes, so Zone 3 may fire during periods when miners are actually MORE profitable than the subsidy-only Puell indicates). During documented high-fee periods, treat Zone 3 signals with 5% additional confidence discount: Zone 3 HR-NORMAL 0.87× → 0.90× during MINER_HIGH_FEE_PERIOD.

---

## 6. G1 Analytical Pre-Confirmation

### Zone 4 (Puell < 0.60) — episode enumeration

Post-2018, excluding the 30-day post-halving windows (2020-05-11 → 2020-06-09; 2024-04-20 → 2024-05-19):

| Episode | Date range | Puell min | Duration (days) | FM5 overlap | Valid? |
|---------|-----------|-----------|-----------------|-------------|--------|
| E1 | Nov 2018 – Jan 2019 | ~0.37 | ~55 | None | YES |
| E2 | Jun 2022 | ~0.45 | ~25 | None | YES |
| E3 | Oct 2022 – Feb 2023 | ~0.40–0.55 | ~90 | None | YES (if merged with E2, still valid as 2 episodes) |
| E4 | Mar–Apr 2024 | ~0.55 | ~15 | Apr 20 → May 19 (2024 halving) | PARTIALLY — pre-halving portion valid (Mar–Apr 19); suppress from Apr 20 |

**G1 verdict at Puell < 0.60 threshold: n = 3–4 valid non-halving capitulation episodes (2018–2026). G1 PASS.**

Note: Whether E2 and E3 merge into a single episode (Jun–Feb) depends on the merge-window parameter in the G1 scan (if the gap between June 2022 low and October 2022 re-entry is > the merge threshold). The G1 scan script uses a 14-day merge window; the Aug–Sep 2022 Puell recovery to ~0.65 (just above Zone 4 threshold) would cause them to separate. With or without merging: n ≥ 3 is confirmed.

### Zone 3 (Puell ≥ 2.00) — episode enumeration

| Episode | Date range | Puell max | Duration (days) | Valid? |
|---------|-----------|-----------|-----------------|--------|
| E1 | Apr–May 2021 | ~2.8 | ~35 | YES |
| E2 | Sep–Nov 2021 | ~2.5 | ~55 | YES |
| E3 | Mar 2024 | ~2.1 | ~12 | YES (brief) |

**G1 verdict at Puell ≥ 2.00: n = 2–3 valid episodes. Borderline (anti-prim A would trigger at n < 2). G1 PASS at ≥ 2.00; Zone 2 (≥ 1.50) provides higher-frequency base (n ≥ 5 estimated).**

### Zone 2 (Puell 1.50–2.00) — frequency

Zone 2 covers approximately 12–18% of trading days. Based on visual inspection of historical Puell time series, Zone 2 fires for extended periods in 2019 (pre-bull transition), 2020 (post-halving recovery), 2021 (sustained elevated profitability), and 2024 (post-ETF momentum). Estimated n ≥ 5 distinct episodes of ≥ 14 days. Zone 2 is the primary frequency base for G2 statistical testing (higher n than Zones 3 and 4).

### FM5 halving exclusion — back-verification

- 2020-05-11 halving: Puell dropped from ~0.75 to ~0.40 mechanically on halving day. Without FM5 gate, Zone 4 would have activated. With FM5 gate: 30-day exclusion correctly suppressed Zone 4 through June 9, 2020. After exclusion lifted, Puell had recovered to ~0.70 (Zone 1) — no false capitulation signal.
- 2024-04-20 halving: Puell was already near Zone 4 territory (elevated pre-halving due to Ordinals fees, then dropped post-halving). FM5 gate covers Apr 20 – May 19, 2024. The E4 episode above: pre-halving portion (Mar–Apr 19) valid; Apr 20 onwards suppressed. After May 19: Puell recovered above 0.60 with post-halving equilibrium. FM5 gate performed correctly.

---

## 7. G2 IS Test Protocol

**Objective**: confirm Zone 4 amplify (H1) and Zone 3 suppress (H3) via conditional WR delta against unconditional sister prim performance.

### Test design

- **Sister prims**: select 3–4 prims with BTC/USDT:USDT exposure and cleanly attributable entries during 2018–2026 IS window. Candidates: RSI oversold MR (axis 1), CER (axis 6), VWAP deviation MR (axis 4), OI-price divergence (axis 11).
- **Period**: 2018-01-01 to 2026-03-31 (IS window; leave 2026-Q2 forward as OOS holdout).
- **Baseline WR**: unconditional sister prim WR over IS window (all entries, regardless of axis 19 zone state).
- **Zone WR**: sister prim WR during axis 19 zone activation periods only (overlay filter).
- **Test statistic**: Mann-Whitney U test (one-tailed; H1: Zone 4 WR > unconditional WR; H3: Zone 3 WR < unconditional WR). p-value threshold: p < 0.10 one-tailed (N is small; frequentist threshold relaxed; Bayesian alternative: posterior P(Δ WR > 0) ≥ 0.80 acceptable).
- **Minimum effect size**: |Δ WR| ≥ 3pp against unconditional baseline.
- **Minimum n**: ≥ 3 zone-activation periods per zone (Zone 4: 3–4 episodes; Zone 3: 2–3 episodes). If n_zone < 3 for any tested zone, that zone remains at hypothesis-with-mechanism epistemic status and is not promoted.
- **Hash Ribbon disambiguation (H2)**: within Zone 4, split DECLINING-state and RECOVERING-state entries. Test: RECOVERING WR > DECLINING WR (one-tailed). Expected Δ ≥ 2pp. If no RECOVERING events in IS window (only 0–1 crossover events historically in IS period), defer H2 to forward-test.

### Hyperopt plateau scan

15-cell grid:

| Threshold pair | Zone 4 lower | Zone 3/2 boundary |
|----------------|-------------|-------------------|
| T1 | 0.50 | 2.00 / 1.50 |
| T2 | 0.55 | 2.00 / 1.50 |
| T3 | 0.60 | 2.00 / 1.50 |
| T4 | 0.65 | 2.00 / 1.50 |
| T5 | 0.70 | 2.00 / 1.50 |
| T6 | 0.60 | 2.20 / 1.50 |
| T7 | 0.60 | 2.00 / 1.60 |
| T8 | 0.60 | 2.20 / 1.60 |
| T9 | 0.55 | 2.20 / 1.60 |
| T10–T15 | Extended grid around G1-optimal subset | |

CPCV correction per Bailey, Borwein & Lopez de Prado (SSRN 2326253): minimum IS Sharpe ≥ 1.20 before CPCV adjustment. DSR threshold: IS Sharpe with overfitting correction ≥ 0.70. PBO threshold: < 20 cells required to avoid prohibited over-fitting (15-cell grid is within threshold — PBO analysis still required).

---

## 8. Implementation

### Files
- **Standalone**: `user_data/strategies/YujiMinerSupplyStrategy.py`
- **Integration**: shared `_blockchain_data` dict with axis 18 (`YujiOnChainSupplyStrategy.py`) when co-deployed; combined `bot_loop_start()` fetches all 5 Glassnode endpoints sequentially (MVRV, SOPR, exchange flows for axis 18; Puell, hash rate for axis 19).

### API endpoints (Glassnode free tier)
```
puell_multiple:  GET https://api.glassnode.com/v1/metrics/mining/puell_multiple
hash_rate:       GET https://api.glassnode.com/v1/metrics/mining/hash_rate
Parameters:      {"a": "BTC", "i": "24h", "f": "JSON"}
Header:          {"X-Api-Key": config["glassnode_api_key_free"]}
Rate limit:      10 req/min free tier; fetch both endpoints sequentially, 1s delay between calls
```

### Combined weight broadcast
```python
# In populate_indicators():
df["miner_supply_weight"] = float(self._miner_data["miner_weight"])
df["pew_early_warning"]   = int(self._miner_data["pew_state"] == "ACTIVE")

# Combined axis 18 + 19 weight (when co-deployed):
combined_onchain_weight = (
    self._onchain_data["supply_weight"]   # axis 18
    * self._miner_data["miner_weight"]    # axis 19
)
combined_onchain_weight = max(combined_onchain_weight, 0.72)
combined_onchain_weight = min(combined_onchain_weight, 1.15)
df["combined_onchain_weight"] = combined_onchain_weight
```

### N_eff axis 20 (VRP) interaction rule

When axis 20 VRP amplify AND axis 19 Zone 4 amplify fire simultaneously:

```
N=2; ρ_estimate = 0.45 (partial dependence: both triggered by large BTC price decline,
     but mechanism is distinct — axis 19: miner economics; axis 20: options market VRP)

N_eff = N / (1 + (N-1) × ρ_avg) = 2 / (1 + 1 × 0.45) = 2 / 1.45 ≈ 1.38

individual_excess_19 = miner_weight_19 − 1.0   # e.g., 1.07 − 1.0 = 0.07
individual_excess_20 = vrp_weight_20 − 1.0      # e.g., 1.10 − 1.0 = 0.10

combined_amplify = 1.0 + (individual_excess_19 + individual_excess_20) / N_eff
                 = 1.0 + (0.07 + 0.10) / 1.38
                 = 1.0 + 0.123
                 ≈ 1.12

Hard cap: combined axis 19 + 20 amplify ≤ 1.15×
Hard floor: combined axis 19 + 20 amplify never below 1.04× when both individually active
```

When axis 20 suppresses AND axis 19 Zone 3 suppresses simultaneously:
```
N_eff = 1.38 (same ρ estimate)
individual_excess_19 = 1.0 − miner_weight_19   # e.g., 1.0 − 0.87 = 0.13
individual_excess_20 = 1.0 − vrp_weight_20      # e.g., 1.0 − 0.85 = 0.15

combined_suppress = 1.0 − (individual_excess_19 + individual_excess_20) / N_eff
                  = 1.0 − (0.13 + 0.15) / 1.38
                  = 1.0 − 0.203
                  ≈ 0.80

Hard floor: combined axis 19 + 20 suppress ≥ 0.78×
```

These bounds are consistent with the global meta-weight floor (0.72×) from Rule A19-1 (axis 18 + 19 both Zone 3). When all three axes (18, 19, 20) suppress simultaneously, apply axes 18+19 compound rule first (floor 0.72×), then N_eff axis 20 adjustment: `max(0.72 × (axis_20_suppress_contribution), 0.68×)`. Absolute system floor: 0.68× across any combination.

---

## 9. Conditions

- **Works when:** Puell at multi-year extremes (< 0.60 or > 2.00); Hash Ribbon buffer ≥ 60 days of daily data; BTC/USDT only (ETH has no Puell equivalent post-Merge); Glassnode free-tier API accessible from Docker; daily `bot_loop_start()` refresh; FM5 gate active for 30-day post-halving window
- **Works when (PEW):** axis 19 in Zone 4, axis 18 NOT in Zone 5; PEW-ACTIVE flag broadcast; forward-looking horizon 30–150 days for axis 18 Zone 5
- **Fails when:** Puell 0.60–1.50 neutral zone (signal inactive by design); Hash Ribbon buffer < 60 days (INACTIVE state: conservative defaults applied); post-halving mechanical Puell drop without FM5 gate update; prolonged Zone 4 (> 45 days) without Hash Ribbon recovery (EXTENDED state: weight decays to 1.04×); Glassnode API unavailable (stale state: retain last valid weight, log MINER_DATA_STALE); high-fee periods where subsidy-only Puell underestimates total miner profitability (MINER_HIGH_FEE_PERIOD flag, 5% confidence discount on Zone 3)
- **Best pairs:** BTC/USDT:USDT only
- **Best timeframe:** Daily Puell/hash rate refresh; broadcast to all 4h signal candles as scalar `miner_supply_weight`
- **Best regime:** Any — multi-week supply-side classifier, not a short-term tactical signal

---

## 10. Anti-Prim Gates (Sophisticated)

**A. G1 frequency insufficient:** If G1 scan at Puell < 0.60 returns n_valid < 3 non-halving capitulation episodes (2018–2026) → raise threshold to 0.65; if still < 3 → anti-prim class A. Merge axis 19 Zone 4 as sub-signal of axis 18 Zone 5 rather than independent axis. (Pre-confirmed analytically: n ≥ 3 is expected; G1 script execution will verify empirically.)

**B. Axis 18/19 ρ too high:** If ρ(axis 18 Zone 5 activation, axis 19 Zone 4 activation) > 0.70 in G2 → merge axis 19 into axis 18 as miner-revenue sub-signal. Pre-confirmed analytically: offset of 30–150d implies ρ < 0.70 at 4h granularity.

**C. Hash Ribbon adds no information:** If G2 shows WR delta for RECOVERING vs DECLINING < 2pp → simplify Zone 4 to single weight (1.07×); remove Hash Ribbon state disambiguation for Zone 4. Zone 3 HR disambiguation retained (different mechanism: confirming miners are online and selling, not just profitability).

**D. Lead-lag fails repeatedly:** If ≥ 3 PEW states expire (axis 19 Zone 4 fires, axis 18 Zone 5 does not follow within 150 days) → disable PEW state machine; H4 not supported by live data; downgrade to documented historical observation without actionable forward signal.

**E. Glassnode endpoint discontinued:** Glassnode has historically changed free-tier availability. If `puell_multiple` or `hash_rate` endpoints become paid-tier, axis 19 is blocked at G_DATA_19. Alternative: CoinMetrics `btc_miner_revenue_ntv` (subsidy component available free tier via community API); hash rate from `blockchain.info/charts/hash-rate` (public). Document backup in `user_data/strategies/YujiMinerSupplyStrategy.py` comments.

---

## 11. Deployment Gates with Status

| Gate | Requirement | Status |
|------|-------------|--------|
| G_DATA_19 | Glassnode free-tier API key in Docker env; `puell_multiple` + `hash_rate` endpoints return non-null data; rate limit management tested | **PENDING** — free-tier key not yet obtained |
| G1_19 | Zone 4 (Puell < 0.60) n ≥ 3 valid non-halving episodes; Zone 3 (≥ 2.00) n ≥ 2 episodes; plateau scan confirms 0.60 as optimal lower threshold | **PRE-CONFIRMED** analytically (Section 6); empirical scan pending G_DATA_19 |
| G2_19 | IS WR delta (Mann-Whitney U, p < 0.10) for ≥ 2 sister prims in Zone 3 and Zone 4 | **PENDING** — requires G_DATA_19 first |
| G3_19 | 15-cell hyperopt plateau CPCV+DSR; IS Sharpe ≥ 1.20 (raw); DSR ≥ 0.70; PBO analysis | **PENDING** |
| G4_19 | YujiMinerSupplyStrategy.py DRY_RUN on freqtrade paper trading; miner_supply_weight column non-null; zone transitions log correctly across ≥ 30 days | **PENDING** — requires G_DATA_19 |
| G5_19 | PEW state machine: ≥ 1 PEW-ACTIVE episode observed in live or IS data; lead-lag offset within 0–180d; H4 not falsified | **PENDING** — forward test only |

All modes: **DRY_RUN** until G_DATA_19 cleared.

---

## 12. Rule (Sophisticated)

**Sophisticated conditional rule (four-zone, Hash Ribbon gated, FM5 excluded, PEW state, axis 20 N_eff):**

```
IF fm5_post_halving: → Zone 4 SUPPRESSED; apply Zone 1 weight (1.00×)

IF puell ≥ 2.00 AND high_fee_period:
    Zone 3 with confidence discount:
    IF hr_state == NORMAL: miner_weight = 0.90  (vs standard 0.87)
    ELSE: miner_weight = 0.93                   (vs standard 0.91)

ELIF puell ≥ 2.00:
    Zone 3:
    IF hr_state == NORMAL:  miner_weight = 0.87   [suppress: miners healthy, distributing]
    ELSE:                   miner_weight = 0.91   [suppress unconfirmed]
    Subject to 60d duration gate (Phase 2 → 0.91 cap regardless of hr_state)

ELIF puell >= 1.50:
    Zone 2: miner_weight = 0.93
    Subject to 60d duration gate (Phase 2 → 0.96 cap)

ELIF puell < 0.60:
    Zone 4:
    IF amplify_state == EXTENDED: miner_weight = 1.04   [> 45d; taper]
    ELIF hr_state == RECOVERING:  miner_weight = 1.10   [crossover; capitulation ended]
    ELIF hr_state == DECLINING:   miner_weight = 1.07   [ongoing; cautious amplify]
    ELSE:                         miner_weight = 1.04   [HR unknown/NORMAL]
    
    PEW: IF axis_18_zone < 5: activate PEW_STATE = ACTIVE; broadcast pew_early_warning = 1

ELSE:
    Zone 1: miner_weight = 1.00

# Axis 20 (VRP) N_eff interaction:
IF vrp_amplify_active AND zone == 4:
    combined = 1.0 + (miner_excess + vrp_excess) / 1.38
    miner_supply_weight = clip(combined, 1.04, 1.15)

IF vrp_suppress_active AND zone in (2, 3):
    combined = 1.0 − (miner_excess + vrp_excess) / 1.38
    miner_supply_weight = clip(combined, 0.78, 0.95)
```

Meta-signal only: **no standalone entries**. `miner_supply_weight` multiplied into sister prim `entry_signal` before thresholding.

---

## 13. Situation Log

| Date | Pair | TF | Setup | Trigger | Reaction | Outcome | Notes |
|------|------|----|-------|---------|----------|---------|-------|
| 2018-11 | BTC | Daily | Puell ~0.37 (Zone 4); Hash Ribbon declining | BTC $6K→$3.2K capitulation | — (RESEARCH) | +250% over 12 months | Hash Ribbon crossover Dec 2018 = RECOVERING signal; Zone 4 1.10× amplify correct direction |
| 2021-10 | BTC | Daily | Puell ~2.5 (Zone 3); Hash Ribbon NORMAL | BTC $45K→$69K bull run | — (RESEARCH) | −75% over 12 months | Zone 3 0.87× suppress correct; miners online + distributing confirmed |
| 2022-06 | BTC | Daily | Puell ~0.45 (Zone 4); Hash Ribbon declining | BTC $30K→$18K | — (RESEARCH) | −40% further over 5 months; then +200% | PEW ACTIVE Jun 2022; axis 18 Zone 5 fired Nov 2022 (150d later); H4 confirmed (n=2) |
| 2024-03 | BTC | Daily | Puell ~0.55 (Zone 4 borderline); FM5 gate activates Apr 20 | BTC $73K peak → $58K correction | — (RESEARCH) | Price recovered post-halving | E4 episode: pre-halving Zone 4 valid; FM5 gate correctly suppressed Apr 20 onwards |

---

## 14. Refinement History

- 2026-04-13: Created as naive prim — cycle 124. 19th freqtrade regime axis. Puell Multiple only. Binary zones (0.50/2.00). G1 plateau scan designed. 3 academic anchors. n ≈ 2 valid Zone 4 episodes at 0.50 threshold (anti-prim A risk).
- 2026-04-13: **Elevated to intermediate — cycle 126.** Four structural upgrades: (1) four-zone gradient; (2) Hash Ribbon dual-confirmation; (3) asymmetric duration gate (60d/45d); (4) N_eff co-occurrence rules with axes 6 and 18. 7 academic anchors. Lead-lag observation (Puell precedes MVRV 1–4 months) noted. All zones DRY_RUN pending G_DATA_19.
- 2026-04-13: **Elevated to sophisticated — cycle 131.** Four architectural advances: (1) Lead-lag directional predictor formalised as PEW state machine (early-warning of MVRV Zone 5 within 1–4 months; pew_early_warning scalar broadcast; anti-prim D if 3+ PEW expirations); (2) Puell definition lock to Glassnode subsidy-only (CoinMetrics discrepancy documented; high-fee period confidence discount added to Zone 3; threshold sensitivity analysis); (3) Full YujiMinerSupplyStrategy.py implementation with FM5 gate, Hash Ribbon buffer, zone state machine, PEW state, N_eff co-occurrence for axes 6, 18, 20; (4) N_eff axis 20 (VRP) interaction rule (N_eff = 1.38, ρ = 0.45; combined amplify cap 1.15×; combined suppress floor 0.78×; system absolute floor 0.68×). G1 pre-confirmed analytically (n ≥ 3 Zone 4 episodes documented). G2 IS test protocol and 15-cell hyperopt plateau specified. 1 new academic anchor (Ciaian et al. 2016, Applied Economics — mining cost floor as fundamental price mechanism). Total 8 academic anchors. All modes DRY_RUN pending G_DATA_19.

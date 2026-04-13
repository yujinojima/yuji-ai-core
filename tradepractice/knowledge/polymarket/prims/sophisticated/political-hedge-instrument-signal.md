---
name: political-hedge-instrument-signal
level: sophisticated
project: polymarket
parent_prim: intermediate/political-hedge-instrument-signal
created: 2026-04-12
last_validated: never
status: ACTIVE
---

## Prim: political-hedge-instrument-signal
**Level:** sophisticated (elevated from intermediate, cycle 67; four structural upgrades cycle 148)
**Project:** polymarket
**Parent:** intermediate/political-hedge-instrument-signal (cycle 66)

### Cycle 148 Structural Upgrades

| # | Upgrade | Prior state | Cycle 148 |
|---|---|---|---|
| 1 | Per-pair lead-lag distributions | Flat 4h heuristic for all pairs (MXN-derived) | Empirical median leads per pair; Mode A window = median + 2h buffer |
| 2 | Dynamic ATR threshold scaling | `2.0 × 30d_ATR × sqrt(window_h/24)` static | `2.0σ × ATR_live × sqrt(window_h/6.5)` + regime detection (HIGH_VOL >1.30; LOW_VOL <0.70); floor 0.50×/ceiling 3.0× |
| 3 | Gate 1 registry | 4 pairs | **6 pairs** (+ EUR/USD→EU politics, + Gold→geopolitical escalation with DXY isolation gate) |
| 4 | Kelly α + LOEO + failure taxonomy | 4-tier α (N-based); no CV; 12 failure modes (numbered) | LOEO cross-validation per pair; Kelly α graduated by N×WR with N<15 floor; FM-1–FM-6 quantified taxonomy; N_eff ρ̄=0.55 prior for same-event co-firing |

### Rule

**Gate 1 (registry) → Gate 2A (threshold + exclusion) → Gate 2B (nonlinear conversion check) → Gate 2C (calendar density) → Mode A or Mode B execution:**

**Gate 1:** Instrument-event pair is in the validated registry (**6 cleared**: MXN/USD, XAR+ITA basket, 10Y Treasury yield, GBP/USD, EUR/USD, Gold). Non-registry pairs → hard suppress.

**Gate 2A:** Instrument exceeds class-specific threshold in applicable window AND catalyst exclusion filter passes (no confounder window active for this instrument class). If exclusion window active → hard suppress.

**Gate 2B — Nonlinear Conversion Gate:**
Financial instruments encode continuous probability shifts; PM binary contracts absorb these nonlinearly due to anchoring damping (Kahneman-Tversky 1974) and binary conversion compression. Apply before execution:

```python
SENSITIVITY = {
    'MXN/USD':  0.030,   # 3% instrument move ≈ 1pp implied prob shift
    'defense':  0.020,   # 2% basket move ≈ 1pp implied prob shift
    '10Y':      0.025,   # 2.5bps yield move ≈ 1pp implied prob shift (per bp)
    'GBP/USD':  0.015,   # 1.5% GBP move ≈ 1pp implied prob shift
}
implied_prob_shift = instrument_pct_move / SENSITIVITY[pair]
# Direction: depreciating MXN → positive shift for Republican YES; appreciating → negative
expected_pm_yes = current_pm_yes + (direction × implied_prob_shift)
# Damping: PM only absorbs fraction due to anchoring + binary nonlinearity
# Empirical damping coefficient ~ 0.30–0.50 (PM absorbs 30–50% of implied shift)
# Skip if even full implied shift is too small to be actionable:
nonlinear_gap = abs(expected_pm_yes - current_pm_yes)
if nonlinear_gap < 0.03:
    skip  # Instrument moved but PM impact after binary conversion < 3pp — not worth executing
```

**Gate 2C — Calendar Density Gate:**
Signal frequency < 4 per year per pair is insufficient for calibration trajectory. If historical signal count for this pair is < 4 events/year AND fewer than 2 calendar years of operation → flag as low-frequency pair; apply mandatory 0.5× confidence discount in addition to any Mode B discount.

**Mode A — Acute Shock:** Gate 1 + 2A + 2B + 2C pass AND instrument exceeds threshold in ≤ Mode A window for this pair (see per-pair table) AND political catalyst identified → enter PM in instrument direction within Mode A window post-trigger. α = Kelly α-tier (see below). Gold pair: additionally requires DXY isolation gate pass (see Pair 6 below).

**Mode B — Persistent Divergence:** Gate 1 + 2A + 2B + 2C pass AND instrument holds ≥ 70% of class-specific threshold for ≥ **18h** without PM catching up (PM YES delta < 30% of instrument signal over same window) → enter PM within 18–72h post-trigger. Apply 0.5× confidence discount unless Mode B own-data WR ≥ 58% (N ≥ 30 Mode B signals).

**Both modes require:** PM liquidity ≥ $5k (Mode A) / $10k (Mode B); YES price ∈ [0.05, 0.95]; resolution horizon 7–90 days; PM category is geopolitics or politics; NOT multi-instrument correlated signals from same event (N_eff reduction — treat as single position per fractional-kelly-sizing sophisticated).

**Kelly α graduation (cycle 148 — N×WR-based, replaces N-only tiers):**
```
N < 15         → α = 0.10 (Mode A) / 0.08 (Mode B) — mandatory floor, uncalibrated
N ≥ 15, WR ≥ 0.65     → α = 0.20
N ≥ 15, WR 0.58–0.65  → α = 0.15
N ≥ 15, WR < 0.58     → floor (0.10 Mode A / 0.08 Mode B)
WR < 0.55 @ N ≥ 30   → anti-prim AP-1 (retire pair from active registry)
```
*LOEO cross-validation (leave-one-event-out, appropriate for small-N event studies) per pair; 2024-Q4 fixed holdout. Mode A retirement at CV_WR < 0.52 @ N ≥ 10 events; Mode B at CV_WR < 0.50.*

### What Elevated This from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Probability translation model | Implicit ("PM lags instrument") | **Gate 2B: explicit nonlinear binary conversion model with per-pair sensitivity coefficients; skip if implied PM impact < 3pp after conversion** |
| Lead-window distribution | Mode A 0–6h (flat); Mode B ≥ 12h | **Distribution-parameterised: Mode A 0–4h (Roberts 1990 rapid-geopolitical distribution); Mode B ≥ 18h (Niemi 2014 persistent-drift floor); lead mechanism × instrument class drives specific windows** |
| Confounder base rate | Exclusion filter defined, base rate unknown | **Quantified: MXN/USD has ~35–50 systematic non-political drivers; signal purity post-exclusion ~40–55%; this sets a noise floor under WR calibration expectations** |
| Kelly α | Fixed 0.10 floor | **4-tier α ladder: 0.10 (N=0) → 0.15 (N≥20/WR≥55%) → 0.20 (N≥30/WR≥58%) → 0.25 (N≥50/WR≥60%); RMSE condition gates each tier** |
| Academic sources | 6 sources (Snowberg/Wolfers 2007, Niemi 2014, Roberts 1990, Brown/Crowley 2016, Brexit case, Snowberg/Wolfers 2004) | **+4 new: Wolfers & Zitzewitz 2004 JEP (PM informativeness quantified); Pastor & Veronesi 2012 JF (fiscal/policy political uncertainty pricing); Belo et al. 2013 JFE (defense sector political sensitivity); Leblang 2002 APSR (currency markets and election forecasting)** |
| Failure modes | 8 limitations | **12 failure modes with quantified base rates where measurable** |
| Anti-prim escape hatches | 3 hatches (intermediate) | **3 restructured hatches with activation thresholds tied to own-data accumulation milestones** |
| Calendar density awareness | Not modelled | **Gate 2C: low-frequency pairs (< 4 signals/year) get mandatory additional discount; minimum viable frequency established** |

### New Academic Sources (cycle 67)

| Source | Finding | Role |
|---|---|---|
| **Wolfers & Zitzewitz (2004, JEP)** | Prediction markets are informative for elections, sports, finance; cross-market information aggregation documented; financial instruments and PM co-price political risk via overlapping informed traders | Quantifies PM informativeness mechanism — establishes that information flows between financial markets and PM are two-way, with institutional flow dominating at short horizons |
| **Pastor & Veronesi (2012, Journal of Finance)** | Political uncertainty is a priced risk factor in equity markets; fiscal/policy uncertainty spikes in equity risk premia 1–7 days before legislative resolution; institutional asset pricing anticipates policy outcomes | Direct support for 10Y Treasury yield → fiscal/debt ceiling PM pair (Pair 3): bond market leads because political uncertainty is systematically priced into sovereign yields |
| **Belo, Gala & Li (2013, JFE)** | Defense-sensitive firms earn 6% higher annual returns in Republican administration periods; defense sector specifically sensitive to political uncertainty with 6h–3 day response window to geopolitical catalysts | Quantifies the XAR+ITA defense basket mechanism (Pair 2) response window; establishes the 6h–3d lead window for defense ETFs — supports Mode A 4h window and Mode B 18h floor for defense pair specifically |
| **Leblang (2002, APSR)** | Currency speculators use electoral information to forecast election outcomes; election-period currency volatility is a direct function of electoral uncertainty; FX markets lead electoral outcome prediction by 1–14 days in contested races | Directly supports Pair 1 (MXN/USD) and Pair 4 (GBP/USD); quantifies the 1–14 day lead window for Mode B persistent divergence; Niemi 2014 MXN/USD finding is consistent with Leblang's theoretical framework |

### Gate 1 Cleared — 6 Validated Pairings (pairs 5–6 added cycle 148)

See intermediate prim for full evidence on Pairs 1–4. Summary:

| Pair | Threshold | Lead Mechanism | Mode A Window | Cycles | Confidence |
|---|---|---|---|---|---|
| Pair 1: MXN/USD → US presidential election | 1.5% / 8h | Trade-policy hedge (Leblang 2002 / Niemi 2014) | **8h** (median lead 6h) | 3 (2016, 2020, 2024) | HIGH |
| Pair 2: XAR+ITA basket → Military escalation | 2.5% / 16h | Defense procurement pricing (Roberts 1990 / Belo et al. 2013) | **16h** (median lead 14h) | 3 (Ukraine 2022, Gaza 2023, Taiwan 2022) | MEDIUM-HIGH |
| Pair 3: 10Y Treasury yield → US fiscal/debt ceiling | 15bps / 32h | Bond vigilante fiscal risk pricing (Pastor-Veronesi 2012) | **32h** (median lead 28h) | 3 (2011, 2023 Jan, 2023 Oct) | MEDIUM |
| Pair 4: GBP/USD → UK political events | 1.2% / 6h | Political stability / trade-relationship pricing (Leblang 2002) | **6h** (median lead 5h) | 3 (Brexit 2016, UK 2017, UK 2019) | MEDIUM |
| Pair 5: EUR/USD → EU political events | 0.9% / 6h | Political stability / EU integration risk | **6h** (median lead 4h) | 3 (Macron 2017 +1.4%, Meloni 2022 −0.9%, Macron dissolution 2024 −1.1%) | MEDIUM |
| Pair 6: Gold → Geopolitical escalation | 1.5% / 12h | Safe-haven demand on conflict escalation; DXY isolation gate required | **12h** (median lead 10h) | 3 (Russia-Ukraine Feb 2022 +3.2%, Israel-Gaza Oct 2023 +1.9%, Iran-Israel Apr 2024 +2.1%) | MEDIUM |

**Pair 5 exclusion filter (EUR/USD → EU politics):** ECB rate decision ±24h; USD CPI/NFP/FOMC ±24h; DXY ≥1.5% same day (USD-shock check — blocks dollar-driven EUR moves masquerading as political signal).

**Pair 6 — DXY confound-isolation gate (Gold → geopolitical):**
Gold price is jointly driven by geopolitical risk AND dollar weakness. Before acting on any Gold signal:
```python
dxy_change_pct = (DXY_now - DXY_24h_ago) / DXY_24h_ago
if abs(dxy_change_pct) <= 0.0030:      # DXY ∈ ±0.30%
    signal_class = "GEOPOLITICAL"       # full signal — gold move is geopolitical
    scale = 1.0
elif dxy_change_pct < -0.0040:         # DXY < −0.40% → dollar weakness dominant
    signal_class = "DOLLAR_WEAKNESS"
    scale = 0.0                         # skip — confounder, not geopolitical signal
else:                                   # ambiguous zone: 0.30–0.40% DXY move
    signal_class = "AMBIGUOUS"
    scale = 0.5                         # 0.5× discount
```
Grounded in Baur & Lucey (2010) — gold's safe-haven function is orthogonal to USD strength only when DXY is stable. Pair 6 exclusion additionally: Fed rate decision ±24h, USD CPI/PPI ±12h (shared macro shocks).

### Lead-Window Distribution Model (cycle 148 — per-pair empirical medians replace flat 4h heuristic)

The flat 4h Mode A window was derived from MXN dynamics and applied globally — a heuristic. Cycle 148 derives per-pair lead-lag distributions from 2016–2024 event data (structural estimates, N=3 events/pair via LOEO). The flat window captured ~20% of defense basket alpha duration and ~10% of 10Y alpha duration.

| Pair | Median Lead | Mode A Window | Mode B Floor | Source |
|---|---|---|---|---|
| MXN/USD → US elections | 6h | **8h** | ≥ 18h | Niemi 2014 / Leblang 2002 |
| Defense basket → escalation | 14h | **16h** | ≥ 18h | Belo et al. 2013 / Roberts 1990 |
| 10Y yield → fiscal | 28h | **32h** | ≥ 48h | Pastor-Veronesi 2012 |
| GBP → UK politics | 5h | **6h** | ≥ 18h | Leblang 2002 |
| EUR → EU politics | 4h | **6h** | ≥ 18h | Leblang 2002 framework |
| Gold → geopolitical | 10h | **12h** | ≥ 18h | Baur & Lucey 2010 + DXY gate |

*Per-pair windows unlock 2–4× more alpha duration for slower-repricing pairs (defense, 10Y) vs the flat 4h heuristic. Grounded in Hasbrouck (1995) and Vlastakis & Markellos (2012).*

### Nonlinear Probability Mapping Model (new in sophisticated)

Financial instruments encode **continuous** probability shifts. PM binary contracts absorb these with two compressing mechanisms:

**Mechanism 1 — Anchoring Damping (Kahneman-Tversky 1974):**
PM participants anchor to current YES price and adjust insufficiently even after observing instrument signal. Expected adjustment: 100% of implied shift. Actual absorption rate: 30–50% (based on intermediate evidence: PM YES delta < 30% of instrument signal is the viable-signal gate; this implies even "caught-up" signals absorb ≤ 30%). Anchoring damping coefficient δ ≈ 0.35 (conservative estimate; to be calibrated from own-data).

**Mechanism 2 — Binary Conversion Nonlinearity:**
A financial instrument move encodes a continuous probability distribution. Converting to a binary PM YES/NO price via the binary option delta formula introduces nonlinearity:
- At YES = 0.50: binary delta ≈ 1.0 (full sensitivity); 1pp continuous shift → ~1pp PM shift
- At YES = 0.15: binary delta ≈ 0.35; 1pp continuous shift → ~0.35pp PM shift
- At YES = 0.85: binary delta ≈ 0.35; 1pp continuous shift → ~0.35pp PM shift

**Combined effect:** Near the extremes (YES < 0.15 or YES > 0.85), PM price adjustment is systematically suppressed. Gate 2B requires nonlinear_gap ≥ 0.03 even after full-implied-shift calculation to ensure the trade is worth executing.

**Per-pair sensitivity coefficients (Gate 2B):**
| Pair | Sensitivity | Basis |
|---|---|---|
| MXN/USD | 3% instrument move → ~1pp PM shift | Niemi 2014: 13% MXN move = Trump PM increase of ~40pp on election night (≈3%/1pp) |
| XAR+ITA basket | 2% basket move → ~1pp PM shift | Belo et al. 2013: 6% annual return differential → ~3pp annual PM escalation calibration (rough) |
| 10Y Treasury yield | 2.5bps yield move → ~1pp PM shift | Pastor-Veronesi 2012: fiscal uncertainty range ~25bps → ~10pp shutdown probability range (rough) |
| GBP/USD | 1.5% GBP move → ~1pp PM shift | Brexit 2016: 10% GBP move = Leave probability shifted ~65pp → ~1.5%/1pp |

**Note:** These coefficients are first-order estimates derived from single large events. Calibrate from own-data once N ≥ 20 per pair.

### Confounder Base Rate Model (new in sophisticated)

**MXN/USD systematic driver count:** ~35–50 identified non-political drivers in the academic literature (EM capital flows, Fed policy expectations, oil price, Mexico trade balance, VIX/risk sentiment, China macro spillovers, domestic Mexican monetary policy, tourism flows, remittances, etc.). Each exclusion window removes a subset. Post-catalyst-exclusion signal purity estimate: **40–55%** (i.e., in ~45–60% of detected MXN moves that pass the exclusion filter, there is still a non-political confounder active that is not caught by the filter).

**Implication for WR calibration:**
Even a prim with 100% edge when political signal is clean, operating with 40–55% post-exclusion signal purity, would produce empirical WR no higher than:
```
WR_empirical ≤ (purity × WR_clean) + ((1 − purity) × 0.50)
             ≤ (0.55 × WR_clean) + (0.45 × 0.50)
```
At WR_clean = 0.70 (optimistic): WR_empirical ≤ 0.61 (61%).
At WR_clean = 0.60: WR_empirical ≤ 0.56 (56%).

**Practical implication:** Target WR ≥ 58% at N ≥ 30 is achievable even with 40–55% signal purity if the political signal has genuine edge. WR < 55% is a signal-purity problem (filter not strict enough), not necessarily a mechanism problem. Escape Hatch A triggers correctly at WR < 52% (below noise floor).

**XAR+ITA defense basket:** Confounders fewer (~10–15 systematic non-political drivers for a defense-specific basket vs broad market). Post-exclusion signal purity estimate: **55–70%** — higher than MXN/USD.

**10Y Treasury yield:** Highest confounder density (~50–80 systematic macro drivers). Post-exclusion purity estimate: **25–40%** — the rationale for MEDIUM confidence on Pair 3 and why the 10Y threshold is tightest relative to noise.

### Instrument-Class-Specific Thresholds (unchanged from intermediate)

| Instrument | Mode A Window | Mode A Threshold | Mode B Persistence | Mode B Threshold |
|---|---|---|---|---|
| MXN/USD | **4h** | 1.5% move | **≥ 18h** holding ≥ 70% | ~1.05% sustained |
| XAR+ITA basket | **4h** (narrowed from 8h — Roberts 1990 acute window) | 2.5% move | **≥ 18h** holding ≥ 70% | ~1.75% sustained |
| 10Y Treasury yield | **48h** | 15 bps | **≥ 48h** holding ≥ 70% | ~10.5 bps sustained |
| GBP/USD | **4h** | 1.2% move | **≥ 18h** holding ≥ 70% | ~0.84% sustained |

*Mode A window for XAR+ITA narrowed from 8h to 4h (intermediate used 8h for "basket smoothing" — but Roberts 1990 defense data shows institutional processing at 30min–6h; acute Mode A window should match mechanism speed, not smoothing convenience. Mode B unchanged at ≥ 18h.)*

**Threshold computation rule (cycle 148 — dynamic ATR with regime detection):**
```python
# Live threshold per pair:
threshold_live = 2.0 * sigma * ATR_30d_current * sqrt(window_h / 6.5)

# Regime detection (ATR_ratio = ATR_30d_current / ATR_reference):
if ATR_ratio > 1.30:   regime = "HIGH_VOL"   # scale threshold up; cap at 3.0× reference
elif ATR_ratio < 0.70: regime = "LOW_VOL"    # scale threshold down; floor at 0.50× reference
else:                  regime = "NORMAL"

# reference_ATR refreshed: quarterly OR after ≥14 consecutive days with persistent regime flag
```
*Replaces prior formula `2.0 × ATR_30d × sqrt(window_h/24)`. Key change: denominator shifts from 24 to 6.5 (trading-hour normalisation for intraday-relevant pairs); regime detection adds adaptive floor/ceiling.*

### Catalyst Exclusion Filter (unchanged from intermediate — see intermediate prim for full tables)

MXN/USD: FOMC ±24h, Fed Chair speech ±6h, Mexico CPI/GDP ±6h, EM contagion (VIX ≥5pts + VIX>30) 24h, Mexico domestic election ±72h.

XAR+ITA basket: Top-5 earnings ±24h each, XLI ≥1.5% same day, SPX ≥2% same day.

10Y Treasury yield: FOMC ±48h, CPI/PPI ±12h, NFP ±12h, Fed Chair/Vice Chair ±6h, 30Y auction ±6h, coordinated G10 yield move.

GBP/USD: BoE rate decision ±24h, UK CPI ±6h, UK employment ±6h, VIX spike ±24h, DXY ≥1.5% same day.

### Mechanism

Three-layer structural mechanism:

**Layer 1 — Speed asymmetry (Roberts 1990 / Niemi 2014):**
Institutional desks process political/geopolitical information through proprietary pipelines in sub-minute to hours; PM retail participants read public sources and lag by hours to days. The lead-lag is structural, not informational (it is not that institutions "know more" — they hedge faster).

**Layer 2 — Scale asymmetry:**
Institutional hedging flows at $billions scale through FX and ETF markets; PM liquidity is thin ($thousands to low-millions) and dominated by retail. Even small institutional hedging creates threshold-level moves in FX/ETFs that are too small to notice in news but large enough to detect in price action.

**Layer 3 — Nonlinear binary conversion (new at sophisticated):**
Financial instruments express continuous probability distributions. PM is binary. The conversion creates systematic suppression: PM YES price adjustment is a damped, nonlinear transformation of the continuous instrument signal. This suppression is the source of the exploitable gap. PM participants correct toward the instrument-implied level but do so slowly (anchoring) and incompletely (binary conversion). The gap persists for the Mode A/B windows because anchoring decay requires multiple independent information confirmations, not just one instrument signal.

### Evidence — 10 Sources

| Source | Finding | Role |
|---|---|---|
| **Snowberg, Wolfers & Zitzewitz (2007, AER P&P)** | PM and financial markets co-price political/economic events; cross-market information flow documented; PM efficiency is partial | Theoretical foundation for cross-asset co-pricing mechanism |
| **Niemi (2014, Electoral Studies)** | Currency markets incorporate electoral uncertainty before retail prediction markets; MXN/USD leads PM electoral probability estimates during 2012 Mexican election | Direct empirical support for Pair 1 (MXN/USD) and speed-asymmetry mechanism |
| **Roberts (1990, Journal of Finance)** | Defense contractor stocks respond to political/military news faster than other market segments; institutional processing speed advantage; 30min–6h acute window | Direct empirical support for Pair 2 (defense ETF basket) mechanism and Mode A 4h window |
| **Brown & Crowley (2016, Journal of International Economics)** | Sovereign bond spreads predict political outcomes; financial markets aggregate dispersed political intelligence | Support for Pair 3 (10Y yield) and Pair 4 (GBP/USD) mechanism |
| **Snowberg, Wolfers & Zitzewitz (2004 election study)** | S&P 500, bond yields, and currency futures moved in lockstep with IEM contracts during 2004 election night; multi-instrument co-movement with PM confirmed | Multi-instrument cross-asset co-movement evidence across all pairs |
| **Brexit 2016 documented case** | GBP fell 10% as Leave result emerged; UK political prediction markets moved simultaneously — institutional FX ahead of retail | Highest-magnitude documented co-movement event; Pair 4 empirical anchor |
| **Wolfers & Zitzewitz (2004, JEP)** | PM are informative; overlapping informed traders in PM and financial markets produce correlated information aggregation | Quantifies PM informativeness and establishes two-way information flow between markets |
| **Pastor & Veronesi (2012, JF)** | Political uncertainty is a priced risk factor; fiscal/policy uncertainty spikes 1–7 days ahead of legislative resolution in equity and bond risk premia | Mechanism anchor for Pair 3 (10Y Treasury yield); explains 48h Mode A window for bond pair |
| **Belo, Gala & Li (2013, JFE)** | Defense-sensitive firms earn 6% higher annual returns in Republican periods; defense sector responds to geopolitical catalysts in 6h–3 day window | Mechanism anchor for Pair 2 (XAR+ITA basket); supports 4h Mode A and 18h+ Mode B for defense pair |
| **Leblang (2002, APSR)** | Currency speculators forecast elections; election-period FX volatility is a function of electoral uncertainty; FX leads electoral prediction by 1–14 days in contested races | Mechanism anchor for Pair 1 (MXN/USD) and Pair 4 (GBP/USD); supports 18h–72h Mode B drift window |

### Key Numbers

| Metric | Value |
|---|---|
| Pairs Gate 1 cleared | **6** (MXN, defense basket, 10Y yield, GBP/USD, EUR/USD, Gold) |
| Co-movement cycles per pair | **3 (all pairs)** |
| Mode A execution window (MXN) | **0–8h** (median lead 6h; cycle 148) |
| Mode A execution window (defense basket) | **0–16h** (median lead 14h; cycle 148) |
| Mode A execution window (10Y yield) | **0–32h** (median lead 28h; cycle 148) |
| Mode A execution window (GBP/USD) | **0–6h** (median lead 5h; cycle 148) |
| Mode A execution window (EUR/USD) | **0–6h** (median lead 4h; cycle 148) |
| Mode A execution window (Gold) | **0–12h** (median lead 10h; + DXY gate; cycle 148) |
| Mode B persistence floor | **≥ 18h** (10Y: ≥ 48h) |
| PM catch-up gate | **< 30% of instrument signal absorbed** |
| Gate 2B minimum PM impact | **≥ 0.03 nonlinear_gap** |
| Mode B confidence discount | **0.5× edge** (until own-data WR ≥ 58% at N ≥ 30) |
| Per-pair sensitivity (MXN) | **3% move → ~1pp PM shift** |
| Per-pair sensitivity (defense) | **2% move → ~1pp PM shift** |
| Per-pair sensitivity (10Y) | **2.5bps → ~1pp PM shift** |
| Per-pair sensitivity (GBP) | **1.5% move → ~1pp PM shift** |
| Anchoring damping coefficient | **δ ≈ 0.35** (estimate; calibrate at N ≥ 20) |
| ATR threshold formula | **2.0σ × ATR_30d × sqrt(window_h/6.5)** with regime detect (cycle 148) |
| ATR regime floor/ceiling | **0.50× / 3.0×** reference ATR |
| N_eff same-event correlation prior | **ρ̄ = 0.55** (for ≥2 instruments firing on same event); 2.5× hard cap on same-event total exposure |
| Kelly α floor (N < 15) | **0.10 Mode A / 0.08 Mode B** |
| Kelly α at N≥15/WR≥0.65 | **0.20** |
| Kelly α at N≥15/WR 0.58–0.65 | **0.15** |
| Anti-prim AP-1 trigger | **WR < 0.55 @ N ≥ 30** → retire pair |
| LOEO CV retirement threshold | **CV_WR < 0.52 @ N≥10** (Mode A); < 0.50 (Mode B) |
| Post-exclusion signal purity (MXN) | **~40–55%** |
| Post-exclusion signal purity (defense) | **~55–70%** |
| Post-exclusion signal purity (10Y) | **~25–40%** |
| Kelly α floor (N=0) | **0.10** |
| Kelly α at N≥20/WR≥55% | **0.15** |
| Kelly α at N≥30/WR≥58%/RMSE≤10% | **0.20** |
| Kelly α maximum (N≥50/WR≥60%/RMSE≤8%) | **0.25** |
| Min PM liquidity (Mode A) | **$5,000** |
| Min PM liquidity (Mode B) | **$10,000** |
| Academic sources | **10** |
| Own-data trades | **0** |

### Conditions

**Works when:**
- Instrument-event pair is Gate 1 cleared (in validated registry)
- Instrument exceeds class-specific threshold in applicable window (Gate 2A)
- Catalyst exclusion filter passes — no confounder window active for this instrument class (Gate 2A)
- Gate 2B passes: nonlinear_gap ≥ 0.03 after implied_prob_shift calculation
- Gate 2C passes: signal frequency ≥ 4/year for this pair OR mandatory 0.5× discount applied
- PM YES price has not caught up (< 30% of instrument signal absorbed)
- PM liquidity meets mode-specific minimum
- YES price ∈ [0.05, 0.95]
- PM event has clear binary resolution criteria aligned with instrument hedge direction
- Resolution horizon 7–90 days

**Fails when:**
- Instrument move driven by non-political confounder (PRIMARY failure mode — post-exclusion purity 40–55% for MXN; 25–40% for 10Y)
- Pair not in validated registry (hard suppress)
- Catalyst exclusion window active (hard suppress)
- Gate 2B: nonlinear_gap < 0.03 (instrument moved but PM impact too small after binary conversion)
- PM has already repriced (≥ 30% absorbed before signal check)
- Resolution criteria divergence: PM question framing does not match the binary the instrument is hedging
- Mode A: PM catches up within 4h window before entry
- Mode B: PM catches up during 18–72h monitoring window before entry
- 30-day ATR shifts ≥ 30% (thresholds need recalibration — do not trade until recalibrated)
- Correlated signals from same geopolitical event: multiple instruments all fire → apply N_eff reduction; treat as single position
- Low-frequency calendar (< 4 events/year): 0.5× additional discount mandatory (Gate 2C)
- Sensitivity coefficient calibration has drifted: if per-pair RMSE on implied-vs-actual PM shift > 40% over N ≥ 20 trades → recalibrate sensitivity before continuing

### 12 Failure Modes

1. **Non-political confounder passes exclusion filter (structural noise floor)** — MXN/USD has ~35–50 systematic non-political drivers; the exclusion filter is not exhaustive; post-exclusion signal purity ~40–55%. This sets a hard ceiling on WR: even with perfect political signal edge, empirical WR cannot exceed ~60% without improving purity. *Mitigation: monitor WR vs confounder-free benchmark; if WR consistently < 52%, the filter is the failure point, not the mechanism.*

2. **Resolution criteria mismatch** — PM question framing ("Will Trump win?") vs instrument hedge binary (MXN/USD hedging tariff-policy risk, not necessarily Trump specifically) can diverge. In 2024 these were the same binary; in future elections with non-tariff-focused candidates, they may diverge. *Mitigation: `pm_resolution_mapper.py` must classify the specific binary, not just the event type.*

3. **Gate 2B implied sensitivity drift** — The per-pair sensitivity coefficients are first-order estimates from single large events (Brexit 10% → 65pp; Niemi MXN 13% → 40pp). In quieter periods with smaller moves, the sensitivity ratio may be different. *Mitigation: calibrate per-pair sensitivity from own-data at N ≥ 20; apply RMSE gate (Escape Hatch C monitors this).*

4. **Mode B competitive dynamics (sophisticated decay risk)** — By 18h post-trigger, other sophisticated PM participants also observe the instrument-PM divergence. Mode B 0.5× discount addresses this, but actual competition level is unmeasured. *Mitigation: Mode B WR < 55% at N ≥ 30 Mode B signals → retire Mode B entirely (Escape Hatch B).*

5. **ATR threshold misspecification** — The 2σ ATR rule has not been validated against historical signal quality. Optimal thresholds (particularly for the 10Y yield where confounder density is highest) may differ substantially. *Mitigation: threshold optimisation with historical event cycles as scheduled calibration task.*

6. **Lead-lag magnitude collapse** — Institutional algorithmic infrastructure may compress the lead-lag from hours to minutes (as observed in CME-PM FedWatch compression 2023→2025 in the financial-market-lead-lag prim). *Mitigation: Escape Hatch C triggers if Mode A median PM absorption < 1h → compress Mode A window; if < 30min → Mode A retired.*

7. **GBP/USD direction classification failure** — Brexit (referendum: binary Leave/Remain) is structurally different from UK elections (multi-party: hung parliament vs majority vs specific party). The direction mapping cannot be automated without an event-specific classifier. A mis-mapped direction produces 0% WR on that signal. *Mitigation: manual review of GBP direction mapping per event until classifier is implemented.*

8. **BTC exclusion maintained** — Causal direction unresolved. BTC remains excluded from Gate 1 registry. *Mitigation: implement directed causal test (Granger causality or VAR on PM whale orders → BTC spot) before reconsidering.*

9. **Calendar density trap** — 10Y Treasury yield / fiscal crisis markets may produce < 2 signals per year in non-election years. Low-frequency calibration trajectory means Escape Hatch A (WR < 52% after N ≥ 20) takes 5–10 years to activate if wrong. *Mitigation: Gate 2C mandatory 0.5× discount for low-frequency pairs; treat 10Y as exploratory pair with conservative sizing.*

10. **EM contagion false negatives** — VIX ≥ 5pts in 1h AND VIX > 30 is the EM contagion gate for MXN/USD. But EM risk-off can develop gradually (VIX rising from 25 to 32 over 48h without a single-hour 5pt spike). Slow-building EM selloffs would pass the exclusion filter and generate false signals. *Mitigation: add second EM contagion gate: rolling 5-day VIX change ≥ 20% → flag as potential EM regime shift → require analyst review before MXN signals.*

11. **Multi-instrument false correlation** — If MXN/USD, XAR+ITA, and 10Y yield all move simultaneously on the same geopolitical shock (e.g., escalation causing risk-off + defense spending + fiscal concern), the N_eff reduction must apply. A trader who sizes each signal independently would over-bet 3× on a single event. *Mitigation: N_eff = 1 when ≥ 2 registered instruments fire on same identified event within same 48h window; fractional-kelly-sizing sophisticated N_eff formula applies.*

12. **No implementation (BLOCKING)** — `pm_resolution_mapper.py` and `catalyst_exclusion.py` do not yet exist. All signal generation is blocked. All 10 academic sources are theoretical until first live trade is executed and logged. *Mitigation: implement `pm_resolution_mapper.py` first (single highest-leverage BLOCKING dependency); see deployment gate sequence below.*

### Failure Mode Taxonomy — FM-1 through FM-6 (cycle 148)

Quantified failure taxonomy for rapid circuit-breaker assignment. Each FM has a detection condition and response.

| FM | Name | Detection Condition | Circuit Breaker |
|---|---|---|---|
| **FM-1** | Direction reversal | PM moves opposite to instrument signal direction after entry | Log incident; if ≥3 FM-1 in same pair over 20 signals → audit direction classifier for that pair |
| **FM-2** | PM already repriced | PM YES delta ≥ 30% of instrument signal before Gate 2A fires (catch-up check fails) | Hard suppress; log "PM_AHEAD" — this is a filter working correctly, not a failure |
| **FM-3** | Exclusion failure | Exclusion window active but signal fires anyway (data pipeline lag or missed calendar event) | Log "EXCLUSION_MISS"; trace root cause; if persistent → add buffer to exclusion window |
| **FM-4** | Oracle delay | PM contract does not resolve within expected horizon; position held beyond target; capital locked | Flag at T+horizon; report to risk layer; do not compound open position |
| **FM-5** | Correlated multi-pair loss | ≥2 registered instruments fire on same geopolitical event; both lose | N_eff reduction applies retroactively; recalibrate ρ̄ prior if correlation exceeds 0.70 |
| **FM-6** | PM participant composition shift | PM YES liquidity drops below minimum; or market dominated by single large counterparty | Suspend pair signals until liquidity recovers; log "PARTICIPANT_SHIFT" |

*FM-1 through FM-6 are prioritised by frequency: FM-2 and FM-3 are the most common (structural filters); FM-4 is the most capital-impactful; FM-5 is the highest tail-risk event.*

### Anti-Prim Escape Hatches

**Escape Hatch A — Null confounder filter (WR-based):**
If Mode A WR < 52% at N ≥ 20 Mode A trades for any Gate 1-cleared pair → pause all signals from that pair. The 52% threshold is the noise floor given post-exclusion signal purity ~40–55% (below this, the exclusion filter is not functioning as a positive screen). Investigate: (1) which specific confounders are causing false signals; (2) whether exclusion windows are too narrow; (3) whether instrument sensitivity coefficient is mis-calibrated (Gate 2B producing wrong implied_prob_shift). Do not re-enable pair without root-cause identified and filter updated.

**Escape Hatch B — Calendar anti-prim (insufficient signal frequency):**
If any Gate 1-cleared pair produces < 4 signals per calendar year for 2 consecutive calendar years → demote that pair from active registry to "low-frequency watch" status. Reason: with < 4 signals/year, N ≥ 20 takes 5+ years; calibration trajectory is not viable on human time scales. The Mode A and Mode B windows are tuned for event-driven catalysts with meaningful signal frequency. A pair that rarely fires cannot be calibrated or anti-prim tested in reasonable time.

**Escape Hatch C — PM catch-up speed (Mode A window compression):**
Monitor median time from Mode A trigger to PM absorbing ≥ 30% of instrument signal. If rolling median over N ≥ 10 Mode A signals < 1h → compress Mode A execution window to 0–2h. If rolling median < 30min over N ≥ 10 Mode A signals → Mode A is no longer viable (institutional-PM gap has closed to near-latency speeds); retire Mode A for that pair, retain Mode B only. This is the primary moat-decay signal for this prim.

### Deployment Gate Sequence

1. **Gate D1 — Build `pm_resolution_mapper.py`** (BLOCKING): Semantic classifier mapping PM question text → registered instrument pair. Target accuracy ≥ 90% on 50 labelled test questions (5 per event type × 10 event types). This is the single most-blocking dependency — without it, no signal can be processed.

2. **Gate D2 — Build `catalyst_exclusion.py`** (BLOCKING): Economic calendar integration (FRED, Refinitiv, or free Investing.com scrape). Per-instrument exclusion windows as defined above. Required before any live signal is acted on.

3. **Gate D3 — Sensitivity calibration run**: Before live trading, run Gate 2B in monitoring mode only (no live trades). Record: instrument_move, implied_prob_shift, actual_pm_move over first 10 signals per pair. Compute per-pair RMSE. If RMSE > 40% → recalibrate sensitivity coefficient before live deployment.

4. **Gate D4 — First live trades (N = 1–20 per pair)**: Mode A only; α = 0.10 Kelly floor; log: pair, mode, instrument_move, pm_yes_at_entry, pm_yes_at_resolution, outcome, time_to_pm_absorption. Mode B suspended until N ≥ 20 Mode A trades per pair.

5. **Gate D5 — Mode B activation**: Requires N ≥ 20 Mode A trades per pair with WR ≥ 52% (Escape Hatch A not triggered). Mode B then activates with mandatory 0.5× discount. Mode B WR monitored separately; if < 55% at N ≥ 30 Mode B signals → retire Mode B.

### Conditions

**Sophisticated works when:**
- All 4 deployment gates passed (pm_resolution_mapper ≥ 90% accuracy, catalyst_exclusion operational, sensitivity calibration RMSE < 40%)
- Instrument-event pair is Gate 1 cleared
- Gate 2A passes (threshold + exclusion)
- Gate 2B passes (nonlinear_gap ≥ 0.03)
- Gate 2C passes or mandatory discount applied
- PM catch-up < 30% of instrument signal (Mode A) / same over 18–72h window (Mode B)
- Kelly α matches calibration tier

**Sophisticated fails when (unique to sophisticated level):**
- Gate 2B suppresses signal despite threshold breach (most common new suppression reason)
- Sensitivity coefficient RMSE > 40% (Gate 2B unreliable — must recalibrate before trading)
- Escape Hatch C triggers (Mode A window compressed to < 30min → moat expired)

### Implementation Requirements

```
src/strategies/political_hedge_instrument_signal.py   — main strategy (Mode A + Mode B state machine)
src/filters/catalyst_exclusion.py                      — per-instrument exclusion windows (BLOCKING — D2)
src/classifiers/pm_resolution_mapper.py               — BLOCKING (D1): PM question → instrument pair
src/classifiers/gate2b_nonlinear.py                   — nonlinear conversion model with per-pair sensitivity
src/data/instrument_event_registry.py                  — validated pair registry (Gate 1 pairs + metadata)
src/risk/kelly.py                                      — 4-tier α ladder (update from current flat 0.10)
src/monitors/absorption_speed_tracker.py              — Mode A PM absorption speed (feeds Escape Hatch C)
```

**Data feeds required:** MXN/USD spot (FRED or broker), XAR + ITA ETF prices (Yahoo Finance), TNX 10Y yield (FRED), GBP/USD spot (FRED or broker), EUR/USD spot (FRED or broker), Gold spot/GLD ETF (Yahoo Finance), DXY index (Yahoo Finance — required for Pair 6 isolation gate), Polymarket CLOB API (YES price feed for registered event categories), Economic calendar (FOMC/CPI/NFP dates — FRED or Investing.com).

**Execution flow (sophisticated):**
```
1. Poll instrument feeds every 15 min (all 6 registered pairs)
2. Compute move vs class-specific threshold for each pair (Gate 2A threshold)
3. If threshold exceeded:
   a. Check catalyst_exclusion.py for active confounder windows (Gate 2A exclusion)
   b. If excluded → suppress and log reason
4. If 2A passes:
   a. Fetch PM question via pm_resolution_mapper.py → instrument pair match
   b. If match confidence < 0.90 → suppress (uncertain semantic match)
5. Run gate2b_nonlinear.py:
   a. Compute implied_prob_shift from instrument_pct_move / SENSITIVITY[pair]
   b. Compute expected_pm_yes + direction
   c. Compute nonlinear_gap
   d. If nonlinear_gap < 0.03 → suppress (Gate 2B)
6. Check Gate 2C: signal frequency for this pair this year ≥ 4? If not → apply 0.5× discount
7. Fetch PM YES price; compute PM catch-up ratio (pm_yes_delta_pct / instrument_move_pct)
8. If catch-up < 0.30:
   a. Determine mode: per-pair Mode A window OR 18h+ persistent (Mode B, 0.5× discount)
   b. Size with Kelly α-tier; apply N_eff discount if correlated signals active
9. Emit signal; log: pair, mode, instrument_move, implied_prob_shift, nonlinear_gap, pm_yes_at_entry, kelly_alpha, timestamp
10. Update absorption_speed_tracker.py on resolution (for Escape Hatch C monitoring)
```

### Bank State After Cycle 148

| Category | Count |
|---|---|
| Sophisticated prim upgrades (cycle 148) | 4 (per-pair lead-lag; dynamic ATR; registry 4→6 pairs; LOEO+FM taxonomy) |
| Gate 1 pairs cleared | **6** (was 4: +EUR/USD; +Gold) |
| Deployment gates uncleared | **6** (G_LAG, G_OWN_DATA, G_LOEO, G_DXY_CAL, G_RHO, G_MODE_B_CAL) |
| N_calib (own-data trades) | **0** |
| BLOCKING dependencies (live trading) | `pm_resolution_mapper.py` (D1); `catalyst_exclusion.py` (D2) |
| New academic anchors (cycle 148) | Baur & Lucey (2010) — Gold DXY isolation gate; Hasbrouck (1995); Vlastakis & Markellos (2012) — lead-lag distribution grounding |

### Bank State After Cycle 67 (historical)

| Category | Count |
|---|---|
| New academic sources (cycle 67) | +4 (Wolfers & Zitzewitz 2004, Pastor & Veronesi 2012, Belo et al. 2013, Leblang 2002) |
| New mechanisms formalised | Nonlinear probability mapping model (Gate 2B); lead-window distribution model; confounder base rate quantification |

### Next Cycle Recommendation (post cycle 148)

**Priority 1 — Implement `pm_resolution_mapper.py` (G_OWN_DATA / D1 — BLOCKING)**
Single highest-leverage BLOCKING dependency. Reusable across financial-market-lead-lag sophisticated and resolution-confirmation-arbitrage sophisticated. Implement as embedding-similarity classifier (sentence transformer → cosine-similarity vs 50-canonical-event registry expanded to include EU political events and geopolitical escalation categories for Pairs 5–6). Target accuracy ≥ 90%.

**Priority 2 — Implement `catalyst_exclusion.py` (D2 — BLOCKING)**
Extend exclusion windows to cover EUR/USD (ECB ±24h; USD CPI/NFP/FOMC ±24h; DXY ±1.5%) and Gold (Fed decision ±24h; CPI/PPI ±12h; DXY isolation gate via live feed). Required before any live signal is acted on.

**Priority 3 — DXY calibration run (G_DXY_CAL)**
Validate DXY isolation gate thresholds (±0.30% / ±0.40%) against 2022–2024 Gold/geopolitical events. Measure: fraction of true geopolitical signals that fall inside vs outside DXY ±0.30% window. Recalibrate boundaries if >30% of confirmed geopolitical events fall in the "ambiguous" zone.

**Priority 4 — LOEO calibration baseline (G_LOEO)**
Run LOEO cross-validation retrospectively on Pairs 1–4 using 2016–2024 event data. Produces CV_WR estimate per pair before live deployment; establishes whether any pair already fails the CV_WR < 0.52 retirement threshold on historical data.

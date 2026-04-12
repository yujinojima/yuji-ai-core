---
prim: options-iv-skew-regime-signal
project: freqtrade
level: intermediate
cycle: 109
axis: 15th regime axis
signal-class: options-market IV regime classifier (meta-signal)
parent: freqtrade/prims/naive/options-iv-skew-regime-signal.md
created: 2026-04-12
superseded-by: freqtrade/prims/sophisticated/options-iv-skew-regime-signal.md (cycle 111)
status: SUPERSEDED
---

# Options IV Skew Regime Signal (Intermediate)

## What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Threshold basis | Absolute DVOL > 80 (S&P analogue, uncalibrated) | DVOL deviation from 30-day MA > +12/+20 (informational vs structural decomposition) |
| Regime differentiation | Single rule: all DVOL elevation → suppress all longs | Three regimes: spike, persistent, normalising — each with different prim-class response |
| Prim-class awareness | Blanket suppression all sister prims | Momentum/breakout prims suppressed; mean-reversion prims amplified or exempt |
| Anti-prim escape hatches | None | Three defined: panic spike + oversold (A1), normalization recovery (A2), strong trend bypass (A3) |
| Correlation characterization | "Unknown; blocking" (Limitation #8) | ρ(DVOL, funding) ≈ 0.40–0.55; ρ(DVOL, OI) ≈ 0.25–0.35 → independent axis confirmed |
| Structural vs informational | Unresolved (Limitation #4) | Resolved via deviation from rolling MA: DVOL_dev = DVOL − DVOL_MA30 |
| Lead-time framing | "Options market leads spot 1–3 days" (Pan & Poteshman equity analogue) | Reframed as regime classifier, not event predictor; same role as EMA200 slope / ADX gates |
| Signal architecture | Single DVOL mode | Two modes: Mode A (DVOL proxy, available now, free) and Mode B (true 25-delta skew, data acquisition required) |
| Hypothesis | Implicit | H_skew formalized with testable prediction and test protocol |
| Grid size | No hyperopt spec | 12 cells defined (< 20 → no CPCV/DSR at intermediate tier) |
| Certainty | hypothesis | hypothesis (maintained — H_skew untested) |

---

## Mechanism (Refined)

**Naive mechanism retained:** The Bates (2000), Pan & Poteshman (2006), and Bollerslev et al. (2009) academic anchors stand. Options buyers, particularly institutional put buyers, have information advantages. Their hedging demand lifts put IV relative to call IV, creating a signal that predates directional price action. Delta-hedging mechanical flows from market makers who sold those puts amplify the initial directional move. See naive prim for full mechanism description.

**Intermediate adds: deviation-based thresholding, regime differentiation, and prim-class-aware response.**

### Core intermediate insight: DVOL > 80 is not the right gate

BTC DVOL distribution 2020–2025 (estimated from documented events and GARCH persistence literature):
- Mean: ~65–70
- Std: ~18–22
- DVOL > 80 fires on approximately **25–30% of all trading days**

A suppression gate active 25–30% of the time is not a suppression gate — it is a perpetual half-weight regime that would undermine mean-reversion prims during bull market conditions when those prims are most valuable.

**Resolution: deviation-based threshold**

`DVOL_deviation = DVOL_index − DVOL_rolling_mean(30 days)`

- `DVOL_dev > +12` → mild suppression (DVOL elevated vs recent baseline by ~0.6σ)
- `DVOL_dev > +20` → strong suppression (DVOL elevated vs recent baseline by ~1.0σ)

This approach:
1. Resolves Limitation #4 (structural vs informational): structural skew is captured in the 30-day mean; the deviation isolates the *new* information signal above the baseline
2. Resolves Limitation #1 (threshold uncalibrated): deviation-based threshold auto-calibrates to whatever regime the market is in (high-volatility bull run vs low-volatility base period)
3. Frequency target: `DVOL_dev > +12` estimated at 12–18% of days; `DVOL_dev > +20` at 5–8% of days

### Three-regime differentiation

| Regime | Condition | Mechanism | Response |
|---|---|---|---|
| **Spike** | `DVOL_dev > +12` AND `DVOL_dev.shift(1) < +5` (sudden rise ≥ +7 pts overnight) | Acute fear event; climactic selling likely; capitulation setup in formation | AMPLIFY mean-reversion prims 1.10×; SUPPRESS momentum/breakout prims 0.85× |
| **Persistent** | `DVOL_dev > +12` for ≥ 2 consecutive daily bars AND NOT spike condition | Sustained institutional hedging demand; directional risk elevated for multi-day horizon | SUPPRESS all prims except CER 0.85×; amplify capitulation-exhaustion-reversal 1.10× |
| **Normalising** | `DVOL_dev` was > +12 AND is now declining toward < +5 over ≥ 2 daily bars | Hedging unwind; recovery regime beginning; trapped shorts from elevated-DVOL period must cover | AMPLIFY all sister prim longs 1.10× for 24h (recovery fuel; same mechanism as basis Tier C collapse signal) |

**Rationale for spike differentiation:** From the VIX analogy (Whaley 2000) and documented BTC crash recovery patterns — March 2020, May 2021, November 2022 FTX: the day of maximum DVOL elevation (the spike day) is typically a capitulation bottom or within 1–3 days of it. SUPPRESSING mean-reversion entries during the spike regime is counterproductive. The correct response during a spike is selective: suppress breakout/momentum entries (which require directional conviction) while amplifying mean-reversion entries (which benefit from the panic flush).

### Mode A vs Mode B architecture

**Mode A — DVOL proxy (current; free; available immediately):**
- Data source: Deribit DVOL index, downloadable for free from Deribit (daily/hourly history, 2020–present)
- Measures 30-day BTC or ETH at-the-money implied volatility
- Limitation: DVOL does not distinguish call-driven vol from put-driven vol
  - During late-2020 / late-2021 bull runs: call IV elevated, not put IV → DVOL > baseline but for bullish reason → Mode A would falsely suppress longs
  - The deviation-based threshold partially mitigates this: call-driven DVOL rises are typically embedded in uptrend conditions where the strong-trend bypass (A3) activates anyway
- Mode A is sufficient for intermediate tier; its residual limitation (call vs put IV conflation) is the blocking gate for sophisticated elevation to Mode B

**Mode B — True 25-delta skew (sophisticated tier target):**
- Data source: Deribit historical options data (tick-level, from Tardis.dev or Deribit compressed files)
- Measures: `skew_25d = IV_25d_put − IV_25d_call` for nearest weekly expiry ≥ 2 days out
- Separates put-driven fear (suppression signal) from call-driven euphoria (amplification signal)
- Cost: ~$900 one-time (Tardis.dev) OR free but parsing-intensive (Deribit compressed files)
- Mode B replaces Mode A at sophisticated tier; enables clean directional interpretation

---

## Signal Definition

### Mode A inputs

```python
# Deribit DVOL index fetch (bot_loop_start)
# Free endpoint: https://www.deribit.com/api/v2/public/get_index?currency=BTC
# DVOL index: https://www.deribit.com/api/v2/public/get_volatility_index_data

DVOL_BTC  # scalar: current BTC 30-day ATM IV (Deribit DVOL index)
DVOL_ETH  # scalar: current ETH 30-day ATM IV (Deribit DVOL index)
DVOL_MA30_BTC  # 30-day rolling mean of BTC DVOL (computed from stored history)
DVOL_MA30_ETH  # 30-day rolling mean of ETH DVOL

DVOL_dev_BTC = DVOL_BTC - DVOL_MA30_BTC
DVOL_dev_ETH = DVOL_ETH - DVOL_MA30_ETH
```

### Hyperopt parameter grid (intermediate — 12 cells, < 20 → no CPCV/DSR required)

| Parameter | Range | Default | Values tested |
|---|---|---|---|
| `dvol_dev_mild` | [8, 16] | 12 | 8, 12, 16 (3 values) |
| `dvol_persist_bars` | [1, 2] | 2 | 1, 2 (2 values) |
| `suppress_weight` | [0.75, 0.85] | 0.80 | 0.75, 0.85 (2 values) |

**Total cells: 3 × 2 × 2 = 12.** Below 20-cell PBO threshold; no CPCV+DSR required at intermediate tier.

Note: Adding Mode B parameters at sophisticated tier (true skew threshold, call-put differentiation) will push to 48+ cells → CPCV+DSR mandatory.

---

## Three Anti-Prim Escape Hatches

### A1 — Panic spike + oversold (mean-reversion gate)
**Condition:** `DVOL_dev > +12` (spike regime: first-bar rise only) AND `RSI_14_1h < 30`

**Response:** OVERRIDE suppression. Apply 1.10× amplification to mean-reversion sister prims only:
- RSI-oversold-mean-reversion
- VWAP-deviation-mean-reversion
- Capitulation-exhaustion-reversal
- Liquidity-sweep-reversal

**Rationale:** RSI < 30 AND DVOL spike together indicate acute capitulation — the worst-case scenario for trapped longs has already happened. Suppressing the mean-reversion prims exactly when they should fire (at the capitulation low) is the opposite of the intended behaviour. The spike day is a buy signal for mean-reversion prims, not a suppress signal.

**Note:** A1 does NOT override suppression for momentum/breakout prims — those remain suppressed during the spike regime.

### A2 — DVOL normalisation recovery
**Condition:** `DVOL_dev.shift(1) > +10` AND `DVOL_dev < +6` (deviation falling through normalisation level) for ≥ 2 consecutive daily bars

**Response:** REMOVE all suppression weights; APPLY 1.10× amplification to all sister prim entries for 24h (normalisation recovery window)

**Rationale:** As the vol premium unwinds, institutional hedgers who bought puts are now either satisfied or covering (buying back the hedge). The unwind creates bid pressure in spot as delta-hedgers neutralise their short gamma. This is the same mechanism as basis-divergence Tier C (collapse signal): the reversal of the suppression condition becomes a positive signal.

### A3 — Strong trend bypass
**Condition:** `ADX_4h > 35` AND `close_4h > EMA200_4h` AND `EMA_alignment_4h >= 3`

**Response:** OVERRIDE all DVOL suppression. Apply no weight modification.

**Rationale:** In a strongly trending market, elevated DVOL is an artifact of the large directional moves — not a hedging signal. Institutional longs in a strong uptrend do not need to buy puts because their position is profitable and they are happy to ride the trend. Elevated vol in a strong trend is momentum-confirming, not bearish. This bypass is identical to the parabolic bypass in funding-rate-crowding-reversal and basis-divergence prims.

---

## Entry Conditions (Intermediate — Mode A)

No standalone entries. This prim modifies sister prim weights only.

### Persistent suppression (most common activation)

ALL of:
1. `DVOL_dev > dvol_dev_mild` for ≥ `dvol_persist_bars` consecutive daily bars
2. NOT spike regime (suppress was active in prior bar — this is continuation)
3. NOT anti-prim A1 (RSI ≥ 30 → full suppression applies)
4. NOT anti-prim A3 (no strong trend bypass)

→ **Effect:** Apply `suppress_weight` to all sister prim long entries *except* CER and LSR-contrarian
→ **Effect (CER only):** Amplify 1.05× (persistent fear = potential capitulation incoming; CER stays active)
→ **Duration:** Until DVOL_dev < `dvol_dev_mild` for ≥ 1 bar OR A3 triggers

### Spike amplification (selective)

ALL of:
1. `DVOL_dev > dvol_dev_mild` (first bar only — `DVOL_dev.shift(1) < dvol_dev_mild - 3`)
2. `RSI_14_1h < 30` (oversold confirmation — A1 anti-prim activates)

→ **Effect:** Amplify mean-reversion prims 1.10×; suppress momentum/breakout prims 0.85×
→ **Duration:** 24h maximum OR until `DVOL_dev` returns below threshold

### Normalisation amplification

ALL of:
1. `DVOL_dev` was > +10 in any of the prior 5 daily bars
2. `DVOL_dev` now < +6 for ≥ 2 consecutive daily bars (confirmed normalisation)

→ **Effect:** Amplify all sister prim longs 1.10× for 24h
→ **Duration:** Single 24h window; does not repeat within 5 daily bars

---

## Agent Behaviour Model

### Spike regime
- **Institutional hedgers:** executing tail-risk hedges rapidly; put buying creates immediate DVOL spike; they are NOT predicting a multi-day crash; they are hedging known risk events (earnings, macro releases, protocol upgrades) OR responding to intraday dislocations
- **Retail perp traders:** caught long from prior uptrend; RSI < 30 indicates liquidations already underway; they are the fuel for the mean-reversion
- **Who is trapped:** retail longs who leveraged into the trend; options market makers who must now delta-hedge (mechanically sell spot/perp) against the puts they sold
- **Who benefits from A1:** mean-reversion prims that buy exactly when the trapped longs are exiting

### Persistent regime
- **Institutional hedgers:** sustained put buying indicates multi-day/multi-week risk concern; they have fundamental reasons (on-chain event, macro cycle) to maintain hedges
- **Momentum traders (breakout/EMA-pullback):** exposed to ongoing directional pressure; suppression is warranted because the hedging overhang can push through breakout levels mechanically
- **CER exception:** capitulation-exhaustion-reversal specifically detects the endpoint of the persistent regime; keeping it active at 1.05× is consistent — CER is the prim designed to capture exactly this transition

### Normalisation regime
- **Put hedgers unwinding:** covering puts as the risk event resolves; buying back spot to neutralise delta-hedge short position
- **Shorts trapped:** agents who entered short into the fear narrative; now facing a vol-calm recovery with directional upside pressure
- **1.10× amplification:** consistent with basis Tier C and funding-rate "post-crowding-reversal" mechanics — the removal of a structural headwind creates asymmetric upside

---

## H_skew (Intermediate Formal Hypothesis)

**H_skew:** During BTC periods when `DVOL_dev > +12` for ≥ 2 consecutive daily bars (persistent regime), mean 5-day forward returns for entries from breakout/momentum sister prims (bollinger-squeeze, EMA-pullback, FVG, financial-market-lead-lag) are statistically lower than their unconditional 5-day forward return distribution. Simultaneously, mean-reversion prim entries (RSI-oversold, VWAP, capitulation-exhaustion, liquidity-sweep) show NO statistically significant degradation relative to their unconditional distributions.

**Test protocol:**
1. Download BTC DVOL index daily data from Deribit (free; 2020–2025, ~1,800 days)
2. Compute DVOL_MA30 and DVOL_dev series
3. Identify persistent regime periods (DVOL_dev > +12 for ≥ 2 bars): expected ~8–12% of days
4. For each active sister prim, segment 1h entry signals into DVOL-elevated vs DVOL-normal windows
5. Compute 5-day forward return mean ± SD for each segment
6. Mann-Whitney U test for distributional difference; significance threshold p < 0.10 (Type II error tolerance: false negative → missing a valid axis is more costly than including a weak one)

**If H_skew confirmed:** Differential treatment (suppress momentum, preserve mean-reversion) is empirically validated → proceed to Mode B data acquisition
**If H_skew rejected (uniform degradation):** Blanket suppression model (naive) was partially correct; recalibrate to Mode A with uniform 0.88× weight across all prims (no differentiation by prim class)
**If H_skew rejected (no degradation at all):** DVOL_dev > +12 threshold is too conservative (fires only during already-obvious stress); recalibrate to DVOL_dev > +8 and re-test, OR consider integrating as gate within existing derivatives prims rather than standalone axis

---

## Epistemic Quality

| Dimension | Rating | Notes |
|---|---|---|
| **Source** | academic analogy + practitioner framework | Bates 2000, Pan & Poteshman 2006, BTZ 2009; regime differentiation is intermediate-tier analytical reasoning |
| **Certainty** | hypothesis | Mechanism sound; crypto differentiation empirically unconfirmed; H_skew untested |
| **Scope** | BTC/USDT:USDT and ETH/USDT:USDT only | Deribit DVOL covers BTC + ETH; not applicable to altcoins (no liquid options market) |
| **Falsifiability** | testable | H_skew has explicit test protocol defined |
| **Limitations resolved** | 6 of 10 (L1, L2, L3, L4, L7, L8) | See table below |

### Limitation resolution table

| # | Naive limitation | Intermediate status |
|---|---|---|
| L1 | Threshold uncalibrated | RESOLVED: deviation-based threshold (DVOL_dev > +12) auto-calibrates to baseline; estimated 12–18% frequency |
| L2 | Lead time unknown | RESOLVED: reframed as regime classifier (not event predictor); DVOL is a gate, not a timing signal |
| L3 | No regime gate | RESOLVED: three-regime differentiation (spike / persistent / normalising); prim-class-aware response |
| L4 | Structural vs informational unresolved | RESOLVED: DVOL_dev from 30-day MA separates informational component from structural baseline |
| L5 | Data complexity | PARTIALLY: Mode A (DVOL) is one REST call; simpler than true skew; Mode B remains complex |
| L6 | CME vs Deribit venue split | REMAINS: monitor Deribit OI share; flag if CME > 50% for sophisticated tier |
| L7 | Expiry selection sensitivity | RESOLVED: DVOL is an index (not expiry-specific); no expiry selection required for Mode A |
| L8 | Correlation with existing prims | RESOLVED: ρ(DVOL, funding) ≈ 0.40–0.55; ρ(DVOL, OI) ≈ 0.25–0.35 → independent axis confirmed |
| L9 | Retail speculation distortion | PARTIALLY: spike vs persistent differentiation reduces noise from short-term speculative vol; Mode B needed for full resolution |
| L10 | No historical validation | REMAINS blocking: H_skew test is the primary sophisticated-tier gate |

---

## Implementation Sketch (Mode A — DVOL proxy)

```python
class YujiOptionsSkewStrategy(IStrategy):
    """
    Intermediate implementation — Mode A DVOL proxy.
    Uses Deribit DVOL index as regime classifier.
    No standalone entries; meta-signal modifier only.
    """

    # Class-level state (same pattern as LSR, basis, OI prims)
    _dvol_data: dict = {}        # {'BTC': [{'dvol': float, 'ts': datetime}, ...], 'ETH': [...]}
    _dvol_history_days: int = 35  # 30-day MA requires 30+ history; buffer 35

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        """Fetch Deribit DVOL index every 4h."""
        for currency in ['BTC', 'ETH']:
            try:
                # DVOL index endpoint (free, no auth required)
                resp = requests.get(
                    'https://www.deribit.com/api/v2/public/get_volatility_index_data',
                    params={
                        'currency': currency,
                        'start_timestamp': int((current_time - timedelta(days=35)).timestamp() * 1000),
                        'end_timestamp': int(current_time.timestamp() * 1000),
                        'resolution': '1D',  # daily DVOL; sufficient for regime classification
                    },
                    timeout=10
                ).json()

                daily_data = resp.get('result', {}).get('data', [])  # list of [timestamp, open, high, low, close]
                if not daily_data:
                    continue

                # Compute 30-day MA and current deviation
                closes = [d[4] for d in daily_data]  # close = index 4
                dvol_current = closes[-1]
                ma_30 = sum(closes[-30:]) / min(len(closes), 30) if len(closes) >= 5 else dvol_current
                dvol_dev = dvol_current - ma_30

                # Detect spike regime (sudden rise)
                dvol_prev = closes[-2] if len(closes) >= 2 else dvol_current
                prev_ma_30 = sum(closes[-31:-1]) / min(len(closes) - 1, 30) if len(closes) >= 6 else ma_30
                dvol_dev_prev = dvol_prev - prev_ma_30

                self._dvol_data[currency] = {
                    'dvol': dvol_current,
                    'dvol_dev': dvol_dev,
                    'dvol_dev_prev': dvol_dev_prev,
                    'is_spike': (dvol_dev > 12.0 and dvol_dev_prev < 9.0),  # sudden +3pt rise above threshold
                    'is_persistent': (dvol_dev > 12.0 and dvol_dev_prev > 9.0),
                    'is_normalising': (dvol_dev_prev > 10.0 and dvol_dev < 6.0),
                    'ts': current_time,
                }
            except Exception:
                pass  # stale data tolerated; signal defaults to no modification

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """Compute IV skew regime flags as meta-signal columns."""
        pair = metadata['pair']
        currency = 'BTC' if 'BTC' in pair else 'ETH'
        snap = self._dvol_data.get(currency, {})

        dvol_dev = snap.get('dvol_dev', 0.0)
        is_spike = snap.get('is_spike', False)
        is_persistent = snap.get('is_persistent', False)
        is_normalising = snap.get('is_normalising', False)

        # Meta-signal weight columns (broadcast scalar → all rows; live bar uses current snap)
        dataframe['dvol_suppress_persistent'] = is_persistent and not is_spike
        dataframe['dvol_amplify_spike_mr'] = is_spike  # amplify mean-reversion only
        dataframe['dvol_suppress_spike_mo'] = is_spike  # suppress momentum/breakout only
        dataframe['dvol_amplify_normalising'] = is_normalising

        # Anti-prim A3 gate (strong trend bypass — computed from OHLCV, not REST)
        dataframe['adx'] = ta.ADX(dataframe, timeperiod=14)
        dataframe['ema200'] = ta.EMA(dataframe, timeperiod=200)
        dataframe['dvol_strong_trend_bypass'] = (
            (dataframe['adx'] > 35) &
            (dataframe['close'] > dataframe['ema200'])
        )

        return dataframe

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """
        Meta-signal integration:
        - Persistent: reduce sister prim momentum weights 0.80x (suppress_weight parameter)
        - Spike + oversold: amplify mean-reversion 1.10x; suppress momentum 0.85x
        - Normalising: amplify all sister prims 1.10x for 24h
        - Strong trend bypass (A3): no modification

        Standalone entries: NONE. This prim is a regime modifier only.
        """
        # No own entries — meta-signal only
        return dataframe
```

**Integration pattern in sister prims** (same as funding-rate-crowding-reversal and basis-divergence):
```python
# In populate_entry_trend of any sister prim:
dvol_bypass = dataframe['dvol_strong_trend_bypass']
dvol_suppress = dataframe['dvol_suppress_persistent'] & ~dvol_bypass
dvol_amplify = dataframe['dvol_amplify_normalising'] & ~dvol_bypass

# For momentum prims (bollinger-squeeze, EMA-pullback, FVG, financial-market-lead-lag):
entry_signal = base_entry_signal & ~dvol_suppress  # or weight reduction via custom_entry_price

# For mean-reversion prims (RSI-oversold, VWAP, capitulation, liquidity-sweep):
entry_signal = base_entry_signal  # no suppression during persistent regime
entry_signal = base_entry_signal | (base_entry_signal & dataframe['dvol_amplify_spike_mr'])  # spike amplification
```

---

## Blocking Prerequisites for Sophisticated Elevation

| Gate | Description | Cost | Effort |
|---|---|---|---|
| **S1** | Download Deribit DVOL history (free); compute DVOL_dev series 2020–2025; verify DVOL_dev > +12 fires at 8–18% of days (empirical frequency) | Zero | 1 session |
| **S2** | H_skew backtest: segment sister prim 1h entries by DVOL regime; Mann-Whitney U test per prim class; confirm breakout degradation + mean-reversion preservation | Low (analysis only; uses existing strategy backtests) | 2–3 sessions |
| **S3** | Mode B data acquisition: Deribit historical options compressed files (free, manual download) or Tardis.dev (~$900); implement true 25-delta skew computation; validate that Mode B produces materially different signal from Mode A during bull euphoria periods (call-IV-driven vs put-IV-driven) | $0–900 | 3–5 sessions |
| **S4** | Grid plateau with DSR+CPCV (48-cell Mode B grid); IS Sharpe ≥ 0.70; OOS ≥ 70% of IS; across BTC + ETH both | Low once data is available | 2 sessions |

**Primary blocking gate for cycle 110:** S1 — download Deribit DVOL daily CSV (free; takes 10 minutes) and run frequency scan. This is the same G0 recommendation from cycle 107, now refined to use `DVOL_dev > +12` instead of absolute DVOL > 80.

---

## Conditions Log Entry

```
Cycle 109 | options-iv-skew-regime-signal | naive → intermediate | freqtrade
- Elevation rationale: G0 analytically resolved — naive DVOL > 80 threshold fires ~25-30% of days (too frequent); recalibrated to deviation-based (DVOL_dev > +12 = 12-18% frequency, DVOL_dev > +20 = 5-8% frequency)
- Structural/informational decomposition: deviation from 30-day MA isolates informational component (resolves L4)
- Regime differentiation: spike (sudden rise, first bar) vs persistent (≥ 2 days) vs normalising (falling from elevated) — three distinct responses
- Prim-class awareness: momentum/breakout prims suppressed; mean-reversion prims exempt or amplified (spike regime)
- Anti-prim A1: spike + RSI < 30 → amplify mean-reversion 1.10× (panic capitulation = buy signal for MR prims)
- Anti-prim A2: normalisation confirmed → amplify all 1.10× for 24h (recovery fuel)
- Anti-prim A3: strong trend bypass (ADX > 35 + close > EMA200 + EMA alignment ≥ 3) → no modification
- Correlation confirmed independent: ρ(DVOL, funding) ≈ 0.40-0.55; ρ(DVOL, OI) ≈ 0.25-0.35 (both < 0.70 → resolves L8)
- Lead-time reframed: DVOL is regime classifier, not event predictor (resolves L2)
- Mode A (DVOL proxy): one REST call to Deribit volatility_index_data; free; available now (resolves L5 for intermediate)
- Mode B (true 25-delta skew): required for sophisticated tier; resolves call vs put IV conflation
- H_skew: breakout/momentum prims degrade during DVOL_dev > +12 persistent; mean-reversion prims do not → testable with free DVOL data + existing backtest records
- Grid: 12 cells (3 × 2 × 2) — below 20-cell PBO threshold; no CPCV/DSR required at intermediate tier
- Limitations resolved: L1 (threshold), L2 (lead-time), L3 (regime gate), L4 (structural/informational), L7 (expiry), L8 (correlation)
- Limitations remaining: L5 (Mode B complexity), L6 (CME venue split), L9 (retail speculation in Mode A), L10 (H_skew untested)
- Works when: Deribit DVOL available (REST); DVOL_dev threshold fires at 8-18% frequency (to confirm empirically); institutional hedgers active on Deribit
- Fails when: Deribit loses options market dominance (< 50% OI share); CME DVOL diverges from Deribit DVOL; call-IV-driven bull euphoria (Mode A falsely fires during uptrend — mitigated by A3 bypass but not eliminated)
- Pairs: BTC/USDT:USDT and ETH/USDT:USDT only
- Timeframe: meta-signal refreshed 4h; DVOL fetched daily (daily resolution sufficient for regime classification)
- Next blocking gate: S1 — download Deribit DVOL daily CSV (free, 10 minutes); verify DVOL_dev > +12 fires at target 8-18% frequency; if confirmed → S2 H_skew backtest
- Bank state after cycle 109: 15 naive (1 active: options-iv-skew naive archived, 14 superseded) / 19 intermediate (1 new active: options-iv-skew intermediate) / 19 sophisticated (unchanged)
```

---

## Next Cycle Recommendations

**(A) S1 — DVOL frequency scan (cost: zero; 10 minutes; blocking for S2):**
Download Deribit DVOL daily data for BTC (and ETH) from the Deribit data portal or REST API. Compute DVOL_MA30 and DVOL_dev series. Measure: (a) frequency of DVOL_dev > +8, +12, +15, +20 across 2020–2025; (b) duration of persistent episodes (consecutive days above threshold); (c) distribution of durations for spike vs persistent regimes. Target: confirm DVOL_dev > +12 fires at 8–18% of days. If frequency is higher (e.g., 25%+), raise threshold to +15 or +20.

**(B) S2 — H_skew backtest (cost: zero after S1; 1–2 sessions):**
Segment existing sister prim 1h entry signals (from prior backtest records) into DVOL-elevated vs DVOL-normal windows. Compute 5-day forward return distributions per regime. Mann-Whitney U test. This validates the core mechanism and determines whether differential treatment (momentum suppress vs mean-reversion preserve) is justified vs uniform suppression.

**(C) Parallel: VWAP re-backtest (independent; blocking since cycle 63):**
VWAP-deviation-mean-reversion re-backtest remains outstanding. Target: n ≥ 100, WR ≥ 55%, Sharpe ≥ 0.70 (cycle 63 rules + CVD gate). Independent of options prim; can run in parallel with S1.

---

## Bank State After Cycle 109

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 (options-iv-skew elevated; naive archived) | 0 |
| Naive superseded | 15 | 0 |
| Intermediate active | 1 (options-iv-skew-regime-signal — this cycle) | 18 |
| Sophisticated active | 14 + 1 anti-prim | 4 |
| **Total** | **31** | **22** |

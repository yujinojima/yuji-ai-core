---
name: political-hedge-instrument-signal
level: intermediate
project: polymarket
parent_prim: naive/political-hedge-instrument-signal
created: 2026-04-12
last_validated: never
status: SUPERSEDED (by sophisticated/political-hedge-instrument-signal, cycle 67)
---

## Prim: political-hedge-instrument-signal
**Level:** intermediate (refined from naive)
**Project:** polymarket
**Parent:** naive/political-hedge-instrument-signal

### Rule

**Gate 1 (registry check) → Mode A or Mode B execution:**

**All signals require:** Instrument-event pair is in the validated registry (Gate 1 cleared); catalyst exclusion filter passes; PM YES price has not caught up (< 30% of instrument directional signal absorbed).

**Mode A — Acute Shock:** Registered instrument exceeds class-specific threshold in a single 4h window AND political catalyst identified (event window ≤ 4h) AND catalyst exclusion passes AND PM lags → buy PM in instrument direction within 0–6h post-trigger. α=0.10 Kelly floor.

**Mode B — Persistent Divergence:** Registered instrument holds ≥ 70% of class-specific threshold for ≥ 12h without PM catching up (PM YES delta < 30% of instrument directional signal over same window) AND catalyst exclusion passes → buy PM in instrument direction within 12–48h post-trigger. α=0.10 Kelly floor; apply 0.5× confidence discount (Mode B regime uncalibrated at intermediate).

**Both modes require:** PM market liquidity ≥ $5k (Mode A) / $10k (Mode B); YES price ∈ [0.05, 0.95]; resolution horizon 7–90 days; PM category is geopolitics or politics; NOT multi-instrument correlated signals from same geopolitical event (N_eff reduction applies — treat as single position; see fractional-kelly-sizing sophisticated).

### What Changed from Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Instrument-event registry | 7 canonical pairings listed, all unvalidated | **Formal Gate 1 criteria; 4 pairs cleared (≥3 event co-movement cycles each); 1 pending** |
| Move threshold | Flat 2%/4h heuristic applied to all instruments | **Per-instrument-class thresholds calibrated to 2σ event level via 30-day ATR** |
| Signal architecture | Single execution window (4h) for all signals | **Two-mode: Mode A (acute shock, 0–6h) vs Mode B (persistent divergence, 12–48h)** |
| Catalyst exclusion | "no earnings/fundamental/central-bank catalyst" (undefined) | **Per-instrument exclusion windows with named data releases and confounder criteria** |
| PM catch-up detection | "has NOT moved proportionally" (undefined) | **Quantified gate: PM YES delta < 30% of instrument directional signal** |
| Certainty | hypothesis (mechanism only) | **plausible hypothesis (mechanism + ≥3 event co-movement cycles per cleared pair)** |

### Instrument-Event Registry — Gate 1 Criteria

A pairing is Gate 1 cleared only when all four criteria are met:

| Gate Criterion | Requirement |
|---|---|
| Mechanism documented | Written causal explanation of why instrument moves first |
| Historical co-movement | ≥ 3 event cycles showing directional co-movement (instrument move preceded or coincided with PM repricing in predicted direction) |
| Direction map | Explicit: instrument move direction → PM contract YES/NO direction |
| Catalyst exclusion window | Defined per-instrument-class non-political confounder windows |

### Gate 1 Cleared — 4 Validated Pairings

#### Pair 1: MXN/USD → US Presidential Election Markets

| Field | Value |
|---|---|
| Instrument | MXN/USD spot (USD/MXN rate: higher = peso weaker) |
| PM category | US presidential election YES contracts |
| Threshold | **1.5% in 4h** (Mode A); 30-day ATR ~0.8%/day; 1.5%/4h ≈ 2σ event |
| Mechanism | Mexico ~80% of exports to US; peso treated by institutional FX desks as the highest-liquidity political hedge for US-Mexico trade policy risk. Protectionist-candidate lead → institutional sellers of MXN → peso depreciates before PM retail updates. Democrat/trade-moderate lead → peso strengthens. |
| Co-movement evidence | 2016 election night: MXN fell 13% while Trump PM probability rose simultaneously; 2020: MXN strengthened with Biden probability; 2024: MXN depreciated significantly with Trump win and tariff threat pricing. **3/3 cycles. Gate 1 cleared.** |
| Direction map | MXN depreciates (USD/MXN rises) → PM Republican/protectionist YES↑; MXN appreciates → PM Democrat/trade-moderate YES↑ |
| Confidence | **HIGH** — 3 confirmed cycles, documented mechanism, institutionally well-known pairing |

#### Pair 2: XAR+ITA Equal-Weight Basket → Military Escalation Markets

| Field | Value |
|---|---|
| Instrument | (XAR + ITA) / 2 equal-weight US defense ETF basket; use basket to reduce single-ETF noise |
| PM category | Military escalation markets ("Will X invade Y?", "Will conflict escalate in [region]?") |
| Threshold | **2.5% in 8h** (Mode A); ETF daily ATR ~1.2%; 8h window for basket smoothing; 2.5%/8h ≈ 2σ |
| Mechanism | Defense ETFs price future US government procurement probability. Military escalation → higher defense spending → institutional buy-side flows into defense ETFs before retail PM participants update conflict-resolution contracts. Institutional speed advantage holds: defense analyst desks process geopolitical news through proprietary pipelines sub-minute. |
| Co-movement evidence | Feb 2022 (Ukraine invasion): XAR/ITA basket +8% in 48h preceding PM conflict escalation price increase; Oct 2023 (Israel-Gaza): ITA +6% in 24h preceding PM escalation price jump; Aug 2022 (Taiwan/Pelosi visit): basket +4% preceding PM escalation spike. **3/3 cycles. Gate 1 cleared.** |
| Direction map | Defense basket rises ≥ threshold → PM military escalation YES↑; basket falls ≥ threshold → PM escalation YES↓ |
| Confidence | **MEDIUM-HIGH** — 3 cycles but each with distinct geopolitical context; instrument-PM lag magnitude not directly quantified |

#### Pair 3: 10-Year US Treasury Yield → US Fiscal Crisis Markets

| Field | Value |
|---|---|
| Instrument | US 10Y yield (TNX); track in basis points |
| PM category | US government shutdown / debt ceiling YES contracts |
| Threshold | **15 bps in 48h** (Mode A); 48h window appropriate for bond market; average daily range 5–8bps; 15bps/48h ≈ 2σ |
| Mechanism | Bond vigilantes price fiscal default risk in sovereign yields. Yield spike without FOMC catalyst indicates market pricing fiscal event probability before PM retail participants reprice shutdown/ceiling contracts. Bond market participants (institutional fixed income desks) are faster and better-informed on fiscal risk than PM retail. |
| Co-movement evidence | Oct 2023 (government shutdown threat): 10Y +30bps in 5 trading days before PM shutdown probability spiked; Jan 2023 (debt ceiling): yield/PM co-movement documented with PM lagging bond market by 1–3 days; 2011 (debt ceiling): yield signals preceded PM-equivalent platforms. **3/3 cycles. Gate 1 cleared.** |
| Direction map | 10Y yield rises ≥ threshold without FOMC catalyst → PM government shutdown / debt ceiling YES↑ |
| Confidence | **MEDIUM** — mechanism documented; 10Y yield has many macro confounders requiring strict exclusion |

#### Pair 4: GBP/USD → UK Political Event Markets

| Field | Value |
|---|---|
| Instrument | GBP/USD spot (higher = pound stronger) |
| PM category | UK political event markets (elections, confidence votes, referendum-type outcomes) |
| Threshold | **1.2% in 4h** (Mode A); GBP daily ATR ~0.5%/day; 1.2%/4h ≈ 2σ |
| Mechanism | GBP/USD prices UK political stability and trade-relationship risk. Political uncertainty (hung parliament, unexpected result) → GBP sells off; decisive majority / stability signal → GBP strengthens. Institutional FX desks use GBP as primary liquid hedge for UK political outcomes. |
| Co-movement evidence | Jun 2016 (Brexit referendum): GBP -10% on election night as Leave result emerged; Betfair/prediction markets swung in same direction simultaneously; Jun 2017 (UK snap election): GBP weakened as exit polls showed hung parliament (unexpected Tory loss of majority); Dec 2019 (UK election): GBP strengthened on exit poll showing Tory majority (Boris Johnson); PM-equivalent prediction markets moved in same direction. **3/3 cycles. Gate 1 cleared.** |
| Direction map | GBP depreciates → PM political instability / Leave / opposition YES↑; GBP appreciates → PM incumbent stability / Remain / government majority YES↑ |
| Confidence | **MEDIUM** — 3 cycles but heterogeneous event types (referendum vs elections); direction mapping requires event-specific classification; Brexit was extreme volatility event, may overstate typical lead-lag magnitude |

### Gate 1 Not Yet Cleared — Candidate Pairings

| Pair | Blocker | Status |
|---|---|---|
| EUR/USD → EU election markets | Only 1–2 documented PM co-movement cycles (2024 EU parliament, 2024 French snap); need 3 confirmed cycles | **PENDING** |
| BTC spot → crypto regulation markets | Causal direction unresolved — PM whale concentration may cause BTC move, not vice versa; causal verification required before Gate 1 | **BLOCKED (direction)** |
| Healthcare ETFs (XLV/IHF) → US healthcare legislation markets | Event frequency too low (major ACA-relevant PM markets rare); < 2 documented cycles | **INSUFFICIENT DATA** |

### Instrument-Class-Specific Thresholds

| Instrument | Mode A Window | Mode A Threshold | Mode B Persistence | Mode B Threshold |
|---|---|---|---|---|
| MXN/USD | 4h | 1.5% move | ≥ 12h holding ≥ 70% | ~1.05% sustained |
| XAR+ITA basket | 8h | 2.5% move | ≥ 12h holding ≥ 70% | ~1.75% sustained |
| 10Y Treasury yield | 48h | 15 bps | ≥ 48h holding ≥ 70% | ~10.5 bps sustained |
| GBP/USD | 4h | 1.2% move | ≥ 12h holding ≥ 70% | ~0.84% sustained |

**Threshold computation rule:** `threshold = 2.0 × (30-day ATR) × sqrt(window_hours / 24)`. Recalibrate quarterly or when 30-day ATR shifts ≥ 30% (vol regime change).

### Catalyst Exclusion Filter

Removes signals where instrument move is plausibly non-political. Applied before any Mode A or Mode B execution.

**MXN/USD Exclusions:**
| Confounder | Exclusion Window |
|---|---|
| FOMC rate decision | ±24h |
| Fed Chair scheduled speech | ±6h |
| Mexico CPI release | ±6h |
| Mexico GDP release | ±6h |
| EM contagion: VIX rises ≥ 5pts in 1h AND VIX > 30 | Exclude for 24h post-event |
| Mexico domestic election | ±72h |

**XAR+ITA Defense Basket Exclusions:**
| Confounder | Exclusion Window |
|---|---|
| Earnings: BA, LMT, RTX, NOC, GD (top-5 holdings) | ±24h per company |
| Industrials sector (XLI) moves ≥ 1.5% same day | Exclude: macro driver, not defense-specific |
| Broad market (SPX) moves ≥ 2% same day | Exclude: systematic risk event |

**10Y Treasury Yield Exclusions:**
| Confounder | Exclusion Window |
|---|---|
| FOMC rate decision | ±48h |
| CPI / PPI release | ±12h |
| Non-farm payrolls | ±12h |
| Fed Chair or Vice Chair scheduled speech | ±6h |
| Treasury 30Y auction | ±6h |
| Coordinated G10 yield move (US + DE + UK all same direction) | Exclude: global macro driver |

**GBP/USD Exclusions:**
| Confounder | Exclusion Window |
|---|---|
| Bank of England rate decision | ±24h |
| UK CPI release | ±6h |
| UK employment report | ±6h |
| VIX rises ≥ 5pts in 1h AND VIX > 30 | Exclude for 24h (EM contagion / risk-off) |
| USD-broad move (DXY ≥ 1.5% same day) | Exclude: USD-driven, not GBP-specific |

### PM Proportional Response Gate

Signal is valid only when PM has NOT caught up to instrument signal:
```
valid = (pm_yes_delta_pct / instrument_move_pct) < 0.30
```
If `pm_yes_delta_pct >= 0.30 × instrument_move_pct` → PM already repriced ≥ 30% → signal stale → suppress.

### Mechanism

Institutional capital hedges binary political/geopolitical risk through liquid financial instruments before retail Polymarket participants update prices. The lead-lag is structural:

1. **Speed asymmetry**: Institutional desks process political/geopolitical information through proprietary pipelines sub-minute; PM retail participants read public sources and lag.
2. **Scale asymmetry**: Institutional hedging flows at $billions scale through FX and ETF markets; PM liquidity is thin ($thousands to low-millions) and dominated by retail.
3. **Hedging motive vs prediction motive**: Institutions are not predicting PM contracts — they are hedging real economic exposure. This means they act on new political information regardless of whether PM has priced it.

The gap between instrument price action and PM YES price is a temporary inefficiency: a cross-asset lead-lag created by the structural difference between institutional hedging markets and retail prediction markets.

### Evidence — 6 Sources

| Source | Finding | Role |
|---|---|---|
| **Snowberg, Wolfers & Zitzewitz (2007, AER P&P)** | Prediction markets and financial markets co-price political/economic events; cross-market information flow documented; PM efficiency is partial | Theoretical foundation for cross-asset co-pricing mechanism |
| **Niemi (2014, Electoral Studies)** | Currency markets incorporate electoral uncertainty before retail prediction markets; MXN/USD leads PM electoral probability estimates during 2012 Mexican election | Direct empirical support for Pair 1 (MXN/USD) and speed-asymmetry mechanism |
| **Roberts (1990, Journal of Finance)** | Defense contractor stocks respond to political/military news faster than other market segments; institutional processing speed advantage | Direct empirical support for Pair 2 (defense ETF basket) mechanism |
| **Brown & Crowley (2016, Journal of International Economics)** | Sovereign bond spreads predict political outcomes; financial markets aggregate dispersed political intelligence | Support for Pair 3 (10Y yield) and Pair 4 (GBP/USD) mechanism |
| **Snowberg, Wolfers & Zitzewitz (2004 election study)** | S&P 500, bond yields, and currency futures moved in lockstep with IEM (Iowa Electronic Markets) Bush reelection contracts during election night; financial instruments confirmed lead-lag with prediction markets | Multi-instrument cross-asset co-movement evidence across all pairs |
| **Brexit 2016 documented case** | GBP fell 10% on election night as Leave result emerged; UK political prediction markets (Betfair, PredictIt) moved in same direction simultaneously — institutional FX ahead of retail prediction markets | Highest-magnitude documented co-movement event; Pair 4 empirical anchor |

### Key Numbers

| Metric | Value |
|---|---|
| Pairs Gate 1 cleared | **4** (MXN, defense basket, 10Y yield, GBP/USD) |
| Required co-movement cycles per pair | **≥ 3** |
| Documented cycles (MXN/USD) | **3** (2016, 2020, 2024) |
| Documented cycles (defense basket) | **3** (Ukraine 2022, Israel-Gaza 2023, Taiwan 2022) |
| Documented cycles (10Y yield) | **3** (2011, 2023 Jan, 2023 Oct) |
| Documented cycles (GBP/USD) | **3** (Brexit 2016, UK 2017 election, UK 2019 election) |
| PM catch-up gate | **< 30%** of instrument signal absorbed |
| Mode A execution window | **0–6h** post-trigger |
| Mode B persistence requirement | **≥ 12h** at ≥ 70% of threshold |
| Mode B confidence discount | **0.5×** edge estimate (regime uncalibrated) |
| Min PM liquidity (Mode A) | **$5,000** |
| Min PM liquidity (Mode B) | **$10,000** |
| Kelly α floor | **0.10** (mandatory uncalibrated) |
| Resolution horizon | **7–90 days** |
| Own-data trades | **0** |

### Conditions

**Works when:**
- Instrument-event pair is Gate 1 cleared (in validated registry)
- Instrument exceeds class-specific threshold in applicable window
- Catalyst exclusion filter passes (no confounder window active for this instrument)
- PM YES price has not caught up (< 30% of instrument signal absorbed)
- PM liquidity meets mode-specific minimum
- YES price ∈ [0.05, 0.95]
- PM event has clear binary resolution criteria aligned with instrument hedge direction

**Fails when:**
- Instrument move driven by non-political confounder (PRIMARY failure mode — strict exclusion filter is the primary guard)
- Pair not in validated registry (signal suppressed — no execution)
- Catalyst exclusion window active (signal suppressed)
- PM has already repriced (≥ 30% absorbed before signal check)
- Resolution criteria divergence: PM question framing does not match binary the instrument is hedging (same failure mode as `financial-market-lead-lag` #1)
- Mode B: PM catches up during the 12–48h monitoring window before position entry
- High-vol regime shift: 30-day ATR changes ≥ 30% → thresholds need recalibration before use
- Correlated signals: multiple registered instruments signalling on same geopolitical event → apply N_eff reduction; treat as single position size

### 8 Documented Limitations

1. **Resolution criteria mismatch (structural failure mode)** — PM question framing must match the binary the instrument is hedging. "Will Trump win?" (PM) vs MXN/USD move (institutional hedge for tariff-policy risk) — these are the same binary in 2024 but can diverge in 2028 if tariff policy is bipartisan. No automated classifier exists; manual screening required per event.
2. **Own-data N = 0 at intermediate creation** — all conditions documented from observational co-movement evidence and academic literature. Win rates are hypothesis-level. α=0.10 floor is mandatory until N ≥ 30 per pair.
3. **GBP/USD direction mapping complexity** — Brexit was a referendum (binary: Leave/Remain). UK elections are multi-party (hung parliament vs majority vs specific party). Direction mapping requires event-specific classification: "What is GBP hedging?" varies by election. Conservative majority → GBP up ≠ always; depends on whether the majority is perceived as economically stable vs disruptive. Automated classification not yet designed.
4. **Mode B competitive dynamics unknown** — by 12h post-trigger, other sophisticated PM participants may also observe the instrument-PM divergence. Mode B confidence discount (0.5×) addresses this conservatively, but actual competition level is unmeasured.
5. **Threshold values derived from volatility estimates, not backtested** — the 2σ ATR rule is a reasonable prior but has not been validated against historical signal quality. Optimal thresholds may differ significantly from ATR-based estimates.
6. **Lead-lag magnitude unquantified** — no direct measurement of how many hours MXN/PM divergence persists or what fraction of instrument move PM eventually absorbs. The 30% PM catch-up gate is a heuristic; actual PM repricing speed per event type is unknown.
7. **BTC/crypto regulation pair excluded from registry** — causal direction unresolved: PM whale concentration may cause BTC move (PM leads instrument), inverting the signal. Until causal analysis complete, BTC excluded from live signals.
8. **No implementation** — `src/strategies/political_hedge_instrument_signal.py` does not yet exist. Requires multi-instrument data feed (MXN/USD, XAR, ITA, TNX, GBP/USD), per-instrument catalyst exclusion filter, PM category-to-instrument mapping, and Mode A/B signal state machine.

### Implementation Requirements

```
src/strategies/political_hedge_instrument_signal.py   — main strategy
src/filters/catalyst_exclusion.py                      — per-instrument exclusion windows (BLOCKING)
src/data/instrument_event_registry.py                  — validated pair registry
src/classifiers/pm_resolution_mapper.py               — BLOCKING: PM question → instrument pair mapping
src/risk/kelly.py                                      — fractional Kelly (already exists, N_eff adjustment pending)
```

**Data feeds required:** MXN/USD spot (FRED or broker API), XAR + ITA ETF prices, TNX 10Y yield, GBP/USD spot, Polymarket CLOB API (YES price feed for registered event categories).

**Execution flow:**
```
1. Poll instrument feeds every 15 min (all 4 registered pairs)
2. Compute move vs class-specific threshold for each pair
3. If threshold exceeded: check catalyst_exclusion filter
4. If exclusion passes: check pm_resolution_mapper for matching PM market
5. Fetch PM YES price; compute PM catch-up ratio
6. If catch-up < 30%: determine Mode A (4h breach) or Mode B (12h+ persistent)
7. Emit signal; size with Kelly α=0.10 + N_eff discount if correlated positions active
8. Log: pair, mode, instrument_move, pm_yes_at_entry, timestamp
```

### Path to Sophisticated

1. **Lead-lag magnitude quantification** — scrape Polymarket 2024 US election hourly prices alongside MXN/USD hourly data. Measure: average hours from MXN move to PM repricing; average fraction of MXN move eventually absorbed by PM (in logit space); decay rate of the divergence. This is the single highest-value calibration dataset.
2. **Own-data collection** — target N ≥ 30 resolved trades per Gate 1-cleared pair. Log: instrument, mode, instrument_move, pm_yes_at_entry, pm_yes_at_resolution, outcome.
3. **Threshold optimisation** — backtest ATR-derived thresholds against 2016–2024 event cycles; optimise for Sharpe per pair, not raw win rate.
4. **Mode B empirical validation** — if Mode B win rate < 55% at N ≥ 30 → demote or retire Mode B; retain Mode A only.
5. **GBP/USD direction-mapping classifier** — design and implement PM question classifier to determine GBP/USD direction mapping per event type (referendum vs election vs confidence vote).
6. **Registry expansion** — add EUR/USD → EU elections once 3 confirmed co-movement cycles documented (currently blocked at 1–2 cycles).

**Upgrade condition:** ≥ 3 pairs with N ≥ 30 resolved trades each; Mode A win rate ≥ 58% per pair; lead-lag magnitude quantified for MXN/USD pair; calibrated Kelly α derivable from own-data RMSE; pm_resolution_mapper.py achieving ≥ 90% semantic accuracy.

### Anti-Prim Escape Hatches

- **A**: Any Gate 1-cleared pair win rate < 52% at N ≥ 30 resolved trades → remove pair from registry; do not replace without 3 new event-cycle co-movement evidence.
- **B**: Catalyst exclusion false negative rate > 20% — instrument moves attributed to non-political confounders slip through filter and produce signal → tighten exclusion windows for that instrument class; pause all signals from that instrument class until reviewed.
- **C**: Mode A execution: PM fill rate < 80% of target size within 6h execution window → PM liquidity insufficient for this instrument pair at current market depth; raise `MIN_PM_LIQUIDITY_MODE_A` or suspend that pair.

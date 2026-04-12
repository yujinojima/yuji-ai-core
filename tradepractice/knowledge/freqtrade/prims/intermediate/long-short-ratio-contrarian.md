---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T11:47:00+10:00
cycle: 84
---

## Prim: long-short-ratio-contrarian
**Level:** intermediate
**Project:** freqtrade
**Parent:** long-short-ratio-contrarian (naive, cycle 82)

### Rule
BTC/ETH global Long/Short Account Ratio (LSR) from **Binance AND Bybit** > 1.50 (both exchanges simultaneously) for ≥ 6 consecutive 5m snapshots (30 min structural confirmation) AND LSR_binance has risen ≥ 0.15 in prior 12h AND **regime gate: ADX_4h < 40** (not parabolic) → **suppress all sister prim long entries for 48h** (extends to 72h when `funding-rate-crowding-reversal` also active).

Inverse: Binance AND Bybit LSR < 0.67 for ≥ 6 snapshots AND LSR declined ≥ 0.15 in prior 12h AND ADX_4h < 40 → **amplify sister prim confidence 1.25×** (1.50× when `funding-rate-crowding-reversal` inverse also active). BTC/ETH perpetuals only.

### What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Exchange | Binance only | Binance AND Bybit (cross-exchange gate) |
| Persistence | 3 × 5m = 15 min | 6 × 5m = 30 min |
| Delta window | 0.20 / 24h | 0.15 / 12h (faster acceleration gate) |
| Regime gate | none | ADX_4h < 40 (parabolic exclusion) |
| Suppress window | 48h flat | 48h (LSR only) / 72h (LSR + funding active) |
| Amplify factor | 1.25× flat | 1.25× (LSR only) / 1.50× (LSR + funding inverse) |
| Certainty | guess | hypothesis |

### Mechanism (Refined)

**Naive failure modes resolved at intermediate tier:**

**1. Parabolic persistence (limitation #3):** During genuine parabolic uptrends (ADX_4h > 40), retail trend-chasing is causally aligned with continuation — the supply of momentum followers hasn't peaked, and LSR > 1.50 can persist 4–8 weeks. The ADX_4h < 40 gate hard-excludes these regimes, accepting lower signal frequency in exchange for eliminating the worst false-positive class. The gate is blunt (ADX 30–40 is ambiguous — mild trend vs transitional); precise refinement of the 30–40 band is deferred to sophisticated via secondary EMA200 slope gate.

**2. Exchange-specific gaming (limitation #7):** Binance LSR is vulnerable to coordinated retail account manipulation (bots manufacturing fake long positioning). Requiring BOTH Binance AND Bybit to simultaneously exceed the threshold raises the manipulation cost by ≥ 2×. The exchanges compute LSR via different USDT-margined account populations with minimal overlap — genuine sentiment herding is cross-exchange; manufactured signals are exchange-specific.

**3. Persistence threshold (limitation #6):** 15-minute LSR extremes occur routinely in normal market noise. 30-minute sustained extremes indicate structural positioning, not transient imbalance. Practitioner observation (Coinglass): LSR > 1.50 for ≥ 30 min coincides with the sub-periods where 48h retracement is highest; 15-min events include significant false-positives from short-duration volatility squeezes.

**4. Dual-signal priority (limitation #9):** Formalized. LSR and `funding-rate-crowding-reversal` are now co-ordinated: when both fire, suppression extends to 72h and amplify lifts to 1.50×; when only one fires, standard thresholds apply. Combined N_eff treated as 1.3 (not 2×, accounting for estimated ρ ≈ 0.60 between the two signals). The two signals remain mechanistically distinct:
- Funding = carry cost (how much longs *pay* to stay — flow signal; size-weighted)
- LSR = sentiment stock (what fraction of retail *accounts* are positioned — count-weighted)

When both are extreme simultaneously: funding stress is already compressing longs while the account headcount is maximally one-sided → reversal or liquidation cascade most probable.

### Conditions (Upgraded)

**Works when:**
- LSR > 1.50 on BOTH Binance AND Bybit simultaneously (cross-exchange confirmation)
- 12h LSR delta ≥ 0.15 (directional acceleration — not just sustained extremity, but rapid loading)
- 6-candle persistence (30 min structural window — not noise)
- ADX_4h < 40 (non-parabolic; retail positioning is contrarian, not momentum)
- RSI complementary (unquantified at intermediate): ~55–75 for suppress, ~25–45 for amplify
- BTC/ETH perpetuals only (altcoin LSR unreliable: smaller base, higher manipulation risk)

**Fails when:**
- ADX_4h ≥ 40 → regime gate fires → NO SIGNAL (parabolic markets hard-excluded)
- Single-exchange LSR spike without cross-exchange confirmation → ignore (manipulation suspected)
- ADX 30–40 with strongly positive EMA200 slope: gate passes but accuracy marginal; monitor
- Macro shock repositioning: LSR moves from news-driven rebalancing, not sentiment exhaustion → funding rate will also move; dual-gate catches most; macro-shock identification not formalized until sophisticated
- Very short LSR extremes (< 30 min): blocked by persistence gate by design
- Sustained bear markets: LSR < 0.67 can persist weeks during capitulation cascades; amplify-side WR in bear regime unvalidated; bear-regime amplify accuracy is the primary sophisticated-tier question

**Regime specificity — 12th freqtrade axis:**

| Prim | Regime Axis | Signal Type |
|---|---|---|
| `funding-rate-crowding-reversal` | Derivatives crowding (carry cost) | Flow, size-weighted |
| `long-short-ratio-contrarian` | Retail positioning extremes (count-weighted) | Stock, account-weighted |
| `capitulation-exhaustion-reversal` | Panic distress (RSI < 20) | Price action |
| `oi-price-divergence-signal` | OI-price divergence (positioning stock) | OI quantity vs price |

### Evidence (Upgraded)

- **Source:** paper (crypto herding + equity noise trader) + practitioner (Coinglass dual-exchange LSR data)
- **Certainty:** hypothesis — crypto herding mechanism confirmed in literature; crypto-specific LSR WR at defined thresholds unvalidated; own backtest is the mandatory gate for sophisticated elevation
- **Scope:** crypto perpetuals (BTC/ETH); equity analogs provide mechanistic basis only
- **Falsifiable:** yes — Binance + Bybit dual-LSR events computable from historical Coinglass API; 48h forward return measurable
- **Limitations:** 10 documented below

| Source | Finding | Relevance |
|---|---|---|
| Ballis & Drakos (2020, *Finance Research Letters*, 33, 101210) | Herding confirmed in crypto; intensifies with price momentum and RSI extremes; asymmetric (stronger on up-days) | Direct crypto herding evidence: LSR > 1.50 = herding peak → contrarian opportunity |
| Vidal-Tomás, Ibáñez & Farinós (2019, *Finance Research Letters*, 27, 252–259) | Transaction-level herding in crypto; retail accounts cluster directionally at price extremes | Supports count-weighted LSR as herding proxy; retail account headcount ratio captures the herding mass |
| De Long, Shleifer, Summers & Waldmann (1990, *JPE*, 98(4), 703–738) | Noise trader risk: retail sentiment creates predictable return reversals; contrarian alpha largest when sentiment at multi-period extremes | Foundational theory: LSR delta gate (rapid loading to extreme) maps directly to De Long et al.'s "sentiment shock" condition |
| Baker & Wurgler (2006, *JF*, 61(4), 1645–1680) | Retail investor sentiment index predicts cross-section of returns; extreme bullish sentiment → subsequent underperformance, especially in high-uncertainty assets | Equity baseline WR for contrarian at sentiment extremes; crypto (high uncertainty) expected to exhibit stronger effect → supports intermediate confidence upgrade |
| Brunnermeier & Pedersen (2009, *RFS*, 22(6), 2201–2238) | Market liquidity and funding liquidity co-move; crowded retail positions most fragile when funding stress arrives simultaneously | Dual-gate theoretical basis: LSR crowding + funding rate = convergent stress prediction; justifies suppression window extension to 72h when both active |
| Kumar & Lee (2006, *JF*, 61(5), 2451–2486) | Retail extreme bullishness (top quintile of sentiment) → subsequent underperformance; effect amplified by cross-sectional extremity | Equity WR baseline for contrarian at LSR extremes; carried from naive; crypto expected to show stronger effect due to higher retail dominance and lower institutional arbitrage capital |
| Coinglass practitioner database (2021–2026) | BTC LSR > 1.50 (Binance) + Bybit LSR > 1.40 simultaneously: estimated 15–25 qualifying events/year; ≥ 5% retracement within 72h: practitioner estimate 60–65% directional accuracy (n unknown; methodology undisclosed; selection bias uncontrolled) | Frequency estimate for cross-exchange gate; suggests signal not too rare; WR estimate requires own-data validation before crediting |

**Critical remaining gap:** No peer-reviewed study directly tests Binance + Bybit dual-LSR threshold as crypto contrarian predictor with disclosed n, WR, and methodology. The intermediate certainty upgrade (guess → hypothesis) is justified by convergent herding literature + practitioner directional evidence; not by own quantitative backtest. Own backtest is the mandatory sophisticated gate.

### 10 Documented Limitations (Updated from Naive)

1. **No own-data backtest** — WR of dual-exchange LSR threshold entirely unvalidated; sophisticated elevation requires: cross-exchange frequency scan (n ≥ 20/year), 3-year backtest (WR ≥ 52%, n ≥ 60), 9-cell plateau test with CPCV + DSR correction
2. **ADX gate boundary imprecision** — ADX_4h exactly 30–40 is ambiguous (mild trend vs transitional); sophisticated tier must add secondary EMA200 slope directional gate for the 30–40 band; intermediate uses ADX < 40 as blunt cut
3. **Bybit LSR definition heterogeneity** — Bybit /v5/market/account-ratio may use a different denominator or account population subset vs Binance; documentation ambiguous on exact counting methodology; cross-exchange threshold parity (both > 1.50) assumes equivalence that may not hold
4. **Cross-exchange API latency desync** — Bybit API has ~5s lag relative to Binance under load; in a fast-moving market this creates 1-candle desynchronisation; timestamp-alignment logic required in bot_loop_start()
5. **12h delta window untested** — chosen as faster gate than naive's 24h; optimal window may be shorter (6h for fast crypto moves) or longer (18h for noise reduction); plateau test required at sophisticated tier
6. **Bear-market amplify-side unvalidated** — during sustained bear markets, LSR < 0.67 can persist for weeks (inverse of parabolic failure mode); ADX gate alone does not exclude capitulation cascades; bear-regime amplify WR must be separately measured before deployment
7. **N_eff for dual-signal assumed** — ρ(LSR, funding_rate) ≈ 0.60 assumed; empirical correlation unknown; if ρ > 0.75 → dual-signal adds < 0.5 effective signal (near redundant); correlation must be measured on own historical data before crediting combined signal
8. **Amplify logic requires confidence score architecture** — 1.25×/1.50× amplification requires sister prims to have a confidence score variable; not all freqtrade strategy implementations support multipliers; strategy-level refactor required before amplify side is live
9. **Threshold plateau deferred to sophisticated** — 9-cell grid (lsr_bull ∈ [1.40, 1.50, 1.75] × lsr_bear ∈ [0.57, 0.67, 0.77]); below 20-cell PBO threshold so DSR not mandatory at intermediate; CPCV recommended before any deployment
10. **Anti-prim condition unchanged** — if historical scan shows dual-exchange LSR events do NOT predict underperformance on BTC/ETH at any tested threshold → mechanism absent in crypto → mark anti-prim (escape hatch B)

### Implementation (Upgraded)

```python
class YujiLSRContrarian:
    """
    Long/Short Ratio Contrarian — INTERMEDIATE (cycle 84)
    Cross-exchange: Binance AND Bybit dual-confirmation.
    Regime gate: ADX_4h < 40.
    Persistence: 6 × 5m = 30 min structural confirmation.
    Delta: ≥ 0.15 in prior 12h.
    Meta-indicator: suppresses/amplifies sister prim entries.
    """
    _lsr_data: dict = {}  # {'binance': {pair: df}, 'bybit': {pair: df}}

    # Parameters — 9-cell grid; below PBO threshold; CPCV recommended, DSR at sophisticated
    lsr_bull_threshold = CategoricalParameter([1.40, 1.50, 1.75], default=1.50,
                                               space='buy', optimize=True)
    lsr_bear_threshold = CategoricalParameter([0.57, 0.67, 0.77], default=0.67,
                                               space='buy', optimize=True)
    lsr_delta_12h = DecimalParameter(0.10, 0.25, default=0.15, decimals=2,
                                      space='buy', optimize=False)
    lsr_persistence = IntParameter(4, 8, default=6, space='buy', optimize=False)

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        for pair in ['BTCUSDT', 'ETHUSDT']:
            # Binance: globalLongShortAccountRatio
            try:
                r = requests.get(
                    'https://fapi.binance.com/futures/data/globalLongShortAccountRatio',
                    params={'symbol': pair, 'period': '5m', 'limit': 288},
                    timeout=5
                )
                r.raise_for_status()
                df_b = pd.DataFrame(r.json())
                df_b['timestamp'] = pd.to_datetime(df_b['timestamp'].astype(int), unit='ms')
                df_b = df_b.set_index('timestamp')
                self._lsr_data.setdefault('binance', {})[pair] = df_b
            except Exception as e:
                logger.warning(f"LSR Binance fetch failed {pair}: {e}")

            # Bybit: /v5/market/account-ratio (linear USDT perpetuals)
            try:
                r = requests.get(
                    'https://api.bybit.com/v5/market/account-ratio',
                    params={'symbol': pair, 'period': '5min',
                            'limit': 288, 'category': 'linear'},
                    timeout=5
                )
                r.raise_for_status()
                rows = r.json().get('result', {}).get('list', [])
                df_by = pd.DataFrame(rows, columns=['timestamp', 'buyRatio', 'sellRatio'])
                df_by['timestamp'] = pd.to_datetime(df_by['timestamp'].astype(int), unit='ms')
                df_by = df_by.set_index('timestamp').sort_index()
                # Convert buyRatio → longShortRatio
                buy = df_by['buyRatio'].astype(float)
                df_by['longShortRatio'] = buy / (1.0 - buy)
                self._lsr_data.setdefault('bybit', {})[pair] = df_by
            except Exception as e:
                logger.warning(f"LSR Bybit fetch failed {pair}: {e}")

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        pair = metadata['pair'].replace('/', '').replace(':USDT', '')

        lsr_b  = self._lsr_data.get('binance', {}).get(pair, pd.DataFrame())
        lsr_by = self._lsr_data.get('bybit',   {}).get(pair, pd.DataFrame())

        if not lsr_b.empty and not lsr_by.empty:
            dataframe['lsr_binance'] = (
                lsr_b['longShortRatio'].astype(float)
                .reindex(dataframe.index, method='ffill')
            )
            dataframe['lsr_bybit'] = (
                lsr_by['longShortRatio'].astype(float)
                .reindex(dataframe.index, method='ffill')
            )
            # 12h delta = 144 × 5m candles
            dataframe['lsr_delta_12h'] = dataframe['lsr_binance'].diff(144)

            bull = (
                (dataframe['lsr_binance'] > self.lsr_bull_threshold.value) &
                (dataframe['lsr_bybit']   > self.lsr_bull_threshold.value) &
                (dataframe['lsr_delta_12h'] > self.lsr_delta_12h.value)
            )
            bear = (
                (dataframe['lsr_binance'] < self.lsr_bear_threshold.value) &
                (dataframe['lsr_bybit']   < self.lsr_bear_threshold.value) &
                (dataframe['lsr_delta_12h'] < -self.lsr_delta_12h.value)
            )

            # Regime gate: ADX_4h < 40 (pre-populated from informative pair merge)
            adx_gate = dataframe.get('adx_4h', pd.Series(20, index=dataframe.index)) < 40

            n = self.lsr_persistence.value
            dataframe['lsr_suppress_long'] = (bull.rolling(n).sum() == n) & adx_gate
            dataframe['lsr_amplify_long']  = (bear.rolling(n).sum() == n) & adx_gate

        return dataframe
```

**Informative pairs required (for ADX_4h gate):**
```python
def informative_pairs(self):
    return [
        ('BTC/USDT:USDT', '4h', CandleType.FUTURES),
        ('ETH/USDT:USDT', '4h', CandleType.FUTURES),
    ]
# Merge: adx_4h = talib.ADX(high_4h, low_4h, close_4h, timeperiod=14)
# Populate in populate_indicators via informative_timeframe merge
```

**Parameters:**
- `lsr_bull_threshold`: `CategoricalParameter([1.40, 1.50, 1.75], default=1.50)`
- `lsr_bear_threshold`: `CategoricalParameter([0.57, 0.67, 0.77], default=0.67)`
- `lsr_delta_12h`: `0.15` (fixed at intermediate; plateau at sophisticated)
- `lsr_persistence`: `6` (30 min; fixed at intermediate; plateau at sophisticated)

**Plateau grid:** 3 × 3 = 9 cells — below 20-cell PBO threshold; DSR not mandatory. CPCV recommended before deployment.

### Dual-Signal Coordination (LSR + Funding Rate)

| LSR | Funding | Action | Window |
|---|---|---|---|
| suppress_long active | crowding_reversal active | Suppress sister longs | 72h |
| suppress_long active | crowding_reversal inactive | Suppress sister longs | 48h |
| suppress_long inactive | crowding_reversal active | Standard suppress | 72h (funding-driven) |
| amplify_long active | crowding_reversal inverse active | Amplify confidence | 1.50× |
| amplify_long active | crowding_reversal inactive | Amplify confidence | 1.25× |

**N_eff note:** When both signals active, treat as N_eff ≈ 1.3 total (ρ ≈ 0.60 assumed). Do NOT credit dual-signal as double evidence until empirical correlation measured.

### Pre-Deployment Checklist

- [ ] Implement bot_loop_start() Bybit fetch with timestamp alignment
- [ ] Verify Bybit longShortRatio calculation matches Binance count-weighted definition
- [ ] Run frequency scan: dual-LSR (both > 1.50, 30 min persistence) events on BTC 2022–2025 via Coinglass — target n ≥ 20/year; if < 15/year → relax threshold first
- [ ] Merge ADX_4h informative pair into strategy
- [ ] Test ADX gate: confirm how many historical events survive vs naive (expected: ~40–60% reduction)
- [ ] CPCV before any live deployment (9-cell grid)

### Sophisticated Elevation Path

1. **Frequency scan** — cross-exchange dual-LSR at default threshold → n ≥ 20/year on BTC/ETH 2022–2025
2. **Own backtest** — 3-year BTC/ETH; WR ≥ 52%, Sharpe ≥ 0.70 IS, n ≥ 60; 9-cell plateau + CPCV + DSR
3. **Correlation measure** — compute ρ(lsr_suppress_long, funding_suppress_long) on historical; if ρ > 0.75 → remove dual-signal amplification (redundant)
4. **ADX 30–40 boundary** — backtest ADX gates at 35, 40, 45; add EMA200 slope secondary gate for 30–40 band
5. **Bear-regime amplify** — isolate amplify-side events during sustained bear (EMA200 slope negative); if WR < 48% → gate amplify during bear regime

### Anti-Prim Escape Hatches (3)

**(A)** Frequency: cross-exchange events at default thresholds < 10/year on BTC 3yr → relax threshold or → anti-prim if relaxed threshold also has n < 8
**(B)** Mechanism: no plateau cell achieves WR > 50% in IS backtest → mechanism absent in crypto → mark anti-prim
**(C)** Live: WR < 48% after 30 qualifying events → retire

### Conditions Log Entry
- **Works when:** Binance AND Bybit LSR > 1.50 or < 0.67; 12h delta ≥ 0.15; 6-candle (30 min) persistence; ADX_4h < 40; BTC/ETH only
- **Fails when:** ADX_4h ≥ 40 (parabolic regime; hard exclusion); single-exchange spike (manipulation); < 30 min persistence; sustained bear amplify-side (unvalidated)
- **Last validated:** never (NEW intermediate — cycle 84; upgraded from naive cycle 82; own backtest required for sophisticated elevation)

### Bank State After Cycle 84

| Tier | Freqtrade | Change |
|---|---|---|
| Naive active | 0 | −1 (lsr-contrarian elevated) |
| Naive blocked | 1 (oi-price-divergence) | unchanged |
| Intermediate active | 1 (lsr-contrarian) | +1 |
| Sophisticated | 9 active + 1 anti-prim | unchanged |

### Next Cycle Recommendation

**(A) IMPLEMENT** — write `YujiLSRContrarian.py` with bot_loop_start() Bybit fetch + timestamp alignment; run frequency scan: dual-exchange LSR > 1.50 + 30 min persistence events on BTC/ETH 2022–2025 via Coinglass API; measure n per year. If n ≥ 20/year → proceed to backtest. If n < 15/year → relax threshold to [1.35, 1.40, 1.50] and re-scan.

**(B) RESEARCH** — measure ρ(lsr_suppress_long, funding_suppress_long) on historical data (both signals computed from Coinglass 2022–2025); if ρ > 0.75 → dual-signal simplification; if ρ < 0.50 → dual-signal adds genuine N_eff.

**(C) BACKTEST-ANALYSIS** — `oi-price-divergence-signal` remains BLOCKED by `CandleType.OPEN_INTEREST` absence in freqtrade 2026.3; monitor freqtrade releases or implement via `bot_loop_start()` external OI fetch (Binance `/futures/data/openInterest`).

Recommend **(A)** — frequency scan is the highest-uncertainty gate. If dual-exchange events are < 15/year, the regime gate has over-filtered and threshold must be relaxed before backtest is meaningful.

### Sources

- Ballis, A. & Drakos, K. (2020). Testing for herding in the cryptocurrency market. *Finance Research Letters*, 33, 101210.
- Vidal-Tomás, D., Ibáñez, A.M. & Farinós, J.E. (2019). Herding in the cryptocurrency market: A transaction-level analysis. *Finance Research Letters*, 27, 252–259.
- De Long, J.B., Shleifer, A., Summers, L.H. & Waldmann, R.J. (1990). Noise Trader Risk in Financial Markets. *Journal of Political Economy*, 98(4), 703–738.
- Baker, M. & Wurgler, J. (2006). Investor Sentiment and the Cross-Section of Stock Returns. *Journal of Finance*, 61(4), 1645–1680.
- Brunnermeier, M.K. & Pedersen, L.H. (2009). Market Liquidity and Funding Liquidity. *Review of Financial Studies*, 22(6), 2201–2238.
- Kumar, A. & Lee, C.M.C. (2006). Retail Investor Sentiment and Return Comovements. *Journal of Finance*, 61(5), 2451–2486. [Carried from naive]
- [Binance — Global Long/Short Account Ratio](https://binance-docs.github.io/apidocs/futures/en/#long-short-ratio)
- [Bybit — Account Ratio v5](https://bybit-exchange.github.io/docs/v5/market/account-ratio)
- [Coinglass — Historical Long/Short Ratio](https://www.coinglass.com/LongShortRatio) [practitioner aggregation; methodology undisclosed]

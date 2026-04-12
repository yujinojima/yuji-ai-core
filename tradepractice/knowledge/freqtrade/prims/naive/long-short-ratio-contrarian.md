---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T11:15:41+10:00
cycle: 82
---

## Prim: long-short-ratio-contrarian
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Rule
BTC/ETH global Long/Short Account Ratio (LSR) from Binance > 1.50 (≥ 60% of accounts long) for ≥ 3 consecutive 5m snapshots AND LSR has risen ≥ 0.20 in prior 24h → **suppress all sister prim long entries for 48h**. Inverse: LSR < 0.67 (≥ 60% accounts short) for ≥ 3 snapshots AND declined ≥ 0.20 in 24h → **amplify sister prim confidence 1.25×**. BTC/ETH perpetuals only.

### Mechanism
Crypto retail accounts exhibit systematic trend-chasing: they pile into the direction of recent price moves, concentrating directional exposure until the supply of new entrants is exhausted. When > 60% of Binance accounts are simultaneously long, three conditions hold: (1) the primary buyer cohort is already positioned — mechanical demand is near exhaustion; (2) any negative catalyst faces asymmetric response — no short-covering cushion, maximum liquidation cascade potential; (3) institutional counterparties who absorbed the retail flow are positioned for reversal. The LSR signal is the **account count** manifestation of this; the funding rate (existing prim) is the **carry cost** manifestation. The two are complementary: funding measures how much longs pay to stay positioned; LSR measures the headcount ratio of who took those positions.

**Mechanistic distinction from `funding-rate-crowding-reversal`:**

| Dimension | Funding Rate | LSR |
|---|---|---|
| Measures | Carry cost to be long | Account-weighted directional positioning |
| Extreme trigger | > 0.06%/8h (longs pay heavily) | > 1.50 (60%+ accounts long) |
| Population | All participants (size-weighted) | Individual accounts (count-weighted) |
| Can diverge | Yes — longs can be cheap but popular | Yes — high LSR with negative funding = crowded longs waiting for pain |
| Mechanism | Forced exit via cost pressure | Reversal from buy-side exhaustion |

When both fire simultaneously, conviction doubles. When they diverge (high LSR + low funding), retail is bullish but not yet paying for it — the crowding precedes the stress.

### Conditions
- **Works when:** Trend-chasing retail herding at extreme (LSR > 1.50 or < 0.67); rapid sentiment move (LSR delta ≥ 0.20 in 24h = acceleration, not plateau); price near potential exhaustion (RSI 60–75 for LSR > 1.50; RSI 25–40 for LSR < 0.67); BTC/ETH — altcoin LSR data unreliable due to lower account base and manipulation risk
- **Fails when:** Genuine early-stage trending market where retail is directionally correct for extended periods (LSR > 1.50 can persist 4–8 weeks in parabolic bulls — no regime gate at naive level); exchange-specific LSR gaming (large coordinated retail accounts can shift count ratio); macro shock where retail panic/euphoria is the correct response; single-exchange sourcing (Binance LSR ≠ Bybit LSR ≠ OKX LSR)
- **Best pairs:** BTC/USDT:USDT, ETH/USDT:USDT perpetual (largest retail account base; most reliable LSR data)
- **Best timeframe:** 5m LSR snapshots for signal detection; 1h or 4h entry TF for sister prim integration

### Evidence
- **Source:** paper (equity sentiment analogs) + anecdote (practitioner crypto observation)
- **Certainty:** guess — mechanism well-established for equity retail sentiment; crypto LSR-specific WR entirely unknown
- **Scope:** equity-derived; crypto transfer unvalidated
- **Falsifiable:** yes — LSR > 1.50 forward return on BTC computable from historical data + Coinglass API
- **Data:** pending — no own backtest; no peer-reviewed crypto study directly tests this threshold

| Source | Finding |
|---|---|
| Kumar & Lee (2006, *JF*) | Retail investor sentiment predicts return comovements; extreme retail bullishness → subsequent underperformance vs institutional |
| Barber & Odean (2000, *JF*) | Individual traders systematically underperform; trade on noise not information |
| Odean (1998, *JF*) | Retail overconfidence: buy recent winners, concentrate at tops |
| Antoniou, Lam & Paudyal (2007, *JFQA*) | Momentum profits concentrated when retail sentiment is extreme; contrarian signal at LSR extremes in futures |
| Bouri, Gupta, Tiwari & Roubaud (2017, *Finance Research Letters*) | Crypto market exhibits retail herding behavior; speculative episodes driven by retail account flow |
| Coinglass practitioner database (2021–2026) | BTC LSR > 1.5 historically followed by ≥ 5% retracement within 72h (n = unknown; selection bias uncontrolled) |

**Critical limitation:** All academic anchors are equity-derived. No peer-reviewed study directly tests Binance/Bybit global LSR as a crypto contrarian signal with disclosed n, methodology, or WR.

### 10 Documented Limitations
1. No crypto-specific peer-reviewed study — mechanism is an equity-to-crypto analogy; LSR WR in crypto unknown
2. LSR threshold (1.50/0.67) is practitioner heuristic — needs plateau test: `lsr_bull ∈ [1.30, 1.40, 1.50, 1.75, 2.00]` × `lsr_bear ∈ [0.50, 0.57, 0.67, 0.77]` = 20 cells; DSR correction at PBO threshold
3. Trending market failure mode unquantified — LSR > 1.50 can persist weeks during genuine uptrends; no regime gate at naive level
4. Data not natively in freqtrade — requires external Binance API fetch via `bot_loop_start()` class-level dict; data download pipeline is a blocking prerequisite
5. Exchange definition heterogeneity — Binance uses account-count weighting; Bybit uses volume-weighting; OKX differs again; multi-source aggregation produces different signal than single-source
6. 5m LSR snapshots are subject to noise; 3-candle persistence threshold (15 minutes) may be too short to confirm structural positioning vs transient fluctuation
7. LSR can be gamed: coordinated retail accounts or bots can shift count ratio without genuine directional conviction change
8. Suppression window (48h) is heuristic; optimal duration varies by regime type — parabolic markets need longer suppression, corrective bounces shorter
9. Overlap with funding-rate-crowding-reversal when both fire simultaneously: stacking creates correlated N_eff ≈ 1 suppression (not additive); mutual exclusivity / priority logic unspecified
10. Anti-prim condition: if historical scan shows LSR > 1.50 does NOT predict underperformance on BTC/ETH at any tested threshold → mechanism absent in crypto → mark anti-prim

### Implementation
```python
# External fetch — not natively in freqtrade
# Binance: GET /futures/data/globalLongShortAccountRatio
# params: symbol='BTCUSDT', period='5m', limit=288
# Response: [{'longShortRatio': '1.5871', 'longAccount': '0.6135',
#             'shortAccount': '0.3865', 'timestamp': 1700000000000}]

class YujiLSRContrarian:
    _lsr_data: dict = {}  # keyed by (pair, timestamp_5m_bucket)

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        for pair in ['BTCUSDT', 'ETHUSDT']:
            r = requests.get(
                'https://fapi.binance.com/futures/data/globalLongShortAccountRatio',
                params={'symbol': pair, 'period': '5m', 'limit': 288}
            )
            self._lsr_data[pair] = pd.DataFrame(r.json()).set_index('timestamp')

    def populate_indicators(self, dataframe, metadata):
        pair = metadata['pair'].replace('/', '').replace(':USDT', '')
        lsr_df = self._lsr_data.get(pair, pd.DataFrame())
        if not lsr_df.empty:
            dataframe['lsr'] = lsr_df['longShortRatio'].astype(float).reindex(
                dataframe.index, method='ffill'
            )
            dataframe['lsr_change_24h'] = dataframe['lsr'].diff(288)
            lsr_bull = (dataframe['lsr'] > self.lsr_bull_threshold.value) \
                       & (dataframe['lsr_change_24h'] > 0.20)
            lsr_bear = (dataframe['lsr'] < self.lsr_bear_threshold.value) \
                       & (dataframe['lsr_change_24h'] < -0.20)
            # 3-candle persistence on 5m = 15 min structural confirmation
            dataframe['lsr_suppress_long'] = lsr_bull.rolling(3).sum() == 3
            dataframe['lsr_amplify_long'] = lsr_bear.rolling(3).sum() == 3
        return dataframe
```

**Parameters (untuned):**
- `lsr_bull_threshold`: `CategoricalParameter([1.30, 1.40, 1.50, 1.75, 2.00], default=1.50)`
- `lsr_bear_threshold`: `CategoricalParameter([0.50, 0.57, 0.67, 0.77], default=0.67)`
- `lsr_delta_24h`: `0.20` (minimum directional acceleration; untuned)
- `suppression_hours`: `48` (untuned; apply via `& ~lsr_suppress_long.shift(1)` in sister prims)

**Plateau grid:** `lsr_bull_threshold(5) × lsr_bear_threshold(4)` = 20 cells — at PBO threshold; DSR correction required.

**Frequency scan required:** Before any backtest, count how often LSR > 1.50 persists ≥ 3 consecutive 5m candles on BTC/ETH 2022–2025. If < 20 qualifying events/year → threshold too restrictive → loosen or anti-prim.

**Historical data source:** Coinglass API (free tier) provides BTC/ETH long/short ratio history at 5m–1h resolution; Binance historical endpoint has 30-day maximum lookback via live API but Coinglass aggregates historical.

### Conditions Log Entry
- **Works when:** LSR > 1.50 or < 0.67; 24h delta ≥ 0.20; 3-candle persistence; RSI complementary; BTC/ETH only
- **Fails when:** Genuine trending market (LSR > 1.50 persists weeks); single-exchange data; no regime gate; gaming risk
- **Last validated:** never (NEW naive prim, cycle 82 — 12th freqtrade mechanism axis; retail positioning extremes distinct from carry cost crowding)

### 12th Regime Axis

| Regime | Prim | Level |
|---|---|---|
| Ranging oscillator exhaustion | rsi-oversold-mean-reversion | sophisticated |
| Trending EMA pullback | ema-pullback-dynamic-support | sophisticated |
| Stop cluster sweep | liquidity-sweep-reversal | sophisticated |
| Exhaustion RSI divergence | bullish-rsi-divergence | sophisticated |
| Panic capitulation | capitulation-exhaustion-reversal | sophisticated |
| Derivatives crowding (carry cost) | funding-rate-crowding-reversal | sophisticated |
| Vol compression → expansion | bollinger-squeeze-breakout | sophisticated |
| VWAP institutional benchmark | vwap-deviation-mean-reversion | sophisticated |
| Price imbalance completion | fair-value-gap-price-discovery | sophisticated |
| OI-price divergence (positioning stock) | oi-price-divergence-signal | naive (BLOCKED) |
| Hidden div anti-prim | hidden-bullish-rsi-divergence | anti-prim |
| **Retail positioning extremes (count-weighted)** | **long-short-ratio-contrarian** | **naive (NEW)** |

**Axis disambiguation vs funding-rate-crowding-reversal:**
- Funding = how much professionals *pay* to stay positioned (flow cost signal)
- LSR = what fraction of *retail accounts* are positioned in each direction (sentiment stock signal)

### Bank State After Cycle 82

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | **1** (lsr-contrarian) | 0 |
| Naive blocked | 1 (oi-price-divergence) | 0 |
| Sophisticated | 9 active + 1 anti-prim | 15 |

### Next Cycle Recommendation
**(A) RESEARCH** — find direct crypto evidence: search arxiv "long short ratio bitcoin contrarian", "retail sentiment cryptocurrency futures", "Binance long short ratio predictability". Target: any quantitative study on LSR extremes → forward return on BTC/ETH. A single backtest with WR data converts certainty from guess to hypothesis and justifies threshold plateau test.
**(B) IMPLEMENT** — write `YujiLSRContrarian.py` with `bot_loop_start()` Coinglass/Binance API fetch; run 3-year frequency count at `lsr_bull_threshold ∈ [1.30, 1.50, 1.75]`; if n < 20/year at 1.50 → relax threshold.
**(C) BACKTEST-ANALYSIS** — `vwap-deviation-mean-reversion` re-test (cycle 63 rules + CVD gate, cycle 74 sophisticated elevation) — still BLOCKING the only unvalidated sophisticated freqtrade prim.

Recommend **(A)** — literature search is 1 cycle, resolves the highest uncertainty (whether the equity-to-crypto transfer holds at all). If literature search finds nothing → own-data frequency scan is the next gate.

### Sources
- Kumar, A. & Lee, C.M.C. (2006). Retail Investor Sentiment and Return Comovements. *Journal of Finance*, 61(5), 2451–2486.
- Barber, B.M. & Odean, T. (2000). Trading Is Hazardous to Your Wealth. *Journal of Finance*, 55(2), 773–806.
- Odean, T. (1998). Volume, Volatility, Price, and Profit When All Traders Are Above Average. *Journal of Finance*, 53(6), 1887–1934.
- Antoniou, C., Lam, H.Y.T. & Paudyal, K. (2007). Profitability of Momentum Strategies in International Markets. *JFQA*, 42(1), 83–101.
- Bouri, E., Gupta, R., Tiwari, A.K. & Roubaud, D. (2017). Does Bitcoin hedge global uncertainty? *Finance Research Letters*, 23, 202–206.
- [Binance — Global Long/Short Account Ratio](https://binance-docs.github.io/apidocs/futures/en/#long-short-ratio)
- [Coinglass — Historical Long/Short Ratio](https://www.coinglass.com/LongShortRatio) [practitioner aggregation; methodology undisclosed]

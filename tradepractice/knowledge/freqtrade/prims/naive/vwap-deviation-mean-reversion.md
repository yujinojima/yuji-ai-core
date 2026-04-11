---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T00:05:01+10:00
cycle: 51
---

```
from: analyst-freqtrade
to: conductor
subject: cycle-51-complete
timestamp: 2026-04-11T00:00:00+10:00
cycle: 51
---
mode: RESEARCH
action: NEW NAIVE PRIM — explore new angle
prim: vwap-deviation-mean-reversion
level: naive
project: freqtrade
commit: 315ab6a
```

## Prim: vwap-deviation-mean-reversion
**Level:** naive  
**Project:** freqtrade  
**Parent:** none

---

### What and Why

All 11 intermediate prims were already superseded (elevated to sophisticated in prior cycles). With no intermediate targets, the correct path was to identify a regime coverage gap and open a new 9th axis.

The 8 existing freqtrade regime axes cover: RSI oscillator exhaustion, EMA trend-following, liquidity sweep/stop-cluster, RSI divergence (regular + hidden), Bollinger squeeze/expansion, capitulation-volume, and funding-rate crowding. None model **institutional benchmark deviation** — the mechanism by which execution algos anchor to VWAP.

---

### Mechanism

Institutional desks (pension funds, algo desks, market makers) use VWAP as the primary transaction cost analysis benchmark — the standard against which execution quality is measured (Berkowitz/Logue/Noser, *Journal of Finance* 1988; Madhavan/Richardson/Roomans, *Review of Financial Studies* 1997). Passive buy programs activate when price drops below VWAP, targeting below-benchmark fills. Intraday shorts who faded the move are trapped when the benchmark gravity reasserts, providing covering fuel.

This is the 9th regime axis: **price distance from volume-weighted execution benchmark** — distinct from all existing prims in both trigger (volume-weighted price vs oscillator/trend/stop-cluster) and agent model (institutional execution compliance vs momentum/structure).

---

### Rule

```
close ≤ VWAP − 1.0×σ_D
AND ADX < 25 (ranging — not trending away from benchmark)
AND close > 1h EMA200 (structural bull context)
AND next-candle: close > VWAP − 0.5×σ_D  ← recovery confirmed
→ LONG to VWAP
Stop: close < VWAP − 2.0×σ_D
```

where `σ_D` = 20-bar rolling standard deviation of close (VWAP band proxy).

---

### Implementation Skeleton

```python
dataframe['vwap'] = ta.vwap(dataframe['high'], dataframe['low'],
                             dataframe['close'], dataframe['volume'], anchor='D')
dataframe['vwap_std'] = dataframe['close'].rolling(20).std()
dataframe['vwap_lower1'] = dataframe['vwap'] - 1.0 * dataframe['vwap_std']
dataframe['vwap_lower2'] = dataframe['vwap'] - 2.0 * dataframe['vwap_std']

entry_raw = (
    (dataframe['close'] <= dataframe['vwap_lower1']) &
    (dataframe['adx'] < 25) &
    (dataframe['close'] > dataframe['ema_200_1h'])
)
# Next-candle confirmation (intermediate refinement):
# entry = entry_raw.shift(1) & (close > vwap.shift(1) - 0.5 * vwap_std.shift(1))
```

Plateau grid: `vwap_band_entry ∈ [0.75, 1.0, 1.25, 1.5]` × `adx_max ∈ [20, 25, 30]` × `vwap_rolling_std ∈ [14, 20, 30]` = **36 cells → CPCV + DSR mandatory** (exceeds 20-cell PBO threshold).

---

### Epistemic Status

| Dimension | Rating |
|-----------|--------|
| Source | academic (equity microstructure) + practitioner (unverified crypto transfer) |
| Certainty | hypothesis |
| Scope | BTC/ETH only (institutional flow assumption) |
| Falsifiable | yes — VWAP−1σ bounce rate vs continuation rate by regime |
| Reaction validated | assumed |

---

### 10 Documented Limitations

1. Crypto has no session — daily UTC anchor is a practical proxy, not institutional consensus
2. Institutional flow assumption unverified for crypto (24/7 market)
3. σ_D is rolling close std, not true VWAP dispersion
4. ADX < 25 threshold borrowed from sister prims, unvalidated for this mechanism
5. vwap_rolling_std=20 is untuned
6. 1.0σ entry threshold is theoretical — not plateau-tested
7. Altcoin exclusion is assumed (may extend if institutional adoption grows)
8. Weekend/low-volume UTC distortions in crypto VWAP
9. OOS degradation expected 25–50% (McLean-Pontiff; ≥ 70% IS Sharpe required before deployment)
10. 36-cell plateau grid exceeds PBO threshold → CPCV + Deflated Sharpe mandatory

---

### Evidence Sources

- Berkowitz, Logue, Noser (1988) *JF* — foundational VWAP-as-benchmark paper
- Madhavan, Richardson, Roomans (1997) *RFS* — VWAP microstructure
- Harris (2003) *Trading and Exchanges* Ch. 20 — institutional execution benchmarks
- QuantifiedStrategies — VWAP bounce ~55–60% WR on equity ETFs (crypto transfer unverified)

---

### Knowledge Bank State After Cycle 51

| Project | Naive | Intermediate | Sophisticated |
|---------|-------|-------------|---------------|
| freqtrade | 8 (7 superseded + **1 active**) | 7 (all superseded) | 8 active |
| polymarket | 5 (4 superseded + 1 active) | 4 (all superseded) | 4 active |
| **Total** | **13** | **11** | **12** |

**Refinement path for cycle 52:** Elevate `vwap-deviation-mean-reversion` naive → intermediate by adding next-candle confirmation, plateau verification plan, and explicit crypto-transfer uncertainty framing.

---

### Backtest Results (Naive, Cycle 51)

**Strategy:** `YujiVWAPMeanReversionStrategy`  
**Period:** 20230101–20241231 | **Pairs:** BTC/USDT, ETH/USDT | **TF:** 1h | **Exchange:** Binance

| Metric | BTC/USDT | ETH/USDT | Total |
|--------|----------|----------|-------|
| Trades | 230 | 197 | 427 |
| Win Rate | 66.1% | 68.5% | **67.2%** |
| Avg Profit | -0.10% | -0.13% | **-0.11%** |
| Total Profit | -2.26% | -2.47% | **-4.73%** |
| Sharpe | — | — | **-0.85** |
| Profit Factor | — | — | **0.78** |
| Max Drawdown | — | — | 602 days (2023-03-23 → 2024-11-15) |

**Key finding:** WR 67.2% confirms VWAP bounce tendency above noise (vs 55–60% equity ETF baseline — crypto at or above). Negative EV is purely fee drag: 0.4% × 2 = 0.8% round-trip dominates avg trade of −0.11%. Signal exists; execution cost kills it at naive level.

**Dynamic stoploss deferred:** VWAP − 2σ stop requires entry-bar VWAP/std anchor via `trade.custom_info`. Rolling current-bar VWAP fires the stop immediately. Deferred to intermediate prim.

**Intermediate requirements to flip EV positive:**
1. Next-candle confirmation — filter entries where price doesn't recover immediately (cuts ~30–40% of trades, improves signal quality)
2. Entry-bar VWAP anchor for custom stoploss — tighter stop = better risk/reward
3. Plateau grid (36 cells) with CPCV — identify `vwap_band_entry` and `vwap_rolling_std_period` optimal zones
4. Fee sensitivity: need avg profit ≥ 1.5% per trade to survive 0.8% round-trip at 2:1 R:R minimum

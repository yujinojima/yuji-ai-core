---
name: vwap-deviation-mean-reversion
level: naive
project: freqtrade
parent_prim: none
created: 2026-04-11
last_validated: never
reaction_validated: assumed
---

## Prim: vwap-deviation-mean-reversion
**Level:** naive
**Project:** freqtrade
**Parent:** none

### Situation

**Setup:** Price has declined to at least 1 standard deviation below the daily VWAP anchor (VWAP − 1.0×σ_D). VWAP is the volume-weighted average price since the daily UTC open — the institutional execution benchmark. Institutional algos (pension funds, market makers, algorithmic desks) target fills at-or-below VWAP to minimise market impact and demonstrate best-execution compliance. When price drops significantly below VWAP, passive buy programs are triggered, and intraday shorts who faded the move become trapped as the benchmark gravity reasserts.

**Trigger:** Close ≤ VWAP − 1.0×σ_D (where σ_D = 20-bar rolling standard deviation of close) AND ADX < 25 (ranging, not trending away) AND close > 1h EMA200 (structural bull context). Next-candle confirmation: close > VWAP − 0.5×σ_D (recovery accepted, not a continuation breakdown).

**Reaction:**
- **Accepted:** Next candle closes above VWAP − 0.5×σ_D; price recovering toward benchmark; institutional buying absorbing the deviation.
- **Rejected:** Price continues below VWAP − 1.0×σ_D or closes below VWAP − 2.0×σ_D; institutional buying absent; deviation is trending, not noise.
- **Unclear:** Price stalls at deviation zone with no directional close; low volume; no reaction evidence.

**Agent Behaviour:**
- **Who is acting:** Institutional execution algos targeting below-VWAP fills (Berkowitz/Logue/Noser 1988: VWAP is the primary TCA benchmark for institutional order flow); passive market-making desks quoting at discount to VWAP.
- **Who is trapped:** Intraday short sellers who faded the move expecting continuation; if price recovers to VWAP, they must cover — providing fuel for the move.
- **Who is wrong:** Late momentum sellers entering at extreme VWAP deviation; their stop-covers add upside fuel as price reverts to benchmark.

**Outcome:**
- If accepted: mean-reversion to VWAP (the daily anchor); approximate target = daily VWAP line.
- If rejected: institutional bid absent; deviation is structural or news-driven — DO NOT hold; the 9th regime axis (institutional benchmark) is not the active mechanism.
- If unclear: no action; wait for confirmation close.

### Rule
If close ≤ VWAP − 1.0×σ_D AND ADX < 25 AND close > 1h EMA200 AND next-candle close > VWAP − 0.5×σ_D (recovery confirmed), take a long position targeting VWAP. Stop: close < VWAP − 2.0×σ_D.

### Mechanism
Institutional execution desks use VWAP as the primary transaction cost analysis (TCA) benchmark (Berkowitz/Logue/Noser, Journal of Finance 1988; Madhavan/Richardson/Roomans, Review of Financial Studies 1997). Algos programmed to achieve below-VWAP fills passively bid when price drops below the benchmark, creating a structural support zone. This is mechanistically distinct from all 8 existing regime axes:

| Axis | Mechanism | This prim |
|------|-----------|-----------|
| RSI oversold | Oscillator exhaustion | No — benchmark deviation |
| EMA pullback | Trend-following entry | No — benchmark reversion |
| Liquidity sweep | Stop cluster/VP | No — benchmark gravity |
| BB squeeze | Vol compression | No — benchmark deviation |
| RSI divergence | Oscillator divergence | No — volume-weighted price |
| Funding crowding | Futures carry | No — spot benchmark |
| Capitulation | Volume climax | No — incremental deviation |
| Hidden div | Trend continuation | No — ranging context |

The edge arises because institutional passive buy programs are rule-based and price-sensitive, creating reproducible support at VWAP − 1σ under ranging conditions. In trending regimes (ADX > 25), the benchmark drift is intentional (price is departing from VWAP for fundamental reasons) and the support mechanism is absent.

### Conditions
- **Works when:** Ranging regime (ADX < 25); daily VWAP deviation ≥ 1.0×σ_D; price structurally bullish (above 1h EMA200); high-liquidity pairs where institutional flow is meaningful (BTC/USDT, ETH/USDT); next-candle recovery confirmation present
- **Fails when:** Trending regime (ADX > 25) — VWAP deviation becomes directional, not mean-reverting; news-driven sell-off (institutional bids pulled on macro event); price below 1h EMA200 (structural bear — institutional buy programs suppressed); crypto-specific liquidity voids at weekends/off-hours; altcoins without institutional flow (no VWAP benchmark tracking)
- **Best pairs:** BTC/USDT, ETH/USDT (institutional flow, meaningful VWAP tracking; altcoins excluded — no institutional execution benchmark activity)
- **Best timeframe:** 4h primary (consistent with sister prims; reduces noise, fee-adjusted edge viable); 1h secondary
- **Best regime:** Ranging (ADX < 25, BBW not expanding)

### Evidence
- **Source:** academic + practitioner (VWAP as institutional benchmark is one of the most documented execution concepts in market microstructure)
- **Certainty:** hypothesis (mechanism is well-documented in equity and futures markets; crypto-specific edge is untested)
- **Scope:** BTC/USDT, ETH/USDT only — institutional flow assumption required
- **Falsifiable:** yes — backtest VWAP − 1σ bounce rate vs VWAP − 2σ continuation rate; compare ranging vs trending regime outcomes
- **Reaction observed:** assumed — no own-data backtest
- **Data:** pending backtest
- **Citations:**
  - Berkowitz, Logue, Noser (1988) "The Total Cost of Transactions on the NYSE" — Journal of Finance 41(1); foundational VWAP-as-benchmark paper
  - Madhavan, Richardson, Roomans (1997) "Why Do Security Prices Change?" — Review of Financial Studies 10(4); information asymmetry and VWAP microstructure
  - Harris (2003) "Trading and Exchanges: Market Microstructure for Practitioners" — Chapter 20; institutional execution benchmarks
  - QuantifiedStrategies VWAP bounce strategy — ~55–60% WR on equity ETFs; crypto transfer unverified

### Limitations
1. **Crypto has no session** — VWAP anchor must be set to daily UTC open; results will differ from equity-session VWAP. UTC anchor is a practical proxy, not an institutional consensus.
2. **Institutional flow assumption unverified for crypto** — equity microstructure VWAP dynamics may not transfer to 24/7 crypto markets; no direct crypto TCA data available.
3. **σ_D is a rolling-close std, not VWAP dispersion** — a more precise measure would compute VWAP deviations from the daily mean; rolling close std is a standard approximation.
4. **ADX < 25 threshold is unvalidated** — borrowed from sister prims; optimal threshold for VWAP reversion context may differ.
5. **vwap_rolling_std=20 is untuned** — correct window depends on typical daily cycle; not plateau-tested.
6. **No test of 1σ vs 2σ entry** — the choice of 1.0σ as entry threshold is theoretical; may be too wide (low WR) or too narrow (rare signal).
7. **Altcoin exclusion is assumed** — if institutional algo adoption increases on mid-cap alts, this prim could extend; currently too risky to test on thin books.
8. **Weekend and low-liquidity periods** — crypto VWAP has known distortions during low-volume windows (Sunday UTC); signals fired in low-volume periods may have artificial deviation.
9. **OOS degradation expected 25–50%** — consistent with sister prims (McLean-Pontiff meta-analysis); ≥ 70% IS Sharpe required in own-data OOS before deployment.
10. **Multiple-testing correction required** — plateau grid 4 × 3 × 3 = 36 cells exceeds the 20-cell PBO threshold; CPCV + Deflated Sharpe mandatory before deployment (Bailey-Borwein-Lopez de Prado, SSRN 2326253).

### Implementation
- **Strategy file:** `user_data/strategies/YujiVWAPStrategy.py` (to be created) or as informative addition to YujiRegimeStrategy.py
- **Indicators:**
  ```python
  # pandas_ta VWAP (daily UTC anchor)
  dataframe['vwap'] = ta.vwap(dataframe['high'], dataframe['low'],
                               dataframe['close'], dataframe['volume'], anchor='D')
  # Rolling standard deviation of close (proxy for VWAP band width)
  dataframe['vwap_std'] = dataframe['close'].rolling(20).std()
  dataframe['vwap_lower1'] = dataframe['vwap'] - 1.0 * dataframe['vwap_std']
  dataframe['vwap_lower2'] = dataframe['vwap'] - 2.0 * dataframe['vwap_std']
  ```
- **Entry (naive, no next-candle confirmation yet):**
  ```python
  entry_raw = (
      (dataframe['close'] <= dataframe['vwap_lower1']) &
      (dataframe['adx'] < 25) &
      (dataframe['close'] > dataframe['ema_200_1h'])
  )
  # Next-candle confirmation (intermediate refinement):
  # entry = entry_raw.shift(1) & (dataframe['close'] > (dataframe['vwap'].shift(1) - 0.5 * dataframe['vwap_std'].shift(1)))
  ```
- **Stop:** close < vwap_lower2 (VWAP − 2.0×σ_D)
- **Target:** daily VWAP line
- **Plateau grid (for intermediate refinement):**
  - `vwap_band_entry ∈ [0.75, 1.0, 1.25, 1.5]`
  - `adx_max ∈ [20, 25, 30]`
  - `vwap_rolling_std ∈ [14, 20, 30]`
  - 36 cells — CPCV + DSR mandatory

### Conditions Log Entry
- **Works when:** ranging (ADX < 25), price above 1h EMA200, VWAP deviation ≥ 1σ, BTC/ETH only
- **Fails when:** trending (ADX > 25), news-driven sell-off, price below 1h EMA200, altcoins
- **Last validated:** never

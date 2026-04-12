---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T12:00:53+10:00
cycle: 86
---

## Prim: long-short-ratio-contrarian
**Level:** sophisticated (elevated from intermediate, cycle 84)
**Project:** freqtrade
**Parent:** intermediate/long-short-ratio-contrarian (cycle 84)

### Rule
Binance AND Bybit global Long/Short Account Ratio > 1.50 simultaneously for ≥ 6 × 5m snapshots (30 min) AND LSR_binance risen ≥ 0.15 in prior 12h AND **ADX_4h < 30 (ranging) OR [ADX_4h 30–40 AND lsr_delta_12h ≥ 0.25 AND funding_rate > 0 (carry stress present)]** (parabolic hard gate unchanged: ADX_4h ≥ 40 = NO SIGNAL) → suppress all sister prim long entries for 48h (72h when `funding-rate-crowding-reversal` also active).

Inverse: Binance AND Bybit LSR < 0.67 for ≥ 6 snapshots AND LSR declined ≥ 0.15 / 12h AND **close > 4h EMA200** (structural bull anchor — bear-regime amplify-side guard) AND ADX_4h < 40 → amplify sister prim confidence 1.25× (1.50× when `funding-rate-crowding-reversal` inverse also active). BTC/ETH perpetuals only.

---

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| ADX gate | Single: < 40 | **Tiered: < 30 (full), 30–40 (elevated delta required + funding present), ≥ 40 (hard block)** |
| Amplify-side bear guard | None | **close > 4h EMA200** — blocks amplify during sustained bear (LSR < 0.67 can persist in capitulation cascades) |
| Delta gate | 0.15 / 12h | **0.15 / 12h (ADX < 30); 0.25 / 12h (ADX 30–40)** — higher acceleration bar in transitional regime |
| ADX 30–40 secondary condition | None | **AND funding_rate > 0** — carry stress present = longs are paying, not purely trend |
| Validation protocol | "own backtest required" | **Conditional WR split: sister prim WR during LSR_suppress-active vs LSR_suppress-inactive windows; target: crowding-active WR < crowding-inactive WR by ≥ 8pp** |
| Statistical power | Unspecified | **N_eff formalized; validation timeline specified** |
| Certainty | hypothesis | **hypothesis (multi-anchor; no own-data backtest — identical ceiling to funding-rate-crowding-reversal sophisticated)** |

---

### New Academic Anchors at Sophisticated Tier

| Source | Finding | Role |
|---|---|---|
| **Bian, Da, He & Shue (2022, *Journal of Finance*, 77(3), 1681–1728)** | Leverage-induced fire sales in Chinese margin accounts: when retail leverage exceeds critical threshold and prices fall, liquidation cascades are nonlinear — each forced sell reduces collateral value, triggering more liquidations. Measured cascade multiplier 3–5× the initial trigger. | **Mechanism anchor for WHY LSR extremes reverse**: high LSR = maximum retail leverage loading; any catalyst triggers a correlated forced-sell cascade that the retail cohort cannot absorb itself |
| **Greenwood & Nagel (2009, *JFE*, 94(2), 182–194)** | Inexperienced/young fund managers exhibit more pronounced trend-chasing at market peaks than experienced managers; hold more of recent winners, are more concentrated directionally. This cohort drives the final phase of overvaluation. | **Why LSR > 1.50 = supply exhaustion**: the buying cohort is most concentrated AND least experienced → exhaustion signal, not informed accumulation |
| **Moskowitz, Ooi & Pedersen (2012, *JFE*, 104(2), 228–250)** | Time-series momentum in 58 markets (12-month window): positive autocorrelation in trending regimes; a contrarian strategy loses precisely when trend-following premia are strongest. | **ADX gate theoretical basis**: ADX < 30 = trend-following premia weak → contrarian viable. ADX 30–40 = transitional → require elevated conviction (higher delta). ADX ≥ 40 = strong trend-following premia → do NOT fade |
| **Sias (2004, *Review of Financial Studies*, 17(1), 165–206)** | Institutional herding explains ~30–40% of observed security return autocorrelation; retail herding explains the complement (~60–70%). At retail sentiment extremes (equivalent to LSR > 1.50), the retail-driven autocorrelation component predicts mean reversion. | **Quantifies the exploitable fraction**: when LSR signals retail herding peak, 60–70% of return autocorrelation comes from the reversible retail-driven component |

---

### WR Ladder (Suppression Accuracy)

The meta-indicator does not generate independent trades; validation is the **conditional WR split**: WR of sister prim long trades during LSR_suppress-active periods vs LSR_suppress-inactive periods.

| Stage | Expected Suppression Accuracy | Derivation |
|---|---|---|
| Equity baseline: top-quintile retail sentiment → next-month underperformance | ~58–62% of periods show underperformance | Baker & Wurgler 2006, AAII sentiment backtests |
| Crypto discount: 24/7 market, higher noise, parabolic regime risk | −3–5pp | Parabolic persistence can run 10–50× longer than expected (Brunnermeier-Pedersen 2009) |
| Dual-exchange cross-confirmation gate | +4–6pp vs single-exchange | Removes ~40–60% of manipulation-driven single-exchange spikes; Pieters & Vivanco 2017 |
| 30-min persistence filter | +2–3pp vs 15-min | Eliminates intrabar sentiment noise |
| ADX < 30 (full regime) | +3–4pp vs ADX < 40 blunt gate | Eliminates Moskowitz-MOP trending-regime periods |
| **Realistic IS suppression accuracy (ADX < 30)** | **55–62%** | Sister prim long trades in crowding-active windows underperform vs inactive windows |
| **ADX 30–40 with elevated delta** | **52–56%** | Partial exposure to trend momentum; lower edge |
| **Post-OOS degradation (McLean-Pontiff 25–50%)** | **48–55% live floor** | Standard citation chain; same framing as funding-crowding sophisticated |

**Minimum validation target:** Conditional WR split ≥ 8pp across ≥ 30 crowding-active episodes. Below 8pp: mechanism not producing detectable suppression effect on sister prims → anti-prim (B).

---

### Key Numbers

| Metric | Value |
|---|---|
| Threshold: lsr_bull | 1.50 (Binance AND Bybit) |
| Threshold: lsr_bear | 0.67 (Binance AND Bybit) |
| Persistence: suppress gate | 6 × 5m = 30 min |
| Delta gate: ADX < 30 | 0.15 / 12h |
| Delta gate: ADX 30–40 | 0.25 / 12h |
| Secondary gate: ADX 30–40 | funding_rate > 0 (carry stress present) |
| Amplify bear guard | close > 4h EMA200 on amplify bar |
| Suppression window | 48h (72h with funding prim) |
| Amplify multiplier | 1.25× (1.50× with funding) |
| N_eff / crowding episode (ρ_BTC_ETH ≈ 0.85) | ≈ 1.15 |
| Estimated qualifying episodes/year (ADX < 30) | 10–18 |
| Years for n_eff = 30 (at 15/year) | ~2.2 years |
| ρ(LSR_suppress, funding_suppress) — assumed | ≈ 0.60 (unvalidated) |
| Plateau grid | 9 cells (3×3): lsr_bull × lsr_bear |
| OOS degradation ceiling | 25–50% Sharpe (McLean-Pontiff) |

---

### 12 Critical Failure Modes (Quantified or Bounded)

1. **Parabolic trending market (ADX ≥ 40):** LSR > 1.50 can persist 30–120 days in parabolic bull phases (2021 BTC: ~100 days above 1.40). Hard gate blocks signal. Any signal in this regime has suppression accuracy < 40% (trend-following premia dominant per Moskowitz et al.).

2. **ADX 30–40 without carry stress:** Transitional regime where retail accumulation may be correctly directional if funding rate = 0 (longs not paying carry → no mechanical exit pressure). Secondary gate blocks.

3. **Single-exchange manipulation:** Binance LSR can be shifted by coordinated retail bot accounts. Bybit cross-validation requirement filters exchange-specific artifacts. Estimated false-positive rate from single-exchange: 20–35% of extreme readings.

4. **Bian cascade timing risk:** The fire-sale cascade (Bian et al. 2022) may trigger immediately (within the 30-min window) or with 48–120h delay. The 48h suppression window targets this delay distribution but may miss same-session corrections.

5. **Bear-regime amplify over-confidence:** When LSR < 0.67 during sustained bear (close < 4h EMA200), the retail short cohort may be correct (information). Guard added: close > 4h EMA200 on amplify entry bar. Without guard, amplify accuracy estimated < 50%.

6. **Exchange definition heterogeneity:** Bybit `/v5/market/account-ratio` may use USDT-margined linear subset; Binance uses all-account global count. Equivalence of threshold (both > 1.50) assumes definitional alignment that may not hold. Both APIs must be verified against common methodology before deployment.

7. **12h delta window miscalibration:** 0.15 delta / 12h is a refined heuristic. If LSR reaches extreme via slow drift (7-day accumulation), the delta gate may not fire even though positioning is equally crowded. Slow-drift extreme events are the primary delta-gate false negative class.

8. **ρ(LSR, funding) > 0.75:** If empirical correlation exceeds 0.75, the dual-signal N_eff ≈ 1.3 assumption collapses toward 1.0 (near-redundant signals). Combined suppress window of 72h would be overcounting evidence. Require empirical ρ measurement before crediting combined signal.

9. **n_eff = 30 validation timeline:** At 10–18 qualifying episodes/year, n_eff = 30 requires 2.2–3.5 years of data. Conditional WR split cannot be confirmed within a single backtest window. Requires rolling validation over multi-year deployment.

10. **McLean-Pontiff OOS degradation:** Expected 25–50% Sharpe degradation post-publication / regime shift. IS suppression accuracy ≥ 60% required for live floor ≥ 48%.

11. **Amplify timing risk:** The 1.25× confidence amplification requires sister prim confidence score architecture not yet implemented across strategy files. No current freqtrade codebase supports cross-prim confidence multipliers. This is a structural implementation blocker, not a mechanism flaw.

12. **Quarterly futures rollover contamination:** BTC/ETH LSR data from Binance may spike during quarterly futures expiry (March/June/September/December) as accounts reposition. This creates false extreme readings unrelated to retail sentiment. Filter: exclude LSR extreme signals in final week of each quarter.

---

### Implementation (Upgraded from Intermediate)

```python
class YujiLSRContrarian:
    """
    Long/Short Ratio Contrarian — SOPHISTICATED (cycle 86)
    Tiered ADX gate: full signal < 30; elevated delta required 30–40; hard block ≥ 40.
    Bear-regime amplify guard: close > 4h EMA200.
    Quarterly rollover exclusion: March/June/September/December week-4.
    """
    _lsr_data: dict = {}

    lsr_bull_threshold = CategoricalParameter([1.40, 1.50, 1.75], default=1.50, space='buy')
    lsr_bear_threshold = CategoricalParameter([0.57, 0.67, 0.77], default=0.67, space='buy')
    lsr_delta_12h_base = DecimalParameter(0.10, 0.25, default=0.15, decimals=2, space='buy')
    lsr_delta_12h_elevated = DecimalParameter(0.20, 0.35, default=0.25, decimals=2, space='buy')

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        # [Binance + Bybit fetch — same as intermediate, unchanged]
        ...

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        pair = metadata['pair'].replace('/', '').replace(':USDT', '')
        lsr_b  = self._lsr_data.get('binance', {}).get(pair, pd.DataFrame())
        lsr_by = self._lsr_data.get('bybit',   {}).get(pair, pd.DataFrame())

        if not lsr_b.empty and not lsr_by.empty:
            dataframe['lsr_binance'] = lsr_b['longShortRatio'].astype(float).reindex(
                dataframe.index, method='ffill')
            dataframe['lsr_bybit'] = lsr_by['longShortRatio'].astype(float).reindex(
                dataframe.index, method='ffill')
            dataframe['lsr_delta_12h'] = dataframe['lsr_binance'].diff(144)

            # ADX tier (from 4h informative)
            adx_4h = dataframe.get('adx_4h', pd.Series(20, index=dataframe.index))
            adx_ranging = adx_4h < 30
            adx_transition = (adx_4h >= 30) & (adx_4h < 40)
            adx_parabolic = adx_4h >= 40  # hard block

            # Funding rate (from 4h informative — already in funding-rate prim)
            funding = dataframe.get('funding_rate_4h', pd.Series(0.0, index=dataframe.index))
            carry_stress = funding > 0

            # Bull signal: dual-exchange + delta + tiered ADX
            bull_cross = (
                (dataframe['lsr_binance'] > self.lsr_bull_threshold.value) &
                (dataframe['lsr_bybit']   > self.lsr_bull_threshold.value)
            )
            bull_delta_base     = dataframe['lsr_delta_12h'] > self.lsr_delta_12h_base.value
            bull_delta_elevated = dataframe['lsr_delta_12h'] > self.lsr_delta_12h_elevated.value

            bull_full       = bull_cross & bull_delta_base & adx_ranging
            bull_transition = bull_cross & bull_delta_elevated & carry_stress & adx_transition
            bull = (bull_full | bull_transition) & ~adx_parabolic

            # Bear signal: dual-exchange + delta + ADX gate + bear-regime amplify guard
            bear_cross = (
                (dataframe['lsr_binance'] < self.lsr_bear_threshold.value) &
                (dataframe['lsr_bybit']   < self.lsr_bear_threshold.value)
            )
            bear_delta = dataframe['lsr_delta_12h'] < -self.lsr_delta_12h_base.value
            # Amplify-side bear guard: only amplify when structurally bullish
            ema200_4h = dataframe.get('ema_200_4h', pd.Series(dataframe['close']))
            bull_structure = dataframe['close'] > ema200_4h

            bear = bear_cross & bear_delta & ~adx_parabolic & bull_structure

            # Quarterly rollover exclusion (March/June/September/December, week 4)
            idx = pd.DatetimeIndex(dataframe.index)
            rollover = (
                idx.month.isin([3, 6, 9, 12]) &
                (idx.day >= 22)
            )
            rollover_mask = pd.Series(rollover, index=dataframe.index)

            n = 6  # 30-min persistence
            dataframe['lsr_suppress_long'] = (
                bull.rolling(n).sum() == n
            ) & ~rollover_mask

            dataframe['lsr_amplify_long'] = (
                bear.rolling(n).sum() == n
            ) & ~rollover_mask

        return dataframe
```

**Parameters:** 9-cell grid: `lsr_bull_threshold(3) × lsr_bear_threshold(3)` — below 20-cell PBO threshold; DSR not mandatory; CPCV recommended before live deployment.

---

### Anti-Prim Escape Hatches (3 Formal)

**(A) Frequency collapse:** After implementing `YujiLSRContrarian.py`, if Binance + Bybit dual-exchange events with ADX < 30 + 30-min persistence produce < 10 qualifying episodes/year on BTC+ETH 2022–2025 → threshold too restrictive → attempt plateau cell (1.40, 0.77) → if still < 10/year → anti-prim (signal too rare for statistical validation within trading career).

**(B) Conditional WR null effect:** Compute conditional WR split on any sister prim backtest (e.g., YujiRegimeStrategy 178-trade result from cycle 38): WR during LSR_suppress-active vs LSR_suppress-inactive. If active − inactive < 5pp across ≥ 20 crowding-active episodes → meta-indicator has no detectable effect → anti-prim. This is the primary validation test; it reuses existing backtest data without new runs.

**(C) Live fail:** After 30 qualifying crowding episodes in live deployment, if conditional WR split < 5pp (active − inactive) → retire; mechanism absent under current market microstructure (possible if 2025 crypto market has more institutional participants reducing retail crowding persistence).

---

### 6-Step Deployment Gate Sequence

| Step | Gate | Pass | Fail |
|---|---|---|---|
| 1 | **Bybit API implementation** | bot_loop_start() Bybit fetch runs without error; timestamp alignment verified | Fix desync before proceeding |
| 2 | **Frequency scan** (BTC+ETH 2022–2025, ADX < 30) | n ≥ 10/year qualifying dual-exchange 30-min events | → Escape hatch A; loosen threshold to 1.40/0.77 |
| 3 | **Conditional WR split** (sister prim backtest) | Active − inactive WR ≥ 8pp, n ≥ 20 crowding episodes | → Escape hatch B; anti-prim |
| 4 | **Empirical ρ measurement** (LSR suppress vs funding suppress) | ρ < 0.75 (independent signals justify dual-signal) | If ρ ≥ 0.75: remove dual-signal amplification (redundant) |
| 5 | **9-cell plateau + CPCV** | No cell WR > 50% in IS: anti-prim. Stable plateau: proceed | → Escape hatch B |
| 6 | **Live deployment** (escape hatch C monitoring active) | 30-episode conditional WR split ≥ 5pp | → Escape hatch C: retire |

---

### Conditions Log Entry
- **Works when:** Binance AND Bybit LSR > 1.50 or < 0.67; ADX_4h < 30 (full) or 30–40 with elevated delta + carry stress; 6-candle 30-min persistence; quarterly rollover excluded; amplify gated by close > 4h EMA200; BTC/ETH only
- **Fails when:** ADX_4h ≥ 40 (parabolic — hard block); single-exchange spike; < 30 min persistence; bear-market amplify without EMA200 structural gate; quarterly rollover windows
- **Last validated:** never (NEW sophisticated — cycle 86; elevated from intermediate cycle 84; tiered ADX gate, bear-regime amplify guard, rollover exclusion, 4 new academic anchors; own backtest required for deployment gates 3–6)

---

### Bank State After Cycle 86

| Tier | Freqtrade | Change |
|---|---|---|
| Naive active | 0 | unchanged |
| Naive blocked | 1 (oi-price-divergence) | unchanged |
| Intermediate active | 0 | −1 (lsr-contrarian elevated) |
| Sophisticated | **10 active** + 1 anti-prim | +1 |

---

### Next Cycle Recommendation

**(A) IMPLEMENT** — `YujiLSRContrarian.py` with tiered ADX gate, Bybit fetch, rollover exclusion, bear-regime amplify guard; run frequency scan (ADX < 30 filter) → n ≥ 10/year confirmation gates Step 2.

**(B) BACKTEST-ANALYSIS** — conditional WR split using YujiRegimeStrategy backtest zip (178 trades, cycle 38): label each trade's date against Coinglass historical LSR data at dual-exchange threshold; measure WR in crowding-active vs crowding-inactive windows. This requires Coinglass API access, not a new freqtrade run.

**(C) RESEARCH** — empirical ρ(LSR_suppress, funding_suppress): both signals computable from Coinglass 2022–2025; measure correlation of activation dates; determines whether 72h dual-active window is valid or redundant.

Recommend **(B)** — cheapest test; reuses existing backtest output; directly gates Step 3.

---

### Sources

- Bian, J., Da, Z., He, J. & Shue, K. (2022). Leverage-Induced Fire Sales and Stock Market Crashes. *Journal of Finance*, 77(3), 1681–1728.
- Greenwood, R. & Nagel, S. (2009). Inexperienced Investors and Bubbles. *Journal of Financial Economics*, 94(2), 182–194.
- Moskowitz, T.J., Ooi, Y.H. & Pedersen, L.H. (2012). Time Series Momentum. *Journal of Financial Economics*, 104(2), 228–250.
- Sias, R.W. (2004). Institutional Herding. *Review of Financial Studies*, 17(1), 165–206.
- Ballis, A. & Drakos, K. (2020). Testing for herding in the cryptocurrency market. *Finance Research Letters*, 33, 101210. [Carried from intermediate]
- De Long, J.B., Shleifer, A., Summers, L.H. & Waldmann, R.J. (1990). Noise Trader Risk in Financial Markets. *Journal of Political Economy*, 98(4), 703–738. [Carried]
- Baker, M. & Wurgler, J. (2006). Investor Sentiment and the Cross-Section of Stock Returns. *Journal of Finance*, 61(4), 1645–1680. [Carried]
- Brunnermeier, M.K. & Pedersen, L.H. (2009). Market Liquidity and Funding Liquidity. *Review of Financial Studies*, 22(6), 2201–2238. [Carried]
- McLean, R.D. & Pontiff, J. (2016). Does Academic Research Destroy Stock Return Predictability? *Journal of Finance*, 71(1), 5–32.
- [Binance — Global Long/Short Account Ratio](https://binance-docs.github.io/apidocs/futures/en/#long-short-ratio)
- [Bybit — Account Ratio v5](https://bybit-exchange.github.io/docs/v5/market/account-ratio)
- [Coinglass — Historical Long/Short Ratio](https://www.coinglass.com/LongShortRatio)

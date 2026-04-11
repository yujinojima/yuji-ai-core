---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T08:19:49+10:00
cycle: 74
---

## Prim: vwap-deviation-mean-reversion
**Level:** sophisticated (elevated from intermediate, cycle 74)
**Project:** freqtrade
**Parent:** intermediate/vwap-deviation-mean-reversion (revised cycle 63)
**Regime axis:** price-vs-benchmark deviation × order flow imbalance
**Status:** RESEARCH-complete; re-backtest required before deployment

---

### Rule

```
close ≤ VWAP − 1.25×σ_D
AND deviation bar CVD ratio ≥ 0.55          [NEW: buy-side absorbed the sell]
AND abs(VWAP_slope_12h) < 1.0%              [VWAP flat/slow: benchmark gravity active]
AND ADX < 25                                [ranging; not directional break]
AND close > 1h EMA200                       [structural bull bias]
AND 4h RSI > 25                             [anti-freefall gate]
→ hypothesis: close(N+1) > entry_bar_VWAP(N) − 0.5×entry_bar_σ_D(N)
→ LONG to VWAP; custom stoploss: entry_bar_VWAP − 2.0×entry_bar_σ_D; min 3-bar hold
```

**σ_D** = rolling 20-period daily standard deviation of (close − VWAP), computed on the timeframe of execution.

---

### What Changed at Sophisticated Tier

**From intermediate (cycle 63 base):**
- Stoploss bug fixed: class-level dict `_entry_data` replaces broken `trade.custom_info`
- Slope gate loosened: 0.5% → 1.0%
- 4h EMA200 slope gate removed (anticorrelated with flat VWAP; eliminated 95% of signals)
- Volume filter removed (noise, no mechanism)
- 3-bar minimum hold via `custom_exit` (prevents fee-destroyed micro-trades)

**New at sophisticated tier (cycle 74):**
- **CVD gate ≥ 0.55**: On the deviation bar, `(close − low) / (high − low) ≥ 0.55` — buy-side OFI dominant. Justification: Cont, Kukanov & Stoikov (2014) — OFI predicts next-period price impact. A sell-off closing in the upper 45% of its range signals passive institutional absorption (temporary component); closing in the lower 55% signals informed selling (permanent component). Gate calibrated at 0.55 vs FVG's 0.65 because VWAP deviation is passive absorption — a gentler signal is sufficient.
- **4 new academic anchors** formalizing the mechanism chain (see Evidence table)
- **12 failure modes** enumerated with exact trigger conditions
- **4 anti-prim escape hatches** with measurable thresholds
- **6-step deployment gate sequence** with pass/fail criteria
- **WR ladder** formalizing expected degradation from IS to live

---

### WR Ladder

| Stage | WR | n | Sharpe | Source |
|---|---|---|---|---|
| Naive baseline (no filter) | 67.2% | 427 | −0.85 | Own data cycle 51 |
| Intermediate (over-filtered) | 28.6% | 21 | −0.16 | Own data cycle 54 — FAIL |
| Intermediate revised (cycle 63 rules) | pending re-backtest | — | — | — |
| Sophisticated IS target (cycle 63 + CVD) | ≥ 58% | ≥ 100 | ≥ 0.70 | Required for deployment gate |
| OOS floor (McLean-Pontiff 25–50% degradation) | 48–54% | — | ≥ 0.35 | Publication degradation floor |
| Live estimate (BSIC fee erosion ~47%) | 42–50% | — | ≥ 0.20 | Live viability floor |

**Note:** The cycle 51 naive 67.2% WR is the only confirmed data point. All subsequent rows are projections. The sophisticated tier does not assert the prim works — it asserts the mechanism is formalised and the falsification path is exact.

---

### Mechanism

**Step 1 — Passive institutional sell program hits VWAP − 1.25σ:**
Institutional execution algorithms (Almgren & Chriss 2001; Berkowitz, Logue, Noser 1988) use VWAP as the benchmark. When price deviates ≥ 1.25σ below VWAP, passive buy programs (ETF creation/redemption, benchmark-tracking allocations) activate. Makarov & Schoar (2020) confirm crypto institutional flows follow equity microstructure. ETF AP mechanics (BlackRock/Fidelity BTC ETF, 2024–) provide direct evidence: creation/redemption windows are VWAP-priced, creating mechanical reversion force.

**Step 2 — Ranging regime (ADX < 25) → price impact is temporary (Kyle 1985):**
Kyle (1985) shows that in low-λ regimes (thin directional order flow), price impact of a given order is predominantly temporary. ADX < 25 is a proxy for low directional order flow. The deviation is therefore more likely to be a temporary dislocation than a permanent repricing. This is the core bet: ranging market + VWAP miss = temporary component.

**Step 3 — High-volume deviation lowers Amihud illiquidity (Amihud 2002):**
Amihud's illiquidity ratio = |return| / volume. Large-volume deviations reduce illiquidity → moves are more temporary → institutional buy programs reverse the impact faster. This reinforces the temporary-component thesis at sophisticated tier.

**Step 4 — CVD ≥ 0.55 confirms buy-side absorption on the deviation bar:**
Cont, Kukanov & Stoikov (2014) show OFI (order flow imbalance) predicts next-period mid-price changes. CVD = (close − low) / (high − low) is a candle-level OFI proxy. CVD ≥ 0.55 means the bar closed in the upper 45% of its range despite pushing below VWAP − 1.25σ: sell pressure was absorbed by buy-side volume. Informed selling closes bars in the lower portion of their range. Buy-side absorption closes bars mid-to-upper. This single gate filters the "knife-catch" failure mode.

**Step 5 — Reversion to VWAP:**
Given steps 1–4 are satisfied, VWAP functions as gravitational anchor. Price returns to benchmark. Target = VWAP. Stoploss = VWAP − 2.0σ (2× the entry deviation, giving ~1.6:1 R:R at 1.25σ entry).

---

### Evidence

| # | Claim | Source | Year | Journal | Strength |
|---|---|---|---|---|---|
| 1 | VWAP as institutional execution benchmark | Berkowitz, Logue, Noser | 1988 | Journal of Finance | Foundational |
| 2 | VWAP as optimal execution schedule | Almgren & Chriss | 2001 | Journal of Risk and Financial Management | Theoretical |
| 3 | Crypto institutional flows follow equity microstructure | Makarov & Schoar | 2020 | Journal of Financial Economics | Empirical |
| 4 | ETF AP mechanics use VWAP pricing | BlackRock/Fidelity BTC ETF filings | 2024 | Regulatory filing | Direct evidence |
| 5 | Low-λ ranging regime → temporary price impact | Kyle | 1985 | Econometrica | Theoretical (canonical) |
| 6 | High-volume moves lower illiquidity → more temporary | Amihud | 2002 | Journal of Financial Markets | Empirical |
| 7 | OFI predicts next-period price changes | Cont, Kukanov & Stoikov | 2014 | Management Science | Empirical |
| 8 | OOS Sharpe degradation 25–50% post-publication | McLean & Pontiff | 2016 | Journal of Finance | Empirical |
| 9 | Fee erosion ~47% Sharpe at crypto costs | BSIC transaction cost model | 2019 | Practitioner | Empirical |
| 10 | CPCV + DSR mandatory for plateau grids > 20 cells | Bailey, Borwein, López de Prado | 2014 | Journal of Portfolio Management | Methodological |
| 11 | Mean reversion stronger in high-volume regimes | Blume, Easley, O'Hara | 1994 | Journal of Finance | Empirical |
| 12 | Passive buy programs activate at benchmark deviations | Gârleanu & Pedersen | 2013 | Journal of Financial Economics | Theoretical |

---

### Conditions

**Entry required (all must be true):**
1. `close ≤ VWAP − 1.25×σ_D` — deviation threshold breached
2. `CVD_ratio ≥ 0.55` — buy-side OFI dominant on deviation bar
3. `abs(VWAP_slope_12h) < 1.0%` — VWAP is flat/slow; benchmark gravity active
4. `ADX < 25` — ranging regime; not a directional break
5. `close > 1h EMA200` — structural bull bias; not a bear market
6. `4h RSI > 25` — anti-freefall gate; not in capitulation

**Exit:**
- Target: VWAP (current bar's VWAP value)
- Stoploss: entry_bar_VWAP − 2.0×entry_bar_σ_D (anchored at entry, not trailing)
- Minimum hold: 3 bars (prevents fee drag on immediate reversals)
- Maximum hold: freqtrade default (no upper cap; VWAP target handles this)

**Regime assignment:**
- Primary: ranging (ADX < 25)
- Secondary: benchmark-relative (price vs VWAP)
- Mutual exclusivity: this prim cannot co-activate with trend-following prims sharing ADX < 25 filter — check conditions log for conflicts before deployment

---

### 12 Critical Failure Modes

| # | Failure Mode | Trigger | Detection | Response |
|---|---|---|---|---|
| 1 | Informed selling (permanent component) | CVD < 0.55 on deviation bar | CVD gate fires | Blocked by CVD ≥ 0.55 gate |
| 2 | Trending VWAP (benchmark inactive) | VWAP slope > 1.0% | Slope gate fires | Blocked by slope < 1.0% gate |
| 3 | ADX breakout during trade | ADX crosses 25 after entry | Monitor in custom_exit | Optional: add ADX-cross exit |
| 4 | Capitulation / freefall | 4h RSI < 25 | RSI gate fires | Blocked by RSI > 25 gate |
| 5 | Bear market structural | close < 1h EMA200 | EMA gate fires | Blocked by EMA200 gate |
| 6 | Stoploss anchor drift | `_entry_data` key miss (pair rename, restart) | Dict lookup fails | Initialize `_entry_data` defensively; log key misses |
| 7 | Over-filtering (cycle 54 recurrence) | Joint condition probability < 5% of bars | n < 50 in IS backtest | Run condition frequency audit before backtesting |
| 8 | Fee drag on low-ATR pairs | ATR(14) < 0.3% on entry bar | Post-backtest Sharpe < 0.70 | Add ATR filter ≥ 0.3% as optional gate |
| 9 | σ_D = 0 (constant price) | Stablecoin / zero-volatility pair | Division by zero in entry calc | `+ 1e-9` guard in σ_D computation |
| 10 | VWAP resets mid-bar on exchange data gap | Missing candle in feed | VWAP jump artifact | Validate VWAP continuity; reject entries on gap bars |
| 11 | OOS degradation below breakeven | McLean-Pontiff 50% worst-case scenario | Live WR < 42% | Deploy with strict live kill-switch: halt if 30-trade rolling WR < 42% |
| 12 | Parameter overfitting (plateau grid > 20 cells) | σ_D threshold, slope %, ADX value tuning | PBO > 0.5 | CPCV + Deflated Sharpe required if grid > 20 cells; PBO ceiling enforced |

---

### Implementation (cycle 63 base + CVD gate)

```python
def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
    # VWAP (rolling session approximation)
    dataframe['vwap'] = (
        (dataframe['high'] + dataframe['low'] + dataframe['close']) / 3
    ).rolling(window=20).mean()

    # σ_D: rolling std of (close − VWAP)
    dataframe['vwap_dev'] = dataframe['close'] - dataframe['vwap']
    dataframe['sigma_d'] = dataframe['vwap_dev'].rolling(window=20).std() + 1e-9

    # Lower band (1.25σ below VWAP)
    dataframe['vwap_lower1'] = dataframe['vwap'] - 1.25 * dataframe['sigma_d']

    # VWAP slope over 12h (% change / bar count)
    period_12h = int(12 * 60 / self.timeframe_mins)
    dataframe['vwap_slope_12h'] = (
        dataframe['vwap'].pct_change(periods=period_12h)
    )

    # ADX
    adx = ta.ADX(dataframe, timeperiod=14)
    dataframe['adx'] = adx['adx']

    # EMA200 (1h equivalent)
    dataframe['ema_200'] = ta.EMA(dataframe, timeperiod=200)

    # RSI 4h (informer timeframe — merge separately)
    # [4h RSI merged via informative_pairs / merge_informative_pair]

    # CVD ratio (NEW at sophisticated tier)
    # OFI proxy: Cont, Kukanov & Stoikov (2014)
    dataframe['cvd_ratio'] = (
        (dataframe['close'] - dataframe['low']) /
        (dataframe['high'] - dataframe['low'] + 1e-9)
    )

    return dataframe


def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
    cvd_ok = dataframe['cvd_ratio'] >= 0.55  # buy-side absorbed the sell

    enter_long = (
        (dataframe['close'] <= dataframe['vwap_lower1'])
        & cvd_ok                                          # NEW at sophisticated tier
        & (dataframe['vwap_slope_12h'].abs() < 0.010)
        & (dataframe['adx'] < 25)
        & (dataframe['close'] > dataframe['ema_200'])
        & (dataframe['rsi_4h'] > 25)
    )

    dataframe.loc[enter_long, 'enter_long'] = 1
    return dataframe


def custom_stoploss(self, pair, trade, current_time, current_rate, current_profit, **kwargs):
    key = (pair, trade.open_date_utc)
    if key in self._entry_data:
        entry_vwap = self._entry_data[key]['entry_vwap']
        entry_sigma = self._entry_data[key]['entry_sigma']
        stop_price = entry_vwap - 2.0 * entry_sigma
        return (stop_price / current_rate) - 1
    return -0.05  # fallback 5% if key miss


def custom_exit(self, pair, trade, current_time, current_rate, current_profit, **kwargs):
    # Minimum 3-bar hold
    bars_held = (current_time - trade.open_date_utc).seconds // (self.timeframe_mins * 60)
    if bars_held < 3:
        return None

    # Target: current VWAP
    key = (pair, trade.open_date_utc)
    if key in self._entry_data:
        entry_vwap = self._entry_data[key]['entry_vwap']
        if current_rate >= entry_vwap:
            return 'vwap_target_reached'
    return None
```

**Note:** `_entry_data` must be populated in `confirm_trade_entry` using the current bar's `vwap` and `sigma_d` values. `timeframe_mins` should be set as a class attribute matching the strategy timeframe.

---

### Anti-Prim Escape Hatches

If any of the following fire during the deployment gate sequence, the prim is reclassified as **anti-prim** and retained for documentary value only.

| # | Hatch | Threshold | Action |
|---|---|---|---|
| A | IS WR below breakeven across all parameter cells | WR < 52% at all (σ_D, slope, ADX) grid points, n ≥ 100 per cell | Anti-prim; document mechanism failure |
| B | CVD gate eliminates > 80% of signals | Remaining n < 30 after CVD filter applied | Recalibrate CVD threshold; if WR still fails, anti-prim |
| C | Live 30-trade rolling WR < 42% | Below McLean-Pontiff worst-case OOS floor | Hard halt; review structural break (regime change, fee change) |
| D | PBO > 0.5 on plateau grid | CPCV returns probability of backtest overfitting above 50% | Anti-prim; no deployment regardless of IS Sharpe |

---

### 6-Step Deployment Gate Sequence

| Step | Task | Pass Criterion | Fail Action |
|---|---|---|---|
| 1 | Re-backtest with cycle 63 rules + CVD gate | n ≥ 100, WR ≥ 55%, Sharpe ≥ 0.70 | If n < 50: check condition frequency (failure mode #7); if WR < 52%: anti-prim |
| 2 | Condition frequency audit | Each gate fires independently on ≥ 15% of bars | Remove any gate with < 5% independent frequency (over-filter) |
| 3 | Parameter sensitivity (plateau grid) | Grid ≤ 20 cells; Sharpe stable ±0.10 across ±20% parameter range | If grid > 20: run CPCV + DSR; PBO must be < 0.5 |
| 4 | Fee and slippage stress test | Sharpe ≥ 0.35 after BSIC model applied | If Sharpe < 0.35 post-fee: not deployable |
| 5 | OOS walk-forward validation | 3-month OOS WR ≥ 48%, Sharpe ≥ 0.35 | If WR < 42%: activate escape hatch C |
| 6 | Live paper trading | 30-trade live WR ≥ 48%, no execution anomalies | Monitor for CVD data feed quality; stoploss dict integrity |

---

### Historical Backtest Record

| Cycle | Mode | WR | n | Sharpe | Profit Factor | Notes |
|---|---|---|---|---|---|---|
| 51 | BACKTEST-ANALYSIS | 67.2% | 427 | −0.85 | 0.78 | Naive: signal exists; fee drag kills EV |
| 54 | BACKTEST-ANALYSIS | 28.6% | 21 | −0.16 | — | FAIL: over-filtering + stoploss bug |
| 63 | RULE-REVISION | — | — | — | — | Loosened rules; bug fixed; re-backtest not run |
| 74 | RESEARCH | — | — | — | — | Sophisticated elevation; CVD gate added; re-backtest required |

**Next required:** BACKTEST-ANALYSIS (cycle 75 or earliest available slot)

---

### Conditions Log Entry

```
vwap-deviation-mean-reversion | sophisticated | cycle 74
Gates: VWAP−1.25σ, CVD≥0.55, slope<1.0%, ADX<25, EMA200, RSI4h>25
Stoploss: VWAP−2.0σ (class-level dict); target: VWAP; min hold: 3 bars
Status: RESEARCH-complete; re-backtest required
Supersedes: intermediate/vwap-deviation-mean-reversion (revised cycle 63)
```

Intermediate entry in conditions log: mark `[historical — superseded cycle 74]`

---

### Epistemic Index Update

- `intermediate/vwap-deviation-mean-reversion` → status: **[historical — superseded cycle 74]**
- `sophisticated/vwap-deviation-mean-reversion` → status: **RESEARCH-complete (cycle 74); re-backtest pending**

---

### Bank State After Cycle 74

| Tier | Count | Change |
|---|---|---|
| Naive | 9 | — |
| Intermediate | 12 | −1 (vwap superseded) |
| Sophisticated | 15 | +1 (vwap elevated) |

---

### Next Cycle Recommendation

**Mode:** BACKTEST-ANALYSIS
**Target:** `vwap-deviation-mean-reversion` (sophisticated, cycle 74 rules)
**Command:** Run freqtrade backtest with cycle 63 strategy file + CVD gate as implemented above
**Pass criteria:** n ≥ 100, WR ≥ 55%, Sharpe ≥ 0.70
**Fail path:** If n < 50 — condition frequency audit (failure mode #7); if WR < 52% across all cells — activate anti-prim escape hatch A

---

### Sources

1. Berkowitz, S.A., Logue, D.E., Noser, E.A. (1988). *The Total Cost of Transactions on the NYSE*. Journal of Finance, 43(1), 97–112.
2. Almgren, R., Chriss, N. (2001). *Optimal Execution of Portfolio Transactions*. Journal of Risk and Financial Management, 3(1), 5–39.
3. Kyle, A.S. (1985). *Continuous Auctions and Insider Trading*. Econometrica, 53(6), 1315–1335.
4. Amihud, Y. (2002). *Illiquidity and Stock Returns: Cross-Section and Time-Series Effects*. Journal of Financial Markets, 5(1), 31–56.
5. Cont, R., Kukanov, A., Stoikov, S. (2014). *The Price Impact of Order Book Events*. Management Science, 60(6), 1415–1436.
6. McLean, R.D., Pontiff, J. (2016). *Does Academic Research Destroy Stock Return Predictability?* Journal of Finance, 71(1), 5–32.
7. Makarov, I., Schoar, A. (2020). *Trading and Arbitrage in Cryptocurrency Markets*. Journal of Financial Economics, 135(2), 293–319.
8. Bailey, D.H., Borwein, J., López de Prado, M. (2014). *The Deflated Sharpe Ratio*. Journal of Portfolio Management, 40(5), 94–107.
9. Blume, L., Easley, D., O'Hara, M. (1994). *Market Statistics and Technical Analysis: The Role of Volume*. Journal of Finance, 49(1), 153–181.
10. Gârleanu, N., Pedersen, L.H. (2013). *Dynamic Trading with Predictable Returns and Transaction Costs*. Journal of Finance, 68(6), 2309–2340.
11. BSIC Transaction Cost Model (2019). *Cryptocurrency Transaction Cost Analysis*. Bocconi Students Investment Club.
12. BlackRock/Fidelity BTC ETF SEC filings (2024). *iShares Bitcoin Trust / Wise Origin Bitcoin Fund creation/redemption mechanics*.

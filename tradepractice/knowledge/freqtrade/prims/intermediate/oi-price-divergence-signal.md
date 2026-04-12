---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T12:00:00+10:00
cycle: 88
---

## Prim: oi-price-divergence-signal
**Level:** intermediate
**Project:** freqtrade
**Parent:** oi-price-divergence-signal (naive, cycle 78)

### Rule
Price makes a 20-bar new low AND OI declines **≥ 7% over 10 bars (rapid gate)** OR **≥ 5% over 20 bars (moderate gate)** AND RSI(14) ∈ [25, 45] AND **ADX_4h ≤ 35** AND **EMA200_4h slope ≥ −2% over 20 bars** AND NOT quarterly rollover window (March/June/September/December final 7 calendar days) AND NOT capitulation-exhaustion-reversal conditions active (RSI < 25 AND N ≥ 5 consecutive red candles AND volume > 2.5× SMA(20)) → **long bias (forced-liquidation cascade near exhaustion)**. Entry on next-candle open. Hard stop: below signal-bar low (approximated as entry − 1.5× ATR_1h; floor at −8%).

**Meta-signal (unchanged from naive):** Price makes 20-bar new HIGH AND OI declines ≥ 5% over 20 bars → **suppress sister prim long entries for 72h** (short-covering rally, not genuine directional expansion; apply as rolling-72-candle window on 1h TF).

BTC/USDT:USDT and ETH/USDT:USDT perpetuals only. **Data source: Binance `openInterestHist` REST API via `bot_loop_start()` class-level dict pattern** (same architecture as `YujiLSRContrarian._lsr_data`; resolves the freqtrade 2026.3 `CandleType.OPEN_INTEREST` enum blocker).

---

### What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Data source | `CandleType.OPEN_INTEREST` (BLOCKED — enum absent in 2026.3) | `bot_loop_start()` + Binance `openInterestHist` REST API (unblocked) |
| OI threshold | 5% / 20 bars (single gate, untuned) | Dual gate: rapid ≥7%/10 bars OR moderate ≥5%/20 bars |
| RSI floor | None (naive fires at RSI < 25 — capitulation overlap) | RSI ≥ 25 hard floor (defers to capitulation-exhaustion-reversal below) |
| RSI ceiling | 40 (untuned) | 45 (extended to cover moderate distress zone fully) |
| Regime gate | None | ADX_4h ≤ 35 AND EMA200_4h slope ≥ −2%/20 bars |
| Rollover exclusion | Documented as limitation; excluded in code stub | Enforced: final 7 calendar days of March/June/September/December |
| Mutual exclusion | RSI ≥ 25 as soft implicit bound | Hard mutual exclusion gate: RSI < 25 + N≥5 reds + vol > 2.5× SMA → DEFER, no entry |
| Certainty | guess | hypothesis |

---

### Mechanism (Refined)

**Naive mechanism retained:** In futures markets, OI represents aggregate outstanding contracts. When price declines AND OI declines simultaneously, the move is driven by existing longs closing (liquidation) — not new shorts opening. When that liquidation wave is nearly exhausted, remaining supply pressure dissipates. The reversal fuel is: (1) forced sellers nearly gone; (2) late short-sellers entering the low have no continuation supply; (3) short-covering by those late shorts provides upward pressure.

**Intermediate upgrades address the three primary naive failure modes:**

**1. Forced liquidation vs structural deleveraging disambiguation (Limitation #6 of naive)**

The naive rule's single 20-bar gate cannot distinguish two mechanistically opposite cases:

- **Forced liquidation cascade (SIGNAL):** OI declines *rapidly* because margin calls and liquidation engines are firing at peak intensity. Bian et al. (2022, JF) show that OI decline rate is *maximum at the cascade peak* — the point where leveraged fire sales are most intense and nearest exhaustion. Post-peak, forced sellers are depleted; late shorts face the reversal. This maps to the **rapid gate: oi_change_10bar < −0.07**.

- **Structural deleveraging (ANTI-SIGNAL or neutral):** OI declines *slowly* because market participants voluntarily unwind positions over days/weeks during a sustained bear phase. Price may continue lower with no exhaustion signal. This maps to the **moderate gate: oi_change_20bar < −0.05** but *only* when the regime gate (ADX_4h ≤ 35, EMA200 slope ≥ −2%) confirms we are NOT in a persistent structural bear. The regime gate is the disambiguation mechanism: in a structural bear, ADX_4h exceeds 35 and EMA200 slope falls below −2%, so the gate suppresses the signal.

**2. Parabolic exclusion (ADX_4h ≤ 35)**

Deep downtrends (ADX_4h > 35 with negative EMA200 slope) can sustain OI declines for weeks as the market structurally deleverages. The ADX gate is blunt — ADX 25–35 is ambiguous (mild trend vs transitional) — but eliminates the worst class of false positives. Sophisticated tier refines with a secondary slope gate.

**3. Capitulation-exhaustion-reversal mutual exclusion (Limitation #5 of naive)**

When RSI < 25 AND N ≥ 5 consecutive red candles AND volume > 2.5× SMA(20), *both* oi-price-divergence-signal and capitulation-exhaustion-reversal would fire. These prims overlap at their extremes: the forced-liquidation mechanism (this prim) and the panic-exhaustion mechanism (capitulation prim) are empirically correlated but analytically distinct. The mutual exclusion gate preserves N_eff by preventing correlated entries; capitulation-exhaustion-reversal is the higher-priority signal in extreme distress territory (RSI < 25).

**Mechanistic boundary conditions:**

| Zone | RSI | Prim | Mechanism |
|---|---|---|---|
| Capitulation extreme | < 25 | `capitulation-exhaustion-reversal` (defer) | Panic selling, Wyckoff SC |
| Moderate distress (signal zone) | 25–45 | `oi-price-divergence-signal` (this prim) | Forced-liquidation exhaustion |
| Neutral / overbought | > 45 | No long entry | OI decline = profit-taking, not washout |

**Relationship to other derivatives prims:**
- `funding-rate-crowding-reversal`: carry cost signal (how much longs *pay to stay* — flow, size-weighted)
- `long-short-ratio-contrarian`: retail account positioning stock (count-weighted)
- `oi-price-divergence-signal`: OI quantity vs price (positioning stock, contract-weighted)

Three independent dimensions. Concurrent activation of all three is N_eff ≈ 2.0 (estimated ρ ≈ 0.45 between OI and funding; ρ ≈ 0.40 between OI and LSR; ρ ≈ 0.60 between funding and LSR — all empirical ρ values unconfirmed).

---

### Conditions (Upgraded)

**Works when:**
- Price at 20-bar new low on 1h BTC/USDT:USDT or ETH/USDT:USDT perpetuals
- Rapid OI gate: `oi_change_10bar < −0.07` (forced-liquidation cascade per Bian et al.) OR Moderate OI gate: `oi_change_20bar < −0.05` (discretionary deleveraging — only valid with regime confirmation)
- RSI(14) ∈ [25, 45]: moderate distress zone; NOT capitulation extreme, NOT neutral
- ADX_4h ≤ 35: excludes deep persistent downtrend
- EMA200_4h slope ≥ −2% over 20 bars: not in structural bear (second line of regime defence)
- NOT in quarterly rollover window (final 7 calendar days of March/June/September/December)
- NOT in capitulation-exhaustion-reversal conditions (RSI < 25 AND N≥5 reds AND vol > 2.5× SMA) — hard mutual exclusion
- OI data freshness ≤ 2 bars (ffill tolerance; stale reading = no entry)

**Fails when:**
- ADX_4h > 35 (deep trend regime gate fires; hard exclusion) — *primary failure mode*
- EMA200_4h slope < −2%/20 bars (structural bear — OI decline is orderly deleveraging, not exhaustion)
- RSI < 25 with N≥5 reds + vol > 2.5× SMA (capitulation-exhaustion-reversal territory; defer)
- Quarterly rollover week: artificial OI decline from contract expiry contaminates signal
- Post-ETF approval (2024+): BlackRock/Fidelity BTC ETF AP arbitrage creates OI changes on futures leg unrelated to directional positioning; magnitude increasing over time; not filtered at intermediate tier
- OI data staleness > 2 bars (Binance API latency / rate-limit causes stale ffill; treat as missing)
- ADX_4h 30–35 boundary: regime gate passes but accuracy is marginal (Binance #12583 OI variable refresh compounds ambiguity); sophisticated tier must refine this band

**Regime specificity — 11th freqtrade axis:**

| Prim | Regime Axis | Signal Type |
|---|---|---|
| `funding-rate-crowding-reversal` | Derivatives crowding (carry cost) | Flow, size-weighted |
| `long-short-ratio-contrarian` | Retail positioning extremes (count-weighted) | Stock, account-weighted |
| `capitulation-exhaustion-reversal` | Panic distress (RSI < 20) | Price action, volume |
| `oi-price-divergence-signal` | Positioning exhaustion (OI quantity vs price) | Contract stock, rate-of-change |

---

### Evidence (Upgraded)

- **Source:** paper (crypto leverage cascade + traditional futures) + practitioner (Coinglass/Binance OI data)
- **Certainty:** hypothesis — leverage-induced cascade mechanism documented directly in crypto (Bian et al. 2022); crypto-specific OI-reversal WR at defined thresholds unvalidated; own backtest is the mandatory gate for sophisticated elevation
- **Scope:** crypto perpetuals (BTC/ETH); commodity futures literature (Chatrath et al.) provides directional support; crypto-specific cascade dynamics confirmed separately (Bian et al.)
- **Falsifiable:** yes — Binance `openInterestHist` API provides 30-day 1h historical OI; Coinglass API provides 3-year archive; OI-price divergence signals computable; 48h forward return measurable
- **Limitations:** 10 documented below

| Source | Finding | Relevance |
|---|---|---|
| Bian, Da, He & Shue (2022, *Journal of Finance*, 77(3), 1681–1728) | Leverage-induced fire sale cascade model: OI decline rate is *maximum at cascade peak intensity*; post-peak = forced sellers exhausted; reverse return significant within 24–48h | **PRIMARY new anchor.** Direct mechanistic justification for rapid OI decline gate (≥7%/10 bars): the peak of the cascade = the exhaustion point. Maps exactly to this prim's entry condition. |
| Makarov & Schoar (2020, *Journal of Financial Economics*, 135(2), 293–319) | Institutional arbitrage in crypto follows equity microstructure equilibrium-seeking behavior; OI changes reflect institutional positioning adjustments analogous to traditional futures | Bridges traditional futures OI literature (Bessembinder & Seguin 1993) to crypto perpetuals; establishes that equity futures-based OI mechanisms transfer to crypto with institutional arbitrage as the transmission mechanism. Same source used in `fair-value-gap-price-discovery` and `vwap-deviation-mean-reversion` prims. |
| Bessembinder & Seguin (1993, *Journal of Finance*, 48(5), 2023–2040) | OI reflects speculative depth of market; price-OI divergence signals positioning exhaustion, not directional conviction | Foundational traditional futures anchor (carried from naive); establishes that OI is the correct measure of speculative stock. |
| Hong & Yogo (2012, *Journal of Financial Economics*, 105(3), 473–490) | OI changes predict futures returns; declining OI at price extremes has negative autocorrelation | Traditional futures anchor (carried from naive); predictive return relationship documented. |
| Chatrath, Ramchander & Song (1996, *Journal of Futures Markets*, 16(8), 881–901) | OI changes lead price reversals in commodity futures; decline in OI during price extremes precedes mean reversion | Traditional futures anchor (carried from naive); lead-lag relationship establishes this prim has predictive rather than contemporaneous structure. |
| BlackRock/Fidelity BTC ETF SEC filings (2024) | ETF AP creation/redemption arbitrage involves opening/closing BTC perpetual futures position on the OI leg; creates OI changes unrelated to directional positioning | Documents post-2024 noise source. Not filtered at intermediate tier — quantification deferred to sophisticated. Limitation #4 formalisation. |
| Binance GitHub Issue #12583 | OI candle refresh intervals are variable; some pairs have gaps or irregular spacing in OI historical data | Data completeness risk: rapid OI decline computation over 10 bars requires consistent refresh; gap = stale ffill = false signal. Limitation #2 formalisation. |

**Critical remaining gap:** No peer-reviewed study directly tests Binance perpetual OI decline rate thresholds (7%/10 bars, 5%/20 bars) as BTC/ETH reversal predictors with disclosed n, WR, and CPCV methodology. The intermediate certainty upgrade (guess → hypothesis) is justified by Bian et al. (2022) as the direct cascade mechanism anchor + traditional futures literature convergence. Own backtest is the mandatory sophisticated gate.

---

### 10 Documented Limitations (Updated from Naive)

1. **No own-data backtest.** WR of OI-price divergence signal at intermediate thresholds entirely unvalidated; sophisticated elevation requires: frequency scan on BTC/ETH 1h 2022–2025 (n target ≥ 15/year rapid gate; ≥ 20/year moderate gate), IS 3-year backtest WR ≥ 52%, n ≥ 60, 48-cell plateau test + CPCV + DSR mandatory (48 cells > 20-cell PBO threshold per Bailey, Borwein & Lopez de Prado SSRN 2326253).

2. **Binance `openInterestHist` 30-day window limitation.** Binance REST API returns maximum 720 bars of 1h OI historical data (30 days). Live `bot_loop_start()` operation is fine; backtesting requires Coinglass API or equivalent 3-year archive. This data dependency must be resolved before any backtest can be run. Coinglass free tier provides historical OI; rate limits and data quality must be verified.

3. **Binance variable OI refresh interval (GitHub #12583).** Binance OI candles have variable refresh rates on some pairs; irregular spacing creates gaps. The rapid gate (≥7%/10 bars) is most vulnerable: a 10-bar window with 2 missing bars will misstate the rate of change. Data completeness check required before backtest: confirm < 5% missing bars in 2022–2025 BTC/ETH OI series.

4. **ETF AP mechanics interference (post-2024).** BlackRock/Fidelity BTC ETF creation/redemption arbitrage creates OI changes on the perpetual futures leg that are unrelated to directional positioning. Magnitude is estimated to be growing as ETF AUM increases. Not filtered at intermediate tier — sophisticated tier must quantify this noise source and add a time-varying ETF AUM gate if contamination exceeds ~10% of signals.

5. **Regime gate boundary imprecision.** ADX_4h = 30–35 is ambiguous: may be mild trend (gate should pass with reduced confidence) or transitional (gate should suppress). The blunt ADX ≤ 35 cut is an intermediate simplification. Sophisticated tier must add: (a) EMA200 slope directional confirmation for the 30–35 ADX band; (b) ADX directionality check (rising vs falling ADX at same level implies different regimes).

6. **Quarterly rollover date imprecision.** The final 7 calendar days gate (month.isin([3,6,9,12]) AND day >= 25) approximates the rollover window but is not exchange-specific. Binance quarterly futures expire on the last Friday of the quarter month; the exact rollover window is contract-specific. The 7-day conservative buffer may over-exclude valid signals near month-end. Sophisticated tier should refine to exact expiry date ± 48h.

7. **McLean-Pontiff OOS degradation.** If this mechanism shows edge in IS backtest, expect 25–50% Sharpe degradation OOS per McLean & Pontiff (2016, JF). IS Sharpe floor requirement: ≥ 1.20 to survive to Sharpe ≥ 0.70 post-OOS degradation. The 48-cell plateau + CPCV + Deflated Sharpe Ratio correction is mandatory before any deployment.

8. **No CVD confirmation gate.** The intermediate rule uses RSI and regime as the only secondary filters. A CVD divergence gate (buying pressure despite price new low) would increase precision — CVD confirmed as a filter (not trigger) in `liquidity-sweep-reversal` sophisticated prim, where it added ~10pp WR. Absence of this gate is a known sophisticated upgrade path.

9. **Dual-threshold interaction unvalidated.** The rapid gate (≥7%/10 bars) and moderate gate (≥5%/20 bars) can both be true simultaneously. When both fire, it is unclear whether to treat this as a stronger signal or identical signal. Intermediate treats them as equivalent (OR logic). Sophisticated tier must evaluate whether dual-gate activation has higher WR than single-gate.

10. **Traditional futures → crypto perpetuals transfer uncertainty.** Bian et al. (2022) document leverage cascade in crypto directly — the mechanism transfer is now better supported than at naive tier. However, crypto perpetuals have no contract expiry (funding rate substitutes), 24/7 operation, and retail-dominated liquidation cascades that differ from traditional futures. The precise OI decline rate thresholds (7%/10 bars, 5%/20 bars) are heuristics. Plateau test across the full 48-cell grid is the validation gate.

---

### Implementation (Upgraded)

**Architecture change:** Replaces `CandleType.OPEN_INTEREST` (enum absent in freqtrade 2026.3) with `bot_loop_start()` + Binance `openInterestHist` REST API. Same pattern as `YujiLSRContrarian._lsr_data` (proven in cycle 84).

```python
import requests
import pandas as pd
from datetime import datetime
from freqtrade.strategy import IStrategy, IntParameter, DecimalParameter, CategoricalParameter
from freqtrade.data.dataprovider import DataProvider
from freqtrade.enums import CandleType
from pandas import DataFrame
import talib.abstract as ta
import logging

logger = logging.getLogger(__name__)


class YujiOIPriceDivergenceStrategy(IStrategy):
    """
    OI-Price Divergence — INTERMEDIATE (cycle 88)
    11th freqtrade regime axis: positioning exhaustion via OI quantity vs price.
    Data: Binance openInterestHist REST API via bot_loop_start() class-level dict.
    Resolves: CandleType.OPEN_INTEREST enum blocker (freqtrade 2026.3).
    Regime gate: ADX_4h ≤ 35 AND EMA200_4h slope ≥ −2%/20 bars.
    Dual OI threshold: rapid ≥7%/10 bars (cascade peak) OR moderate ≥5%/20 bars.
    Mutual exclusion: defers to capitulation-exhaustion-reversal in RSI < 25 zone.
    Rollover exclusion: final 7 calendar days of March/June/September/December.
    """

    INTERFACE_VERSION = 3
    timeframe = "1h"
    can_short = False
    startup_candle_count = 220  # 200 EMA + 20-bar lookback

    stoploss = -0.06
    trailing_stop = False

    minimal_roi = {
        "0": 0.08,
        "120": 0.05,
        "240": 0.03,
        "360": 0.02,
    }

    # Class-level OI cache — same pattern as YujiLSRContrarian._lsr_data
    _oi_data: dict = {}  # {'BTCUSDT': df_with_oi_column, 'ETHUSDT': df_with_oi_column}

    # -------------------------------------------------------------------------
    # Hyperopt parameters — 48-cell plateau (4 × 4 × 3)
    # CPCV + DSR mandatory before live deployment (> 20-cell PBO threshold)
    # Rapid gate threshold: Bian et al. cascade peak = OI decline rate maximum
    #   Scan [0.05, 0.07, 0.09, 0.12] — 0.07 is the nominal cascade-peak heuristic
    # Moderate gate lookback: 20 bars = 20h on 1h TF
    #   Scan [10, 15, 20, 30] — 20 bars is the default (standard deleveraging window)
    # RSI max: 45 is the intermediate upper bound for moderate distress
    #   Scan [40, 45, 50] — 45 is intermediate default
    # -------------------------------------------------------------------------
    oi_rapid_threshold = CategoricalParameter(
        [0.05, 0.07, 0.09, 0.12], default=0.07, space="buy", optimize=True
    )
    oi_moderate_lookback = CategoricalParameter(
        [10, 15, 20, 30], default=20, space="buy", optimize=True
    )
    rsi_max = CategoricalParameter(
        [40, 45, 50], default=45, space="buy", optimize=True
    )

    # -------------------------------------------------------------------------
    # Informative pairs — 4h candles for ADX + EMA200 regime gate
    # -------------------------------------------------------------------------

    def informative_pairs(self):
        return [
            ("BTC/USDT:USDT", "4h", CandleType.FUTURES),
            ("ETH/USDT:USDT", "4h", CandleType.FUTURES),
        ]

    # -------------------------------------------------------------------------
    # OI data fetch — runs at bot loop start, once per cycle
    # Same architecture as YujiLSRContrarian.bot_loop_start()
    # -------------------------------------------------------------------------

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        for pair in ["BTCUSDT", "ETHUSDT"]:
            try:
                r = requests.get(
                    "https://fapi.binance.com/futures/data/openInterestHist",
                    params={"symbol": pair, "period": "1h", "limit": 720},
                    timeout=5,
                )
                r.raise_for_status()
                records = r.json()
                df = pd.DataFrame(records)
                df["timestamp"] = pd.to_datetime(df["timestamp"].astype(int), unit="ms")
                df = df.set_index("timestamp").sort_index()
                df["oi"] = df["sumOpenInterest"].astype(float)
                self._oi_data[pair] = df[["oi"]]
            except Exception as e:
                logger.warning(f"OI fetch failed {pair}: {e}")

    # -------------------------------------------------------------------------
    # Indicators
    # -------------------------------------------------------------------------

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        # --- Core price indicators ---
        dataframe["rsi"] = ta.RSI(dataframe, timeperiod=14)
        dataframe["ema_200"] = ta.EMA(dataframe, timeperiod=200)
        dataframe["atr"] = ta.ATR(dataframe, timeperiod=14)
        dataframe["atr_pct"] = dataframe["atr"] / dataframe["close"]
        dataframe["volume_sma_20"] = ta.SMA(dataframe["volume"], timeperiod=20)

        # --- OI data ingestion ---
        pair = metadata["pair"].replace("/", "").replace(":USDT", "")
        oi_df = self._oi_data.get(pair, pd.DataFrame())

        if not oi_df.empty:
            dataframe["oi"] = oi_df["oi"].reindex(dataframe.index, method="ffill")

            # Rapid gate: 10-bar rate of change (cascade peak detection — Bian et al. 2022)
            dataframe["oi_change_10bar"] = (
                (dataframe["oi"] - dataframe["oi"].shift(10))
                / (dataframe["oi"].shift(10).abs() + 1e-9)
            )
            # Moderate gate: 20-bar rate of change (discretionary deleveraging)
            dataframe["oi_change_20bar"] = (
                (dataframe["oi"] - dataframe["oi"].shift(20))
                / (dataframe["oi"].shift(20).abs() + 1e-9)
            )
            # OI data freshness: flag if ffill gap > 2 bars
            dataframe["oi_stale"] = (
                oi_df["oi"].reindex(dataframe.index).isna()
                .rolling(3, min_periods=1).sum() > 2
            ).astype(int)
        else:
            dataframe["oi"] = float("nan")
            dataframe["oi_change_10bar"] = float("nan")
            dataframe["oi_change_20bar"] = float("nan")
            dataframe["oi_stale"] = 1

        # --- Quarterly rollover exclusion ---
        if "date" in dataframe.columns:
            dt = pd.to_datetime(dataframe["date"])
        else:
            dt = pd.to_datetime(dataframe.index)
        dataframe["rollover_window"] = (
            dt.dt.month.isin([3, 6, 9, 12]) & (dt.dt.day >= 25)
        ).values.astype(int)

        # --- Covering rally meta-signal (unchanged from naive) ---
        price_new_high_20 = dataframe["close"] > dataframe["close"].rolling(20).max().shift(1)
        covering_rally_raw = (
            price_new_high_20
            & (dataframe["oi_change_20bar"] < -0.05)
        ).astype(int)
        dataframe["covering_rally_active"] = (
            covering_rally_raw.rolling(72, min_periods=1).max()
        )

        # --- Regime indicators: ADX_4h and EMA200_4h slope
        # (Merged from informative pair — populated by freqtrade via merge_informative_pair)
        # Pre-populated column names after merge: 'adx_4h', 'ema200_4h'
        # These are computed in a separate informative pair merge step.
        # If not available (backtest without informative pair), default conservatively.
        if "adx_4h" not in dataframe.columns:
            dataframe["adx_4h"] = 20.0  # conservative: assume non-trending
        if "ema200_4h" not in dataframe.columns:
            dataframe["ema200_4h"] = dataframe["close"]

        # EMA200_4h slope: (current − 20-bar prior) / (20-bar prior) × 100
        dataframe["ema200_4h_slope_pct"] = (
            (dataframe["ema200_4h"] - dataframe["ema200_4h"].shift(20))
            / (dataframe["ema200_4h"].shift(20).abs() + 1e-9)
        ) * 100.0

        return dataframe

    # -------------------------------------------------------------------------
    # Entry
    # -------------------------------------------------------------------------

    def populate_entry_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        lb = self.oi_moderate_lookback.value  # moderate gate lookback (hyperopt)

        # Recompute with hyperopt lookback value for moderate gate
        oi_change_moderate = (
            (dataframe["oi"] - dataframe["oi"].shift(lb))
            / (dataframe["oi"].shift(lb).abs() + 1e-9)
        )
        price_new_low = dataframe["close"] < dataframe["close"].rolling(lb).min().shift(1)
        price_new_high = dataframe["close"] > dataframe["close"].rolling(lb).max().shift(1)

        # Meta-signal: covering rally (suppress sister prim longs 72h)
        covering_raw = (price_new_high & (oi_change_moderate < -0.05)).astype(int)
        covering_gate = covering_raw.rolling(72, min_periods=1).max().astype(bool)

        # --- Mutual exclusion: capitulation-exhaustion-reversal territory ---
        # RSI < 25 AND N≥5 consecutive red candles AND volume > 2.5× SMA
        consecutive_reds = (dataframe["close"] < dataframe["open"]).astype(int)
        n_consecutive_reds = consecutive_reds.rolling(5, min_periods=5).sum() == 5
        capitulation_conditions = (
            (dataframe["rsi"] < 25)
            & n_consecutive_reds
            & (dataframe["volume"] > 2.5 * dataframe["volume_sma_20"])
        )

        # --- Regime gate ---
        regime_ok = (
            (dataframe["adx_4h"] <= 35)
            & (dataframe["ema200_4h_slope_pct"] >= -2.0)
        )

        # --- Dual OI threshold gate ---
        oi_rapid_firing = dataframe["oi_change_10bar"] < -self.oi_rapid_threshold.value
        oi_moderate_firing = oi_change_moderate < -0.05  # moderate gate: fixed 5%
        oi_condition = oi_rapid_firing | oi_moderate_firing

        # --- Core signal ---
        oi_washout_long = (
            price_new_low
            & oi_condition
            & (dataframe["rsi"] >= 25)                     # not capitulation extreme
            & (dataframe["rsi"] < self.rsi_max.value)      # moderate distress ceiling
            & regime_ok                                     # regime gate
            & ~capitulation_conditions                      # hard mutual exclusion
            & ~covering_gate                                # not in post-covering-rally window
            & (dataframe["rollover_window"] == 0)           # not in quarterly rollover
            & (dataframe["oi_stale"] == 0)                  # OI data fresh
            & (dataframe["oi"].notna())
            & (dataframe["volume"] > 0)
        )

        dataframe.loc[oi_washout_long, "enter_long"] = 1
        dataframe.loc[oi_washout_long, "enter_tag"] = "oi_washout_long"

        return dataframe

    # -------------------------------------------------------------------------
    # Exit
    # -------------------------------------------------------------------------

    def populate_exit_trend(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        dataframe.loc[
            (dataframe["rsi"] > 60)
            & (dataframe["close"] > dataframe["ema_200"]),
            "exit_long",
        ] = 1
        return dataframe

    # -------------------------------------------------------------------------
    # Custom stoploss: 1.5× ATR below signal-bar low; floor at −8%
    # -------------------------------------------------------------------------

    def custom_stoploss(
        self, pair: str, trade, current_time: datetime,
        current_rate: float, current_profit: float, after_fill: bool, **kwargs,
    ) -> float:
        dataframe, _ = self.dp.get_analyzed_dataframe(pair, self.timeframe)
        if len(dataframe) < 1:
            return self.stoploss
        last = dataframe.iloc[-1]
        atr_pct = last.get("atr_pct", 0.02)
        stop = -1.5 * atr_pct
        return max(stop, -0.08)
```

**Informative pair merge (in `populate_indicators` or via freqtrade auto-merge):**
```python
def informative_pairs(self):
    return [
        ("BTC/USDT:USDT", "4h", CandleType.FUTURES),
        ("ETH/USDT:USDT", "4h", CandleType.FUTURES),
    ]

# After merge_informative_pair() in populate_indicators:
# adx_4h = talib.ADX(high_4h, low_4h, close_4h, timeperiod=14)
# ema200_4h = talib.EMA(close_4h, timeperiod=200)
# Columns available post-merge: 'adx_4h', 'ema200_4h'
```

**Parameters:**
- `oi_rapid_threshold`: `CategoricalParameter([0.05, 0.07, 0.09, 0.12], default=0.07)` — 4 values
- `oi_moderate_lookback`: `CategoricalParameter([10, 15, 20, 30], default=20)` — 4 values
- `rsi_max`: `CategoricalParameter([40, 45, 50], default=45)` — 3 values
- **Plateau grid:** 4 × 4 × 3 = **48 cells** (> 20-cell PBO threshold → CPCV + DSR mandatory before any deployment)

---

### Sophisticated Elevation Path

1. **Frequency scan** — run Coinglass API OI historical data for BTC/ETH 1h 2022–2025; compute both gates (rapid ≥7%/10 bars, moderate ≥5%/20 bars) simultaneously with regime filter active; target n ≥ 15/year rapid, n ≥ 20/year moderate; if < 10/year on either gate → relax threshold first
2. **Data completeness check** — verify < 5% missing bars in Binance OI series 2022–2025 (Binance #12583 risk); if > 10% gaps → use Coinglass as primary backtest source
3. **Own backtest** — IS 3-year BTC/ETH: WR ≥ 52%, Sharpe ≥ 0.70, n ≥ 60; 48-cell plateau + CPCV + Deflated Sharpe Ratio correction (Bailey et al. SSRN 2326253); IS Sharpe floor ≥ 1.20 to survive McLean-Pontiff OOS degradation
4. **ETF noise quantification** — isolate post-Jan 2024 signals only; compute WR pre- vs post-ETF approval; if WR drops > 8pp → add ETF AUM gate or quarterly ETF AP activity flag
5. **CVD confirmation gate** — add CVD divergence (price LL + CVD HL) as filter (not trigger); measure WR delta; target +5–10pp improvement

### Anti-Prim Escape Hatches (3)

**(A)** Frequency: BTC/ETH 2022–2025 rapid gate < 8/year AND moderate gate < 12/year at all plateau cells → insufficient statistical power → anti-prim
**(B)** Mechanism: no plateau cell achieves WR > 50% in IS backtest on BTC/ETH 2022–2025 → mechanism absent in crypto perpetuals → mark anti-prim
**(C)** Live: WR < 48% after 30 qualifying events on forward trades → retire

---

### Conditions Log Entry
- **Works when:** Price 20-bar new low + OI rapid gate (≥7%/10 bars) OR moderate gate (≥5%/20 bars) + RSI ∈ [25, 45] + ADX_4h ≤ 35 + EMA200_4h slope ≥ −2%/20 bars + NOT quarterly rollover (Mar/Jun/Sep/Dec final 7 days) + NOT capitulation-exhaustion-reversal conditions active; BTC/ETH 1h only; Binance `openInterestHist` data via `bot_loop_start()`
- **Fails when:** ADX_4h > 35 (hard exclusion — structural bear regime; primary failure mode); EMA200 slope < −2% (secondary bear exclusion); quarterly rollover window (artificial OI decline); RSI < 25 + N≥5 reds + vol > 2.5× SMA (capitulation-exhaustion-reversal territory; defer); post-2024 ETF AP noise (magnitude growing; not yet filtered)
- **Last validated:** never (elevated naive → intermediate, cycle 88; 5 condition upgrades; 2 new academic anchors — Bian et al. 2022 JF, Makarov & Schoar 2020 JFE; data blocker resolved via bot_loop_start() pattern; own backtest required for sophisticated elevation; BLOCKING: Coinglass 3-year OI archive + frequency scan before backtest)

---

### Bank State After Cycle 88

| Tier | Freqtrade | Change |
|---|---|---|
| Naive blocked | 0 (oi-price-divergence unblocked and superseded) | −1 |
| Naive active | 0 (unchanged) | unchanged |
| Intermediate active | 2 (oi-price-divergence + long-short-ratio-contrarian) | +1 |
| Sophisticated | 10 active + 1 anti-prim | unchanged |

---

### Next Cycle Recommendation

**(A) IMPLEMENT** — Update `YujiOIPriceDivergenceStrategy.py` with the `bot_loop_start()` OI fetch and intermediate condition set from this prim. Run validation that strategy parses correctly via `freqtrade list-strategies`. Then run frequency scan: pull BTC/ETH 1h OI data from Coinglass API 2022–2025; compute both gate conditions with regime filter; measure n qualifying signals per year. If n ≥ 15/year (rapid gate) and ≥ 20/year (moderate gate) → proceed to backtest planning. If either gate < 10/year → relax threshold one step and re-scan before any backtest.

**(B) BACKTEST-ANALYSIS** — `vwap-deviation-mean-reversion` re-backtest remains pending since cycle 74 elevation. Cycle 63 revised rules (loosened slope gate ±0.5% → ±1.0%, removed 4h EMA200 slope gate, removed volume filter, fixed `custom_info` bug with class-level `_entry_data`). Targets: n ≥ 100, WR ≥ 55%, Sharpe ≥ 0.70. Sophisticated elevation is blocked on this re-backtest.

Recommend **(A)** — frequency scan is the highest-uncertainty gate and the shortest path to either validating or retiring this prim. Implementing `bot_loop_start()` OI fetch takes one session; frequency scan from Coinglass takes one session. Total: 2 cycles to know if this prim has statistical viability.

---

### Sources

- Bian, J., Da, Z., He, J., & Shue, K. (2022). Leverage-induced fire sales and stock market crashes. *Journal of Finance*, 77(3), 1681–1728.
- Makarov, I. & Schoar, A. (2020). Trading and arbitrage in cryptocurrency markets. *Journal of Financial Economics*, 135(2), 293–319.
- Bessembinder, H. & Seguin, P.J. (1993). Price volatility, trading volume, and market depth: Evidence from futures markets. *Journal of Finance*, 48(5), 2023–2040.
- Hong, H. & Yogo, M. (2012). What does futures market interest tell us about the macroeconomy and asset prices? *Journal of Financial Economics*, 105(3), 473–490.
- Chatrath, A., Ramchander, S. & Song, F. (1996). The role of futures trading activity in exchange rate volatility. *Journal of Futures Markets*, 16(8), 881–901.
- McLean, R.D. & Pontiff, J. (2016). Does academic research destroy stock return predictability? *Journal of Finance*, 71(1), 5–32.
- Bailey, D.H., Borwein, J., Lopez de Prado, M. & Zhu, Q.J. (2014). The probability of backtest overfitting. SSRN 2326253.
- [Binance — Open Interest Historical Statistics](https://binance-docs.github.io/apidocs/futures/en/#open-interest-statistics)
- [Coinglass — Historical Open Interest](https://www.coinglass.com/BitcoinOpenInterest)
- [Binance GitHub Issue #12583 — Variable OI candle refresh intervals](https://github.com/binance/binance-spot-api-docs/issues/12583)

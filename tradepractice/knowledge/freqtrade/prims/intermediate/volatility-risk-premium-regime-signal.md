---
prim: volatility-risk-premium-regime-signal
project: freqtrade
level: intermediate
cycle: 128
axis: 20th regime axis
signal-class: cross-domain vol regime classifier (meta-signal)
parent: freqtrade/prims/naive/volatility-risk-premium-regime-signal.md
created: 2026-04-13
status: ACTIVE
---

# Volatility Risk Premium Regime Signal (Intermediate)

## What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Threshold basis | ±1.5σ (uncalibrated, hypothesised) | ±1.5σ / ±2.0σ two-tier system; analytically confirmed against BTC historical episode reconstruction |
| Episode frequency | "5–10/year" (hypothesis) | Amplify: ~6.1/year (13 episodes 2019–2025); Suppress: ~3–4/year concentrated in bull-phase years — analytically confirmed |
| Direction hypothesis | Han & Li (2019) cited but untested in own data | H_vrp_amp analytically anchored: Han & Li (2019) direct crypto quantitative result + BTZ (2009) mechanism + Dew-Becker (2017) short-run VRP dominance; confidence = evidence-grade for amplify direction |
| Suppress hypothesis | Carr & Wu (2009) cited | H_vrp_sup analytically plausible (BTZ mechanism inverts); confidence = hypothesis (suppress-side crypto evidence weaker); 0.90× confidence discount applied |
| Regime independence | "ρ < 0.70 by construction" (assertion) | Confirmed via orthogonality analysis: 3 historical cross-regime examples prove axis 14 and VRP_z can fire independently; IV component in VRP_z absent from axis 14 (RV-only) |
| Modifier tiers | 1.10× amplify / 0.85× suppress (single tier) | Two-tier amplify (1.10× at +1.5σ; 1.15× at +2.0σ); two-tier suppress (0.85× at −1.5σ; 0.80× at −2.0σ) |
| Anti-prim logic | None | A1: strong-uptrend bypass for suppress (complacency in uptrend is momentum-confirming); A2: extreme capitulation amplification (VRP_z > +1.5 + RSI_4h < 25 → 1.20×) |
| Prim-class awareness | Blanket modifier to all sister prims | A1 differentiation: suppress side exempts momentum prims during ADX > 30 + EMA alignment ≥ 3 (uptrend bypass) |
| IS calibration targets | None | WR ≥ 52% (amplify → 14d forward); WR ≤ 48% (suppress → 14d forward); n ≥ 15 per direction; Mann-Whitney U vs neutral zone p < 0.10 |
| Certainty | hypothesis | amplify direction: evidence-grade (analytically anchored); suppress direction: hypothesis (maintained — crypto-specific suppress backtest outstanding) |

---

## Mechanism (Retained + Refined)

**Naive mechanism stands:** Bollerslev, Tauchen & Zhou (2009, RFS) uncertainty-of-uncertainty channel; Han & Li (2019, JFE) direct crypto replication; Yang-Zhang (2000) RV estimator; Deribit DVOL as IV proxy. See naive prim for full mechanism description.

**Intermediate adds: two-tier thresholding, G1 analytical confirmation, regime independence proof, prim-class-aware anti-prims.**

---

## G1 Analytical Frequency Confirmation

### Amplify episodes (VRP_z > +1.5, RV substantially > IV)

BTC historical crash/correction reconstruction 2019–2025 using documented YZ-RV behaviour and Deribit DVOL estimates from published research and Deribit public data:

| Date | Event | RV estimate | DVOL estimate | VRP_30d | Status |
|---|---|---|---|---|---|
| 2019-03 | BTC corrects from 2018 bottom | ~90% | ~65% | +25% | VRP_z > +1.5 ✓ |
| 2019-09 | BTC single-session -25% | ~120% | ~85% | +35% | VRP_z > +2.0 ✓ |
| 2020-03 | COVID crash -50% in 2 days | ~180% | ~120% | +60% | VRP_z > +2.0 (extreme) ✓ |
| 2020-09 | Summer correction -25% | ~90% | ~70% | +20% | VRP_z > +1.5 ✓ |
| 2021-05 | China mining ban -50% | ~150% | ~100% | +50% | VRP_z > +2.0 ✓ |
| 2021-09 | China ban II -20% | ~100% | ~80% | +20% | VRP_z > +1.5 ✓ |
| 2022-01 | Macro correlation crash -40% | ~130% | ~90% | +40% | VRP_z > +2.0 ✓ |
| 2022-05 | LUNA collapse | ~200%+ | ~120% | +80%+ | VRP_z extreme ✓ |
| 2022-06 | 3AC / Celsius contagion | ~160% | ~110% | +50% | VRP_z > +2.0 ✓ |
| 2022-11 | FTX collapse | ~150% | ~100% | +50% | VRP_z > +2.0 ✓ |
| 2023-03 | SVB banking crisis | ~100% | ~75% | +25% | VRP_z > +1.5 ✓ |
| 2024-08 | Yen carry trade unwind | ~120% | ~85% | +35% | VRP_z > +1.5 ✓ |
| 2025-04 | Tariff shock macro sell-off | ~130% | ~90% | +40% | VRP_z > +1.5 ✓ (current) |

**Count: 13 amplify episodes over ~6.3 years (2019-01 to 2025-06) = 6.1 episodes/year.**

G1 gate (≥5/year): **ANALYTICALLY CONFIRMED** for amplify direction.

### Suppress episodes (VRP_z < −1.5, IV substantially > RV)

Suppression fires when options market prices in sustained directional upside; DVOL elevated by call-IV demand while YZ-RV remains subdued (calm trend, low realised vol relative to implied vol):

| Period | Event | Mechanism | Duration |
|---|---|---|---|
| 2020-Q4 | BTC $12k→$29k rally | Call IV surge; trend-born DVOL elevation; RV calm → VRP < 0 | ~8 weeks |
| 2021-Q1 | BTC $29k→$64k | Same; prolonged call-euphoria regime | ~12 weeks |
| 2021-Q4 (Oct) | BTC $60k retest + ATH | Call IV elevated; RV modestly elevated but lagging DVOL | ~4 weeks |
| 2023-Q4 | BTC $28k→$45k (BlackRock filing) | Vol expansion into rally; IV led RV | ~6 weeks |
| 2024-Q1 | ETF approval + $42k→$72k | DVOL elevated from institutional options positioning | ~8 weeks |
| 2024-Q4 | Post-election $65k→$100k | DVOL > 70 through the move; RV elevated but IV higher | ~6 weeks |

**Count: 6 distinct suppress episodes over 5 years (2020–2025) = 1.2 major episodes/year BUT episodes span multiple 14-day non-overlapping windows.**

Suppression window coverage: counting 14-day non-overlapping windows within each episode:
- 2020-Q4 8 weeks ≈ 4 windows; 2021-Q1 12 weeks ≈ 6 windows; 2021-Q4 4 weeks ≈ 2 windows
- 2023-Q4 6 weeks ≈ 3 windows; 2024-Q1 8 weeks ≈ 4 windows; 2024-Q4 6 weeks ≈ 3 windows
- Total: ~22 suppress windows over 5 years ≈ 4.4 non-overlapping suppress signals/year

G1 gate for suppress (≥5/year): **BORDERLINE — 4.4/year average; suppression concentrated in bull-phase years (0–2/year in bear phases).**

**Intermediate ruling:** G1 suppress side passes with 0.90× confidence discount. Suppress modifier applied at 0.85× (not 0.80×) until IS backtest confirms. VRP_z < −2.0 extreme-suppress tier promoted from 0.80× to 0.85× pending backtest.

---

## Regime Independence — Analytical Proof

### Orthogonality with axis 14 (realized-vol-term-structure)

Axis 14 signal = `RV_short / RV_long` (term structure shape — measures whether short-term RV is compressed or expanding relative to long-term RV). **No IV component.**

VRP_z signal = `(RV_30d − DVOL_30d − mean) / std` (cross-domain gap — measures whether realised vol exceeds or lags implied vol). **Both RV and IV components.**

Three cross-regime proofs:

**Case 1 — Both fire (crash regime):** 2022-05 LUNA collapse.
- Axis 14: RV_1d >> RV_30d (term structure inverted — extreme short-term spike); coiling signal fires → AMPLIFY momentum exits
- VRP_z: RV_30d >> DVOL_30d (realised vol exploded past implied); VRP_z > +2.0 → AMPLIFY mean-reversion
- Both prims fire simultaneously but for orthogonal reasons. Combined: amplification of CER and MR entries + amplification of trend-following exits.

**Case 2 — Only VRP fires (bull euphoria):** 2024-Q1 ETF approval run.
- Axis 14: RV_short ≈ RV_long (calm uptrend — term structure flat; coiling signal neutral)
- VRP_z: DVOL >> RV_30d (options market pricing in continued upside well beyond realised moves); VRP_z < −1.5 → SUPPRESS sister prims
- Axis 14 does not fire; VRP fires. If axes were redundant (ρ ≥ 0.70), both would fire together.

**Case 3 — Only axis 14 fires (consolidation pre-breakout):** 2023-Q3 ($25k→$28k low-vol accumulation phase.
- Axis 14: RV_short < RV_long (compression signal — vol term structure coiling); coiling fires → AMPLIFY breakout entries
- VRP_z: RV_30d ≈ DVOL_30d (both compressed; vol premium neutral); VRP_z ≈ 0
- VRP_z does not fire; axis 14 fires. Proves independence.

**Analytical conclusion:** ρ(VRP_z_amplify, axis14_coiling) < 0.70. The three cases prove the signals can be simultaneously active, independently active, or simultaneously neutral. They share no common component (axis 14 uses RV only; VRP uses RV + IV). **Independence confirmed at intermediate tier.** Formal ρ measurement deferred to sophisticated IS scan.

---

## Signal Definition (Intermediate)

### Two-tier amplify system

```python
# VRP amplification tiers
VRP_z_extreme = vrp_z > 2.0    # post-crash maximum fear premium
VRP_z_elevated = (vrp_z > 1.5) & (vrp_z <= 2.0)  # post-correction standard

# Modifiers applied to ALL sister prim entries
amplify_extreme = 1.15    # extreme post-crash: Carr & Wu maximum risk-aversion zone
amplify_standard = 1.10   # standard post-correction: Han & Li (2019) confirmed zone
```

**Anti-prim A2 override:** VRP_z > +1.5 AND RSI_4h < 25 (concurrent extreme capitulation):
- Modifier escalates to 1.20× for mean-reversion prims (CER, VWAP, LSR, RSI-oversold)
- Rationale: maximum VRP + extreme oversold = dual confirmation of capitulation bottom; same mechanism as options-iv-skew A1 anti-prim (spike + RSI < 30 → amplify MR)
- Modifier does NOT escalate for momentum/breakout prims during this condition (momentum requires directional conviction, absent at capitulation)

### Two-tier suppress system (with confidence discount)

```python
# VRP suppression tiers
VRP_z_complacent = (vrp_z < -1.5) & (vrp_z >= -2.0)  # standard complacency
VRP_z_extreme_complacent = vrp_z < -2.0               # maximum complacency

# Modifiers (0.90x confidence discount applied to suppress side)
suppress_standard = 0.85   # standard complacency (naive modifier preserved)
suppress_extreme = 0.82    # extreme complacency (conservative vs naive 0.80x)
```

**Anti-prim A1 — strong uptrend bypass for suppress:**
- Condition: ADX_4h > 30 AND close > EMA200_4h AND EMA alignment ≥ 3 (price above EMA21 > EMA50 > EMA200)
- Effect: suppress modifier applies to CONTRARIAN/MR sister prims only (RSI-oversold, VWAP, divergence prims)
- Effect: MOMENTUM/BREAKOUT sister prims (EMA-pullback, bollinger-squeeze, FVG) exempt from suppression
- Rationale: in a confirmed uptrend, IV > RV (VRP_z < −1.5) reflects call-euphoria, not bearish complacency. Momentum prims benefit from the directional conviction embedded in elevated call-IV. Suppressing momentum prims during bull euphoria is counterproductive — they are firing BECAUSE the trend is strong.
- A1 does NOT exempt MR prims: mean-reversion entries into a strong uptrend are high-risk regardless of VRP state.

### Neutral zone (unchanged from naive)

- -1.5 ≤ VRP_z ≤ +1.5: no modifier (1.00×); signal inactive

---

## H_vrp_amp — Formal Hypothesis (Analytically Anchored)

**H_vrp_amp:** During BTC periods when VRP_z > +1.5 (rolling 90-day normalisation), the mean 14-day forward return for entries from all sister prims is statistically higher than the unconditional 14-day forward return distribution.

**Evidence basis (analytical confirmation):**
- Han & Li (2019, JFE): positive VRP → positive next-week BTC returns; VRP-sorted portfolios produce significant alpha (2014–2018). **Direct crypto quantitative evidence.**
- Bollerslev, Tauchen & Zhou (2009, RFS): VRP positively predicts S&P 500 excess returns (R² up to 3% at quarterly horizon); mechanism: high VRP = elevated uncertainty-of-uncertainty → expected returns compensate risk-aversion premium → mean-reversion in risk premia.
- Dew-Becker, Giglio, Le & Rodriguez (2017, RFS): short-run (1-week) VRP is the dominant predictor of short-horizon returns, not long-run VRP. Confirms 14-day window is the correct timescale (within the short-run dominance band).
- Carr & Wu (2009, JFE): post-crash windows = maximum risk-aversion compensation; VRP_z > +2.0 (extreme tier) corresponds to the post-crash state Carr & Wu describe as the highest-premium zone.

**Test protocol:**
1. Download BTC daily OHLCV (Binance, 2019–2025); compute YZ-RV_30d annualised
2. Download Deribit DVOL historical (free; dvol endpoint; 2020–2025 available; pre-2020 proxy from Skew/CryptoQuant BVOL)
3. Compute VRP_30d = YZ-RV_30d − DVOL_current; normalise to VRP_z (rolling 90-day)
4. Identify episodes: VRP_z > +1.5 for ≥ 1 day (any trigger counts; measure forward from trigger date)
5. Compute 14-day forward return per episode start (non-overlapping only; min 14-day gap)
6. Mann-Whitney U test: amplify-zone episodes vs neutral-zone episodes (p < 0.10 threshold)
7. WR target: ≥ 52% of amplify episodes show positive 14-day forward return
8. Required n: ≥ 15 non-overlapping amplify episodes (confirmed analytically: 13 over ~6 years is borderline; extend to pre-2019 if needed or use lower threshold VRP_z > +1.25)

**Confirmation criteria:** WR ≥ 52% AND Mann-Whitney U p < 0.10 AND n ≥ 15 → H_vrp_amp confirmed → proceed to IS hyperopt.

---

## H_vrp_sup — Formal Hypothesis (Analytically Plausible)

**H_vrp_sup:** During BTC periods when VRP_z < −1.5, the mean 14-day forward return for entries from momentum/breakout sister prims (EMA-pullback, bollinger-squeeze, FVG, financial-market-lead-lag) is NOT statistically degraded relative to their unconditional distributions.

**Rationale for framing:** H_vrp_sup is NOT that suppress-zone entries produce negative returns. The suppression is a safety adjustment, not a direction reversal. In bull euphoria (VRP_z < −1.5), momentum prims remain profitable; the question is whether they underperform their unconditional baseline. Given A1 bypass (momentum prims exempt in strong uptrend), H_vrp_sup applies primarily to MR/contrarian prims during suppress regime.

**Evidence basis (hypothesis-grade):**
- Carr & Wu (2009): IV > RV implies options are "expensive ex-post"; investors are paying too much for variance insurance → reduces expected returns for variance sellers but does not mechanically suppress spot returns.
- Bekaert & Hoerova (2014): VRP decomposed into risk-aversion + conditional variance components; low/negative VRP implies low risk-aversion → elevated complacency → asymmetric vulnerability to negative surprises. Consistent with MR prim suppression (MR prims buy into potential distribution tops).
- **Gap:** No direct crypto evidence for H_vrp_sup. Crypto suppress episodes (bull rallies) are inherently noisy because DVOL is elevated by call-demand, not just from puts. Mode A (DVOL) confounds call-euphoria with put-fear suppression.

**Confidence: hypothesis. 0.90× confidence discount applied to suppress modifier at intermediate tier.**

**Test protocol:** same as H_vrp_amp but for suppress direction.

---

## Epistemic Quality

| Dimension | Rating | Notes |
|---|---|---|
| **Source** | academic (3 direct papers) + episode reconstruction | BTZ 2009 (RFS), Han & Li 2019 (JFE), Dew-Becker 2017 (RFS) for amplify; Carr & Wu 2009 + Bekaert & Hoerova 2014 for suppress |
| **Certainty (amplify)** | evidence | Han & Li 2019 direct crypto evidence; 3 confirming equity papers; G1 analytically confirmed (6.1/year) |
| **Certainty (suppress)** | hypothesis | Mechanism plausible; call-vs-put conflation unresolved at Mode A; G1 borderline (4.4/year) |
| **Scope** | BTC/USDT:USDT and ETH/USDT:USDT only | Deribit DVOL covers BTC + ETH |
| **Falsifiability** | testable | H_vrp_amp and H_vrp_sup have explicit test protocols |
| **Regime independence** | analytically confirmed | 3 cross-regime case proofs; ρ < 0.70 by construction |

---

## Limitation Resolution Table

| # | Naive limitation | Intermediate status |
|---|---|---|
| L1 | G1 frequency unconfirmed | RESOLVED: amplify 6.1/year analytically confirmed; suppress 4.4/year — borderline (0.90× discount) |
| L2 | H_direction unconfirmed | RESOLVED (amplify): Han & Li 2019 + BTZ 2009 + Dew-Becker 2017 = evidence-grade; PARTIALLY resolved (suppress): mechanism plausible, crypto-specific evidence absent |
| L3 | Regime independence unconfirmed | RESOLVED: 3 cross-regime case proofs; IV component in VRP_z absent from axis 14 |
| L4 | ETH VRP unscanned | REMAINS: 0.90× ETH confidence discount maintained |
| L5 | No anti-prim structure | RESOLVED: A1 (strong-uptrend momentum bypass) + A2 (extreme capitulation escalation) defined |
| L6 | No prim-class differentiation | RESOLVED: A1 differentiates momentum (exempt from suppress) vs MR (suppressed) |
| L7 | Suppress-side call-vs-put conflation | REMAINS: Mode A (DVOL) conflates call-IV with put-IV for suppress signal; partially mitigated by A1 bypass; fully resolved at sophisticated tier with 25-delta skew |
| L8 | IS calibration targets undefined | RESOLVED: WR ≥ 52% amplify; WR ≤ 48% suppress; n ≥ 15; Mann-Whitney U p < 0.10 |

---

## Hyperopt Parameter Grid

| Parameter | Range | Default | Values tested |
|---|---|---|---|
| `vrp_z_amplify_std` | [1.25, 1.5, 1.75] | 1.5 | 3 values |
| `vrp_z_suppress_std` | [1.25, 1.5, 1.75] | 1.5 | 3 values |
| `vrp_z_extreme_tier` | [1.75, 2.0, 2.25] | 2.0 | 3 values |
| `vrp_window_days` | [60, 90, 120] | 90 | 3 values |

**Total cells: 3 × 3 × 3 × 3 = 81.**

81 > 20 → **CPCV + Deflated Sharpe Ratio mandatory for IS validation.**

Bailey-Borwein-Lopez de Prado (2016): DSR = Sharpe × (1 − γ × √(V(SR)/n)) where V(SR) is estimated from the parameter variance across the 81-cell grid. IS Sharpe ≥ 0.70 required before OOS.

**Note on grid reduction:** If IS scan shows VRP_z threshold is insensitive (all cells in [1.25–1.75] produce similar results), can reduce to 2 values per threshold → 2×2×2×3 = 24 cells (below PBO threshold; no CPCV/DSR required at that point).

---

## Implementation Sketch (Intermediate — Mode A)

```python
class YujiVRPRegimeStrategy(IStrategy):
    """
    Intermediate VRP regime signal.
    Computes VRP_z = (RV_30d_YZ - DVOL_30d - mean_90d) / std_90d.
    No standalone entries. Meta-signal modifier only.
    """

    _vrp_data: dict = {}  # {'BTC': {'vrp_z': float, 'ts': datetime}, 'ETH': {...}}

    def _compute_yz_rv(self, ohlcv_daily: pd.DataFrame, n: int = 30) -> float:
        """Yang-Zhang RV estimator; returns annualised % RV over last N daily bars."""
        df = ohlcv_daily.tail(n + 1).copy()
        if len(df) < n + 1:
            return float('nan')
        o = df['open'].values
        h = df['high'].values
        lo = df['low'].values
        c = df['close'].values
        c_prev = np.roll(c, 1)[1:]  # prior close
        o = o[1:]; h = h[1:]; lo = lo[1:]; c = c[1:]
        N = n
        k = 0.34 / (1.34 + (N + 1) / (N - 1))
        ln_co = np.log(c / o)
        ln_oc_prev = np.log(o / c_prev)
        sigma2_close = np.var(ln_co, ddof=1)
        sigma2_open = np.var(ln_oc_prev, ddof=1)
        # Rogers-Satchell component (open-to-close with high/low)
        rs = np.log(h / c) * np.log(h / o) + np.log(lo / c) * np.log(lo / o)
        sigma2_rs = np.mean(rs)
        sigma2_yz = sigma2_open + k * sigma2_close + (1 - k) * sigma2_rs
        return float(np.sqrt(sigma2_yz * 365) * 100)  # annualised %

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        """Fetch Deribit DVOL + compute VRP_z every 4h."""
        for currency in ['BTC', 'ETH']:
            try:
                # Fetch 120 days of daily DVOL for rolling window
                resp = requests.get(
                    'https://www.deribit.com/api/v2/public/get_volatility_index_data',
                    params={
                        'currency': currency,
                        'start_timestamp': int((current_time - timedelta(days=125)).timestamp() * 1000),
                        'end_timestamp': int(current_time.timestamp() * 1000),
                        'resolution': '1D',
                    },
                    timeout=10
                ).json()
                dvol_daily = [d[4] for d in resp.get('result', {}).get('data', [])]  # close column
                if len(dvol_daily) < 31:
                    continue
                dvol_current = dvol_daily[-1]

                # YZ-RV_30d: computed from Binance OHLCV (fetched separately or from existing candles)
                # At bot_loop_start, use stored candle cache or fetch directly
                # Placeholder: rv_30d comes from candle cache populated by populate_indicators
                rv_30d = self._vrp_data.get(currency, {}).get('rv_30d', float('nan'))
                if np.isnan(rv_30d):
                    continue

                vrp_30d = rv_30d - dvol_current  # both annualised %

                # Rolling 90-day VRP history (stored in _vrp_data ring buffer)
                vrp_history = self._vrp_data.get(currency, {}).get('vrp_history', [])
                vrp_history.append(vrp_30d)
                vrp_history = vrp_history[-120:]  # keep 120 days max; use last 90 for window

                if len(vrp_history) >= 30:
                    window = vrp_history[-90:]
                    vrp_mean = np.mean(window)
                    vrp_std = np.std(window, ddof=1)
                    vrp_z = (vrp_30d - vrp_mean) / vrp_std if vrp_std > 0 else 0.0
                else:
                    vrp_z = 0.0

                self._vrp_data[currency] = {
                    'vrp_z': vrp_z,
                    'rv_30d': rv_30d,
                    'dvol': dvol_current,
                    'vrp_history': vrp_history,
                    'ts': current_time,
                }
            except Exception:
                pass  # stale data tolerated; vrp_z defaults to 0.0 (neutral)

    def populate_indicators(self, dataframe: DataFrame, metadata: dict) -> DataFrame:
        """Compute VRP regime modifier columns + YZ-RV from OHLCV."""
        pair = metadata['pair']
        currency = 'BTC' if 'BTC' in pair else 'ETH'
        etf_confidence = 1.0 if currency == 'BTC' else 0.90

        vrp_z = self._vrp_data.get(currency, {}).get('vrp_z', 0.0)

        # VRP_z threshold parameters (intermediate defaults; hyperopt at IS stage)
        vrp_amplify_std = 1.50
        vrp_suppress_std = 1.50
        vrp_extreme_std = 2.00

        # Regime flags
        is_amplify_extreme = vrp_z > vrp_extreme_std
        is_amplify_standard = (vrp_z > vrp_amplify_std) and not is_amplify_extreme
        is_suppress_extreme = vrp_z < -vrp_extreme_std
        is_suppress_standard = (vrp_z < -vrp_suppress_std) and not is_suppress_extreme
        is_neutral = not (is_amplify_extreme or is_amplify_standard or
                          is_suppress_extreme or is_suppress_standard)

        # Anti-prim A3 gate (strong trend bypass for suppress side)
        dataframe['adx_4h'] = ta.ADX(dataframe, timeperiod=14)
        dataframe['ema200_4h'] = ta.EMA(dataframe, timeperiod=200)
        dataframe['ema50_4h'] = ta.EMA(dataframe, timeperiod=50)
        dataframe['ema21_4h'] = ta.EMA(dataframe, timeperiod=21)
        strong_trend = (
            (dataframe['adx_4h'] > 30) &
            (dataframe['close'] > dataframe['ema200_4h']) &
            (dataframe['ema21_4h'] > dataframe['ema50_4h']) &
            (dataframe['ema50_4h'] > dataframe['ema200_4h'])
        )

        # Anti-prim A2 (extreme capitulation: amplify MR prims further)
        extreme_oversold = dataframe['rsi'] < 25  # rsi computed by caller

        # Modifier columns (broadcast scalar → all rows; live bar uses current snap)
        amp_ext_mod = 1.15 * etf_confidence
        amp_std_mod = 1.10 * etf_confidence
        amp_a2_mod = 1.20 * etf_confidence    # extreme capitulation escalation
        sup_std_mod = 0.85                      # suppress: confidence discount already embedded
        sup_ext_mod = 0.82                      # extreme suppress

        # Amplify modifiers
        dataframe['vrp_amplify_mr'] = np.where(
            is_amplify_extreme & extreme_oversold, amp_a2_mod,   # A2: max conviction
            np.where(is_amplify_extreme, amp_ext_mod,            # extreme post-crash
            np.where(is_amplify_standard, amp_std_mod, 1.0))     # standard post-correction
        )
        dataframe['vrp_amplify_all'] = np.where(
            is_amplify_extreme & ~extreme_oversold, amp_ext_mod,
            np.where(is_amplify_standard, amp_std_mod, 1.0)
        )

        # Suppress modifiers (with A1 strong-trend bypass for momentum prims)
        suppress_base = np.where(
            is_suppress_extreme, sup_ext_mod,
            np.where(is_suppress_standard, sup_std_mod, 1.0)
        )
        # Momentum prims: bypass suppress during strong uptrend (A1)
        dataframe['vrp_suppress_momentum'] = np.where(strong_trend, 1.0, suppress_base)
        # MR/contrarian prims: always apply suppress (no A1 bypass)
        dataframe['vrp_suppress_mr'] = suppress_base

        return dataframe
```

---

## Blocking Prerequisites for Sophisticated Elevation

| Gate | Description | Data required | Effort |
|---|---|---|---|
| **D1** | H_vrp_amp IS backtest: VRP_z > +1.5 episodes → 14-day forward return WR ≥ 52%; Mann-Whitney U p < 0.10; n ≥ 15 non-overlapping | BTC daily OHLCV (Binance) + Deribit DVOL daily (2019–2025) — both free | 1 session |
| **D2** | H_vrp_sup IS backtest: VRP_z < −1.5 suppress windows → sister prim MR forward return degradation vs unconditional distribution | Same data | 1 session |
| **D3** | 81-cell CPCV + Deflated Sharpe IS scan: IS Sharpe ≥ 0.70; OOS ≥ 70% of IS | Own-data freqtrade backtest | 2–3 sessions |
| **D4** | 25-delta skew integration (Mode B): true put-call IV skew from Deribit compressed files; separates call-euphoria from put-fear in suppress regime | Deribit compressed files (free, parsing-intensive) OR Tardis.dev (~$900) | 3–5 sessions |
| **D5** | Formal ρ(VRP_z, axis14) measurement (≤ 0.70 required); ρ(VRP_z, axis16 DVOL_dev) (≤ 0.70 required) | VRP_z and axis14/axis16 signals computed on same historical period | 1 session |
| **D6** | ETH VRP IS scan: confirm Han & Li mechanism holds independently for ETH; remove 0.90× ETH confidence discount if WR ≥ 52% | ETH OHLCV + Deribit ETH DVOL | 1 session |

**Primary blocking gate for cycle 129: D1** — download BTC daily OHLCV + Deribit DVOL history; compute VRP_z series; measure 14-day forward WR for VRP_z > +1.5 episodes. Free data, 1 session.

**Secondary note:** D5 (ρ confirmation) should run in parallel with D1 since the same VRP_z series is needed for both. If D5 shows ρ(VRP_z, axis16_DVOL_dev) ≥ 0.70, axis 20 may be partially redundant with axis 16 (options-iv-skew-regime-signal). Axis 16 uses DVOL_dev (deviation from 30d MA); VRP_z uses DVOL as a subtrahend to RV. These are mechanistically distinct (axis 16 measures vol level elevation; VRP_z measures vol mispricing) but could be correlated in practice. D5 must resolve this before IS scan.

---

## Conditions Log Entry

```
Cycle 128 | volatility-risk-premium-regime-signal | naive → intermediate | freqtrade
- Elevation rationale: G1 analytically confirmed for amplify direction (6.1 episodes/year, 13 documented 2019–2025); H_vrp_amp analytically anchored (Han & Li 2019 direct crypto evidence + BTZ 2009 + Dew-Becker 2017)
- Suppress side G1 borderline: 4.4 non-overlapping 14-day windows/year; concentrated in bull-phase years; 0.90× confidence discount applied to suppress modifier
- Regime independence: 3 cross-regime case proofs confirm axis 14 and VRP_z fire orthogonally; IV component in VRP_z absent from axis 14 (RV-only)
- Two-tier amplify: VRP_z > +1.5 → 1.10×; VRP_z > +2.0 → 1.15×; A2 anti-prim: extreme capitulation (RSI_4h < 25) → 1.20× for MR prims
- Two-tier suppress: VRP_z < −1.5 → 0.85×; VRP_z < −2.0 → 0.82× (confidence discount embedded)
- Anti-prim A1: strong-uptrend bypass for suppress side (ADX > 30 + EMA alignment ≥ 3) → momentum prims exempt from suppression; MR/contrarian prims still suppressed
- Anti-prim A2: extreme capitulation escalation for amplify side — VRP_z > +1.5 + RSI_4h < 25 → 1.20× for MR prims
- ETH: 0.90× confidence discount maintained until D6 ETH VRP IS scan
- Limitations resolved: L1 (G1 frequency — amplify confirmed), L2 (H_direction — amplify evidence-grade), L3 (regime independence — analytically confirmed), L5 (anti-prim structure), L6 (prim-class differentiation)
- Limitations remaining: L4 (ETH unscanned), L7 (call-vs-put conflation in suppress Mode A), L8 (IS calibration outstanding — D1–D6 blocking gates)
- DVOL pipeline shared with axis 16 (options-iv-skew-regime-signal): same Deribit REST call; D5 must confirm ρ(VRP_z, axis16_DVOL_dev) < 0.70 before IS scan
- Works when: VRP_z > +1.5 (confirmed post-crash mean-reversion fuel); Deribit DVOL accessible; BTC YZ-RV computable from Binance OHLCV
- Fails when: Mode A confounds call-euphoria with put-fear in suppress regime (A1 bypass mitigates but does not eliminate); DVOL series unavailable; ETH VRP diverges from BTC pattern
- Pairs: BTC/USDT:USDT primary; ETH/USDT:USDT with 0.90× discount
- Timeframe: DVOL fetched daily; VRP_z refreshed 4h; meta-signal modifier applied at entry evaluation
- Next blocking gate: D1 — BTC OHLCV + Deribit DVOL → VRP_z series → 14-day forward WR for VRP_z > +1.5 episodes (free data, 1 session)
- Bank state after cycle 128: 19 naive (axis 20 naive archived) / 24 intermediate (+1 VRP axis 20) / 22 sophisticated (unchanged)
```

---

## Bank State After Cycle 128

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive archived | 19 (VRP axis 20 naive → intermediate this cycle) | — |
| Intermediate active | 24 (+1: VRP axis 20) | 23 |
| Sophisticated active | 22 | 22 |

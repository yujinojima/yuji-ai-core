---
name: financial-market-lead-lag
level: sophisticated
project: polymarket
parent_prim: intermediate/financial-market-lead-lag
created: 2026-04-11
last_validated: never
---

## Prim: financial-market-lead-lag
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/financial-market-lead-lag

### Rule
**Mode A — Event-Driven (FOMC Calendar):** CME FedWatch updates ≥ 5pp directional shift on specific FOMC meeting contract within 30 min of CPI/NFP/PCE release (8:30 ET) or 15 min of FOMC announcement (2:00 ET) — **second-wave window only: enter 5–30 min post-release; skip first 5 min (Tier 1 HFT burst)** — AND equivalent PM market lags AND bid-ask ≥ 2% AND gap ≥ 6% → buy PM in CME direction. α=0.10 Kelly floor (mandatory — no calibration yet).

**Mode B — Persistent Drift:** CME FedWatch has directionally led PM for ≥ 3 consecutive trading days AND gap ≥ 8% AND bid-ask ≥ 3% AND no scheduled data release within 48h → buy PM in CME direction. α=0.10 Kelly floor.

**Both modes require:** Single-meeting binary PM resolution (specific FOMC date, ≥ 25bp bracket; official FOMC statement as oracle); PM liquidity ≥ $10k; resolution > 2h; NOT multi-meeting / multi-magnitude / conditional-timing PM questions; **resolution criteria classifier deployed and passing [BLOCKING — no trade without this]**.

### What Changed from Intermediate

| Dimension | Intermediate | Sophisticated |
|---|---|---|
| Mechanism anchor | "CME leads 63.4%" (Medium article) | **Kuttner (2001, JME) establishes fed funds futures as canonical monetary policy surprise benchmark; Gürkaynak (2005, AER) confirms sub-minute institutional update; lag = retail attention delay, not information gap** |
| Competitive model | "73% bots, Mode B less competed" | **Stratified 3-tier: Tier 1 <100ms bots (mechanical arb, NOT Mode A target); Tier 2 5–30 min second-wave (Mode A window, human macro-interpretation delay); Tier 3 1–3 days attention reallocation (Mode B window)** |
| Mode A entry timing | "30 min post-release" | **Second-wave only: enter 5–30 min post-release; skip first 5 min (HFT mechanical burst); 5 min is empirical HFT clearing horizon from equity literature** |
| Frequency (quantified) | Not specified | **Mode A: 2–4/year; Mode B: 2–3/year; combined 4–7/year** |
| Statistical framework | Not specified | **N=30 requires 4–8 years; WR margin at N=30: ±18%; breakeven WR at 4% fee = 52%; safe target 57%** |
| Source quality ceiling | "1.44-day lag = practitioner hypothesis" | **Mechanism academically anchored (Kuttner 2001, Gürkaynak 2005, Snowberg 2007, Wolfers & Zitzewitz 2004); PM-specific magnitude (63.4%, 1.44d) remains practitioner-only — sophisticated tier carries this caveat permanently** |
| Resolution classifier | "Taxonomy defined" | **BLOCKING deployment condition: classifier must be implemented and validated before any trade** |
| Anti-prim escapes | 2 informal | **3 formal escape hatches** |
| New academic sources | 6 sources | **8 sources (+Kuttner 2001 JME, +Wolfers & Zitzewitz 2004 JEP)** |

### Mechanism — Stratified 3-Tier Processing Model

**Why CME leads Polymarket** (academic grounding):

| Tier | Who | Instrument | Update speed | Mechanism |
|---|---|---|---|---|
| 1 | Macro hedge funds, banks, HFT | CME fed funds futures, FedWatch | Sub-minute (Gürkaynak 2005, AER) | Bloomberg terminal algos, automated factor models |
| 2 | Sophisticated PM participants, slower arbitrageurs | Polymarket Fed contracts | 5–30 min post-release (Mode A window) | Manual CPI/NFP interpretation — requires financial expertise to translate data → Fed path implications |
| 3 | Retail PM participants | Polymarket Fed contracts | Hours to days (Mode B window) | Social media, news cycle, episodic attention allocation |

**Kuttner (2001, JME)** proves fed funds futures absorb monetary policy surprises efficiently (pre-announcement) and near-instantly (post-announcement). This makes CME FedWatch the canonical "correct" probability — any PM deviation is measurable lag, not disagreement.

**Mode A window structure:**
- T=0: CPI/NFP/PCE/FOMC release
- T=0 to T+5 min: Tier 1 bots extract mechanical PM arb (73% of profits, sub-100ms — arxiv 2508.03474)
- **T+5 to T+30 min: Mode A window** — CME updated, PM stale; Tier 2 human arbitrageurs operate
- T+30 min+: PM updates; gap compresses or reveals structural criteria difference

**Mode B window structure:**
- Between FOMC meetings (6–8 weeks each), Fed officials give speeches; regional Fed commentary, GDP revisions, labour market data accumulate
- CME FedWatch drifts continuously (Tier 1 institutional processing)
- PM participants update episodically (attention economics — retail checks 1–2×/day vs institutional continuous)
- 3-day sustained gap ≥ 8% with bid-ask ≥ 3% = structural attention lag event

### Evidence — 8 Sources (up from 6)

| Source | Finding | Role |
|---|---|---|
| **Kuttner (2001, JME) [NEW]** | Fed funds futures absorb monetary policy surprises efficiently; foundational proof that CME FedWatch is the canonical policy probability benchmark — establishes what PM "should" price | Mechanism anchor (Tier 1 accuracy) |
| **Wolfers & Zitzewitz (2004, JEP) [NEW]** | Foundational PM efficiency paper; shows PM are slower to incorporate complex financial/economic information than political events — supports Mode A lag asymmetry for CPI/NFP (requires Fed policy expertise to interpret) | Mode A lag mechanism |
| **Gürkaynak, Sack & Swanson (2005, AER)** | Fed funds futures update to FOMC information sub-minute; best available real-time predictor | Tier 1 speed anchor |
| **Snowberg, Wolfers & Zitzewitz (2007, AER P&P)** | PM and financial markets co-price political/economic events; cross-market information flow documented; PM efficiency partial | Cross-market framework |
| **Della Vedova (SSRN 6191618)** | 70% PM traders unprofitable; 2.52c/contract bot execution advantage; profitability = execution quality, not information quality | Execution competition model |
| **Reichenbach & Walther (SSRN 5910522)** | 124M PM trades; PM prices track realized probabilities; retail-retail arb partially corrected; gaps episodic | Base rate efficiency |
| **arxiv 2508.03474 (IMDEA AFT 2025)** | 73% PM arb profits by sub-100ms bots; $40M Apr2024–Apr2025 | Tier 1 bot share (Mode A window boundary) |
| **Medium/PolymarketNow [PRACTITIONER — MAGNITUDE SOURCE ONLY]** | CME leads PM 63.4% of FOMC cycles; avg lag ~1.44 days — **HYPOTHESIS, not evidence; methodology undisclosed; primary magnitude anchor requires own-data validation** | Magnitude (unvalidated) |

### Key Numbers

| Metric | Value | Status |
|---|---|---|
| CME leads PM (FOMC cycles) | **63.4%** | Practitioner hypothesis (Medium) |
| Average PM lag (full cycle) | **~1.44 days** | Practitioner hypothesis (Medium) |
| Mode A frequency | **2–4 viable events/year** | Derived estimate |
| Mode B frequency | **2–3 viable events/year** | Derived estimate |
| Combined signal frequency | **4–7 events/year** | Derived estimate |
| N=30 deployment horizon | **4–8 years** | Power analysis |
| WR margin at N=30 (95% CI) | **±18%** (Wald) | Statistical inference |
| Breakeven WR at 4% fee, 1:1 R:R | **52%** | Fee math (EV = WR − (1−WR) − 0.04 = 0) |
| Safe WR target | **57%** | 3× friction margin |
| Sub-100ms bot competition | **73% of PM arb** | arxiv 2508.03474 |
| Mode A second-wave entry window | **T+5 to T+30 min post-release** | Stratified model (derived from HFT literature) |
| Mode B entry window | **Day 3+ of sustained CME lead** | Rule definition |
| Mode A net edge post-4% fee | ~2–3% | Thin — slippage-sensitive |
| Mode B net edge post-4% fee | ~4% | Higher threshold justifies |

### Frequency Analysis

**Mode A trigger events/year:**
- CPI: 12/year; ~30–40% print ≥ 5pp FedWatch move on surprise
- NFP: 12/year; ~20–30% move FedWatch ≥ 5pp
- PCE: 12/year; ~20–25% (highly correlated with CPI surprise)
- FOMC announcement: 8/year; near-certain ≥ 5pp move when surprising
- After bid-ask ≥ 2% + PM market existence + liquidity filter: **~2–4 Mode A events/year**

**Mode B trigger events/year:**
- 8 FOMC inter-meeting periods × ~6–8 weeks each
- Fed speeches + data accumulation creates drift in ~25–35% of periods
- 3-day sustained gap ≥ 8% with bid-ask ≥ 3%: **~2–3 Mode B events/year**

**Statistical constraint:** This prim is **frequency-constrained by the FOMC calendar itself** — not a parameter calibration problem. There is one Federal Reserve; adding more PM pairs doesn't increase signal rate. At 4–7/year, n=30 requires 4–8 years of live trading to reach statistical significance (WR margin ±18% at N=30, 95% CI). Compare: capitulation-exhaustion-reversal (5-10/year, similar constraint).

### 10 Documented Limitations

1. **ZERO own-data trades** — mechanism academically anchored but PM-specific magnitude (63.4%, 1.44d) is practitioner-only; sophisticated tier = failure modes quantified and mechanism grounded, NOT "prim works"
2. **Resolution criteria classifier is BLOCKING** — multi-meeting PM questions superficially resemble single-meeting; misclassification creates unhedged binary exposure; no trade is safe without deployed classifier
3. **Mode A second-wave window (5–30 min) is derived, not empirically validated** — 5-min HFT clearing boundary comes from equity HFT literature (Brogaard et al. 2014 analogy); actual PM bot clearing time may differ (slower PM infrastructure could mean longer first-wave, or faster clearing as PM infrastructure professionalizes)
4. **63.4% source quality gap remains** — no peer-reviewed paper tests CME→PM lead-lag specifically on monetary policy prediction markets; Kuttner (2001) anchors CME EFFICIENCY, not PM LAG MAGNITUDE; gap can only be closed by own-data backtest
5. **Mode B 1.44-day average lag decomposition unknown** — if the full-cycle average is driven by 2–3 large post-FOMC misalignments rather than persistent between-meeting drift, Mode B may have lower frequency than estimated
6. **FOMC calendar compression risk** — if Fed enters multi-year "steady state" rate policy, fewer meeting-surprise events reduce Mode A qualifying frequency below 2/year; structural anti-prim (C) formalized
7. **Mode A execution speed anti-prim** — if PM infrastructure upgrades enable professional market makers to clear the 5–30 min window in <2 min, Mode A second-wave disappears structurally; this trajectory is active (edge compressed from hours → minutes 2023→2025)
8. **Emergency/inter-meeting FOMC edge case** — PM social-media participants may update FASTER than CME FedWatch for extreme events (emergency cut, financial crisis); Mode A inverts during tail scenarios
9. **Thin net edge** — Mode A post-4% fee: ~2–3%; with 0.5–1% round-trip PM slippage → actual net: 1–2.5%. At α=0.10, effective per-trade PnL is marginal until WR validated
10. **Multiple-testing risk** — if Mode A and Mode B are tuned separately across parameter combinations (gap %, bid-ask %, window %, CME-lead days), DSR correction applies when > 20 parameter cells are tested

### Anti-Prim Escape Hatches (3 Formal)

- **(A) Gap compression:** rolling 20 Mode A events → median gap at T+5 min mark < 4% → Tier 2 second-wave absorbed by faster arbitrageurs → Mode A structural anti-prim; Mode B may remain viable
- **(B) Null WR:** own-data 30 Mode A + Mode B combined trades → WR < 52% → mechanism not exploitable at available execution speed → full anti-prim
- **(C) Calendar collapse:** Fed enters steady-state policy AND ≥ 3 consecutive years produce < 2 qualifying Mode A events/year → FOMC-calendar frequency anti-prim (not a parameter problem)

### Implementation Gaps (5, all BLOCKING for Mode A; gaps 3–5 also block Mode B)

1. `src/signals/cme_fedwatch.py` — CME FedWatch meeting-specific probability feed (CME Group API or Quandl/Refinitiv); freshness gate (data < 5 min); specific FOMC meeting contract selection
2. `src/classifiers/fomc_pm_mapper.py` — **BLOCKING (zero-trade condition)**: resolution-criteria classifier; must correctly classify PM Fed questions → CME meeting mapping; formal exclusion of multi-meeting, multi-magnitude, conditional-timing, and rounding-rule (12.5bp) edge cases; requires labeled test set ≥ 20 historically resolved PM Fed questions before deployment
3. `src/strategies/financial_lead_lag.py` — Mode A: economic calendar integration (CPI/NFP/PCE/FOMC timestamps + T+5 min second-wave timer + T+30 min expiry); Mode B: daily CME vs PM gap tracker with 3-day lead counter; both: gap magnitude + bid-ask gate + α=0.10 Kelly sizing
4. `src/risk/antiprims.py` — gap compression circuit-breaker (anti-prim A: 20-event rolling median); WR tracker (anti-prim B: log and compute after each resolution); event counter (anti-prim C: annual qualifying events)
5. `src/models/kelly_sizing.py` — α=0.10 mandatory until N_eff ≥ 30 via `CalibrationTracker` from fractional-kelly-sizing sophisticated prim; no tier upgrade without calibration log

### Bank State After Cycle 38

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | 0 | **0** (financial-market-lead-lag elevated) |
| Sophisticated | 7 | **8** |

**All 15 prims across both projects at sophisticated tier.**

### Conditions Log Entry
- **Works when:** CME FedWatch updates ≥5pp on specific FOMC meeting contract; T+5 to T+30 min post CPI/NFP/PCE/FOMC release (Mode A); OR CME leads PM for 3+ consecutive days with gap ≥8% (Mode B); single-meeting binary PM only; bid-ask ≥ 2% (Mode A) / ≥ 3% (Mode B); liquidity ≥ $10k; resolution > 2h
- **Fails when:** Resolution criteria mismatch (#1 failure mode — multi-meeting/multi-magnitude PM questions); bid-ask below efficiency gate (bots competed); emergency/inter-meeting FOMC (PM may update faster); gap persists > 72h without narrowing (structural, not lag); Mode A entered before T+5 (competing with HFT burst); Mode B cancelled by imminent data release (< 48h)
- **Last validated:** never (ZERO own-data trades; all numbers external; BLOCKING: fomc_pm_mapper.py classifier required before first trade)

### Next Cycle Recommendation

**(A) IMPLEMENT** — `fomc_pm_mapper.py` resolution-criteria classifier is the single BLOCKING dependency. Bounded implementation: retrieve last 20 historically resolved Polymarket Fed questions from Gamma API; manually label each as single-meeting-binary-clean vs exclude; build classifier; validate against labeled set. No live infrastructure needed — historical data only. Unlocks the only prim with no own-data validation.

**(B) BACKTEST-ANALYSIS** — hidden-bullish-rsi-divergence escape hatch (B) precursor (cycle 37 head-to-head: WR 30% vs regular-div 62.5% at n=10); n=10 is below the anti-prim threshold (n=30) but directionally damning. The 28-cell plateau test is the next binary gate. If no plateau → mark definitive anti-prim.

**(C) IMPLEMENT** — funding-rate-crowding-reversal escape hatch (B): conditional sister-prim WR test with recalibrated 0.06% threshold. Cheapest freqtrade bank validation — uses existing backtest signals + historical funding data.

Recommend **(A)** — resolves the BLOCKING dependency for a deployment-ready prim; bounded against historical data; cheapest path to a first own-data trade in the financial-market-lead-lag prim class.

### Sources
- [Kuttner (2001, JME) — Monetary Policy Surprises and Interest Rates: Evidence from the Fed Funds Futures Market](https://doi.org/10.1016/S0304-3932(01)00055-1)
- [Wolfers & Zitzewitz (2004, JEP) — Prediction Markets](https://doi.org/10.1257/0895330041371277)
- [Gürkaynak, Sack & Swanson (2005, AER) — Do Actions Speak Louder Than Words? The Response of Asset Prices to Monetary Policy Actions and Statements](https://www.federalreserve.gov/pubs/feds/2004/200466/200466pap.pdf)
- [Snowberg, Wolfers & Zitzewitz (2007, AER P&P) — Partisan Impacts on the Economy: Evidence from Prediction Markets and Close Elections](https://www.nber.org/papers/w12073)
- [Della Vedova (SSRN 6191618) — Who Profits from Prediction Markets? Evidence from 222M Trades](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=6191618)
- [Reichenbach & Walther (SSRN 5910522) — Exploring Decentralized Prediction Markets: 124M Polymarket Trades](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5910522)
- [arxiv 2508.03474 — Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (IMDEA AFT 2025)](https://arxiv.org/abs/2508.03474)
- [Medium/PolymarketNow — FedWatch vs Polymarket: Who Leads on Rate Decisions?](https://medium.com/polymarket-now/fedwatch-vs-polymarket-2bc9cdd6239c)

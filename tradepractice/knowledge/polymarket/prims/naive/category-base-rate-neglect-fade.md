---
name: category-base-rate-neglect-fade
level: naive
project: polymarket
parent_prim: none
created: 2026-04-12
last_validated: never
reaction_validated: no
---

## Prim: category-base-rate-neglect-fade
**Level:** naive
**Project:** polymarket
**Parent:** none

### Rule
If a Polymarket market's current YES price deviates by ≥ 15 pp from the empirical resolution base rate for its category (computed from ≥ 30 resolved markets of the same category type), fade toward the base rate. If YES > base_rate + 0.15: BUY NO. If YES < base_rate − 0.15: BUY YES. Apply only to markets with liquidity ≥ $5k, bid-ask ≤ $0.05, resolution horizon 14–90 days. Size via fractional-kelly-sizing α=0.10 (mandatory floor — no own-data calibration). Exit when gap < 8 pp, resolution date within 5 days, or 60-day max hold.

### Mechanism
**Inside view / outside view divergence** (Kahneman & Lovallo 1993, Management Science): decision-makers systematically over-weight the specific details of a case ("inside view" — this particular politician, this particular context) and under-weight the reference class frequency ("outside view" — what fraction of similar events actually resolved YES historically). The result is prediction market prices that are anchored to narrative and case-specific detail rather than calibrated to the unconditional base rate of the category.

**Representativeness heuristic / base-rate neglect** (Kahneman & Tversky 1973, Psychological Review): people assess the likelihood of an event based on how representative it is of a category's stereotype rather than the actual base rate of that category. When a political market involves a charismatic leader described in vivid narrative terms, participants price it based on representativeness — how "president-like" the situation feels — not the empirical rate at which similar binary markets resolve YES.

**Prediction market-specific amplifier**: Polymarket participants are self-selected for having strong opinions about specific events. Participants with inside-view certainty displace participants who might apply reference-class thinking. This creates systematic over-confidence in the current case's uniqueness, amplifying the inside-view bias beyond the laboratory levels documented by Kahneman and Lovallo.

**Signal taxonomy comparison** (why this is distinct from the 19 existing axes):

| Prim | Signal source | Base rate role |
|---|---|---|
| favourite-longshot-bias-fade | Price level extreme (< 0.07 or > 0.93) | Not used — probability weighting at tails |
| superforecaster-consensus-lead | External calibrated platform (Metaculus/GJP divergence) | External; requires platform match |
| llm-ensemble-probability-edge | LLM training corpus base rates via AI inference | External; requires LLM inference call |
| institutional-expert-consensus-reversion | Bloomberg/Reuters consensus for macroeconomic releases | External; narrow category (CPI/NFP/GDP) |
| anchor-event-recency-bias-fade | Cross-event availability: recent salient event inflates target | Event-triggered, not category-level |
| **category-base-rate-neglect-fade** | **PM's own historical resolution frequency by category** | **Internal PM historical data; no external feed** |

**Key distinction from FLB (favourite-longshot-bias-fade)**: FLB operates at extreme probabilities (< 0.07 or > 0.93) and is driven by probability weighting of extreme values. Base-rate neglect fade operates at mid-range probabilities (e.g., YES = 0.60 when category base rate = 0.40) and is driven by case-specific narrative overweighting. They can co-occur (a mid-range market with narrative overlay) or be mutually exclusive (an extreme-probability market with no category base-rate signal).

**Key distinction from anchor-event-recency-bias-fade**: recency bias is triggered by a specific recent salient event in the same category. Base-rate neglect is a standing chronic bias from case-specific narrative anchoring with no required triggering event.

**Fee note**: At target prices YES ∈ [0.30, 0.70], Polymarket fees = fee_rate × p × (1−p) ≈ 0.04 × 0.5 × 0.5 = 1% round-trip. Required edge must exceed this floor. A ≥ 15 pp divergence at α = 0.10 Kelly requires estimated edge ≥ 3 pp (conservative) to justify entry — manageable if base-rate neglect effect is ≥ 5–8 pp at mid-range prices.

### Conditions
- **Works when:** YES price deviates ≥ 15 pp from category empirical base rate (≥ 30 resolved markets); liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 14–90 days; mid-range price YES ∈ [0.20, 0.80] (outside FLB zone; overlapping entry only if both conditions independently met); market title/description contains narrative-laden language (vivid case details suggesting inside-view anchoring); category is elections, politics, geopolitics, or law/regulation (categories with documented narrative salience)
- **Fails when:** Category base rate is uninformative (< 30 resolved markets → insufficient sample) or unstable (base rate computed on stale/structurally different prior cohort — e.g., pre-2022 political markets differ from post-2022 due to platform growth and participant composition change); genuine case-level information justifiably moves the market away from base rate (e.g., candidate withdrawal, court ruling, confirmed intelligence leak — information event, not bias); category base rate is trivially homogeneous (all resolved YES/NO → no variance, no calibration signal); thin liquidity < $5k enables a single institutional position to appear as a bias signal; market is near resolution (< 5 days) — base rates degrade as the specific case has resolved most uncertainty; market type is not binary (range contracts, scalar resolution types — base rates across different underlying outcomes are not comparable)
- **Best pairs:** Elections/politics binary markets where question framing contains vivid narrative (named candidate + vivid scenario); geopolitics binary (named state actor + specific military/diplomatic action); law/regulation binary (named legislation/case + outcome prediction)
- **Best timeframe:** 14–90 day resolution window; enter on narrative surge (news spike about the specific case); exit at gap < 8 pp or 5 days to resolution

### Evidence
- **Source:** paper (cognitive psychology + prediction market calibration) + hypothesis (Polymarket-specific base rate signal untested)
- **Certainty:** hypothesis
- **Data:**
  - **Kahneman & Lovallo (1993, Management Science)** — "Timid Choices and Bold Forecasts: A Cognitive Perspective on Risk Taking": inside view / outside view divergence formalized; corporate planners consistently ignore reference class base rates when evaluating specific projects; effect measured in experimental and field settings; mechanism is independent of expertise level (experts show the bias too)
  - **Kahneman & Tversky (1973, Psychological Review)** — "On the Psychology of Prediction": representativeness heuristic; base-rate neglect demonstrated in probability estimation tasks; participants anchor on case description and ignore prior probabilities even when explicitly provided
  - **Flyvbjerg (2006, Management Science)** — "From Nobel Prize to Project Management: Getting Risks Right": reference class forecasting applied to real-world infrastructure projects; inside view produces systematic 40–200% cost overruns across 258 projects globally; empirically validates Kahneman-Lovallo in high-stakes domain; generalises base-rate neglect beyond laboratory
  - **Tetlock (2005, "Expert Political Judgment")** — expert political forecasters systematically underperform simple base-rate models (chimpanzee baseline); inside-view narrative anchoring cited as primary mechanism; effect strongest for high-narrative, high-certainty cases ("hedgehogs" more overconfident than "foxes"); directly applicable to PM political category
  - **Wolfers & Zitzewitz (2004, JEP)** — PM well-calibrated on average at p ≈ 0.30–0.70; well-calibrated average is **compatible** with systematic sub-category bias (high-narrative vs low-narrative markets could produce opposite errors that cancel in aggregate); does not rule out base-rate neglect as a within-category subcategory phenomenon
  - **Manski (2006, JFE)** — "Interpreting the Predictions of Prediction Markets": documents multiple PM calibration anomalies including category-level deviations; notes that aggregate calibration masks systematic within-category departures
  - **Della Vedova (SSRN 6191618, 2025)** — 222M Polymarket trades; 94% overall accuracy; per-category accuracy not reported; confirms high-accuracy baseline but does not disaggregate by narrative-intensity or base-rate-deviation
  - **No peer-reviewed study directly tests inside-view / base-rate neglect in Polymarket binary markets** — this is the core evidence gap; own-data category resolution frequency database is the mandatory refinement path

### Limitations (7)
1. **Category base rate requires own-data infrastructure (#1 blocker)** — the signal requires a database of historical PM category resolution frequencies. Gamma API provides historical market data; but building a reliable, category-tagged resolution frequency database with ≥ 30 resolved markets per category requires scraping, categorisation, and validation work not yet done. Signal is unusable until this database exists.
2. **Category definition ambiguity** — Polymarket does not provide a standardised category taxonomy. "Politics" contains US elections, foreign elections, legislative votes, executive actions, judicial appointments. Each sub-category may have a very different base rate. Coarse categorisation will produce noisy base rates; fine categorisation will produce too few resolved markets per cell to be reliable.
3. **Structural regime change in PM participant composition** — PM's user base has grown substantially since 2021 and shifted from early crypto-native to broader retail and institutional. Base rates computed on 2021–2022 data may not reflect 2025–2026 participant calibration. Rolling window required; but rolling window reduces sample size further.
4. **Information vs. bias confound** — the primary identification problem: when YES deviates from category base rate, it is either (a) base-rate neglect bias (traders anchored on narrative, ignorant of reference class) or (b) genuine information updating (the specific case has properties that legitimately justify deviation). Differentiating (a) from (b) is the central methodological challenge and requires event-specific controls not formalised at naive level.
5. **FLB interaction at extremes** — if base-rate neglect moves YES below 0.10 or above 0.90 for a mid-range category, FLB and base-rate neglect effects compound. Double-counting position sizing risk; need mutual exclusion or explicit combining rule at intermediate level.
6. **Edge may be zero for institutionalised markets** — in high-liquidity political markets (YES > $200k liq), sophisticated participants with reference class awareness may already arbitrage base-rate deviations, leaving residual edge below fee floor. Likely operates primarily in $5k–$50k liquidity range where retail narrative-anchoring dominates.
7. **No implementation** — new strategy file required; no category-resolution database; no narrative-intensity scorer (required to identify inside-view anchoring conditions vs information conditions)

### Implementation
- **New file:** `src/strategies/base_rate_neglect_fade.py`
- **Required infrastructure:** `src/data/category_base_rates.py` — Gamma API scraper + category tagger + resolution frequency aggregator (BLOCKING: must exist before live deployment)
- **Key logic:**
  ```python
  def compute_signal(market, base_rate_db):
      yes_price = market['yes_price']
      category = classify_category(market['title'])  # NLP classifier
      base_rate = base_rate_db.get_rate(category, min_n=30)
      if base_rate is None:
          return None  # insufficient sample — skip
      gap = yes_price - base_rate
      if gap >= BASE_RATE_GAP_THRESHOLD:  # default 0.15
          return Signal(direction='NO', gap=gap, mechanism='base_rate_neglect')
      elif gap <= -BASE_RATE_GAP_THRESHOLD:
          return Signal(direction='YES', gap=abs(gap), mechanism='base_rate_neglect')
      return None

  BASE_RATE_GAP_THRESHOLD = 0.15  # minimum deviation threshold
  MIN_LIQUIDITY = 5000
  MAX_BID_ASK = 0.05
  MIN_RESOLUTION_DAYS = 14
  MAX_RESOLUTION_DAYS = 90
  FLB_EXCLUSION_ZONE = (0.07, 0.93)  # defer to FLB prim at extremes
  ```
- **Sizing:** fractional-kelly-sizing sophisticated at α=0.10 (mandatory — no calibration history)
- **Category classifier:** NLP on market title; initial taxonomy: {elections_US, elections_foreign, legislation, executive_action, judicial, geopolitical_conflict, crypto_regulation, sports_championship} — each category requires separate base rate cell

### Conditions Log Entry
- Works when: YES deviates ≥ 15 pp from category empirical base rate (≥ 30 resolved markets in cell); liquidity ≥ $5k; bid-ask ≤ $0.05; resolution 14–90 days; mid-range YES ∈ [0.20, 0.80]; narrative-laden market framing suggesting inside-view anchoring
- Fails when: Insufficient base rate sample (< 30 resolved markets per category cell); genuine information updating masquerading as bias; structural regime change in PM participant composition (rolling window degradation); thin-liquidity adversarial selection; FLB zone overlap without combining rule; market within 5 days of resolution
- Last validated: never

## Refinement History
- 2026-04-12 (cycle 104): Created as naive prim. 20th polymarket prim class. Inside-view / outside-view mechanism grounded in Kahneman & Lovallo (1993) and Kahneman & Tversky (1973) representativeness heuristic. Distinct from all 19 prior classes: uses PM's own historical category resolution frequencies as the reference signal (internal, no external feed required once database is built). Primary blocker: category-resolution database does not yet exist. 7 limitations documented. Zero own-data. 8-source academic basis.

## Next Refinement Path (Intermediate)
Four upgrades required:
1. **Category-resolution database** — pull all PM resolved markets from Gamma API (available from 2021–present); tag by category using NLP classifier; compute empirical resolution frequency per category cell (target: ≥ 8 cells × ≥ 30 resolved markets = 240+ resolved markets minimum). Validate category tagger precision ≥ 0.85 on manual spot-check sample (N=50).
2. **Rolling window calibration** — compute base rates on rolling 24-month window only (structural regime change guard). Compare 12m vs 24m vs all-time base rates; if correlation < 0.80 across windows → category unstable → mark ineligible.
3. **Information vs. bias gate** — formalise an event-specific confound test at entry: check for breaking news (GDELT velocity > 2×baseline) within 24h of signal generation; if yes → flag as possible genuine-information-updating → reduce to 0.5× position or skip. Category base-rate gate still applies but with explicit uncertainty discount.
4. **IS backtest** — for each category cell with ≥ 30 resolved markets: compute WR of base-rate-fade signals at ≥ 15 pp gap. Mann-Whitney U test vs null WR 0.50 at p < 0.10. If ≥ 3 category cells pass → signal real; if 0–2 cells pass → mechanism too weak or confound dominates → anti-prim.

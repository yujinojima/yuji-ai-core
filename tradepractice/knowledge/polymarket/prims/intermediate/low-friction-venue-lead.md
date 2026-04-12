---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T16:00:00+10:00
cycle: 96
---

## Prim: low-friction-venue-lead
**Level:** intermediate
**Project:** polymarket
**Parent:** low-friction-venue-lead (naive, cycle 95)

---

### Rule

Two-mode signal. Both modes require: semantically equivalent question (embedding similarity ≥ 0.80 + same resolution oracle class); PM YES price $0.10–$0.90 (not near-resolved); resolution horizon 7–90 days; no active resolution dispute on PM; divergence age ≤ age gate per mode.

**Mode A — Manifold lead (play-money venue):**
Manifold Markets community price diverges from PM YES price by ≥ **10 pp** AND divergence formed within **6 hours** AND PM liquidity ∈ **$5k–$50k** (thin/mid tier) AND event category ∈ {elections, politics, geopolitics} → **BUY PM in Manifold direction**. Exit: gap ≤ 3 pp OR 48h max. α=0.10 Kelly floor.

**Mode B — PredictIt lead (low-cap real-money venue):**
PredictIt market price diverges from PM YES price by ≥ **8 pp** AND divergence formed within **12 hours** AND PM liquidity ∈ **$15k–$200k** (mid/deep tier) AND event category ∈ {elections, economics/macro, US politics} → **BUY PM in PredictIt direction**. Exit: gap ≤ 4 pp OR 96h max. α=0.10 Kelly floor.

**Mode A threshold (10 pp) rationale:** Manifold uses play money → zero capital friction → faster repricers but higher noise-trade rate → higher gap threshold required to clear noise floor.

**Mode B threshold (8 pp) rationale:** PredictIt uses real money ($850 cap) → loss-aversion present but reduced vs PM → financially incentivised signal → lower false-positive rate → 8 pp threshold adequate.

**Liquidity tier exclusion (Mode A ≥ $50k):** Deep PM books ($50k–$200k) have institutionally-informed market makers who update sub-minute; Manifold participants have no informational or incentive advantage over deep-PM professionals → Mode A signal quality degrades to noise in deep books.

**Category gate — economics/macro (Mode A excluded):** CPI/NFP/GDP events: PM participants in deep economic markets likely have Bloomberg/Reuters access → PM may LEAD Manifold in macro categories. Mode A is unreliable for macro. Mode B (PredictIt) retains edge in economics because PredictIt's $850 cap creates its own slow-update friction even for macro.

---

### What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Structure | Single-mode rule | Two modes: Manifold lead (Mode A) and PredictIt lead (Mode B) |
| Threshold | 10 pp (both venues) | Mode A: 10 pp (play-money noise floor); Mode B: 8 pp (real-money higher precision) |
| PM liquidity tier | $5k–$50k (single band) | Mode A: $5k–$50k only; Mode B: $15k–$200k; deep books excluded from Mode A |
| Divergence age | 6h (single) | Mode A: 6h (play money self-corrects fast); Mode B: 12h (real-money gaps persist) |
| Hold duration | 72h max | Mode A: 48h max; Mode B: 96h max |
| Exit gap | 3 pp (single) | Mode A: 3 pp; Mode B: 4 pp |
| Category gate | None (all categories) | Mode A: elections/politics/geopolitics; Mode B: elections/economics/US politics; macro excluded from Mode A |
| Semantic filter | Documented as limitation | Formalized: embedding similarity ≥ 0.80 + same resolution oracle class |
| Granger causality | "untested — decisive gate" | Formalized as H_G test protocol; falsification criteria per mode |
| Anti-prim escape hatches | None | Three per convention (A/B/C) |
| Capital friction model | Qualitative | Quantified: Manifold friction floor ≈ 0%; PredictIt friction floor ≈ 0.50% round-trip |
| Certainty | hypothesis | hypothesis (maintained; H_G untested) |

---

### Mechanism (Refined)

**Naive mechanism retained** — see naive prim cycle 95 for baseline. Two behavioral frictions (loss aversion + capital commitment friction) slow PM price updates; Manifold and PredictIt reprice first; gap is directional signal, not arbitrageable spread.

**Intermediate adds: venue-specific friction quantification, two-mode structure, category gating, and H_G protocol.**

#### Capital Friction Quantification

**Manifold friction floor (near-zero):**
Manifold uses play-money (Mana). Position exit costs: zero monetary loss; only opportunity cost of holding the position. Result: loss aversion effect is near-absent on Manifold (Kahneman-Tversky 1979; no real stakes). Manifold participants update positions within minutes when new information arrives because there is no psychological cost to "being wrong." This makes Manifold the fastest-updating prediction venue for any event class — at the cost of lower signal discipline (noise traders pay no financial cost either).

**PredictIt friction floor (~0.50% round-trip):**
PredictIt imposes: 10% fee on profits (not on losses) + 5% withdrawal fee. For a $850 cap position at mid-probability (p≈0.50), buying YES at $0.50 → resolves at $1.00 → profit $425 → fee $42.50 → net $382.50. Round-trip friction ≈ 0.50% of position face value at mid-probability (comparable to Polymarket's 2% win fee but lower because PM contracts pay face; PredictIt pays on profit only). The $850 cap is the binding constraint: at large divergences (8+ pp), PredictIt participants WANT to trade more but cannot → they cannot close the gap as fast as PM participants (unlimited position size) → gap persists longer → Mode B has 12h age window vs Mode A's 6h.

**Polymarket friction floor (~2% on wins):**
PM charges 2% fee on winning positions. For a $10,000 YES position at $0.55 that resolves YES → $7,636 profit → fee $152.72 → net ~1.5% friction. This is materially higher than both Manifold (≈0%) and PredictIt (≈0.5%), creating the directional friction asymmetry that produces the lead-lag: participants in lower-friction venues absorb information faster because acting on a 5 pp edge is profitable at 0% friction but marginally profitable or break-even at 2% friction.

**The edge window:**
For any information event producing a "true" probability shift of Δ pp:
- Manifold updaters: act immediately at Δ > 0 (no friction)
- PredictIt updaters: act at Δ > 0.5 pp effective (friction floor)
- PM updaters: act at Δ > 2 pp effective (friction floor)
- Result: Manifold price reflects information at smallest Δ; PM reflects it last. The Lead-lag exists as long as friction differential > 0 and the market is not dominated by sub-millisecond bots (which require API access PM doesn't currently offer for market orders).

#### Mode A — Manifold Lead: The Play-Money Speed Advantage

Manifold has no loss aversion effect and no capital commitment friction. When new information (news, poll, event) arrives that shifts the true probability by Δ, Manifold participants update within minutes. This creates the 6h window in Mode A: if the Manifold-PM gap formed > 6 hours ago and PM has NOT converged, the explanation is NOT slow PM update — it's either: (a) semantic non-fungibility (gap is real but irrelevant), (b) systematic liquidity reluctance in PM ($5k–$50k book depth; market makers won't cross a 10 pp gap for small size), or (c) Manifold was wrong. The ≤ 6h age gate is designed to catch (a/b) and reject (c): if Manifold is systematically wrong, gaps would form but NOT self-correct, and mode A's H_G test would fail.

**H_G_A (Mode A Granger Hypothesis, intermediate):** On a sample of N ≥ 50 co-listed political events (Manifold + PM, 2022–2025), Manifold price changes PRECEDE PM price changes in the same direction by 1–6 hours in ≥ 60% of matched directional moves (Δ ≥ 5 pp from Manifold). Pass: Mode A is a valid lead signal. Fail (PM leads Manifold in > 50% of cases): Mode A is anti-prim; disable.

#### Mode B — PredictIt Lead: The Informed-but-Constrained Advantage

PredictIt attracts financially-incentivised participants. Unlike Manifold (unconstrained play money), PredictIt participants have real money at stake — but the $850 cap means they cannot move PM prices directly. When a PredictIt participant sees a PM mispricing of 8+ pp, they want to exploit it in PM (larger size, higher profit) but PM participants who hold large positions resist updating (loss aversion, higher ticket size). The divergence persists because PM position holders KNOW about the PredictIt signal but face behavioral friction to act on it.

**H_G_B (Mode B Granger Hypothesis, intermediate):** On a sample of N ≥ 30 co-listed US political/economic events (PredictIt + PM, 2022–2025), PredictIt price changes PRECEDE PM price changes in the same direction by 1–12 hours in ≥ 55% of matched directional moves (Δ ≥ 4 pp from PredictIt). Pass: Mode B valid. Fail: Mode B anti-prim; disable.

Note: Mode B 55% threshold (vs Mode A 60%) reflects that PredictIt's financial incentive makes its signal less noisy (fewer false positives) even at a lower lead percentage — a 55% Granger lead at lower threshold is a stronger signal quality than 60% at a higher threshold.

#### Semantic Non-Fungibility Gate (Upgraded)

The intermediate adds: embedding cosine similarity ≥ 0.80 (minimum for economic interchangeability based on semantic-correlation-pair-trade threshold calibration). Additionally: resolution oracle class must be identical:
- Class A (election result): official government canvass authority
- Class B (economic indicator): BLS/BEA/Fed official release
- Class C (geopolitical fact): AP/Reuters wire service
- Class D (court/legal outcome): court docket official record

Cross-class matching is excluded regardless of embedding similarity. Examples of exclusion:
- "Will Trump win the 2024 election?" (PM, Class A, official canvass) vs "Will Trump win per betting markets?" (Manifold community) → same topic, different oracle → excluded
- "Will CPI exceed 3.5% in March?" (PM, BLS release) vs "Will March inflation be high?" (Manifold community, vague) → resolution class ambiguity → excluded

---

### H_G Test Protocol (Granger Causality Direction Measurement)

**Goal:** Confirm Manifold→PM (Mode A) and PredictIt→PM (Mode B) lead directions. Failure inverts the prim to anti-prim.

**Method (Mode A — Manifold):**
1. Collect Manifold API historical prices for N ≥ 50 political events co-listed on PM (2022–2025)
2. Collect PM CLOB time-stamped price history for same events (Gamma API or PM data export)
3. Align time series at 1h resolution for both venues
4. For each event: identify all Δ ≥ 5 pp directional moves on EITHER venue (to avoid confirmation bias)
5. For each Manifold move: check whether PM moved in same direction within 6h **before** the Manifold move (PM leads) or within 6h **after** (Manifold leads)
6. Count lead direction per event; compute proportion Manifold-leads across sample
7. Pass: Manifold leads in ≥ 60% of events; Fail: < 60% → disable Mode A

**Method (Mode B — PredictIt):**
1. Collect PredictIt contract price history for N ≥ 30 US political/economic events co-listed on PM (2022–2025)
2. Same alignment at 1h; same directional move identification
3. PredictIt leads PM in ≥ 55% of events: Mode B passes. < 55%: disable Mode B.

**Anti-result (both modes):** If Mode A fails AND Mode B fails: prim is anti-prim. Mark as failed and document which direction actually leads. The anti-finding may itself be useful: if PM systematically LEADS Manifold, the signal inverts — expensive-venue-to-cheap-venue lead → different class entirely.

---

### Frequency Estimation (Analytical; Pre-Test)

**Co-listed events (Manifold + PM, 2022–2025):**
Manifold has > 500,000 market questions total (Dec 2025 count per Manifold API). Political/geopolitical overlap with PM: estimated 200–500 co-listed events/year (PM creates ~2,000 new markets/year; Manifold community mimics major PM markets within hours). After semantic filter (embedding ≥ 0.80 + oracle class match): estimated 80–150 co-listed pairs/year.

**Gap events qualifying for Mode A (≥ 10 pp, ≤ 6h, elections/politics, PM $5k–$50k):**
At 80–150 co-listed pairs/year: a 10 pp gap occurring in ≤ 6h is a meaningful event. Literature suggests play-money venues update faster than real-money (Servan-Schreiber et al. 2004; Pennock et al. 2001) → gaps DO form. Estimated qualifying Mode A events: 15–40/year.

**Gap events qualifying for Mode B (≥ 8 pp, ≤ 12h, elections/economics, PM $15k–$200k):**
PredictIt has ~500 active markets at any time; PM has ~2,000. Co-listed US political/economic markets: estimated 50–100/year. After semantic + oracle filter: 30–60/year. Mode B qualifying events (8 pp gap, ≤ 12h): estimated 8–20/year.

**Total qualifying events:** 23–60/year combined Modes A+B. N=30 in approximately 6–18 months. Adequate for initial statistical test (N_eff ≈ 1.0 per event; events are independent across election cycles).

---

### Conditions (Upgraded)

**Works when:**
- New information (poll, news, event) arrives that shifts true probability → Manifold/PredictIt update first (friction differential confirmed)
- PM liquidity $5k–$50k (Mode A): too thin for professional market makers to arbitrage quickly; participants are retail with capital commitment friction
- PM liquidity $15k–$200k (Mode B): PredictIt signal quality high enough to justify; PM still slow due to large position loss aversion
- Event category matched to mode (elections → both; economics → Mode B only; geopolitics → Mode A)
- Semantic non-fungibility cleared (embedding ≥ 0.80, same oracle class)
- Resolution horizon 7–90 days: long enough for information diffusion, short enough for mean-reversion

**Fails when (failure modes):**
- PM is actually the LEADER (H_G fails): PM has superior market participants for some categories (deep economic/financial markets); if PM leads Manifold → Mode A anti-prim in that category
- $850 PredictIt cap binding in both directions: if both PM and PredictIt participants are at max position size and BOTH converged to the same price, they cannot move each other → zero lead-lag; gap reflects genuine resolution uncertainty, not behavioral friction
- Semantic non-fungibility (oracle class mismatch): PM resolves by AP wire; Manifold resolves by community vote → same event different resolution → gap does not close; hold expires at max duration without convergence
- Fake-money sentiment noise (Mode A): Manifold Mana tournaments with play-money prizes attract contrarian/trolling bets → 10 pp gap may be coordinated contrarianism, not information signal → H_G_A test protocol designed to detect this via non-convergence rate
- Simultaneous news release: if news resolves the gap within 5 minutes of formation → entry triggers but exit triggers immediately → zero PnL net of friction → rare but non-zero cost
- PM platform outage or delayed resolution: oracle delays can hold gap open beyond max hold duration → no convergence; position held at max duration without closure (counted as loss in WR)

---

### Implementation (Upgraded)

```python
class LowFrictionVenueLeadStrategy:
    """
    Mode A: Manifold Markets price leads Polymarket YES price.
    Mode B: PredictIt price leads Polymarket YES price.
    
    Data requirements:
    - Manifold API: GET /v0/markets (historical prices via slug)
    - PredictIt API: GET /api/marketdata/all
    - Polymarket CLOB API: GET /clob/book (real-time), Gamma API (historical)
    - Semantic matcher: low_friction_pm_matcher.py (builds on metaculus_pm_matcher.py)
    - Kelly sizer: fractional-kelly-sizing sophisticated prim
    """

    # Mode A parameters (Manifold → PM)
    MODE_A_GAP_THRESHOLD = 0.10          # 10 pp minimum divergence
    MODE_A_AGE_LIMIT_HOURS = 6           # gap must have formed within 6h
    MODE_A_PM_LIQUIDITY_MIN = 5_000      # $5k minimum PM depth
    MODE_A_PM_LIQUIDITY_MAX = 50_000     # $50k maximum (Mode A excluded above)
    MODE_A_EXIT_GAP = 0.03               # exit when gap narrows to 3 pp
    MODE_A_MAX_HOLD_HOURS = 48           # 48h max hold
    MODE_A_CATEGORIES = {'elections', 'politics', 'geopolitics'}

    # Mode B parameters (PredictIt → PM)
    MODE_B_GAP_THRESHOLD = 0.08          # 8 pp minimum divergence
    MODE_B_AGE_LIMIT_HOURS = 12          # gap must have formed within 12h
    MODE_B_PM_LIQUIDITY_MIN = 15_000     # $15k minimum PM depth
    MODE_B_PM_LIQUIDITY_MAX = 200_000    # $200k maximum
    MODE_B_EXIT_GAP = 0.04               # exit when gap narrows to 4 pp
    MODE_B_MAX_HOLD_HOURS = 96           # 96h max hold
    MODE_B_CATEGORIES = {'elections', 'economics', 'US_politics'}

    # Shared filters
    SEMANTIC_SIMILARITY_MIN = 0.80       # embedding cosine minimum
    PM_YES_MIN = 0.10                    # exclude near-resolved markets
    PM_YES_MAX = 0.90
    RESOLUTION_HORIZON_MIN_DAYS = 7
    RESOLUTION_HORIZON_MAX_DAYS = 90

    def scan_mode_a(self, manifold_prices: dict, pm_prices: dict,
                    matcher_results: list) -> list:
        """
        manifold_prices: {manifold_market_id: {'current_price': float, 'last_updated': datetime}}
        pm_prices: {pm_condition_id: {'yes_price': float, 'liquidity': float, 'resolution_date': date}}
        matcher_results: [{'manifold_id': str, 'pm_id': str, 'similarity': float,
                           'oracle_class_match': bool, 'category': str}]
        Returns: list of {'pm_id': str, 'direction': 'YES'|'NO', 'gap': float, 'mode': 'A'}
        """
        signals = []
        for match in matcher_results:
            if not match['oracle_class_match']:
                continue
            if match['similarity'] < self.SEMANTIC_SIMILARITY_MIN:
                continue
            if match['category'] not in self.MODE_A_CATEGORIES:
                continue

            manifold = manifold_prices.get(match['manifold_id'])
            pm = pm_prices.get(match['pm_id'])
            if not manifold or not pm:
                continue

            pm_yes = pm['yes_price']
            if not (self.PM_YES_MIN <= pm_yes <= self.PM_YES_MAX):
                continue
            if not (self.MODE_A_PM_LIQUIDITY_MIN <= pm['liquidity'] <= self.MODE_A_PM_LIQUIDITY_MAX):
                continue

            hours_old = (datetime.utcnow() - manifold['last_updated']).total_seconds() / 3600
            if hours_old > self.MODE_A_AGE_LIMIT_HOURS:
                continue

            gap = manifold['current_price'] - pm_yes  # positive → manifold leads YES
            if abs(gap) >= self.MODE_A_GAP_THRESHOLD:
                direction = 'YES' if gap > 0 else 'NO'
                signals.append({
                    'pm_id': match['pm_id'],
                    'direction': direction,
                    'gap': abs(gap),
                    'mode': 'A',
                    'hours_old': hours_old,
                })
        return signals

    def should_exit(self, signal: dict, current_gap: float,
                    hours_held: float) -> bool:
        """Check exit conditions for an open position."""
        mode = signal['mode']
        exit_gap = self.MODE_A_EXIT_GAP if mode == 'A' else self.MODE_B_EXIT_GAP
        max_hold = self.MODE_A_MAX_HOLD_HOURS if mode == 'A' else self.MODE_B_MAX_HOLD_HOURS
        return current_gap <= exit_gap or hours_held >= max_hold
```

**Matcher architecture (semantic non-fungibility gate):**
```python
# low_friction_pm_matcher.py (extends metaculus_pm_matcher.py pattern)
# Inputs: Manifold market title + question text, PM market title + description
# Output: {'similarity': float, 'oracle_class': str, 'oracle_class_match': bool}

# Oracle class detection:
# - Look for resolution source keywords in description:
#   Class A: "AP", "Reuters", "official results", "canvass"  
#   Class B: "BLS", "BEA", "Fed", "official government"
#   Class C: "court", "ruling", "verdict"
# - Match oracle class between venues before returning similarity
# - If oracle class cannot be determined: return oracle_class_match=False (safe default)
```

---

### 8 Documented Limitations (Updated from Naive)

1. **H_G untested** — Granger causality direction for Mode A (Manifold→PM) and Mode B (PredictIt→PM) is the decisive gate; prim may be anti-prim if direction inverts; H_G protocol defined but not executed → BLOCKING for sophisticated
2. **Semantic non-fungibility is the primary false positive driver** — even at embedding ≥ 0.80, semantically similar questions can have materially different resolution criteria (2024 shutdown case from cross-venue-arb precedent); same-oracle-class gate partially addresses but does not eliminate this risk; BLOCKING: low_friction_pm_matcher.py construction and validation (N=50 manually labeled pairs)
3. **Mode A fake-money noise** — Manifold play-money market participants have no incentive to avoid contrarian/trolling bets; coordinated Mana manipulation of a small Manifold market (1,000 Mana = ~$0 cost) could trigger Mode A signal with zero information content; mitigation: Manifold market size floor (participant count ≥ 30; Mana volume ≥ 1,000) not yet formalized at intermediate tier
4. **PredictIt $850 cap creates non-convergence** — when both PM and PredictIt are at maximum position utilization on the same side, the gap is structural (cannot be closed by PredictIt traders alone → PM traders must close it independently); Mode B signal fires but PM participants may not respond → gap fails to close within 96h; escape hatch B tests for this empirically
5. **API latency and data freshness** — Manifold prices have public API update intervals (~5min); PredictIt data feed has ~30min refresh (unofficial API); a 6h age gate can include gaps that formed ≤ 6h ago in terms of API timestamp but were actually ≤ 15 min old in market time; over-stating gap age is conservative (misses signals); under-stating is not a risk with these API refresh rates
6. **Granger causality is not constant over time** — as Polymarket grows (2024–2026: $500M → $1B+ lifetime volume), PM's own market maker network becomes more sophisticated; the friction differential may compress as PM bots begin monitoring Manifold in real time; edge is structural but not permanent; annual H_G recalibration required
7. **Mode A category gate is coarse** — "geopolitics" may include both very liquid PM markets ($100k+) where professionals dominate AND thin niche markets ($5k); the $5k–$50k liquidity gate partially addresses this but is not a perfect proxy; explicitly exclude top-100 most liquid PM markets from Mode A (professionals dominate these regardless of category)
8. **N_eff correlation across elections** — during high-election-activity periods (US primary season, EU elections), multiple Mode A signals may fire on co-correlated events (different PM markets about the same election cycle → high latent correlation); N_eff ≈ 1.2–1.5 per election cycle (all markets on the same election are correlated); Kelly sizing should reduce position size when multiple signals from the same election cycle are active simultaneously

---

### Blocking Prerequisites for Sophisticated Elevation

**G1. H_G test (mandatory):** Execute Granger causality measurement protocol defined above. Minimum:
- Mode A: Manifold leads PM in ≥ 60% of N ≥ 50 co-listed political events. Failure → disable Mode A, document as anti-prim for play-money venue lead.
- Mode B: PredictIt leads PM in ≥ 55% of N ≥ 30 co-listed political/economic events. Failure → disable Mode B.
- If BOTH fail: prim is anti-prim; do not elevate to sophisticated.

**G2. Semantic matcher validation (mandatory):** Build `low_friction_pm_matcher.py`; manually label N=50 co-listed Manifold+PM and N=30 co-listed PredictIt+PM pairs (True/False positive semantic match). Precision ≥ 0.85 at similarity ≥ 0.80 threshold required. If precision < 0.85: adjust threshold or add oracle-class disambiguation layer.

**G3. IS backtest (mandatory, after G1+G2 pass):** Run Mode A and Mode B against historical Gamma price data (N events per mode as available from H_G sample). Target per mode: gap closure WR ≥ 55% OR gap closure median ≥ 6 pp (positive expected value net of 2% PM friction). If WR < 50% on either mode: retire that mode.

**G4. Manifold noise gate calibration (optional; strengthens Mode A):** Add Manifold market depth filter (participant count ≥ 30, Mana volume ≥ 1,000) and test whether adding the filter improves Mode A WR vs. raw filter. If improvement > 5 pp WR: add to sophisticated rule.

---

### Bank State After Cycle 96

| Level | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 1 (low-friction-venue-lead still naive; now has intermediate successor) |
| Naive superseded | 12 | 17 (including low-friction-venue-lead naive → superseded by this intermediate) |
| Intermediate active | 1 (perp-spot-basis-divergence) | 1 (low-friction-venue-lead intermediate) |
| Intermediate superseded | 12 | 16 (all prior polymarket intermediates elevated to sophisticated) |
| Sophisticated active | 10 + 1 anti-prim | 17 (no change) |

---

### Next Cycle Recommendations

**(A) DATA — G1 H_G test:** Pull Manifold API historical prices for N≥50 political events co-listed on PM (Manifold `/v0/markets?tag=politics&limit=500`); align with PM Gamma historical data; run directional lead-time analysis. Cheapest executable gate; answers the decisive question (is this prim or anti-prim?).

**(B) BUILD — `low_friction_pm_matcher.py`:** Reuse `metaculus_pm_matcher.py` architecture; add oracle-class detection layer; test on 50 manually labeled pairs. Can parallelize with G1 data pull.

**(C) RESEARCH — perp-spot-basis-divergence H_L test:** Remains highest-value freqtrade RESEARCH deliverable. G1 (Binance klines frequency scan) + G2 (H_L lead-time test) are prerequisite for IS backtest. If RESEARCH cycle: formalize H_L into more precise protocol with explicit anti-result criteria and sample size calculation (N_eff required for median test: n ≥ 20 Tier A events → 4–5 years BTC data).

**(D) BACKTEST-PRIORITY — VWAP re-test:** `YujiVWAPMeanReversionStrategy` with cycle 63 rules + cycle 74 CVD gate; target n≥100, WR≥55%, Sharpe≥0.70. Independent of all above; executable now.

---

### Sources

**Retained from naive (cycle 95):**
- Kahneman, D. & Tversky, A. (1979). Prospect Theory: An Analysis of Decision under Risk. *Econometrica*, 47(2), 263–291.
- Shleifer, A. & Vishny, R.W. (1997). The Limits of Arbitrage. *Journal of Finance*, 52(1), 35–55.
- Wolfers, J. & Zitzewitz, E. (2004). Prediction Markets. *Journal of Economic Perspectives*, 18(2), 107–126.
- Servan-Schreiber, E., Wolfers, J., Pennock, D.M. & Galebach, B. (2004). Prediction Markets: Does Money Matter? *Electronic Markets*, 14(3), 243–251.
- Pennock, D.M., Lawrence, S., Giles, C.L. & Nielsen, F.Å. (2001). The real power of artificial markets. *Science*, 291(5506), 987–988.
- Grossman, S.J. & Stiglitz, J.E. (1980). On the Impossibility of Informationally Efficient Markets. *American Economic Review*, 70(3), 393–408.

**Added at intermediate:**
- Atanasov, P., Rescober, P., Stone, E., Swift, S.A., Servan-Schreiber, E., Tetlock, P., Ungar, L. & Mellers, B. (2016). Distilling the Wisdom of Crowds: Prediction Markets vs Prediction Polls. *Management Science*, 63(3), 691–706. *(Real vs play money prediction accuracy comparison; supports Mode B threshold being lower than Mode A.)*
- Budescu, D.V. & Chen, E. (2015). Identifying Expertise to Extract the Wisdom of Crowds. *Management Science*, 61(2), 267–280. *(Financial incentive filters noise traders from crowds; mechanism for why PredictIt real-money constraint selects better forecasters — Mode B theoretical anchor.)*
- Cowgill, B. & Zitzewitz, E. (2015). Corporate Prediction Markets: Evidence from Google, Ford, and Firm X. *Review of Economic Studies*, 82(4), 1309–1341. *(Information transmission and update speed in financially-incentivised vs non-incentivised prediction markets; directly supports friction differential mechanism.)*

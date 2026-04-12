---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T18:00:00+10:00
cycle: 100
---

## Prim: low-friction-venue-lead
**Level:** sophisticated
**Project:** polymarket
**Parent:** low-friction-venue-lead (intermediate, cycle 96)
**Class:** 19th signal class (elevation from intermediate cycle 96)

**Bank state after cycle 100:** 13 naive / 17 intermediate → 18 sophisticated (polymarket) / 14 sophisticated (freqtrade)

---

### What Changed From Intermediate

Five additions resolving the five blocking prerequisites listed at cycle 96:

1. **Three-tier signal confidence structure** — replaces flat two-mode binary; adds Tier C (highest conviction: both venues agree) and probabilistic Kelly allocation per tier
2. **Full H_G statistical specification** — Granger test formalised with lag selection (BIC), F-statistic, power calculation, multiple-testing correction (Bonferroni-Holm), and explicit anti-result protocol
3. **WR ladder with fee-adjusted breakeven** — per-gap-size expected value table; shows minimum WR required per mode/gap; eliminates marginal-EV entries
4. **10 failure modes enumerated** (intermediate had 6); each with diagnostic signature and operational response
5. **Three anti-prim escape hatches (A/B/C)** — measurable thresholds triggering prim retirement; competitive moat decay model; annual recalibration protocol

---

### Signal Specification (Sophisticated)

#### Three-Tier Confidence Structure

All intermediate two-mode gates retained. Sophisticated adds a confidence tier overlay:

| Tier | Condition | Kelly α | Expected WR | Use |
|------|-----------|---------|-------------|-----|
| **Tier C** (single venue, weak) | Mode A OR Mode B alone; gap at threshold minimum (10pp / 8pp); age ≤ 4h (Mode A) or ≤ 8h (Mode B) | 0.10 | ≥55% | Standard entry |
| **Tier B** (single venue, strong) | Mode A ≥ 15pp OR Mode B ≥ 12pp; age ≤ 3h (Mode A) or ≤ 6h (Mode B) | 0.15 | ≥62% | Size up |
| **Tier A** (both venues agree) | Mode A ≥ 10pp AND Mode B ≥ 8pp in same direction on semantically equivalent events (cross-listed) | 0.20 | ≥68% | Full conviction |

**Tier A trigger mechanism (new at sophisticated):** When the same political event is simultaneously co-listed across Manifold + PredictIt + PM, and BOTH Mode A and Mode B signal the same direction → information from two independent venues with different friction profiles converges → higher P(information is real). Tier A is rare (~4–8 qualifying events/year) but highest-quality.

**Tier B upgrade path:** Any Tier C signal that persists > 2h without PM convergence AND gap WIDENS by ≥ 2pp (PM moving away from lead venue) → upgrade to Tier B (gap widening = PM participants absorbing new information from lead venue but behaving contrarily → classic Kahneman-Tversky loss-aversion fingerprint → stronger signal).

```python
class LowFrictionTier(Enum):
    C = 'standard'     # α=0.10
    B = 'strong'       # α=0.15
    A = 'conviction'   # α=0.20

def assign_tier(signal_a: dict | None, signal_b: dict | None) -> LowFrictionTier:
    """
    signal_a: {'gap': float, 'age_h': float, 'widening': bool} | None
    signal_b: {'gap': float, 'age_h': float, 'widening': bool} | None
    """
    if signal_a and signal_b:
        return LowFrictionTier.A

    active = signal_a or signal_b
    mode = 'A' if signal_a else 'B'

    strong_gap = active['gap'] >= (0.15 if mode == 'A' else 0.12)
    strong_age = active['age_h'] <= (3.0 if mode == 'A' else 6.0)
    if (strong_gap and strong_age) or active.get('widening'):
        return LowFrictionTier.B

    return LowFrictionTier.C
```

---

#### WR Ladder — Fee-Adjusted Breakeven

Polymarket charges 2% fee on wins. For a binary position at price p with gap g:

- Entry price: p (PM YES)
- Exit price (gap closed): p + g
- Fee: 0.02 × (exit face value per share)
- Break-even WR = fee_cost / (profit_if_win × WR - loss_if_lose × (1-WR)) solved for WR

| Mode | Gap (pp) | Entry p | Win profit/share | Fee/share | Break-even WR | Target WR |
|------|----------|---------|-----------------|-----------|---------------|-----------|
| A | 10 | 0.45 | 0.10 | 0.011 | 52.1% | ≥55% |
| A | 12 | 0.44 | 0.12 | 0.012 | 50.4% | ≥58% |
| A | 15 | 0.43 | 0.15 | 0.013 | 48.5% | ≥62% |
| A | 20+ | 0.40 | 0.20 | 0.014 | 46.7% | ≥65% |
| B | 8 | 0.47 | 0.08 | 0.010 | 53.6% | ≥56% |
| B | 10 | 0.46 | 0.10 | 0.011 | 52.1% | ≥59% |
| B | 12+ | 0.44 | 0.12 | 0.012 | 50.4% | ≥63% |

**Key insight:** At 10pp gap, break-even WR is only 52%. If H_G confirms ≥60% directional accuracy → EV is strongly positive even at minimum thresholds. Mode A 10pp entries are the highest-frequency and highest-EV combination assuming H_G passes.

**Entry size scaling (N_eff adjusted Kelly):**
```python
def kelly_size(bankroll: float, tier: LowFrictionTier,
               n_concurrent: int, rho: float = 0.30) -> float:
    """
    n_concurrent: number of active signals from same election cycle (correlated)
    rho: estimated correlation between co-election signals (0.30 default)
    N_eff = n / (1 + (n-1)*rho)  — effective independent positions
    """
    alpha = {LowFrictionTier.A: 0.20, LowFrictionTier.B: 0.15, LowFrictionTier.C: 0.10}[tier]
    n_eff = n_concurrent / (1 + (n_concurrent - 1) * rho) if n_concurrent > 1 else 1.0
    # Scale down by sqrt(N_eff) to prevent over-concentration in election cycles
    return bankroll * alpha / max(n_eff ** 0.5, 1.0)
```

---

### Mechanism (Sophisticated — Full Formalisation)

#### Capital Friction Differential → Information Cascade Lag

**Retained from intermediate:** Three-venue friction stack (Manifold ≈0%, PredictIt ≈0.5%, PM ≈2%) produces directional lead-lag because lower-friction participants absorb probability updates at smaller Δ.

**Added at sophisticated: Information cascade theory (Bikhchandani, Hirshleifer & Welch 1992 JPE).**

A cascade forms when rational agents suppress their private signals and copy observed actions. In PM, large-position holders face a coordination problem: when a 10pp gap appears relative to Manifold, each PM participant knows the gap may be signal — but acting requires:
1. Moving price by 10pp (costs ~$X per share)
2. Accepting the 2% fee
3. Conceding that their prior position was wrong (loss-aversion cost)

The combination of financial friction + cognitive friction (Gennaioli & Shleifer 2010 cascade model) delays PM convergence by 1–6h. This is not arbitrage (risk exists: Manifold may be wrong); it is **friction-discounted information propagation**.

**Three-stage convergence model (sophisticated addition):**

```
Stage 1 (0–2h): Information arrives → Manifold/PredictIt reprice immediately
                 (no financial barrier to being first mover)
Stage 2 (2–6h): PM participants observe gap; cognitive friction (loss aversion)
                 delays entry; sequential updaters begin entering one at a time
Stage 3 (6–48h): Critical mass of PM updaters eliminates gap
                 (social proof cascade — see Watts & Dodds 2007 cascade threshold)
```

**Why the cascade is systematic (not random noise):**
- Manifold noise traders have no P&L signal → their moves are random → the FILTER is the age gate (≤6h). A gap that forms quickly and persists is information-driven (noise quickly self-corrects in Manifold because play-money contrarians lack coordination).
- PredictIt traders have $850 cap → they cannot close PM gaps unilaterally → their persistent divergence is a persistent informed view → Mode B signal is by construction the informed subset.

**Friction floor compression risk (competitive moat decay):**

The edge requires friction differential > 0. Risk factors that compress the differential:
- PM launches zero-fee or sub-1% fee tier for large positions (policy risk)
- PM algorithmic market makers begin monitoring Manifold API in real-time (technology risk)
- Manifold adopts real-money layer (platform risk)
- PredictIt increases cap beyond $850 (regulatory risk — unlikely in near term)

Annual recalibration (anti-prim B) monitors for moat compression. The edge is structural and persists as long as PM's fee structure and PM's participant base remain retail-dominated.

---

### H_G Statistical Specification (Full — Sophisticated)

**Goal:** Confirm causal direction (Granger, 1969) of price leadership in both modes. Resolve the decisive gate from intermediate.

#### Formal test construction

**Null hypothesis (H₀):** Manifold price changes do NOT Granger-cause PM price changes (Mode A). PredictIt price changes do NOT Granger-cause PM price changes (Mode B).

**Test design per event pair:**
1. Collect time series: Manifold price p_M(t), PM price p_P(t) at 1-hour resolution for same event
2. First-difference series to achieve stationarity: Δp_M(t), Δp_P(t)
3. Test VAR(k) model with lag k selected by BIC (k ∈ {1,2,3,4,6}):
   - Δp_P(t) = α + Σ β_j Δp_P(t-j) + Σ γ_j Δp_M(t-j) + ε_P(t)
   - Δp_M(t) = α + Σ β_j Δp_M(t-j) + Σ γ_j Δp_P(t-j) + ε_M(t)
4. F-test on γ coefficients (Δp_M lags in p_P equation): F-stat, df = (k, T-2k-1)
5. Record: direction (M→P or P→M), p-value, lag at peak coefficient

**Multiple-testing correction (N events):**
Apply Bonferroni-Holm across all N event-pair tests. α_corrected = 0.05 / rank (Holm step-down). This is conservative; the final test is the PROPORTION of events showing M→P direction, not each individual p-value.

**Power calculation:**
- Assumed effect: 60% of events show M→P direction (Mode A pass threshold)
- Null: 50% (random direction)
- Two-sided proportion test: z = (p̂ - p₀) / √(p₀(1-p₀)/N)
- At N=50, effect=0.60, α=0.05: power = Φ(z - 1.96) where z = (0.60-0.50)/√(0.50×0.50/50) = 1.41
- Power = Φ(1.41 - 1.96) = Φ(-0.55) = 29% (underpowered at N=50 for one-sided α=0.05)
- **Required N for 80% power:** N = (z_α + z_β)² × p₀(1-p₀) / (p - p₀)² = (1.645 + 0.842)² × 0.25 / 0.01 = 155 events

**Implication:** N=50 is insufficient for 80% power. With N=50, Mode A passes at ≥60% with one-sided z-test at α=0.10 (p-value ≤ 0.10). At N=155 (1–3 years of co-listed political events), upgrade to α=0.05 and 80% power threshold.

**Interim decision rule (N<155, N≥50):**
- Mode A passes at α=0.10 (one-sided), ≥60% M→P direction, N≥50
- Mode B passes at α=0.10 (one-sided), ≥55% PI→P direction, N≥30
- Upgrade to α=0.05 once N≥155 (Mode A) / N≥120 (Mode B)

**Anti-result protocol (if H₀ not rejected):**
- If p̂ < 0.55 (M→P direction): Mode A is noise; disable Mode A
- If p̂ < 0.50: Mode A inverts (PM leads Manifold in this category); document as P→M lead — new anti-prim finding with independent informational value
- Publish negative result to conditions-log as anti-prim A activation condition

```python
from scipy import stats
import numpy as np

def granger_mode_a_test(event_lead_directions: list[str]) -> dict:
    """
    event_lead_directions: list of 'M_leads' | 'P_leads' | 'concurrent' per event
    Returns: {'pass': bool, 'p_hat': float, 'p_value': float, 'N': int, 'verdict': str}
    """
    N = len(event_lead_directions)
    n_m_leads = sum(1 for d in event_lead_directions if d == 'M_leads')
    p_hat = n_m_leads / N

    # One-sided proportion test: H0: p <= 0.50, H1: p > 0.50
    result = stats.binomtest(n_m_leads, N, p=0.50, alternative='greater')
    alpha = 0.05 if N >= 155 else 0.10

    if p_hat >= 0.60 and result.pvalue <= alpha:
        verdict = 'PASS — Mode A valid'
    elif p_hat < 0.50:
        verdict = 'ANTI-PRIM — PM leads Manifold; invert or disable'
    else:
        verdict = f'FAIL — insufficient Manifold lead (p_hat={p_hat:.2f}, p={result.pvalue:.3f})'

    return {'pass': verdict.startswith('PASS'), 'p_hat': p_hat,
            'p_value': result.pvalue, 'N': N, 'alpha': alpha, 'verdict': verdict}
```

---

### Manifold Noise Gate (Formalised — Sophisticated)

**Intermediate limitation #3** (fake-money contrarians) resolved. Add to Mode A mandatory pre-filter:

```python
# Manifold market quality gate — applied before Mode A gap check
MANIFOLD_MIN_UNIQUE_TRADERS = 30    # < 30 traders → coordinated noise risk
MANIFOLD_MIN_VOLUME_MANA = 1_000    # < 1,000 Mana → illiquid; gap is structural not informational
MANIFOLD_MIN_COMMENTS = 5           # < 5 comments → no participant engagement → ghost market

def manifold_quality_pass(market: dict) -> bool:
    """market: Manifold API /v0/markets response object"""
    return (
        market.get('uniqueBettorCount', 0) >= MANIFOLD_MIN_UNIQUE_TRADERS
        and market.get('volume', 0) >= MANIFOLD_MIN_VOLUME_MANA
        and market.get('commentsCount', 0) >= MANIFOLD_MIN_COMMENTS
    )
```

**Calibration note:** These thresholds are conservative defaults. After IS backtest (G3), compare WR for noise-gate-filtered vs unfiltered Mode A signals. If filtered WR improves ≥ 3pp: retain gate. If improvement < 3pp: gate adds no value; remove to avoid signal elimination.

---

### 10 Failure Modes

| # | Failure Mode | Diagnostic Signature | Operational Response |
|---|---|---|---|
| 1 | **H_G inverts (PM leads Manifold)** | p̂ < 0.50 in H_G_A test; PM moves BEFORE Manifold in > 50% of events | Disable Mode A; document inversion as new anti-prim; investigate PM-to-Manifold lead as independent signal |
| 2 | **Semantic non-fungibility (oracle class mismatch)** | Gap forms, holds > 48h, no convergence; Manifold resolves differently than PM on same event | Exit at max hold; flag pair as oracle-class mismatch; retrain semantic matcher on false positive examples |
| 3 | **Manifold coordinated contrarianism** | Mode A gap ≥ 10pp; Manifold uniqueBettorCount < 30; gap does not self-correct within 6h | Noise gate should have blocked entry; if bypassed → exit immediately; add to false-positive log |
| 4 | **PredictIt cap binding (Mode B non-convergence)** | Mode B signal fires; PredictIt contract at max volume cap both sides; no PM movement within 24h | Exit at 48h mark (do not wait full 96h); classify as cap-binding failure; reduce Mode B position size in similar cap-binding environments |
| 5 | **Simultaneous public information release** | Gap forms AND closes within 15 minutes; zero PnL net of fee | Exclude: if gap age < 15 minutes AND Manifold volume spiked > 5× in same 15min window → likely news-driven flash convergence → do not enter |
| 6 | **PM machine learning / API-monitoring bot** | Mode A gaps systematically close within ≤ 30 minutes (pre-6h window); WR of entries within 30min window is ≤ 50% | Reduce Mode A age floor from "≤ 6h" to "≥ 1h AND ≤ 6h" — skip gaps that are too fresh (bot-contested zone); H_G annual recalibration will detect systematic compression |
| 7 | **N_eff over-concentration (election cycle)** | ≥ 4 Mode A signals active simultaneously on the same election; all correlated (ρ ≈ 0.60–0.80) | Apply N_eff Kelly scaling: effective positions = N / (1 + (N-1) × 0.50) ≈ 2.2 for 4 signals → cap total election-cycle allocation at α × 2.2 / bankroll |
| 8 | **Resolution timeline compression** | Event resolves earlier than expected (e.g., election called at 80% before counting complete) → PM jumps to 0.90+ → Mode A gap closes but not via convergence; PM exit at max price ≠ profitable exit | If PM YES > 0.85 → abandon convergence trade; exit immediately regardless of gap; resolution risk dominates friction signal |
| 9 | **Manifold platform rule change (play-money devaluation)** | Manifold introduces real-money layer OR changes Mana pricing → friction differential shifts unexpectedly | Monitor Manifold changelog monthly; if fee structure changes → run mini H_G re-test on 20 most recent events before continuing Mode A deployment |
| 10 | **Category bleed (Mode A macro contamination)** | A "politics" question actually resolves on economic indicator (e.g., "Will US enter recession?" → NBER determination) → categorised as geopolitics but actually macro → PM likely leads Manifold | Add resolution-oracle-class to category filter: if oracle class = B (economic indicator) → force Mode B regardless of keyword-based category tag |

---

### 3 Anti-Prim Escape Hatches

**Anti-prim A — Granger Direction Failure:**
Trigger: H_G_A test result: p̂ < 0.55 (Manifold leads PM in < 55% of events) at N ≥ 50 AND H_G_B test result: p̂ < 0.52 (PredictIt leads PM in < 52% of events) at N ≥ 30. Both modes fail simultaneously.
Action: Retire entire prim. Document as anti-prim. If H_G reveals systematic PM→Manifold lead: begin separate research into PM-led venue-lag signal (inverted class).
Threshold: Both tests fail at their respective minimum pass thresholds.

**Anti-prim B — Competitive Moat Compression (WFE Degradation):**
Trigger: Annual WFE (Walk-Forward Evaluation) over trailing 12 months shows Mode A WR < 52% (5pp below IS target) AND Mode B WR < 51% (5pp below IS target) at N ≥ 15 events per mode. OR: average gap closure time drops below 2h for Mode A (bot-monitoring has eliminated the friction window).
Action: Suspend deployment; run diagnostic on friction differential. If Manifold API response time vs PM API response time has compressed to < 15 minutes → edge has been captured by faster participants; retire prim.
Threshold: WFE WR degradation > 5pp below IS baseline, maintained over 12-month trailing window.

**Anti-prim C — Semantic Matcher Precision Collapse:**
Trigger: In forward-test sample of N ≥ 30 new event pairs evaluated by `low_friction_pm_matcher.py`, manually-labeled precision drops below 0.75 (vs IS precision ≥ 0.85). Indicates oracle-class detection is failing on newer PM market question formats.
Action: Retrain matcher; add additional oracle-class disambiguation rules; do not deploy new signals until precision ≥ 0.82 on re-test sample. If matcher cannot recover above 0.82 after two retraining rounds: retire Mode A (semantic non-fungibility is uncontrollable).
Threshold: Precision < 0.75 at N ≥ 30 forward-test pairs.

---

### Deployment Gates (G1–G6)

**G1. H_G test execution (mandatory, Mode A):**
- Pull Manifold API historical prices: `/v0/markets?tag=politics&limit=500` (2022–2025)
- Pull PM Gamma historical data for same events (co-listed matching via `low_friction_pm_matcher.py`)
- Align at 1h resolution; run directional lead-time analysis per H_G protocol above
- Pass: Mode A ≥ 60% M→P direction at N ≥ 50, α=0.10. Fail → Mode A disabled.
- Duration estimate: 2–3 days of data engineering + 1 day analysis

**G2. H_G test execution (mandatory, Mode B):**
- Pull PredictIt contract price history: PredictIt public API `/api/marketdata/all` (historical export)
- Co-list with PM Gamma for same events
- Pass: Mode B ≥ 55% PI→P direction at N ≥ 30, α=0.10. Fail → Mode B disabled.
- Can parallelize with G1.
- Duration estimate: 1–2 days

**G3. Semantic matcher validation (mandatory):**
- Build `low_friction_pm_matcher.py` on `metaculus_pm_matcher.py` architecture
- Add oracle-class detection layer (keyword-based + regex for resolution source)
- Label N=50 Manifold+PM pairs and N=30 PredictIt+PM pairs manually (True/False match)
- Pass: precision ≥ 0.85 at similarity threshold 0.80. Fail: adjust threshold or add rules.
- Duration estimate: 2–3 days

**G4. IS backtest (mandatory, after G1+G2+G3 pass):**
- Use H_G sample events as IS backtest universe
- Apply full sophisticated rule (3-tier structure, WR ladder, N_eff Kelly, noise gate)
- Pass per mode: WR ≥ 55% (Tier C) AND median gap closure ≥ 6pp (positive EV)
- If either mode fails: retire that mode; continue with passing mode only
- Duration estimate: 1–2 days

**G5. Manifold noise gate calibration (mandatory, Mode A only):**
- Split IS sample into noise-gate-filtered vs unfiltered
- If filtered WR improvement ≥ 3pp: retain noise gate thresholds as specified
- If < 3pp: set MANIFOLD_MIN_UNIQUE_TRADERS = 10 (loosen to avoid over-filtering)
- Duration estimate: 0.5 days

**G6. N_eff calibration (mandatory, before live deployment):**
- Estimate empirical ρ between co-election signals using IS sample correlation matrix
- If empirical ρ > 0.50: use ρ=0.50 in N_eff formula (conservative)
- If empirical ρ < 0.20: set N_eff = N (treat as independent; no scaling)
- Publish ρ estimate to conditions-log
- Duration estimate: 0.5 days

---

### Epistemic Quality (Louca et al.)

| Dimension | Naive | Intermediate | Sophisticated |
|-----------|-------|-------------|---------------|
| Source | anecdote | paper + protocol | paper + full statistical spec |
| Certainty | guess | hypothesis (H_G untested) | hypothesis → tested upon G1–G2 execution |
| Scope | one venue pair | two modes, political categories | three tiers, 10 failure modes, annual recalibration |
| Falsifiability | vague | H_G pass/fail defined | H_G fully specified with sample size, power, anti-result |
| Limitations | 3 | 6 (documented) | 10 (enumerated with diagnostic signatures) |
| Reaction validated? | assumed | assumed | partially (H_G protocol executes on historical data) |

**Certainty post-G1–G2:** hypothesis → evidence (if H_G passes both modes)
**Certainty post-G3–G4:** evidence → forward-tested upon WFE accumulation

---

### Competitive Moat Analysis

**Sources of edge (ranked by durability):**

1. **Friction differential is structural** (highest durability): PM's 2% fee model is a business model, not a temporary condition. As long as PM charges ≥ 2% and Manifold charges ≈ 0%, the lag exists. Cannot be arbed away without PM changing its fee structure. Durability: 2–5+ years.

2. **Semantic matching infrastructure** (medium durability): The bottleneck for competition is not knowing the signal exists — it is building a reliable semantic matcher with oracle-class detection. This is a 2–3 week engineering project. Once competitors build it (likely eventually), Mode A edge compresses. Durability: 1–3 years before widespread replication.

3. **PredictIt $850 cap** (medium durability): Structural barrier. PredictIt cap is regulatory constraint (CFTC no-action letter). Durable as long as CFTC regulatory posture unchanged. Durability: unknown regulatory horizon, likely 1–5 years.

4. **Information-cascade timing** (lowest durability): As PM grows in participant count and as bots proliferate, Stage 1 convergence time (0–2h) will compress. The 6h Mode A age gate may need to tighten to 3h within 2–3 years. Annual anti-prim B WFE test is the monitoring mechanism.

**Moat compression indicators to monitor (quarterly):**
- Average Mode A gap closure time (target: stays > 2h; alarm: drops < 1h for > 3 months)
- Mode A WR trend (target: stable ≥ 55%; alarm: rolling 3-month WR < 52%)
- Manifold API traffic patterns (if PM begins making Manifold API calls → bot monitoring has started)

---

### Updated Conditions

**Works when (additional sophistication-tier conditions):**
- H_G confirmed (G1+G2 passed): both mode directions empirically established
- Semantic matcher precision ≥ 0.85 (G3 passed): false positive rate controlled
- Gap is ≥ 2h old (Stage 2 cascade initiation phase): bots have not contested; humans are the updaters
- PM YES price $0.15–$0.85 (tighter than intermediate's $0.10–$0.90): outer extremes are resolution-risk-dominated, not friction-dominated

**Fails when (new at sophisticated, in addition to intermediate failures):**
- Gap formed < 1h ago (failure mode 6: bot-contested zone; wait for Stage 2)
- N_eff scaling produces position < $50 (signal not worth acting on at sub-minimum size)
- Tier A signal: both modes agree but in OPPOSITE directions (contradiction → no entry; resolution oracle class mismatch likely)
- Anti-prim A, B, or C triggered (immediate suspension)

---

### Sources

**Retained from intermediate (cycles 95–96):**
- Kahneman, D. & Tversky, A. (1979). Prospect Theory. *Econometrica*, 47(2), 263–291.
- Servan-Schreiber et al. (2004). Prediction Markets: Does Money Matter? *Electronic Markets*, 14(3), 243–251.
- Atanasov et al. (2016). Distilling the Wisdom of Crowds. *Management Science*, 63(3), 691–706.
- Budescu & Chen (2015). Identifying Expertise. *Management Science*, 61(2), 267–280.
- Cowgill & Zitzewitz (2015). Corporate Prediction Markets. *Review of Economic Studies*, 82(4), 1309–1341.
- Wolfers & Zitzewitz (2004). Prediction Markets. *Journal of Economic Perspectives*, 18(2), 107–126.
- Pennock et al. (2001). The real power of artificial markets. *Science*, 291(5506), 987–988.
- Grossman & Stiglitz (1980). On the Impossibility of Informationally Efficient Markets. *AER*, 70(3), 393–408.
- Shleifer & Vishny (1997). The Limits of Arbitrage. *Journal of Finance*, 52(1), 35–55.

**Added at sophisticated:**
- Bikhchandani, S., Hirshleifer, D. & Welch, I. (1992). A Theory of Fads, Fashion, Custom, and Cultural Change as Informational Cascades. *Journal of Political Economy*, 100(5), 992–1026. *(Information cascade formation mechanism; explains why PM participants delay updating despite observing Manifold signal — rational herding under information asymmetry.)*
- Granger, C.W.J. (1969). Investigating Causal Relations by Econometric Models and Cross-spectral Methods. *Econometrica*, 37(3), 424–438. *(Foundational Granger causality test; H_G test construction.)*
- Gennaioli, N. & Shleifer, A. (2010). What Comes to Mind. *Quarterly Journal of Economics*, 125(4), 1399–1433. *(Availability-based cognitive friction; explains why loss-aversion and cognitive anchoring compound PM's delayed updating — Stage 2 cascade delay mechanism.)*
- Bailey, D.H., Borwein, J.M., & Lopez de Prado, M. (2014). Pseudo-Mathematics and Financial Charlatanism. *Notices of the AMS*, 61(5). *(Multiple-testing correction methodology; Bonferroni-Holm application to H_G cross-event testing.)*
- Watts, D.J. & Dodds, P.S. (2007). Influentials, Networks, and Public Opinion Formation. *Journal of Consumer Research*, 34(4), 441–458. *(Cascade threshold model; Stage 3 critical-mass convergence in three-stage PM update model.)*

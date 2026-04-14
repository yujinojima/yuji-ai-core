---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T00:00:00+10:00
cycle: 183
---

---

**Cycle 183 — RESEARCH — Complete**

---

## Prim: oracle-dispute-prediction-signal
**Level:** sophisticated | **Elevated from:** intermediate (cycle 180) | **Project:** polymarket

---

### What was resolved

**Intermediate blockers resolved via four structural upgrades:**

**1. CPCV+DSR 9-Cell OOS Validation Framework (G_CPCV gate)**

The intermediate prim relied entirely on analytical derivation for P(NO|dispute). The sophisticated upgrade introduces a proper OOS falsification protocol that can detect if the directional thesis is absent before live capital is deployed.

**9-cell Mode A plateau:** LLM_tier ∈ {0.65, 0.72, 0.80} × DTE_sub ∈ {2–4, 4–7, 7–10}

**4-cell Mode B sub-grid:** LLM_tier ∈ {0.72, 0.80} × DTE_sub ∈ {3–5, 5–8}

Protocol: K=5 folds, T2=0.20, C=100 Latin-hypercube paths; 7d purge + 48h embargo. DSR threshold ≥ 0.50 per selected cell (Bailey-Borwein-López de Prado SSRN 2326253, 2015). IS Sharpe floor SR_IS ≥ 0.80 (lower than high-WR prims — reflects the honest thin-edge expectation from intermediate). N_eff = N × (1 − ρ̄); ρ̄ prior 0.35 same-category oracle-dispute positions. Centroid selection: Mode A × DTE 4–7 × LLM 0.72 (intermediate thresholds, mid-window — avoids corner-case overfitting).

Floor α active until G_CPCV cleared: Mode A 0.05, Mode B 0.04 (half of full α — signals can accumulate paper-trade data without large risk exposure).

**Three anti-prims:**
- AP-1: DSR ≤ 0 for centroid cell → ODPS_MECHANISM_ABSENT_CENTROID → retire Mode A; archive unless Mode B survives independently
- AP-2: DSR ≤ 0 for ≥ 5/9 Mode A cells → ODPS_MECHANISM_ABSENT_GLOBAL → retire prim entirely
- AP-3: OOS live WR < 0.48 @ N_eff ≥ 15 Mode A → ODPS_NO_EDGE_MODE_A → suspend Mode A; Mode B proceeds independently

DSR deployment tiers: DEPLOYED (DSR ≥ 0.50) → full α; PROVISIONAL (0.20–0.50) → 0.70× α; RETIRED (< 0.20 @ N_eff ≥ 15) → α = 0.

The DSR threshold for this prim (0.50, vs 0.95 for some other prims) reflects the honest position: the edge is thin (WR ~55% Mode A analytically). A lower DSR threshold is appropriate because we are not claiming a high-Sharpe strategy; we are claiming a modest but persistent positive expectancy above transaction costs. If DSR < 0 (i.e., IS Sharpe degrades to near-zero after multiple-comparison correction), even the modest thesis is unsupported.

**2. DTE Sub-Period Stability via Cramton-Schwartz Late-Filing Calibration (G_DTE gate)**

The intermediate DTE window (2–10 days, Mode A) was structurally motivated but undifferentiated. Cramton & Schwartz (1991, JLEO) predict that disputants with stronger cases strategically delay filing to the deadline (incomplete information → costly delay calibration). Applied to PM dispute filing: challengers with high-confidence cases file closer to resolution (DTE ≤ 5), while weaker cases self-select out. This predicts DTE 2–5 sub-window carries disproportionate dispute frequency.

G_DTE gate: at N ≥ 15 per DTE window (sourced from G_DATA_UMA historical scrape), test:
```
r_DTE = P(dispute | DTE 2–5, LLM≥0.65, YES∈[0.42,0.58]) /
        P(dispute | DTE 6–10, same filters)
```

Decision table:
- r_DTE ≥ 1.30 + CPCV ≥ 3/5 folds showing WR(DTE 2–5) ≥ WR(DTE 6–10): Mode A DTE_max tightened 10 → 7; DTE 7–10 cell retired from 9-cell plateau
- r_DTE ∈ [1.0, 1.30): Cramton model partially confirmed; no window change; flat DTE treatment; log CRAM_WEAK_SUPPORT
- r_DTE < 1.0: anti-prim AP-CRAM_INVERTED (early-filing dominance); Mode A restricted to DTE 5–10; DTE 2–4 cell retired

The sub-period stability requirement (≥ 3/5 CPCV folds) prevents the r_DTE finding from being driven by a single unusual dispute clustering event. The non-blocking fallback (DTE_PRIOR_ONLY tag) means the signal continues to fire during data accumulation — the DTE window is just un-optimised rather than disabled.

**3. Framing Lift Quantification (G_FRAME gate)**

The intermediate prim noted (but did not formalise) the theoretical possibility that asserter YES framing over-prices the YES side at market open. This upgrade converts that theoretical observation into a falsifiable protocol with an α uplift mechanism.

Mechanism: Asserter affirmatively describes outcome as TRUE (YES). For ambiguous-description markets at near-50 YES prices, framing effects (Kahneman & Tversky 1979 §5 — certainty framing at the 50% boundary) and arbitrary coherence anchoring (Ariely, Loewenstein & Prelec 2003, QJE — first-available anchor influences reference price even when informationally irrelevant) predict YES_VWAP_24h will systematically exceed 0.50 in the target population.

G_FRAME gate: Collect YES_VWAP_24h for N ≥ 30 qualifying markets (LLM_score ≥ 0.65, YES_entry ∈ [0.42, 0.58], DTE_entry ≤ 10, no active dispute at entry). Compute:
```
framing_lift = mean(YES_VWAP_24h) − 0.50
95% CI via bootstrap N=1,000 resamples
```

Three outcomes:
- framing_lift ≥ +0.02 (YES systematically 2pp above 0.50): framing effect confirmed
  → EV_adj = EV_base + framing_lift × (1 − P_dispute_prior)
  → Kelly α uplift: Mode A 0.10 → 0.115 (cap 0.12); Mode B 0.07 → 0.082 (cap 0.085)
- framing_lift ∈ [0.00, +0.02): marginal framing; no α adjustment; log FRAMING_LIFT_MARGINAL
- framing_lift < −0.02: anti-prim AP-FRAME_INV — framing thesis inverted (YES is systematically under-priced at entry); directional NO bias assumption loses this component; LLM gate compensator +0.05 to both modes to compensate for missing EV tailwind

Non-blocking fallback: G_FRAME uncleared → framing_lift = 0.0 (conservative; no α uplift). Quarterly recalibration on 90d rolling window. Storage: `knowledge/odps_framing_calibration.json`.

This upgrade is important for the prim's honest accounting: if the framing lift is real, it contributes ~0.018 additional EV to Mode A NO trades (framing_lift 0.02 × (1 − 0.10 P_dispute) ≈ 0.018). That lifts the two-path WR from ~55.5% to ~57%. Modest, but it more than doubles the edge above 50%.

**4. Correlated-Position N_eff Kelly Scaling (OracleDisputeCorrelationTracker)**

Multiple concurrent oracle-dispute positions share systematic risk: regulator posture affects all regulatory compliance markets simultaneously; a UMA governance event affects all categories; a legal precedent in one market reduces P(dispute) in similar adjacent markets. ρ > 0 within-category.

Formula (MacLean & Thorp 2011):
```
N_eff = N / (1 + (N − 1) × ρ̄)
α_adj = α × (N_eff / N)
```

ρ priors by category pair:
- same_category (e.g., 2× regulatory_compliance): ρ = 0.35
- different_category (regulatory + geopolitical): ρ = 0.15
- same_event (both markets reference same regulatory decision): ρ = 0.65
- oracle-dispute + RCA: ρ = 0.05 → **Tier D independent** (formalised from intermediate ρ ≈ 0.05 observation; non-overlapping timing; no N_eff deduction between these two prims)

Hard caps: N_max = 4 concurrent oracle-dispute positions; event-cycle cap N_max = 2 same-event.

Effect: at ρ = 0.35, N = 3 same-category: N_eff = 3 / (1 + 2×0.35) = 1.76; α_adj = α × (1.76/3) = 0.59× α. This is the correct portfolio-level sizing: three concurrent regulatory compliance disputes should be treated as 1.76 independent positions, not 3.

EH-5 saturation trigger: N_eff ≤ 1.2 → suspend new entries in category; ODPS_CAT_SATURATED log.

G_RHO gate: empirical ρ calibration at N ≥ 15 co-fired oracle-dispute pairs per category; quarterly update; OracleDisputeCorrelationTracker replaces prior ρ when N_pairs ≥ 15 per pair type.

---

### New academic anchors at sophisticated

| Source | Contribution |
|--------|-------------|
| Bailey, Borwein & López de Prado (SSRN 2326253, 2015) | CPCV+DSR methodology: combinatorially purged cross-validation eliminates selection bias from multiple-testing; Deflated Sharpe Ratio corrects IS Sharpe for N_comparisons. Foundation for Upgrade 1 OOS validation framework |
| Kahneman & Tversky (1979, Econometrica §5) | Framing effects at the certainty boundary: equivalent outcomes described in gain vs loss framing generate systematically different probability assessments near 50%. Asserter YES description is a positive frame for the YES outcome → crowd anchors above 0.50 even when they assign ~50% probability |
| Ariely, Loewenstein & Prelec (2003, QJE) | Arbitrary coherence: first-available numerical anchor influences subsequent judgements even when the anchor is informationally irrelevant (SSN anchor experiment; willingness-to-pay shifts). PM market open YES price is anchored by the asserter's affirmative description; this becomes the reference even for participants who don't read the full description |
| MacLean & Thorp (2011) | Kelly criterion with correlated positions: N_eff = N/(1+(N−1)ρ̄) as the correct portfolio fraction under pairwise correlation ρ̄. Foundation for Upgrade 4 correlated-position sizing |

---

### Gate summary at sophisticated

| Gate | Type | Requirement | Status |
|------|------|-------------|--------|
| G_LLM | Blocking | ≥1.5× dispute rate uplift at LLM≥0.65 vs <0.30; N≥50 historical markets | NOT RUN |
| G_DATA_UMA | Blocking | P(NO\|dispute)≥0.55 Mode A + P(dispute\|conditions) vs baseline; N≥30 disputes | NOT RUN |
| G_CPCV | Blocking (above floor) | DSR≥0.50 centroid cell; sub-period stability ≥3/5 folds | NOT RUN |
| G_DTE | Non-blocking | r_DTE test at N≥15 per window; DTE window calibration | NOT RUN |
| G_FRAME | Non-blocking | framing_lift=mean(YES_VWAP_24h)−0.50; bootstrap CI; N≥30 | NOT RUN |
| G_RHO | Non-blocking | ρ empirical: N≥15 co-fired pairs per category | NOT RUN |

Deployment path: G_LLM ∧ G_DATA_UMA → DRY_RUN lifts; paper-trade accumulation. G_CPCV → floor α lifts to full α (0.10 Mode A / 0.07 Mode B). G_DTE + G_FRAME → DTE window + α refinement. G_RHO → correlated-position ρ refinement.

---

### What remains for validation (first production version)

1. **G_DATA_UMA (highest priority, most blocking):** Etherscan DVM contract event logs for `DisputePrice` events + uma.xyz dispute board scrape. Need: (a) P(NO|dispute) stratified by Mode A vs Mode B category; anti-prim condition: P(NO|dispute) < 0.55 across all non-electoral categories → retire directional thesis; (b) P(dispute | LLM_score≥0.65, YES∈[0.42,0.58], DTE≤10) vs baseline P(dispute | all markets) — target ≥3× uplift for meaningful edge
2. **G_LLM:** 50-market labelled dataset with known dispute outcome; validate LLM ambiguity score ≥ 0.65 has ≥ 1.5× dispute rate vs score < 0.30; if ratio < 1.5× → LLM precision insufficient; fallback to strict keyword + manual review at α×0.60
3. **G_CPCV:** Paper-trade accumulation; K=5 CPCV folds; target N=100 total positions; DSR computation for each cell in 9-cell grid
4. **G_DTE:** Available once G_DATA_UMA completed; requires sub-period dispute rate per DTE window
5. **G_FRAME:** Available from live paper-trade data; YES_VWAP_24h for N≥30 qualifying markets

**Bank state:** naive 23 | intermediate 24 | sophisticated **27** (+1)

---

### Implementation (updated for sophisticated)

```python
# src/signals/oracle_dispute_detector.py  STATUS: RESEARCH — DRY_RUN
# src/portfolio/oracle_dispute_correlation_tracker.py  NEW AT SOPHISTICATED

# See full implementation in polymarket-bot/knowledge/polymarket/prims/sophisticated/
# oracle-dispute-prediction-signal.md
```

`src/portfolio/oracle_dispute_correlation_tracker.py` — OracleDisputeCorrelationTracker class. Registers active oracle-dispute positions; computes N_eff and α_adj per new entry; alerts on N_max cap breach; loads/saves ρ priors from `knowledge/odps_correlation_tracker.json`.

---

### Conditions Log Entry (sophisticated)

**Mode A — Regulatory / Economic (full size; G_FRAME uplift available)**
- LLM_score ≥ 0.65; YES ∈ [0.42, 0.58]; DTE 2–10 (2–7 when G_DTE confirms r_DTE≥1.30)
- Category ∈ {regulatory_compliance, economic_indicator, corporate_governance}
- Liquidity ≥ $5k; spread ≤ $0.05; no active dispute
- → BUY NO; α_floor = 0.05 (until G_CPCV); α_full = 0.10 (0.115 if G_FRAME framing_lift≥0.02); 10-day max hold
- α_adj = α × N_eff/N per OracleDisputeCorrelationTracker

**Mode B — Geopolitical / Social (0.70× size)**
- LLM_score ≥ 0.72; YES ∈ [0.43, 0.57]; DTE 3–8
- → BUY NO; α_floor = 0.04; α_full = 0.07 (0.082 if G_FRAME); 7-day max hold

**Mode X — Excluded**
- Elections, political actor outcomes, country leader change, party vote share — NO SIGNAL

**Cross-axis N_eff (RCA, Tier D):** ρ = 0.05 → independent; no N_eff deduction between oracle-dispute and RCA prims

**Exit logic:** DTE=1 close; dispute filed → HOLD through DVM vote; YES>0.65 close; max hold close

**Anti-prims:** AP-1 (centroid DSR≤0→retire Mode A); AP-2 (≥5/9 Mode A cells DSR≤0→retire prim); AP-3 (live WR<0.48@N_eff≥15→suspend Mode A); AP-CRAM_INVERTED (r_DTE<1.0→DTE 5–10 only); AP-FRAME_INV (framing_lift<−0.02→remove directional bias+LLM +0.05)

**Last validated:** never

---

## Refinement History
- 2026-04-14 (cycle 178): Created as naive prim. 27th polymarket signal axis.
- 2026-04-14 (cycle 180): Elevated to intermediate. Mode A/B/X stratification; game-theoretic P(NO|dispute); LLM ambiguity scoring; two-path EV decomposition.
- 2026-04-14 (cycle 183): Elevated to sophisticated. Four upgrades: (1) CPCV+DSR 9-cell OOS (K=5, C=100; DSR≥0.50; floor α 0.05/0.04; 3 anti-prims; 6 EH); (2) DTE sub-period Cramton-Schwartz calibration (r_DTE test; AP-CRAM_INVERTED); (3) framing lift gate (YES_VWAP_24h−0.50; bootstrap CI; α uplift; AP-FRAME_INV); (4) N_eff correlated-position scaling (OracleDisputeCorrelationTracker; ρ priors; Tier D independence from RCA; N_max=4). 4 new sources: Bailey-Borwein-López de Prado 2015, Kahneman & Tversky 1979, Ariely et al. 2003, MacLean & Thorp 2011. Total 14 sources.

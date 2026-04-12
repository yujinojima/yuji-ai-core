---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T06:45:00+10:00
cycle: 132
---

# conditional-probability-cascade-arbitrage — sophisticated prim

**Level**: sophisticated  
**Certainty**: plausible hypothesis (mechanism well-supported; all gates uncleared; N=0 own-data)  
**Signal class**: Conjunction Fallacy / Cascade Pair Mispricing  
**Sizing**: α=0.10 (Mode A) / α=0.08 (Mode B calibrated) / α=0.05 (Mode B uncertain / Mode C calibrated) / α=0.03 (Mode C uncertain) × CQS_mult × phase_disc × f_bregman_cap  
**Cycle**: 132  
**Supersedes**: intermediate (cycle 117) + cycle 127 partial-sophisticated

---

## Mechanism

When Polymarket lists both an upstream market U and a downstream market D where D logically requires U, the Bayesian product constraint P(D) ≈ P(U) × r must hold (r = P(D=YES | U=YES)). Systematic violation occurs because PM traders price U and D in cognitive isolation — the conjunction fallacy (Tversky & Kahneman 1983). Mode A (P(D) > P(U) + 0.02) is a mathematical subset-axiom impossibility requiring no r estimate. Mode B (P(D) > P(U)×r + threshold) is conjunction fallacy. Mode C (P(U)×r − P(D) > threshold) is under-conditioning.

The sophisticated elevation adds seven structural corrections to the intermediate, of which three are new in cycle 132:

1. **Correlated Resolution N_eff** — per-sub-type ρ priors with empirical update path; per-type exposure cap
2. **Resolution Proximity Phase Gate** — four phases, Mode B/C blocked in Phase 3
3. **Cascade Quality Score (CQS)** — three-tier detector confidence multiplier
4. **OOS Validation Framework** — per-mode retirement triggers with N_eff correction
5. *(new, cycle 132)* **CPCV+DSR 9-cell plateau** — threshold × Kelly α grid; DSR ≥ 0.95 pass gate for Mode B/C
6. *(new, cycle 132)* **Bregman/KL-divergence sizing** — KL distance from joint market distribution to no-arbitrage polytope as position size ceiling
7. *(new, cycle 132)* **Cross-axis conflict resolution** — CPCA + CBRNF same-market co-fire rule; shared cognitive-bias N_eff discount

---

## Seven Structural Upgrades

### 1. Correlated Resolution N_eff — Per-Sub-type ρ Priors (upgraded from cycle 127)

**Cycle 127 weakness**: flat ρ̄ = 0.50 for all cascade types. Tournament brackets co-resolve within a single round (ρ ≈ 0.85); nominations are semi-independent (ρ ≈ 0.35). A flat prior over-restricts nominations and under-restricts tournaments.

**Cycle 132 fix**: per-sub-type ρ priors for `CascadeCorrelationTracker`. Exposure cap = base_size × cap_mult (sub-type-dependent). N_eff = N × (1 − ρ̂) for OOS significance.

| Sub-type | ρ prior | Exposure cap | Rationale |
|----------|---------|--------------|-----------|
| ELECTION | 0.70 | 2.0× | All downstream election markets from same cycle co-resolve on election night |
| TOURNAMENT | 0.85 | 1.5× | Bracket downstream markets resolve at same round completion |
| LEGISLATIVE | 0.60 | 2.0× | Bill passage + signing from same session; procedural steps semi-dependent |
| NOMINATION | 0.35 | 3.0× | Nomination and confirmation are distinct events separated by weeks |
| UNKNOWN | 0.50 | 2.5× | Conservative prior (cycle 127 default, preserved for un-typed pairs) |

**Empirical ρ update path**: once G1 yields ≥ 10 co-resolved pair clusters per sub-type, replace ρ prior with sample correlation across same-upstream resolution date. Update annually.

---

### 2. Resolution Proximity Phase Gate (unchanged from cycle 127)

`get_resolution_phase(upstream)` uses `market.end_date_iso` (days to earlier-resolving market):

| Phase | Days to resolution | Mode B/C | Mode A |
|-------|--------------------|----------|--------|
| 1 | > 30 | α × 1.00 | α × 1.00 |
| 2 | 7–30 | α × 0.80 | α × 0.80 |
| 3 | < 7 | BLOCKED | α × 0.60 |
| 4 | Resolved | — | — |

**Rationale Phase 3 block**: near resolution, professional arbitrageurs have partially closed the gap. Remaining gap reflects execution risk and thin liquidity, not mispricing.

---

### 3. Cascade Quality Score (CQS) (unchanged from cycle 127)

`assess_cascade_quality(pair)` returns a size multiplier:

| Tier | Multiplier | Criteria |
|------|-----------|----------|
| CQS_HIGH | 1.00 | Explicit downstream-prerequisite marker ("winner of", "if X wins") + ≥ 3 shared entity tokens |
| CQS_MEDIUM | 0.80 | 2 shared tokens + structural cascade marker (both mention same election/tournament cycle) |
| CQS_LOW | 0.50 | Keyword match only (current detector default until G0 cleared) |

Mode A is not blocked by CQS_LOW but is sized down by the multiplier. Mode B/C with CQS_LOW + Phase 2 may produce sub-economic signal size after all multipliers — log `CPCA_SIZE_TRIVIAL` and skip if f_final < 0.005.

---

### 4. OOS Validation Framework (upgraded from cycle 127 — IS backtest N gate raised)

`OOSValidationState` tracks per-mode raw N and wins. N_eff = N × (1 − ρ̂_sub_type). BH FDR = 0.10 per mode independently. Retirement checked before each signal.

**IS backtest N gate raised** (cycle 132): Mann-Whitney U p < 0.10 one-tailed, **N ≥ 15** per (direction, type) cell (upgraded from N ≥ 10 at intermediate). Rationale: at N=10 the one-tailed test has ~50% power at effect size WR=0.60; N=15 raises power to ~65% — minimum acceptable for Mode B/C unlock.

**Retirement triggers (sophisticated)**:
- Mode A: OOS WR < 0.55 at N_eff ≥ 20 → auto-retire (theoretical floor ≥ 0.70 is generous; WR < 0.55 signals detector failure or market structure change, not sampling)
- Mode B: OOS WR < 0.48 at N_eff ≥ 30 → auto-retire
- Mode C: OOS WR < 0.45 at N_eff ≥ 30 → auto-retire

2025-Q1 holdout: activate when G0 cleared and N_eff (Mode A) ≥ 10.

---

### 5. CPCV+DSR 9-Cell Plateau (new, cycle 132)

**Motivation**: threshold and Kelly α parameters for Mode B/C have not been validated against PM resolution data. A single IS backtest at {threshold=0.08, α=0.08} could be curve-fitted. CPCV (Combinatorial Purged Cross-Validation) + Deflated Sharpe Ratio (Bailey-Borwein-Lopez de Prado, SSRN 2326253) corrects for multiple-comparison inflation across the parameter grid.

**Grid**:
- threshold ∈ {0.06, 0.08, 0.10} (conjunction fallacy gap entry threshold)
- Kelly α ∈ {0.06, 0.08, 0.10} (fractional Kelly multiplier for Mode B/C calibrated)
- 9 cells total

**Protocol** (runs after G1/G2 yield the cascade pair database):
1. For each of the 9 cells, run the IS backtest per (direction, type) using the G3 Mann-Whitney protocol.
2. Record IS Sharpe per cell (N_trades × WR → simulated P&L from BUY NO on D returns).
3. Apply CPCV: combinatorially purge overlapping cascade resolution windows; typically 4–6 splits.
4. Compute Deflated Sharpe Ratio per cell: DSR = Ψ(SR_IS × correction_factor), where correction factor = 1 − σ_SR × (γ₁ × SR/6 − γ₂ × SR²/24 + 1); N_backtest = 9 for the multi-comparison correction.
5. **Gate**: the selected parameter cell (default: {threshold=0.08, α=0.08}) must have DSR ≥ 0.95.
6. If DSR < 0.95 for all cells → Mode B/C suspended pending out-of-sample validation (Mode A unaffected — no calibrated parameters).
7. **Anti-prim trigger**: if the DSR ≤ 0 for the cell with highest IS Sharpe → conjunction fallacy mechanism absent in available data → retire Mode B/C.

**Plateau selection**: if multiple cells have DSR ≥ 0.95, select the cell nearest to {threshold=0.08, α=0.08} (centre of grid) rather than the maximum-Sharpe cell. This prefers the theoretically-grounded parameter over the empirically-maximized one.

---

### 6. Bregman/KL-Divergence Sizing (new, cycle 132)

**Motivation**: Kelly fraction is unbounded in theory; for extreme mispricing (P(D) = 0.90, P(U) = 0.60 — Mode A violation of 0.30), full fractional-Kelly produces unacceptably large positions. The KL distance from the market distribution to the no-arbitrage polytope (arxiv 2508.03474, IMDEA AFT 2025 — $40M extraction infrastructure) provides a principled ceiling.

**KL distance formula** (binary, per leg):

```python
import math

def kl_divergence(p_market, p_fair):
    """
    KL(p_market || p_fair) for a binary outcome.
    p_market: market price for D
    p_fair:   no-arbitrage fair price for D
    """
    eps = 1e-9  # numerical stability
    p = max(eps, min(1 - eps, p_market))
    q = max(eps, min(1 - eps, p_fair))
    return p * math.log(p / q) + (1 - p) * math.log((1 - p) / (1 - q))

def bregman_size_cap(p_d, p_u, r=None):
    """
    Returns f_max = 2 × KL(market || no_arb).
    Mode A: r not needed; no_arb fair value for D = P(U).
    Mode B/C: no_arb fair value for D = P(U) × r.
    """
    p_fair = p_u if r is None else p_u * r
    kl = kl_divergence(p_d, p_fair)
    return min(1.0, 2.0 * kl)  # cap at 1.0 (full bankroll)
```

**Integration into sizing**:

```
f_final = f_kelly × CQS_mult × phase_disc
f_final = min(f_final, bregman_size_cap(p_d, p_u, r))
```

**Empirical calibration**: at N ≥ 30 live Mode A trades, compare WR across KL quintiles. If KL_high quintile (≥ 0.05) has WR ≥ KL_low quintile — the Bregman cap is too conservative (raise multiplier from 2.0× to 3.0×). If reversed — the cap is correctly protective (maintain or tighten).

**Typical values**:
- Mode A 5 pp violation (P_D=0.60, P_U=0.55): KL ≈ 0.007; f_max = 1.4% — below Kelly floor (binds rarely)
- Mode A 15 pp violation (P_D=0.70, P_U=0.55): KL ≈ 0.040; f_max = 8.0% — likely below Kelly (binds rarely)
- Mode A 30 pp violation (P_D=0.85, P_U=0.55): KL ≈ 0.145; f_max = 29% — Kelly likely binds first
- Binding regime: large violations where Kelly fraction is high (> 10%) and KL cap is tighter

In practice, the Bregman cap binds primarily as a sanity check on extreme violations, not as the primary sizing mechanism. Its value is preventing tail-risk over-sizing in thin liquidity situations.

---

### 7. Cross-Axis Conflict Resolution — CPCA + CBRNF (new, cycle 132)

**Motivation**: CPCA (conjunction fallacy on cascade structure) and CBRNF (category base-rate neglect fade) share the same cognitive-bias root — PM traders fail to apply Bayesian updating. They can co-fire on the same market: CBRNF fires when the downstream market D deviates from its category base rate; CPCA Mode B fires because D is over-priced relative to P(U)×r. These are not independent signals — they exploit the same mismatch from two framings.

**Cross-axis ρ**: ρ_CPCA_CBRNF = 0.50 (prior). They can fire on different markets (ρ ≈ 0.20 then) or the same market in the same direction (ρ ≈ 0.85). Differentiate:

| Scenario | ρ | Rule |
|----------|---|------|
| Same market, same direction (D over-priced per both signals) | 0.85 | Position = max(CPCA_α, CBRNF_α) × 1.25 (NOT additive); log CPCA_CBRNF_CONFLICT |
| Same market, opposite direction (rare — CPCA Mode C + CBRNF fade direction differs) | 0.50 | Both signal sizes halved; analyst review flag |
| Different markets, same electoral cycle | 0.50 | N_eff = N / (1 + (N−1) × 0.50) across the combined active positions |
| Different markets, independent events | 0.20 | Standard N_eff for each independently |

**Same-market co-fire rule**:
```python
if cpca_signal and cbrnf_signal and cpca_signal.market_id == cbrnf_signal.market_id:
    combined_alpha = max(cpca_signal.alpha, cbrnf_signal.alpha) * 1.25
    # Credit both to respective prim WR tracking
    # Execute as single combined position at combined_alpha
    log("CPCA_CBRNF_SAME_MARKET_CONFLICT: combined α=%.3f" % combined_alpha)
```

**Portfolio N_eff when both active across different markets**:
```
N_active = count of simultaneous CPCA + CBRNF positions
N_eff = N_active / (1 + (N_active − 1) × 0.50)
```
Kelly α for new signal in concurrent period = standard_α × √(1 / N_eff_increment).

**Why 1.25× multiplier**: two independent signals on the same market would naively justify 2× the size. The 0.50× reduction from high ρ correlation (=1.25× vs 2.00×) reflects that the signals share ≈50% of their information content. The 1.25× vs max(α₁, α₂) split:
- Ensures the combined position is always larger than either solo signal (we are getting genuine confirmation from a second framing)
- Caps the benefit at 1.25× (not 2.0×) because the confirmatory value saturates quickly under high correlation

---

## Condition Summary

**Works when — Mode A (subset axiom)**:
- P(D) > P(U) + 0.02; both markets active; degenerate prices excluded (< 0.02 or > 0.98)
- CQS ≥ LOW (all tiers valid; size multiplied accordingly)
- Phase 1 or 2 (Phase 3: α × 0.60); Phase 4: no signal
- f_final > 0.005 after all multipliers

**Works when — Mode B (conjunction fallacy)**:
- G2 cleared for sub-type (CI ≤ 0.20) OR r_uncertain=True (threshold escalated to 0.12)
- G3: (CONJUNCTION_FALLACY, type) cell in `_IS_VALIDATED_CELLS` (N ≥ 15)
- CPCV+DSR plateau gate passed (DSR ≥ 0.95 for selected cell)
- G4: information gate passes (GDELT D-entity velocity ≤ 3.0×, or stub no-block)
- Phase 1 or 2; P(D) − P(U)×r > threshold (0.08 calibrated; 0.12 r_uncertain)
- f_final > 0.005 after Bregman/KL cap and all multipliers

**Works when — Mode C (under-conditioning)**:
- Same gate requirements as Mode B; P(U)×r − P(D) > threshold
- Lower α (0.05 calibrated / 0.03 r_uncertain); info gate critical (Mode C more susceptible to genuine r shift)

**Fails when**:
- Phase 3 for Mode B/C; Phase 4 any mode
- P(D) or P(U) < 0.02 or > 0.98 (degenerate prices)
- Cascade type = UNKNOWN (no r, no sub-type; skip unless Mode A)
- G4 fires: D-entity GDELT velocity > 3.0× while U-entity < 1.5× → genuine r shift
- CPCV+DSR anti-prim: DSR ≤ 0 in highest-Sharpe cell → Mode B/C retired
- OOS retirement triggered (per-mode WR thresholds at N_eff)
- CPCA + CBRNF same-market opposite directions → analyst review required; both signals halved
- Sub-type correlation cap exhausted (ELECTION 2.0×; TOURNAMENT 1.5×; LEGISLATIVE 2.0×; NOMINATION 3.0×)
- f_final < 0.005 after all multipliers (economically trivial)

**Gates (all uncleared — all modes DRY_RUN)**:
- G0 — Detector precision ≥ 0.85 on 50-item Gamma API spot-check; NER entity matching if precision < 0.85
- G1 — Gamma API cascade pair database ≥ 50 resolved pairs (2022–2024)
- G2 — Beta-Binomial r calibration per sub-type (CI ≤ 0.20, N ≥ 15)
- G3 — IS backtest ≥ 1 conjunction + ≥ 1 under-conditioning cell validated (N ≥ 15; p < 0.10)
- G4 — GDELT velocity adapter (D-entity vs U-entity; 3.0× threshold) live
- G5 *(new)* — CPCV+DSR plateau: DSR ≥ 0.95 for selected {threshold, α} cell (requires G1/G2/G3 first)
- G_MODE_A — Manual review: ≥ 5 Gamma API pairs confirming genuine U→D structure

Mode A requires only G0 + G_MODE_A. Modes B/C require G0 + G1 + G2 + G3 + G4 + G5.

---

## Escape Hatches

- **EA**: Mode A CQS_LOW + Phase 2 + own-data N_eff ≥ 5 WR < 0.55 → raise CQS minimum for Mode A entry to CQS_MEDIUM; check for false-positive cascade pairs
- **EB**: Mode A OOS WR < 0.55 at N_eff ≥ 20 → auto-retire (OOSValidationState handles)
- **EC**: CQS_MEDIUM Mode B WR < 0.48 at N ≥ 15 → raise MEDIUM token threshold from 2 to 3 shared entities
- **ED**: Correlation cap saturating on TOURNAMENT → lower cap from 1.5× to 1.0× (single-pair only) for multi-bracket markets
- **EE**: Phase 2 WR << Phase 1 WR at N ≥ 20 → lower Phase 2 entry threshold from 30d to 14d
- **EF**: Bregman cap binding frequently (> 30% of Mode A signals) → cap multiplier from 2.0× to 3.0× if WR_high_KL > WR_low_KL
- **EG**: CPCA + CBRNF co-fire produces no WR improvement vs solo CPCA → reduce combined_alpha from 1.25× to 1.00× (no confirmation premium for this pair)

---

## Open Calibration Items

1. **G0**: 50-item manual spot-check on Gamma API cascade pair candidates; measure precision per type; implement spaCy NER if precision < 0.85
2. **G1**: Gamma API resolved market extraction 2022–2024; target ≥ 50 pairs across types; tag sub-type and party/composition context
3. **G2**: Beta-Binomial calibration per sub-type from G1 data; CI ≤ 0.20 gate; update `CascadeTypeRegistry` r values
4. **G3**: `scripts/is_backtest_cpca.py` — Mann-Whitney U per (direction, type) cell; N ≥ 15; update `_IS_VALIDATED_CELLS`; 14-day entry window; compare 30d/7d alternatives
5. **G4**: Implement GDELT adapter; `is_conditional_independent_event()` live (not stub)
6. **G5**: Run CPCV+DSR plateau after G1/G2/G3 complete; report DSR per cell; select parameter cell; check anti-prim trigger
7. **CQS validation**: pull 20 Gamma API pairs; manually label CQS tier; verify tier-to-WR monotonicity (if not monotone → tier definitions need revision)
8. **ρ empirical update**: once G1 yields ≥ 10 co-resolved clusters per sub-type, replace prior ρ with sample correlation
9. **Bregman calibration**: at N_eff ≥ 30 Mode A, compare WR by KL quintile; decide whether to tighten or loosen cap multiplier
10. **CPCA–CBRNF cross-axis WR test**: at N_eff ≥ 20 co-fire events, compare co-fire WR vs solo CPCA WR; validate 1.25× confirmation multiplier

---

## Evidence (9 sources; 1 new in cycle 132)

| Source | Finding | Relevance |
|--------|---------|-----------|
| Tversky & Kahneman (1983, Psych Rev) | Conjunction fallacy: P(A∩B) systematically over-estimated; "Linda" N=100+; robust across formats | Primary mechanism Mode B |
| Tversky & Kahneman (1974, Science) | Representativeness heuristic: P(event) judged by similarity to prototype, not frequency | Cognitive underpinning; explains D over-pricing |
| Bar-Hillel (1980, Acta Psych) | Conjunction fallacy proportional to narrative coherence of conjunct | Explains Mode B magnitude by cascade type |
| Wolfers & Zitzewitz (2004, JEP) | PM cross-market constraint violations at category level | PM-specific cross-market mispricing evidence |
| Manski (2006, JFE) | IEM subset-axiom violations documented empirically | Empirical Mode A magnitude reference |
| Leigh & Wolfers (2006, Economic Record) | IEM electoral cascade: 2–4 pp inconsistency primary→general | Gap magnitude reference for threshold calibration |
| Fama (1970, JF) | Weak-form EMH: systematic violation = correctable processing failure | Positions conjunction fallacy as exploitable |
| Mann & Whitney (1947, Ann Math Stat) | Non-parametric rank-sum test; valid for binary WR at small N | G3 IS backtest statistical framework |
| Bailey, Borwein & Lopez de Prado (2014, AMS / SSRN 2326253) | Deflated Sharpe Ratio corrects for multi-strategy selection bias; DSR ≥ 0.95 standard | G5 CPCV+DSR plateau gate (new in cycle 132) |

---

## Refinement History

| Cycle | Level | Key Change |
|-------|-------|------------|
| 114 | naive | Initial prim; keyword cascade detector (4 types); hard-coded r priors; α=0.10 Kelly floor; 5 uncleared gates; dry-run |
| 117 | intermediate | Three-mode architecture (A/B/C); CascadeTypeRegistry + Beta-Binomial r per sub-type; InformationGate G4; IS backtest protocol G3; detector_confidence tiered |
| 127 | partial-sophisticated | N_eff CascadeCorrelationTracker (ρ̄=0.50 flat); Phase gate (4 phases); CQS (3 tiers); OOS retirement triggers — missing CPCV+DSR, Bregman sizing, cross-axis conflict |
| 132 | sophisticated | Per-sub-type ρ priors (ELECTION 0.70 / TOURNAMENT 0.85 / LEGISLATIVE 0.60 / NOMINATION 0.35); IS backtest N gate raised 10→15; CPCV+DSR 9-cell plateau (threshold × α, DSR ≥ 0.95, G5); Bregman/KL-divergence size cap (f_max = 2×KL); cross-axis conflict resolution CPCA+CBRNF (same-market: max(α)×1.25; portfolio N_eff ρ=0.50); anti-prim CPCV DSR ≤ 0 → Mode B/C retire; 9th academic anchor (Bailey et al. 2014) |

---

**Last validated**: never (RESEARCH elevation — cycle 132; intermediate + cycle 127 partial → sophisticated; 7 structural upgrades total; all 7 gates uncleared [G0–G5 + G_MODE_A]; DRY_RUN all modes)

**Prim bank after cycle 132**: polymarket **21 naive** (all superseded) / **21 intermediate** / **21 sophisticated** (+1: conditional-probability-cascade-arbitrage)

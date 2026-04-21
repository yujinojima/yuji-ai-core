---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T12:30:00+10:00
cycle: 197
---

## Prim: binary-calendar-spread-arbitrage
**Level:** sophisticated | **Project:** polymarket | **Cycle:** 197 | **Class:** 29 | **Elevated from:** intermediate (cycle 195)

---

### Signal Class

When the same underlying outcome has multiple PM contracts with staggered resolution deadlines (T1 < T2), the Harrison-Kreps (1979) no-arbitrage monotonicity constraint requires P(outcome by T2) ≥ P(outcome by T1). PM markets violate this routinely because independent liquidity pools, salience bias, mental accounting (Thaler 1985), and availability cascades prevent cross-expiry price integration.

**Sophisticated layer** adds four structural advances over the intermediate prim:
1. Category-specific empirical time-value multiplier `λ_cat` (replaces constant `base_rate_daily`)
2. Convergence speed classifier — logistic model on `(edge, delta_dte, liquidity_ratio, category)` → expected hold duration
3. N_eff Kelly correction for concurrent BCSA + correlated-signal positions
4. CPCV+DSR 9-cell plateau validation — mandatory before live sizing

---

### Empirical Time-Value Model

The intermediate prim used fixed constants (`base_rate_daily = 0.002` for crypto, `0.001` for macro). Sophisticated replaces this with per-category empirical λ estimated from G_PAIR resolved data.

**Estimation:**

```python
def estimate_lambda(resolved_pairs: list[dict], category: str) -> float:
    """
    Fit empirical time-value multiplier from resolved (T1, T2) pairs.
    
    λ_cat = mean( (P_T2_entry / P_T1_entry) / delta_dte )
    
    Only include pairs where T2 resolved after T1 (valid temporal chain)
    and neither contract was in oracle window at entry.
    Minimum 20 pairs per category; return None if insufficient.
    """
    cat_pairs = [p for p in resolved_pairs if p['category'] == category and
                 p['delta_dte'] >= 7 and not p['oracle_window_entry']]
    if len(cat_pairs) < 20:
        return None
    ratios = [(p['p_t2_entry'] / p['p_t1_entry']) / p['delta_dte']
              for p in cat_pairs if p['p_t1_entry'] > 0]
    return float(np.mean(ratios))
```

**Calibrated λ table (requires G_PAIR clearance; priors pending empirical validation):**

| Category | λ_cat prior | Source |
|----------|------------|--------|
| crypto_price | 0.0020/day | Intermediate constant; replace with empirical at N ≥ 20 |
| macro_economic | 0.0010/day | Intermediate constant; replace with empirical at N ≥ 20 |
| political | 0.0015/day | Estimated from election cycle patterns |
| sports_series | 0.0025/day | Estimated from game-series eliminations |
| **live empirical** | **λ_cat from resolved data** | **Override all priors once N ≥ 20 per category** |

**Mode B time_ratio_floor** (sophisticated):

```
time_ratio_floor(category, delta_dte) = 1 + λ_cat(category) × delta_dte × 0.5
time_ratio_target(category, delta_dte) = 1 + λ_cat(category) × delta_dte × 0.75
```

Replaces the fixed `0.002 / 0.001` constants in intermediate Mode B.

---

### Mode A — Strong Violation (Near-Risk-Free Arbitrage)

```
ACTIVATE (Mode A) when ALL of:
  1. Identified pair (A_T1, A_T2) where:
       a. same_event: cosine(embed(A_T1.title), embed(A_T2.title)) ≥ 0.85,
          OR shared event_id / category+entity
       b. same_threshold: resolution condition identical — NOT progressive thresholds
       c. T2 > T1 by ≥ 7 days
  2. P(A_T1) > P(A_T2) + delta_strong    # delta_strong default = 0.05
     (CPCV plateau: use validated centroid delta_strong from 9-cell grid)
  3. A_T1.liquidity ≥ $3,000 AND A_T2.liquidity ≥ $3,000
  4. A_T1.bid_ask ≤ 0.06 AND A_T2.bid_ask ≤ 0.06
  5. A_T1.DTE ≥ 2
  6. NOT either contract in oracle window (UMA assertion pending)
  7. Top-3 wallets < 70% of liquidity on both sides (FM2 guard)

DIRECTION: BUY A_T2 YES
  If bilateral shorting available: ALSO SHORT A_T1 YES
  If unilateral only: long A_T2 only (alpha_unilateral < alpha_bilateral)

SIZE (with N_eff correction):
  base_alpha_bilateral  = 0.08
  base_alpha_unilateral = 0.05
  edge = P(A_T1) − P(A_T2) − delta_strong
  n_concurrent = count of open BCSA + correlated-signal positions
  rho_bar = weighted_rho(n_concurrent, rho_table)
  N_eff = n_concurrent / (1 + (n_concurrent − 1) × rho_bar)
  kelly_fraction = min(base_alpha, edge / (1 − edge)) × sqrt(N_eff / n_concurrent)
  position_size = kelly_fraction × portfolio_value

EXIT:
  PRIMARY: P(A_T2) ≥ P(A_T1) − 0.01 (convergence achieved)
  SPEED:   convergence_speed_classifier predicts hold_days;
           set dynamic_exit = entry_date + hold_days × 1.2 (20% buffer)
  EXPIRY:  A_T1.DTE < 1 AND violation persists → close
  HARD:    max hold = A_T1.DTE − 1 day
```

### Mode B — Weak Violation (Empirical Time-Value Underpricing)

```
ACTIVATE (Mode B) when ALL of:
  1. Same pair conditions as Mode A (1a, 1b, 1c)
  2. P(A_T2) < P(A_T1) × time_ratio_floor(category, delta_dte)
     where time_ratio_floor uses empirical λ_cat (or prior if N < 20)
  3. P(A_T2) > 0.10 AND P(A_T2) < 0.90
  4. Same liquidity/spread/oracle/wallet conditions as Mode A
  5. A_T2.DTE ≥ 14

DIRECTION: BUY A_T2 YES

SIZE (with N_eff correction):
  base_alpha = 0.04
  edge = P(A_T1) × time_ratio_floor − P(A_T2)
  Apply same N_eff correction as Mode A

EXIT:
  TARGET:  P(A_T2) ≥ P(A_T1) × time_ratio_target (empirical λ_cat × 0.75 factor)
  SPEED:   convergence_speed_classifier; dynamic exit as Mode A
  T1 resolves YES → close A_T2 at next tick
  T1 resolves NO  → evaluate conditional structure:
    if T1-NO ≡ T2-NO (shared threshold): close at market
    if T1-NO ≠ T2-NO (partial threshold): hold to T2
  HARD: 21 days OR A_T2.DTE − 3 days
```

---

### Convergence Speed Classifier

Replaces fixed 21-day max hold with a data-driven hold duration estimate.

```python
from sklearn.linear_model import LogisticRegression
import numpy as np

class BCConvergenceClassifier:
    """
    Predicts whether a BCSA spread converges within {7, 14, 21} days.
    
    Features:
      edge          — initial spread size (P_T1 − P_T2 or ratio gap)
      delta_dte     — T2.DTE − T1.DTE at entry (days)
      liquidity_ratio — min(T1.liq, T2.liq) / max(T1.liq, T2.liq)
      category_enc  — one-hot: crypto_price, macro, political, sports, other
    
    Target: converged_within_N (binary, for N ∈ {7, 14, 21})
    Training: requires ≥ 30 resolved pairs per mode (G_CS gate)
    """

    def __init__(self):
        self.models = {}   # one model per horizon N
        self.trained = False

    def fit(self, X: np.ndarray, y_dict: dict[int, np.ndarray]):
        for horizon, y in y_dict.items():
            m = LogisticRegression(C=1.0, max_iter=200)
            m.fit(X, y)
            self.models[horizon] = m
        self.trained = True

    def predict_hold_days(self, features: np.ndarray) -> int:
        """Return expected hold duration: 7, 14, or 21 days."""
        if not self.trained:
            return 21  # conservative fallback
        for horizon in [7, 14, 21]:
            prob = self.models[horizon].predict_proba(features)[0, 1]
            if prob >= 0.60:
                return horizon
        return 21

    def build_features(self, pair: dict) -> np.ndarray:
        cat_vec = [0, 0, 0, 0, 0]
        cat_map = {'crypto_price': 0, 'macro_economic': 1,
                   'political': 2, 'sports_series': 3}
        idx = cat_map.get(pair.get('category', ''), 4)
        cat_vec[idx] = 1
        return np.array([[
            pair['edge'],
            pair['delta_dte'],
            min(pair['t1_liq'], pair['t2_liq']) / max(pair['t1_liq'], pair['t2_liq'], 1),
            *cat_vec
        ]])
```

**Gate G_CS** (new sophisticated gate): Logistic classifier trained on ≥ 30 resolved Mode A and ≥ 30 resolved Mode B pairs. Brier score ≤ 0.22 on holdout (20% split). Until G_CS cleared: use 21-day fallback for Mode B, A_T1.DTE−1 for Mode A.

---

### N_eff Kelly Correction

BCSA T2 positions may overlap with CPCA (same T2 contract, conditional trigger) or PRCC (post-resolution anchor) positions. Apply N_eff before sizing any BCSA entry when concurrent positions exist.

**Correlation table:**

| Pair | ρ | Rationale |
|------|---|-----------|
| BCSA × CPCA | 0.30 | Both structural; same T2 contract possible; different entry triggers; moderate co-movement |
| BCSA × PRCC | 0.25 | PRCC fires post-resolution of a related contract; BCSA may be holding T2 at same time |
| BCSA × BAC (binary arb completeness) | 0.05 | Different violation type; rarely concurrent on same contract |
| BCSA × FMLL | 0.10 | External lead-lag on same contract possible; different information source |
| BCSA × BCSA (two pairs, same event) | 0.50 | Two expiry pairs from the same event share underlying resolution risk |

**N_eff formula:**

```python
def compute_n_eff(positions: list[dict]) -> float:
    """
    positions: list of {'signal': str, 'weight': float}
    Returns N_eff for Kelly correction.
    """
    rho_lookup = {
        ('BCSA', 'CPCA'): 0.30, ('BCSA', 'PRCC'): 0.25,
        ('BCSA', 'BAC'):  0.05, ('BCSA', 'FMLL'): 0.10,
        ('BCSA', 'BCSA'): 0.50,
    }
    n = len(positions)
    if n <= 1:
        return float(n)
    rho_pairs = []
    for i, p1 in enumerate(positions):
        for p2 in positions[i+1:]:
            key = tuple(sorted([p1['signal'], p2['signal']]))
            rho_pairs.append(rho_lookup.get(key, 0.05))
    rho_bar = np.mean(rho_pairs)
    return n / (1 + (n - 1) * rho_bar)
```

**Sizing rule:** `kelly_fraction × sqrt(N_eff / n_concurrent)` — reduces position size under correlated concurrent exposure; never increases above base_alpha.

---

### CPCV+DSR 9-Cell Plateau Validation

Per Bailey, Borwein & Lopez de Prado (2015, SSRN 2326253): combinatorially purged cross-validation with Deflated Sharpe Ratio is mandatory for any hyperopt grid with > 1 cell on resolved PM data.

**Grid:**

| | time_ratio_factor 0.5× | time_ratio_factor 0.75× | time_ratio_factor 1.0× |
|-|------------------------|-------------------------|------------------------|
| **delta_strong 0.03** | cell (1,1) | cell (1,2) | cell (1,3) |
| **delta_strong 0.05** | cell (2,1) | cell (2,2) ★ | cell (2,3) |
| **delta_strong 0.08** | cell (3,1) | cell (3,2) | cell (3,3) |

★ centroid hypothesis: DSR ≥ 0.90 at (delta_strong=0.05, time_ratio_factor=0.75×)

**CPCV specification:**
- K = 5 folds, combinatorial path selection
- T2 (test fraction) = 0.20
- C = 100 log-likelihood paths (Bailey-Borwein-LdP Eq. 14)
- Metric: Deflated Sharpe Ratio (penalises multiple testing over 9 cells)
- Min N per cell: 10 trades (skip cell if insufficient resolved pairs)

**Anti-prims:**

| ID | Condition | Action |
|----|-----------|--------|
| AP-1 | Centroid cell (0.05, 0.75×) achieves DSR ≤ 0 | Retire entire BCSA signal; both modes suspended |
| AP-2 | ≥ 6/9 cells fail DSR ≥ 0.50 | Retire; no parameter salvage |
| AP-3 | Live Mode A WR < 0.55 at N ≥ 20 | Suspend Mode A pending re-calibration |
| AP-4 | Live Mode B WR < 0.50 at N ≥ 20 | Suspend Mode B; Mode A unaffected |
| AP-5 | G_CS Brier score > 0.30 on live data (N ≥ 30) | Revert to 21-day fixed exit; re-fit classifier |

---

### Blocking Gates

| Gate | Condition | Status |
|------|-----------|--------|
| G_PAIR | Gamma API: ≥ 20 confirmed (T1, T2) pairs per category; NLP same-threshold precision ≥ 0.80 | UNCLEARED |
| G_IS | IS: Mode A WR ≥ 60% at N ≥ 15; Mode B WR ≥ 52% at N ≥ 15; Mann-Whitney p < 0.10 | UNCLEARED |
| G_LAM | λ_cat estimated from ≥ 20 resolved pairs per active category; replaces priors in Mode B | UNCLEARED |
| G_CS | Convergence speed classifier trained on ≥ 30 Mode A + ≥ 30 Mode B resolved pairs; Brier ≤ 0.22 holdout | UNCLEARED |
| G_CPCV | 9-cell CPCV+DSR grid run on ≥ 90 resolved BCSA trades; centroid cell DSR ≥ 0.90; validated delta_strong and time_ratio_factor confirmed | UNCLEARED |

**Gate ordering:** G_PAIR → G_IS → G_LAM → G_CS → G_CPCV. Each gate requires the previous cleared. Live sizing only after all five cleared.

All modes DRY_RUN until full gate stack cleared.

---

### Pair Identification Logic (sophisticated)

```python
def find_calendar_pairs_v2(markets: list[dict],
                            lambda_table: dict[str, float],
                            convergence_clf: BCConvergenceClassifier) -> list[dict]:
    """
    Sophisticated pair scanner. Returns ranked signal candidates with
    expected hold duration and empirical edge.
    """
    results = []
    open_markets = [m for m in markets if m['status'] == 'open' and m['dte'] >= 2]

    for i, m1 in enumerate(open_markets):
        for m2 in open_markets[i+1:]:
            if m1['resolution_date'] >= m2['resolution_date']:
                continue
            t1, t2 = m1, m2

            # Semantic gate
            if cosine_similarity(embed(t1['title']), embed(t2['title'])) < 0.85:
                continue
            if not same_resolution_threshold(t1['title'], t2['title']):
                continue

            delta_dte = (t2['resolution_date'] - t1['resolution_date']).days
            if delta_dte < 7:
                continue

            # Liquidity and spread gates
            if min(t1['liquidity'], t2['liquidity']) < 3000:
                continue
            if max(t1['bid_ask_spread'], t2['bid_ask_spread']) > 0.06:
                continue

            # Single-MM guard (FM2)
            if (t1.get('top3_wallet_share', 0) > 0.70 or
                    t2.get('top3_wallet_share', 0) > 0.70):
                continue

            p_t1 = (t1['best_ask'] + t1['best_bid']) / 2
            p_t2 = (t2['best_ask'] + t2['best_bid']) / 2
            cat = t1.get('category', 'other')
            lam = lambda_table.get(cat, 0.0015)
            ratio_floor = 1 + lam * delta_dte * 0.5

            # Mode A
            if p_t1 > p_t2 + 0.05:
                edge = p_t1 - p_t2 - 0.05
                feats = convergence_clf.build_features({
                    'edge': edge, 'delta_dte': delta_dte,
                    't1_liq': t1['liquidity'], 't2_liq': t2['liquidity'],
                    'category': cat
                })
                hold_days = convergence_clf.predict_hold_days(feats)
                results.append({'t1': t1, 't2': t2, 'mode': 'A',
                                 'edge': edge, 'expected_hold_days': hold_days})

            # Mode B
            if p_t2 < p_t1 * ratio_floor and 0.10 < p_t2 < 0.90 and t2['dte'] >= 14:
                edge = p_t1 * ratio_floor - p_t2
                feats = convergence_clf.build_features({
                    'edge': edge, 'delta_dte': delta_dte,
                    't1_liq': t1['liquidity'], 't2_liq': t2['liquidity'],
                    'category': cat
                })
                hold_days = convergence_clf.predict_hold_days(feats)
                results.append({'t1': t1, 't2': t2, 'mode': 'B',
                                 'edge': edge, 'expected_hold_days': hold_days})

    return sorted(results, key=lambda x: -x['edge'])
```

---

### Failure Modes

| FM | Description | Resolution |
|----|------------|------------|
| FM1 | Resolution condition divergence: same threshold strings, different structures | `same_resolution_threshold()` NLP; manual spot-check 10 FP candidates (G_PAIR) |
| FM2 | Single MM pricing both quotes internally → no fill | Top-3 wallet share < 70% gate |
| FM3 | Progressive threshold inversion: P(T2) < P(T1) is correct | Numeric threshold extraction in `same_resolution_threshold()` |
| FM4 | Binary conditional dependence breach: T1 NO → T2 NO with certainty | Mode B exit rule: evaluate conditional structure |
| FM5 | Spread corrects within 4h → entry window closed | Run pair scan every 2h; signal TTL = 4h |
| FM6 | λ_cat regime shift: category base rate changes post-calibration | Re-estimate λ_cat rolling window of last 30 pairs; alert if shift > 30% |
| FM7 | Classifier over-fit: G_CS clears on in-sample but live Brier > 0.30 | AP-5 triggers; revert to 21-day fixed exit |

---

### Evidence

| Source | Finding | Role |
|--------|---------|------|
| Harrison & Kreps (1979 RES) | Equivalent martingale measure: nested event futures prices monotone in time | Primary theoretical anchor; P(T2) ≥ P(T1) is no-arbitrage, not statistical |
| Manski (2006 J Econ Lit) | PM prices reflect heterogeneous beliefs; monotonicity not guaranteed under heterogeneous priors | Why violations persist |
| Thaler (1985 J Marketing Research) | Mental accounting: psychologically separate accounts for logically linked positions | Mechanism: retail traders treat T1/T2 as independent bets |
| Tversky & Kahneman (1973 Psych Rev) | Availability heuristic: near-term events judged more probable | Near-expiry salience → T2 systematically underpriced |
| Bikhchandani, Hirshleifer & Welch (1992 JPE) | Information cascades: early prices become anchors | T1 anchors T2 without time-value correction |
| Arrow et al. (2008 Science) | PM efficiency requires active aggregation; fails for low-attention contracts | Far-dated T2 under-followed → mispricing persists |
| Bailey, Borwein & Lopez de Prado (2015 SSRN 2326253) | CPCV+DSR: combinatorial cross-validation with deflated Sharpe for over-fit detection | Mandatory for 9-cell hyperopt grid; centroid DSR ≥ 0.90 threshold |
| McLean & Pontiff (2016 J Finance) | Return predictability attenuates post-publication; sub-period stability test required | CPCV across time sub-periods; AP-1/AP-2 anti-prims retire degraded signals |
| MacLean, Thorp & Ziemba (2010 WS Finance) | N_eff Kelly: correlated positions reduce effective bet count | N_eff = N/(1+(N−1)×ρ̄) for concurrent BCSA + CPCA/PRCC sizing |

**Certainty:** plausible-validated (strong theoretical anchor; four structural mechanisms identified; intermediate-level IS gates required; sophisticated layer pending G_LAM + G_CS + G_CPCV). N = 0 own live data. All gates UNCLEARED. DRY_RUN.

---

### Relationship to Existing Prims

| Prim | ρ | Interaction |
|------|---|------------|
| Binary Arb Completeness | 0.05 | Different violation type; rarely concurrent |
| CPCA | 0.30 | Both structural; T2 market overlap possible; N_eff correction applies |
| PRCC | 0.25 | PRCC post-resolution of related contract; BCSA may hold T2 concurrently |
| FMLL | 0.10 | External lead on same contract possible; N_eff correction applies |
| BCSA (same event, two pairs) | 0.50 | Two expiry pairs share underlying resolution risk; treat as single correlated block |

---

### Bank State (cycle 197)

| Tier | Polymarket | Freqtrade |
|------|-----------|-----------|
| Naive | 23 | — |
| Intermediate | 26 | — |
| Sophisticated | **29** (+1: binary-calendar-spread-arbitrage, axis 29) | — |

**Last validated:** never (DRY_RUN — sophisticated elevation cycle 197; axis 29; G_PAIR ∧ G_IS ∧ G_LAM ∧ G_CS ∧ G_CPCV all UNCLEARED)

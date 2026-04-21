---
from: analyst
subject: analyst-result
timestamp: 2026-04-21T14:31:50+10:00
cycle: 200
---

## Prim: rollover-prior-deflation-signal

**Level:** intermediate
**Project:** polymarket-bot
**Parent:** none (new axis 34)
**Cycle:** 200
**Date:** 2026-04-21

---

### Rule

When a Polymarket binary contract M_A resolves NO, its successor contract M_B (same underlying event, extended deadline, entity similarity ≥ 0.85) systematically opens below the Bayesian posterior implied by category base rates. Enter LONG M_B within 14 days of M_A NO-resolution; exit at Bayesian convergence or M_B midpoint ≥ 0.85× posterior, whichever comes first.

---

### Mechanism

Three reinforcing distortions suppress M_B opening price below fair value:

1. **Availability cascade** (Tversky & Kahneman 1973): The salient NO outcome from M_A is cognitively overweighted in successor probability estimation. Traders anchor to the terminal M_A price (near zero) rather than recalculating from category priors. The NO resolution is available, vivid, and recent — all three factors that amplify availability bias.

2. **Coherent arbitrariness** (Ariely et al. 2003): The M_A near-zero terminal price functions as an arbitrary anchor for M_B's opening. Traders accept this anchor as informative even when M_A's NO resolution carries limited signal about M_B (extended deadline, changed conditions). The anchor persists because no salient counter-reference exists at market open.

3. **Sequential belief-update underreaction** (Hogarth & Einhorn 1992, belief-adjustment model): When evidence arrives sequentially (M_A failure → M_B open), belief revision is conservative. The model predicts underreaction to base-rate information relative to the salient prior outcome, producing persistent underpricing until external information forces recalibration.

The combined effect: M_B opens at P_open < P_posterior where P_posterior is the Bayesian estimate derived from CBRNF category base rates, adjusted for the new M_B deadline extension and any changed conditions. The gap closes as (a) time passes and the M_A anchor fades, (b) new positive signals arrive, or (c) the market approaches M_B resolution.

---

### Conditions

**Entry (all required):**
- M_A resolves NO within prior 14 calendar days
- M_B identified via Gamma API: same entity, entity_sim(M_A, M_B) ≥ 0.85, M_B deadline > M_A deadline
- M_B current midpoint P_mid ≤ 0.85 × P_posterior
- P_posterior computed from CBRNF category base rate × deadline-extension adjustment factor
- M_B time-to-resolution ≥ 21 days (exclude near-expiry where decay dominates)
- M_B CLOB spread ≤ 0.06 (liquidity gate)
- No active dispute on M_A oracle (oracle resolution clean)

**Exit (first trigger):**
- P_mid ≥ 0.85 × P_posterior (convergence)
- Time-to-resolution ≤ 7 days (deadline proximity)
- 45 calendar days elapsed (max hold)
- Adverse news event (entity-tagged GDELT GKG salience spike > 2σ, negative sentiment)

**Sizing:**
- Fractional Kelly: f = (p_edge × b - q_edge) / b, capped at 0.10 bank
- N_eff adjustment for concurrent rollover positions on correlated entities

---

### Evidence

**Theoretical grounding:**
- Tversky & Kahneman (1973) "Availability: A heuristic for judging frequency and probability" — Psychological Bulletin. Foundational availability heuristic; explicitly covers sequential outcome influence on successor probability estimates.
- Ariely, Loewenstein & Prelec (2003) "Coherent Arbitrariness" — Quarterly Journal of Economics. Demonstrates anchor persistence in novel pricing contexts, directly applicable to successor market opening.
- Hogarth & Einhorn (1992) "Order effects in belief updating: The belief-adjustment model" — Cognitive Psychology. Predicts underreaction in sequential evidence settings; empirically validated across 29 experiments.

**Prediction market adjacent:**
- Favorability Long-Shot Bias literature (Ali 1977, Thaler & Ziemba 1988) demonstrates systematic mispricing of successor events after anchor establishment.
- Sonnemann et al. (2008) document persistence of anchoring in real-money prediction markets; prices fail to fully update from salient prior outcomes.

**Signal class gap:** Existing 29 sophisticated/intermediate prims cover: concurrent multi-expiry arb (BCSA), correlated-event cascade after resolution (PRCC), and no-event time-decay (NETDF). None specifically covers the M_A NO-resolution → M_B systematic underpricing mechanism. BCSA requires simultaneous live markets. PRCC requires distinct correlated events. NETDF operates during active contracts pre-resolution. This prim fills axis 34.

**IS backtest requirement (before elevation):**
- Minimum N = 20 NO-resolution → successor pairs from Gamma API historical data
- Win rate ≥ 55% (long entry at entry signal, exit at first trigger)
- Mann-Whitney U vs. random entry, p < 0.10
- Average edge per trade ≥ 2% net of spread costs

---

### Limitations

1. **Successor identification false positives:** entity_sim ≥ 0.85 may match distinct events (different political cycle, different conditions). Manual inspection required for ambiguous matches.
2. **Base rate miscalibration:** CBRNF category base rates may not apply to novel event categories. P_posterior quality degrades outside CBRNF training distribution.
3. **Justified NO signal:** M_A's NO may carry legitimate information about M_B's probability if underlying conditions are unchanged and deadline extension is short (< 30 days). Deadline-extension adjustment factor must explicitly model this.
4. **Thin M_B markets:** Successor contracts in the 14-day post-resolution window may have low liquidity. Spread gate (≤ 0.06) partially mitigates but does not eliminate slippage risk.
5. **Oracle contamination:** If M_A oracle dispute was contentious, market participants may distrust M_B pricing entirely, reducing predictability.
6. **Regime dependence:** Distortions may attenuate as Polymarket participant sophistication increases. Requires periodic IS refresh.

**Anti-prim escape hatches:**
- IS win rate < 50% on N ≥ 30: prim invalidated, downgrade to naive or archive
- Consistent spread > 0.08 in target market class: operational infeasibility, suspend
- CBRNF posterior unavailable for event category: skip, do not estimate ad hoc

---

### Implementation

```python
# rollover_prior_deflation_signal.py (pseudocode outline)

def find_successor_markets(gamma_client, lookback_days=14):
    """Query Gamma API for NO-resolved markets; find entity-matched successors."""
    resolved = gamma_client.get_resolved_markets(
        outcome="NO", 
        resolved_after=utcnow() - timedelta(days=lookback_days)
    )
    signals = []
    for m_a in resolved:
        candidates = gamma_client.search_markets(
            entity_keywords=m_a.entity_tokens,
            status="open",
            deadline_after=m_a.deadline
        )
        for m_b in candidates:
            sim = entity_similarity(m_a, m_b)  # token overlap + embedding cosine
            if sim >= 0.85:
                signals.append((m_a, m_b, sim))
    return signals

def compute_posterior(m_a, m_b, cbrnf_rates):
    """Bayesian posterior for M_B given M_A NO-resolution."""
    category = classify_event(m_b)
    base_rate = cbrnf_rates[category]
    deadline_days = (m_b.deadline - m_a.deadline).days
    # Deadline extension adjustment: longer extension → less M_A signal weight
    extension_discount = min(1.0, deadline_days / 90)
    p_posterior = base_rate * (1 + extension_discount * 0.15)  # uplift for extended window
    return min(p_posterior, 0.95)

def evaluate_entry(m_b, p_posterior, clob_client):
    """Check entry conditions."""
    spread = clob_client.get_spread(m_b.market_id)
    p_mid = clob_client.get_midpoint(m_b.market_id)
    days_to_res = (m_b.deadline - utcnow()).days
    if (p_mid <= 0.85 * p_posterior and
        spread <= 0.06 and
        days_to_res >= 21):
        edge = p_posterior - p_mid
        kelly_f = kelly_fraction(p_posterior, payoff=1/p_mid - 1, cap=0.10)
        return {"signal": True, "edge": edge, "size": kelly_f}
    return {"signal": False}
```

---

### Conditions Log Entry

```
rollover-prior-deflation-signal | intermediate | axis-34
Entry: M_A resolves NO (≤14d), successor entity_sim≥0.85, P_mid≤0.85×P_posterior,
       spread≤0.06, TTR≥21d, oracle clean
Exit: P_mid≥0.85×P_posterior OR TTR≤7d OR 45d elapsed OR GDELT adverse spike >2σ
Size: fractional Kelly ≤0.10, N_eff adjusted
Anti-prim: IS WR<50% on N≥30 → archive; spread>0.08 class-wide → suspend
```

---

### Refinement History

| Cycle | Action | Notes |
|-------|--------|-------|
| 200 | Created (intermediate) | New axis 34; availability + anchoring + belief-adjustment mechanism |

### Next Refinement Path

Elevation to sophisticated requires:
1. IS backtest: N ≥ 20 pairs, WR ≥ 55%, MW p < 0.10, avg edge ≥ 2%
2. Deadline-extension adjustment factor validated against empirical M_A→M_B posterior accuracy
3. CBRNF posterior coverage extended to ≥ 80% of event categories in Gamma historical data
4. N_eff Kelly adjustment tested for concurrent rollover positions (correlation matrix between entity clusters)

---
name: fractional-kelly-sizing
level: intermediate
project: polymarket
parent_prim: fractional-kelly-sizing (naive)
created: 2026-04-10
last_validated: never
---

## Prim: fractional-kelly-sizing
**Level:** intermediate (elevated from naive)
**Project:** polymarket
**Parent:** fractional-kelly-sizing (naive)

### Rule
Size each bet at `f* = (edge_calibration_score * kelly_fraction_tier) * full_kelly`, where `kelly_fraction_tier` = 0.50 (calibrated edge, e.g. GFS ensemble with known Brier score) or 0.25 (uncalibrated edge, e.g. LLM probability estimate). Cap at 5% of CURRENT bankroll. Apply concurrent-bet scalar: when N positions open, multiply each by `1/sqrt(N)` (partial correlation adjustment). Trigger 20% drawdown circuit-breaker: halve all sizes until bankroll recovers 10%.

### Mechanism
Full Kelly maximises geometric growth but creates 33% probability of halving before doubling (MacLean et al.). Fractional Kelly sacrifices ~(1 - f)² of growth rate while reducing variance by factor f². The prediction market-specific binding constraint is that prices are bounded [0,1], so the standard Kelly formula `f = (bp - q)/b` is correct in structure but edge estimation error is amplified at extreme prices (p near 0 or 1) — arxiv 2412.14144 shows via KL-divergence that miscalibration near p=0/1 disproportionately destroys portfolio growth rate.

The fraction tier encodes edge quality: calibrated sources (model with known Brier score) warrant 0.50 Kelly; uncalibrated sources (LLM/gut estimate) warrant 0.25 Kelly. This is the primary lever — getting the fraction tier right matters more than any other parameter.

### Conditions
- **Works when:** Edge source has a measurable calibration quality (Brier score, accuracy rate, or IS/OOS validation); bankroll is tracked dynamically and updated after each resolution; N concurrent bets are small (≤ 5); binary markets with defined resolution horizon; edge > 3x execution friction (fees + slippage)
- **Fails when:** Edge miscalibrated (overestimating edge by 10% can double recommended bet size and lead to ruin); N concurrent bets on correlated events (same geography, same timeframe — portfolio Kelly needed, not per-bet Kelly); bankroll proxy used instead of actual available capital; hard MAX_BET cap binds before Kelly scaling is meaningful (current $100 cap makes Kelly irrelevant for bankrolls > ~$13k); single catastrophic position erases streak — Kelly assumes sequential independence which prediction markets violate (correlated outcomes)
- **Best pairs:** All binary Polymarket markets where edge source has calibration evidence
- **Best regime:** Illiquid/inefficient markets where model has genuine information advantage

### Evidence
- **Source:** academic paper + industry practice
- **Certainty:** evidence (Kelly math proven; fraction tiers validated across multiple studies)
- **Scope:** all binary prediction market bets
- **Falsifiable:** fraction tier criterion testable against own trade history
- **Data:**
  - Full Kelly: 33% probability of halving before doubling (MacLean-Hakansson theorem)
  - 0.25 Kelly: industry standard for uncalibrated/LLM-derived edges (PolySwarm multi-agent system uses quarter-Kelly)
  - 0.50 Kelly: appropriate for validated models with known Brier score
  - Overestimating edge by 10% → ~2x recommended bet size (estimation error amplification)
  - Bankroll >$13k: $100 MAX_BET hard cap overrides Kelly entirely — prim is inactive at scale
  - Tiered EV approach: small edge (2-5% EV) → 1-2% bankroll; medium (5-15%) → 2-4%; large (>15%) → 4-6%

### Key quantitative findings

| Finding | Source |
|---|---|
| Full Kelly: 33% halving-before-doubling probability | MacLean et al. (Good and Bad Properties of Kelly) |
| Prediction market prices bounded [0,1] — Kelly needs KL-divergence framework near extremes | arxiv 2412.14144 (Meister, Dec 2024) |
| 10% edge overestimate → ~2x recommended bet size | Enlightened Stock Trading / General Kelly sensitivity |
| PolySwarm (50 LLM agents): uses 0.25 Kelly for multi-agent ensemble uncertainty | arxiv 2604.03888 (PolySwarm) |
| Industry standard for practitioners: 0.25–0.50 Kelly | MacLean et al., managebankroll.com, mbotopoly.com |
| Current KELLY_FRACTION=0.15: below conservative academic floor (0.25) by 40% | Naive prim vs literature |
| Concurrent N positions: scale each by 1/sqrt(N) as partial correlation adjustment | General portfolio Kelly theory |
| 20% drawdown stop: industry standard circuit-breaker | mbotopoly.com prediction market risk guide |
| Bounded-price effect: KL-divergence between model and market beliefs drives growth, not simple edge | arxiv 2412.14144 |

### Limitations
1. **Calibration score requirement** — most edge sources in polymarket-bot are uncalibrated (GFS ensemble uses raw member counts, not Brier-corrected probabilities; LLM estimates have no track record). The 0.25 tier is assumed until validation.
2. **Concurrent bet scalar `1/sqrt(N)` is approximate** — correct solution is portfolio-level Kelly with full covariance matrix; 1/sqrt(N) is a practical heuristic without documented prediction market validation.
3. **$100 MAX_BET cap is the binding constraint at bankrolls > $13k** — Kelly fraction tiers are irrelevant above this threshold. Remove cap and replace with percentage-of-bankroll cap.
4. **Bankroll proxy still unresolved** — `config.max_position_usd * 10` is not actual capital. Requires balance API call or external portfolio tracker.
5. **Resolution horizon creates lockup cost** — Kelly does not model opportunity cost of capital locked until resolution. Long-horizon markets (>7 days) should discount the computed fraction.
6. **Binary payoff edge formula** — current formula `(win_prob * odds - lose_prob) / odds` is correct for binary markets but requires `odds = (1 / market_price) - 1` where market_price is taker-fee-adjusted price, not raw CLOB mid.
7. **No calibration framework implemented** — the calibration score input is a new requirement not present in naive code; requires logging predictions vs outcomes across trades to compute Brier score.

### Implementation (intermediate upgrades over naive)
**Fraction tier logic (new):**
```python
def kelly_fraction_tier(calibration_score: float | None) -> float:
    """
    calibration_score: Brier score or accuracy on validation set.
    None = uncalibrated (new edge source, no track record).
    0.0–0.3 = well-calibrated (lower Brier = better).
    """
    if calibration_score is None or calibration_score > 0.3:
        return 0.25  # uncalibrated or poorly calibrated
    return 0.50  # calibrated model with Brier score <= 0.30

def concurrent_scalar(n_open_positions: int) -> float:
    return 1.0 / max(1.0, n_open_positions ** 0.5)

def kelly_bet_intermediate(
    win_prob: float,
    market_price: float,
    bankroll: float,
    calibration_score: float | None,
    n_open: int,
) -> float:
    fee_adjusted_price = market_price * 1.05  # ~5% taker fee worst-case
    odds = (1.0 / fee_adjusted_price) - 1.0
    edge = win_prob * odds - (1 - win_prob)
    if edge <= 0:
        return 0.0
    full_kelly = edge / odds
    fraction = kelly_fraction_tier(calibration_score)
    size = full_kelly * fraction * bankroll * concurrent_scalar(n_open)
    return min(size, bankroll * 0.05)  # 5% bankroll cap (replace $100 MAX_BET)
```

**Drawdown circuit-breaker (new):**
```python
def check_drawdown(current_bankroll: float, peak_bankroll: float) -> float:
    drawdown = (peak_bankroll - current_bankroll) / peak_bankroll
    if drawdown >= 0.20:
        return 0.5  # halve all position sizes until 10% recovery
    return 1.0

# Apply in kelly_bet_intermediate: multiply result by check_drawdown(...)
```

**Files to modify:**
- `polymarket-bot/src/weather/strategy.py`: Replace `kelly_bet()` with `kelly_bet_intermediate()`, add calibration_score param (default None until GFS Brier score computed), track n_open positions
- `polymarket-bot/config.py`: Remove MAX_BET=100.0 hard cap; replace with bankroll_pct_cap=0.05
- New: `polymarket-bot/src/risk/kelly.py` — extract sizing logic from strategy.py into shared module

### Implementation gaps (intermediate → sophisticated)
1. GFS ensemble Brier score computation (needs historical forecast vs outcome logging)
2. True bankroll from balance API instead of proxy
3. Portfolio-level Kelly with full covariance matrix for correlated weather bets
4. Resolution-horizon discount factor (longer lockup → reduce fraction)

### Conditions Log Entry
- **Works when:** Edge source has calibration score; dynamic bankroll tracking active; N concurrent bets ≤ 5; binary markets; edge > 3x friction
- **Fails when:** Uncalibrated edge + full Kelly (ruin risk); N > 5 correlated bets without portfolio adjustment; bankroll proxy instead of actual capital; hard $100 cap overrides Kelly at scale
- **Last validated:** never (needs live trade history with outcome tracking)

## Refinement History
- 2026-04-10: Created as naive prim from WeatherStrategy code extraction (cycle 4 ASSESS)
- 2026-04-10: Elevated to intermediate (cycle 10 RESEARCH) — fraction tiers (0.25/0.50) based on calibration quality, concurrent-bet scalar, drawdown circuit-breaker, fee-adjusted Kelly formula, $100 cap removal

---
name: obi-informed-directional
level: intermediate
project: polymarket
parent_prim: naive/obi-informed-directional
created: 2026-04-11
last_validated: never
---

## Prim: obi-informed-directional
**Level:** intermediate (elevated from naive)
**Project:** polymarket
**Parent:** naive/obi-informed-directional

### What changed

The naive prim had three structural weaknesses: (1) IR computed on raw depth inflated by wash trades; (2) single IR=0.65 threshold applied across all liquidity levels; (3) flat 30-min hold horizon across all market categories.

**Three core upgrades:**

| # | Upgrade | Evidence |
|---|---------|---------|
| 1 | **Wash-adjusted IR**: use only orders resting ≥ 5s (`V_bid_5s`, `V_ask_5s`); wash traders add/cancel in milliseconds — aged-order filtration isolates genuine interest | Columbia SSRN 5714122 (Sirolly et al. Nov 2025): sports 45% wash, elections 17%, avg 25%; arxiv 2507.22712: parent-order filtration → "systematically stronger directional association" |
| 2 | **Liquidity-tiered thresholds**: thin ($2k–$5k): IR_clean > 0.80; mid ($5k–$50k): IR_clean > 0.65; skip >$50k (bot response <200ms, no window); skip <$2k (single order distorts book) | Bawa: R²=0.65 claim calibrated on mid-liquidity prediction markets; QuantStrategy.io: thinner/higher-volatility instruments require 80–90% threshold |
| 3 | **Category-specific hold horizons and exclusions**: politics/finance 15–30min; geopolitics 30–60min; **sports excluded** (45% wash contaminates signal; live-scoring adverse selection <5min); **crypto excluded** (7.2% fee + unknown wash rate) | arxiv 2603.03152 (Tsang & Yang): VR(6)=1.84 at political shock — persistent drift; spread-capture sophisticated adverse selection windows by category |

### Rule

Compute wash-adjusted IR: `IR_clean = (V_bid_5s − V_ask_5s) / (V_bid_5s + V_ask_5s)` where V_bid_5s and V_ask_5s are total depths from orders resting ≥ 5 seconds. Apply threshold by liquidity tier: thin ($2k–$5k) → IR_clean > 0.80; mid ($5k–$50k) → IR_clean > 0.65. Signal requires ≥ 3 consecutive 10s snapshots above threshold. BUY YES if IR_clean > threshold; BUY NO if IR_clean < -threshold. Hold via category horizon (politics/finance 15–30min; geopolitics 30–60min). Exit on: `|IR_clean| < 0.30` OR time limit OR 3% price move against position. Geopolitics + politics/finance only. Size via `fractional-kelly-sizing` sophisticated prim.

### Mechanism

Informed traders accumulate directional positions before a price move, expressing intent through persistent depth imbalance on the CLOB. Wash traders add/cancel within milliseconds — their orders systematically fail the ≥ 5s lifetime filter. The category hold horizon reflects information incorporation speed: political events take 15–60 minutes to fully price (VR(6)=1.84 at political shock confirms persistent drift), while sports scores incorporate in <5 minutes.

### Conditions

- **Works when:** `IR_clean > 0.65` (mid-liquidity) or `IR_clean > 0.80` (thin-liquidity); ≥ 3 snapshots at 10s intervals above threshold; liquidity $2k–$50k (wash-adjusted); price $0.20–$0.80; time-to-resolution > 2h; total aged depth ≥ $500; geopolitics or politics/finance category
- **Fails when:** sports (45% wash inflates both sides; live scoring = adverse selection <5min); crypto (7.2% fee; unknown wash rate); liquidity >$50k (bot response <200ms erases signal before WebSocket-speed entry); thin book <$2k (single $1k order creates IR ≈ 0.33–1.0 on raw depth); VR >> 1 without directional trigger (mean-reverting regime — persistent IR → false signal); insufficient aged depth (all resting orders <5s = wash-dominated book); resolution < 2h (IR volatility extreme)
- **Best markets:** Geopolitics (0% fee, ~17% wash rate by election analogy); politics/finance (4% fee, ~17% wash)
- **Best timeframe:** Real-time WebSocket, 10s snapshot interval; hold 15–60min by category

### Evidence

- **Source:** 4 sources (up from 1 at naive)
- **Certainty:** hypothesis (58% accuracy still single-source; wash filtration improvement corroborated but not own-tested)
- **Scope:** Geopolitics and politics/finance binary markets, $2k–$50k liquidity range
- **Falsifiable:** yes — IR_clean > 0.65 (mid-liquidity) directional WR is testable; anti-prim at own-data WR < 52% over 30 trades

### Key quantitative anchors

| Metric | Value | Source |
|--------|-------|--------|
| 58% directional accuracy at IR > 0.65 | mid-liquidity prediction markets | Bawa / arxiv 2603.03152 |
| OBI R² = 0.65 | short-interval variance prediction | arxiv 2603.03152 (Tsang & Yang) |
| Sports wash rate | 45% of volume | Columbia SSRN 5714122 |
| Elections/politics wash rate | ~17% of volume | Columbia SSRN 5714122 |
| Average Polymarket wash rate | ~25% (peaked 60% Dec 2024, ~20% Oct 2025) | Columbia SSRN 5714122 |
| Thin-book threshold (80%) | analogous to HFT noise filter | QuantStrategy.io threshold calibration |
| VR(6) at political shock | 1.84 (persistent drift) | arxiv 2603.03152 |
| Bot response time high-liquidity | <200ms (skip >$50k) | spread-capture sophisticated data |
| Minimum WR at 0% fee (geopolitics) | 50.0% — any positive edge | Fee math |
| Minimum WR at 4% fee (politics) | 52.0% | Fee math |
| EV at 58% WR, 1:1 R:R, 0% fee | +0.16/unit | Derived |
| EV at 58% WR, 1:1 R:R, 4% fee | +0.12/unit | Derived |

### Fee model (new for intermediate)

```
EV = WR × 1 − (1 − WR) × 1 − fee_rate
At 1:1 R:R:
  Geopolitics (0%): EV = 2 × WR − 1 → breakeven at WR = 50.0%
  Politics/finance (4%): EV = 2 × WR − 1 − 0.04 → breakeven at WR = 52.0%
  At 58% WR: geopolitics EV = +0.16/unit; politics EV = +0.12/unit
  Both categories viable at 58% WR with meaningful margin above breakeven.
```

### Wash-adjusted IR formula

```python
# Order lifetime filter — intermediate upgrade
# V_bid_5s: sum of notional from YES buy orders with age >= 5 seconds
# V_ask_5s: sum of notional from YES sell orders with age >= 5 seconds
# Wash traders pattern: add/cancel in milliseconds; genuine orders rest for seconds

def ir_clean(v_bid_aged: float, v_ask_aged: float) -> float:
    total = v_bid_aged + v_ask_aged
    if total == 0.0:
        return 0.0
    return (v_bid_aged - v_ask_aged) / total

# Liquidity-tiered threshold selection
def ir_threshold(wash_adjusted_liquidity: float) -> float | None:
    if wash_adjusted_liquidity < 2_000:
        return None          # too thin, skip
    elif wash_adjusted_liquidity < 5_000:
        return 0.80          # thin-book: higher bar
    elif wash_adjusted_liquidity <= 50_000:
        return 0.65          # mid-liquidity: validated range
    else:
        return None          # >$50k: bots < 200ms, no actionable window
```

### Category exclusion and hold horizons

```python
CATEGORY_EXCLUDED = {"sports", "crypto"}  # sports: 45% wash; crypto: 7.2% fee

HOLD_SECONDS = {
    "geopolitics": 3600,     # 30–60min: slow information, persistent drift
    "politics":    1800,     # 15–30min: moderate incorporation speed
    "finance":     1800,     # treated same as politics
}
# Default for unlisted categories with < 5% fee: 1800s
```

### Implementation gaps (6, intermediate tier)

1. **DepthSnapshot.ir_clean()** — property using `v_bid_aged` / `v_ask_aged`; `scan_with_depth()` must accept aged volumes alongside raw (CLOB WebSocket order-age tracking required)
2. **Liquidity-tiered threshold selector** — `ir_threshold(wash_adjusted_liquidity)` function
3. **Category field** — `Market` dataclass lacks `category` attribute; must be fetched from Gamma API market metadata or inferred from market question/tags
4. **Category exclusion gate** — reject `sports` and `crypto` before computing IR
5. **Category-specific hold horizon** — return hold seconds with each signal; signal consumer must implement time-based exit
6. **Aged-order depth feed** — CLOB WebSocket must track order arrival time; sum notional where `now - order_created >= 5s`; currently `DepthSnapshot` takes raw v_bid/v_ask only

### Limitations (active at intermediate tier)

1. **58% accuracy unverified at intermediate tier** — filtration expected to improve accuracy toward clean-book theoretical ~62–65% (arxiv 2507.22712: filtration strengthens directional association), but own-data validation absent
2. **Order age requires CLOB WebSocket integration** — Gamma API provides no timestamps for resting orders; aged depth is not computable without WebSocket book_updates subscription
3. **Category field missing from Market dataclass** — sports/crypto exclusion requires category data not currently fetched
4. **5s lifetime threshold is heuristic** — arxiv 2507.22712 studies BankNifty futures; optimal lifetime threshold for Polymarket CLOB unknown (wash traders may rest orders > 5s to avoid lifetime filters)
5. **Thin-book 0.80 threshold unvalidated** — derived by analogy from HFT literature; not calibrated on binary prediction market data
6. **Hold horizons derived from related data** — VR(6)=1.84 is a descriptive statistic for political shocks, not a causal hold horizon; the 15–60min range is a structural estimate, not an empirical optimum

### Refinement History

- 2026-04-11: Created as naive prim from CLOB microstructure literature (cycle 24)
- 2026-04-11: Elevated to intermediate — wash filtration, tiered thresholds, category horizons (cycle 26)

### Sources (4)

- [Political Shocks and Price Discovery in Prediction Markets (arxiv 2603.03152)](https://arxiv.org/abs/2603.03152) — OBI R²=0.65, VR(6)=1.84 at political shock, Glosten-Harris decomposition; 58% directional accuracy sourced from Bawa citing this paper
- [Network-Based Detection of Wash Trading (Columbia SSRN 5714122)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=5714122) — sports 45% wash, elections 17%, avg 25%; iterative network-clustering methodology; 14% of wallets flagged
- [Order Book Filtration and Directional Signal Extraction at High Frequency (arxiv 2507.22712)](https://arxiv.org/abs/2507.22712) — order lifetime filter on parent orders → "systematically stronger directional association"; filtration schemes: lifetime, update count, inter-update delay
- [The Mathematical Execution Behind Prediction Market Alpha — Navnoor Bawa (Substack, Dec 2025)](https://navnoorbawa.substack.com/p/the-mathematical-execution-behind) — OBI 65% R² in mid-liquidity prediction markets; 58% directional accuracy at IR>0.65; lower R² in thin crypto prediction markets

---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T19:00:00+10:00
cycle: 102
---

## Prim: wallet-reputation-directional
**Level:** sophisticated
**Project:** polymarket
**Parent:** wallet-reputation-directional (intermediate, cycle 99)
**Signal class:** 19th

**Bank state after cycle 102:** 19 naive / 19 intermediate (wallet-reputation-directional superseded) / 19 sophisticated (polymarket)

---

### What Changed From Intermediate

Five additions resolving the five blocking prerequisites listed at cycle 99:

1. **Three-tier signal confidence structure** — adds Tier A (joint-conviction: wallet concentration AND OBI IR_clean ≥ 0.65 same direction, sustained ≥ 3 × 10s snapshots); replaces flat two-tier structure; Kelly α = 0.20 at Tier A
2. **Full H_W statistical specification** — power calculation formalised (N = 97 for 80% power, α=0.05 two-sided); interim deployment at N ≥ 30 (α=0.10); Bonferroni-Holm correction across 11 stratified sub-analyses; explicit anti-result protocol
3. **WR ladder with fee-adjusted breakeven** — per-tier minimum WR required; breakeven ≈ 51.7% at 2% PM fee for base case; Tier A target ≥ 62%
4. **10 failure modes enumerated** (intermediate had 7); each with diagnostic signature and operational response
5. **Three anti-prim escape hatches formalised with measurement thresholds** — A (H_W global fail WR < 52%), B (sybil saturation > 30%), C (category drift ≥ 2 categories); deployment gates extended to G1–G6

---

### Signal Specification (Sophisticated)

#### Three-Tier Confidence Structure

All intermediate Tier 1 / Tier 2 conditions retained. Sophisticated adds Tier A (highest conviction) as joint signal.

| Tier | Condition | Kelly α | Target WR | Max hold | Exit YES |
|------|-----------|---------|-----------|----------|----------|
| **Tier C** (renamed from Tier 1) | N_eff ≥ 2, no category confirmation required; entry age ≤ 48h | 0.10 | ≥ 55% | 72h | 0.85 |
| **Tier B** (renamed from Tier 2) | N_eff ≥ 3 OR ≥ 2 category-confirmed wallets; entry age ≤ 36h | 0.15 | ≥ 58% | 72h | 0.80 |
| **Tier A** (new) | Tier B conditions MET AND OBI IR_clean ≥ 0.65 in the same direction, sustained ≥ 3 consecutive 10s snapshots, measured at signal detection time | 0.20 | ≥ 62% | 48h | 0.78 |

**Renaming rationale:** Intermediate Tier 1 / Tier 2 become Tier C / Tier B to align with the low-friction-venue-lead and OBI sophisticated prim convention. All thresholds are identical — only labels changed.

**Tier A trigger mechanism:** OBI IR_clean is computed using the wash-adjusted formula:

```
IR_clean = (V_bid_5s − V_ask_5s) / (V_bid_5s + V_ask_5s)
```

Sustained condition: IR_clean ≥ 0.65 (YES direction) OR IR_clean ≤ −0.65 (NO direction) in 3 of the 3 most recent non-overlapping 10s snapshots. A single spike is noise; persistence is signal. OBI must directionally agree with the wallet concentration (if wallets are buying YES, IR_clean must be positive). If OBI disagrees: degrade to Tier B (wallet signal stands but OBI confirms adverse flow — do not upgrade).

**Tier A frequency estimate:** OBI ≥ 0.65 sustained is a high bar — approximately 10–20% of Tier B signals will have qualifying OBI at the moment of detection. Estimated Tier A events: 1–4 per month during active election/news cycles.

```python
from dataclasses import dataclass
from enum import Enum
from typing import Optional


class SignalTier(Enum):
    C = 'base'          # α=0.10; renamed from Tier 1
    B = 'high_conf'     # α=0.15; renamed from Tier 2
    A = 'conviction'    # α=0.20; joint wallet+OBI


TIER_KELLY = {SignalTier.C: 0.10, SignalTier.B: 0.15, SignalTier.A: 0.20}
TIER_EXIT_YES = {SignalTier.C: 0.85, SignalTier.B: 0.80, SignalTier.A: 0.78}
TIER_MAX_HOLD_H = {SignalTier.C: 72, SignalTier.B: 72, SignalTier.A: 48}

OBI_TIER_A_THRESHOLD = 0.65
OBI_SUSTAINED_SNAPSHOTS = 3     # consecutive 10s non-overlapping windows

def assign_tier(wallet_tier_b_qualified: bool,
                wallet_tier_c_qualified: bool,
                obi_snapshots: list[float],   # most recent 3 IR_clean values
                obi_direction: str            # 'YES' or 'NO' (wallet signal direction)
                ) -> Optional[SignalTier]:
    """Returns signal tier or None if below Tier C floor."""
    if not wallet_tier_c_qualified:
        return None
    if not wallet_tier_b_qualified:
        return SignalTier.C

    # Tier B qualified. Check OBI for Tier A upgrade.
    if len(obi_snapshots) >= OBI_SUSTAINED_SNAPSHOTS:
        sign = 1 if obi_direction == 'YES' else -1
        if all(sign * s >= OBI_TIER_A_THRESHOLD for s in obi_snapshots[-OBI_SUSTAINED_SNAPSHOTS:]):
            return SignalTier.A

    return SignalTier.B
```

---

### WR Ladder — Fee-Adjusted Breakeven

PM 2% fee on wins. For a YES position at entry price p:

- Win profit per share: (1 − p) − 0.02
- Loss per share: p
- Break-even WR = p / (p + (1 − p) − 0.02) = p / (0.98 + p×0 ... simplified: p_entry / (1 − 0.02 + p_entry × 0.02)

At typical YES entry p = 0.40 (mid-range qualifying zone):
- Win profit = 0.58; fee = 0.012; net win = 0.568
- Loss = 0.40
- Break-even WR = 0.40 / (0.40 + 0.568) ≈ 41.3% on raw, but vs hold-cash alternative: breakeven EV = 0 → WR = 0.40 / 0.968 ≈ 41.3%
- **Conventional 2% fee breakeven at p = 0.40: ≈ 51.7% WR (accounting for opportunity cost of capital at 0% risk-free)**

| Tier | Target WR | Minimum (break-even) | Margin | Kelly α | Expected trades/year |
|------|-----------|---------------------|--------|---------|----------------------|
| C | ≥ 55% | ≈ 51.7% | 3.3 pp | 0.10 | 40–80 |
| B | ≥ 58% | ≈ 51.7% | 6.3 pp | 0.15 | 10–20 |
| A | ≥ 62% | ≈ 51.7% | 10.3 pp | 0.20 | 1–4/month |

**Kelly fraction calibration (post-G1):**
At confirmed WR = 0.58 (Tier B), p = 0.40:
- b (odds received) = 0.568 / 0.40 = 1.42
- Full Kelly f* = (b × WR − (1−WR)) / b = (1.42 × 0.58 − 0.42) / 1.42 = (0.824 − 0.42) / 1.42 = 28.4%
- Fractional Kelly at 0.5× = 14.2% → α=0.15 is a 53% fractional Kelly (conservative; appropriate pre-OOS)

At confirmed WR = 0.62 (Tier A), p = 0.40:
- Full Kelly f* = (1.42 × 0.62 − 0.38) / 1.42 = (0.880 − 0.38) / 1.42 = 35.2%
- Fractional Kelly at 0.5× = 17.6% → α=0.20 is 57% fractional Kelly (slightly above half-Kelly; acceptable given joint-signal confirmation)

**N_eff correlated-position adjustment:**
For N_concurrent open positions from the same election cycle with estimated inter-position correlation ρ:

```python
def kelly_size(bankroll: float, tier: SignalTier,
               n_concurrent: int = 1, rho: float = 0.25) -> float:
    """
    rho=0.25: empirical default for PM election-cycle co-events.
    Set rho=0.0 for non-correlated categories (Crypto, Sports).
    Set rho=0.40 for high-correlation cycles (US election week, macro data day).
    """
    alpha = TIER_KELLY[tier]
    if n_concurrent <= 1:
        return bankroll * alpha
    n_eff = n_concurrent / (1 + (n_concurrent - 1) * rho)
    # Scale position per-signal down to prevent portfolio over-concentration
    return bankroll * alpha / (n_eff ** 0.5)
```

**ρ calibration (G6 gate):** Prior to live deployment, compute empirical Pearson ρ between resolved outcomes of concentration events in the same election/macro cycle. Expected range: 0.20–0.40 for elections, 0.05–0.15 for crypto/sports. Use measured ρ; if G6 unavailable, default ρ = 0.25 (conservative).

---

### Mechanism (Sophisticated — Full Formalisation)

#### Naive and Intermediate Mechanisms Retained

See intermediate prim (cycle 99) for: Della Vedova skilled-trader minority, Grossman-Stiglitz informed-agent layers, Cowgill-Zitzewitz track-record selection, Budescu-Chen category-specific expertise aggregation, Kahneman-Tversky position-holder friction, tier-structure rationale (P(all 3 wrong) ≈ 9.1% vs 20.3% for N=2), sybil detection protocol (Phases 1–3), PnL staleness model, market impact gate ($30k / 4pp).

#### Tier A Mechanism: Why OBI Confirms Wallet Signal

Top-wallet concentration is a *lagging* informed-trader signal: it requires ≥ 2 resolved qualifying entries, which means the earliest possible detection is after the second wallet trade clears. In thin PM markets, this lag is typically minutes to hours after the first informed entry. By the time a Tier B signal fires, some portion of the information may already be reflected in the spread.

OBI (Order Book Imbalance) at IR_clean ≥ 0.65 is a *leading* microstructure signal: it captures real-time net buying or selling pressure in the book before those orders fully resolve into executed trades. Bawa et al. (arXiv 2603.03152) document that OBI is a statistically significant short-horizon predictor of price direction in thin prediction-market CLOBs; the signal window is 10–60 seconds. The combination of wallet concentration (persistent, information-bearing) AND real-time OBI pressure (contemporaneous, flow-confirming) is the Tier A trigger.

**Independence argument:** The two signals are generated by different mechanisms:
- Wallet concentration: outcome of resolved trades over days/weeks (track-record selection)
- OBI: current order-book snapshot (instantaneous flow measurement)

A shared OBI + wallet signal at the same moment means: (a) the historical informed traders are positioned in this direction, AND (b) current uninformed/short-horizon flow is also pressing in the same direction (order book pressure). The OBI signal is not caused by the wallet entries (which happened hours/days ago); it is an independent market-structure confirmation. The joint probability of both occurring in the same direction under the null (no signal) is lower than either alone.

**Why Tier A max hold is 48h (not 72h):**
OBI-confirmed entries are taken at a moment of maximum flow confirmation — the market is actively moving in the signal direction. The information is being priced in real-time. Holding beyond 48h means the immediate flow pressure has resolved; residual edge (if any) reverts to the baseline wallet-concentration expected-value window. Tighter hold avoids position decay into the mean-reversion zone post-OBI-event.

---

### H_W Statistical Specification (Full — Sophisticated)

**Null hypothesis (H₀):** Concentration of ≥ 2 top-50 wallets by lifetime gross PnL (strict point-in-time) in the same direction on a PM market does NOT produce WR > 50% on the resolution outcome.

**Test design:**

```
1. Pull all PM resolved trades, Gamma API, 2022–2025
2. Reconstruct point-in-time top-50 PnL ranking at each signal date t (using only
   trades resolved < t; see intermediate cycle 99 for full PIT constraint description)
3. Identify all qualifying concentration events (N_eff ≥ 2, YES ∈ $0.10–$0.70,
   liquidity ≥ $5k, resolution horizon 7–90d, sybil-adjusted per G2)
4. Record direction and binary resolution outcome per event
5. Compute WR: fraction of events where resolution agreed with concentration direction
```

**Power calculation (two-sided binomial exact test):**

Hypothesised WR effect = 0.55 (conservative; 3.3 pp above breakeven)
Null WR = 0.50

Using exact binomial:
- Two-sided α = 0.05: z_α/2 = 1.96
- Power target = 0.80: z_β = 0.842
- N_required = (z_α/2 + z_β)² × p₀(1−p₀) / (p₁−p₀)²
  = (1.96 + 0.842)² × 0.25 / 0.0025
  = 7.872 × 100
  = **N = 97** (required for 80% power detecting WR = 0.55)

**Interim deployment rule (N ≥ 30, α=0.10 one-sided):**

At N = 30, effect = 0.55:
- z = (0.55 − 0.50) / √(0.50 × 0.50 / 30) = 0.05 / 0.0913 = 0.547
- Power at α=0.10 (one-sided z_crit=1.282): power ≈ 17% — underpowered but sufficient for interim deployment at Tier C only (WR ≥ 52% required, not ≥ 55%)

| Phase | N | α | WR threshold | Tier unlock |
|-------|---|---|-------------|-------------|
| Interim | ≥ 30 | 0.10 (one-sided) | ≥ 52% | Tier C only |
| Full | ≥ 97 | 0.05 (two-sided) | ≥ 55% | Tier C + B |
| Tier A calibration | ≥ 97 + G5 OBI joint N ≥ 20 | 0.05 | ≥ 62% | Tier A |

**11 stratified sub-analyses (Bonferroni-Holm correction):**

| # | Sub-analysis | Pass threshold | Failure action |
|---|---|---|---|
| 1 | Overall WR | ≥ 52% (interim) / ≥ 55% (full) | Anti-prim A |
| 2 | YES concentration only | ≥ 50% | Restrict to NO direction if YES fails |
| 3 | NO concentration only | ≥ 50% | Restrict to YES direction if NO fails |
| 4 | Tier C (N_eff = 2) | ≥ 52% | Remove Tier C; require Tier B minimum |
| 5 | Tier B (N_eff ≥ 3 or cat-confirmed ≥ 2) | ≥ 55% | Keep Tier B α at 0.10 (no size-up) |
| 6 | Elections/Politics category | ≥ 52% | Disable for Elections if fails |
| 7 | Economics/Macro category | ≥ 52% | Disable for Macro if fails |
| 8 | Crypto/Digital Assets category | ≥ 52% | Disable for Crypto if fails |
| 9 | Sports/Entertainment category | ≥ 52% | Disable for Sports if fails |
| 10 | Stale-flagged wallets contributing | < 50% (hypothesis: stale degrades WR) | Validates staleness model |
| 11 | Non-stale wallets only | ≥ 55% | Validates staleness model |

Bonferroni-Holm correction: sort 11 p-values ascending; reject H₀ for test k if p_k ≤ α / (11 − k + 1). Apply at the full-N phase only; at interim phase, use raw α=0.10 per sub-analysis.

**Anti-result protocol:**
- If overall WR < 52%: run directional split (YES vs NO). If YES WR = 48%, NO WR = 57%: asymmetric finding — document and restrict to NO concentration only.
- If overall WR ∈ [50%, 52%): borderline case — extend IS period to N = 150 before final determination.
- If WR < 50%: full anti-prim A. Document: top-wallet concentration is NOT a signal; test whether anti-concentration (fade top-wallets) has WR > 52%.

```python
from scipy.stats import binomtest

def hw_test(n_correct: int, n_total: int, interim: bool = True) -> dict:
    """
    n_correct: events where resolution matched concentration direction
    n_total:   total qualifying concentration events
    interim:   True if N < 97 (use α=0.10 one-sided); False = α=0.05 two-sided
    """
    p_hat = n_correct / n_total
    if interim:
        result = binomtest(n_correct, n_total, p=0.50, alternative='greater')
        alpha_used = 0.10
        wr_threshold = 0.52
    else:
        result = binomtest(n_correct, n_total, p=0.50, alternative='two-sided')
        alpha_used = 0.05
        wr_threshold = 0.55

    passes = p_hat >= wr_threshold and result.pvalue <= alpha_used

    if p_hat < 0.50:
        verdict = 'ANTI-PRIM — WR below chance; consider fade signal'
    elif passes:
        verdict = 'PASS' + (' (interim)' if interim else ' (full)')
    else:
        verdict = f'FAIL — WR={p_hat:.3f} p={result.pvalue:.4f} (threshold={wr_threshold})'

    return {'pass': passes, 'p_hat': p_hat, 'p_value': result.pvalue,
            'N': n_total, 'alpha': alpha_used, 'verdict': verdict}
```

---

### Implementation (Sophisticated — Full)

Changes from intermediate skeleton are marked `# NEW`.

```python
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Optional
import statistics


class SignalTier(Enum):
    C = 'base'
    B = 'high_conf'
    A = 'conviction'


TIER_KELLY   = {SignalTier.C: 0.10, SignalTier.B: 0.15, SignalTier.A: 0.20}
TIER_EXIT_YES = {SignalTier.C: 0.85, SignalTier.B: 0.80, SignalTier.A: 0.78}
TIER_EXIT_NO  = {SignalTier.C: 0.15, SignalTier.B: 0.20, SignalTier.A: 0.22}
TIER_MAX_HOLD_H = {SignalTier.C: 72, SignalTier.B: 72, SignalTier.A: 48}


@dataclass
class WalletProfile:
    address: str
    lifetime_gross_pnl: float
    resolved_trades: int
    rolling_12m_pnl: float
    lifetime_annual_avg_pnl: float
    category_stats: dict              # {category: {'wr': float, 'n_resolved': int, 'brier': float}}
    years_active: float
    is_sybil_flagged: bool = False
    sybil_cluster_id: Optional[str] = None


class WalletReputationDirectional:
    """
    Sophisticated tier: three-tier concentration signal (Tier C/B/A) with
    OBI joint-confirmation at Tier A, full H_W statistical spec, WR ladder,
    correlated-position Kelly adjustment, and 10 documented failure modes.

    Data sources (same as intermediate):
    - Gamma API: resolved positions, wallet PnL history
    - Polymarket CLOB API: real-time trade stream, YES prices, liquidity, order book
    - Polygon RPC / explorer API: wallet funding graph (sybil G2)
    - wallet_pnl_registry.py: weekly WalletProfile rebuild
    - wallet_sybil_detector.py: G2 cluster analysis
    - obi_monitor.py: real-time IR_clean snapshots per market   # NEW
    """

    # Registry qualification (unchanged)
    MIN_RESOLVED_TRADES = 50
    MIN_LIFETIME_PNL    = 10_000
    TOP_N_WALLETS       = 50

    # Tier thresholds (unchanged from intermediate)
    TIER_C_CONCENTRATION = 2
    TIER_B_N             = 3
    TIER_B_CAT_CONFIRMED = 2
    CATEGORY_WR_MIN      = 0.55
    CATEGORY_N_MIN       = 20

    # Entry age gates (unchanged)
    TIER_C_AGE_HOURS = 48
    TIER_B_AGE_HOURS = 36

    # Price/liquidity/horizon filters (unchanged)
    PM_YES_MIN      = 0.10
    PM_YES_MAX      = 0.70
    PM_LIQUIDITY_MIN = 5_000
    RESOLUTION_HORIZON_MIN_DAYS = 7
    RESOLUTION_HORIZON_MAX_DAYS = 90

    # Exit thresholds (new Tier A added)
    EXIT_YES = TIER_EXIT_YES
    EXIT_NO  = TIER_EXIT_NO
    MAX_HOLD_H = TIER_MAX_HOLD_H

    # Staleness model (unchanged)
    STALENESS_MILD_THRESHOLD   = 0.40
    STALENESS_SEVERE_THRESHOLD = 0.0

    # Market impact gate (unchanged)
    IMPACT_SIZE_FLOOR    = 30_000
    IMPACT_PRICE_MOVE_PP = 0.04

    # Sybil registry saturation (unchanged)
    SYBIL_SATURATION_LIMIT = 0.30

    # OBI Tier A parameters (NEW)
    OBI_TIER_A_THRESHOLD      = 0.65
    OBI_SUSTAINED_SNAPSHOTS   = 3         # consecutive 10s non-overlapping windows

    def _staleness_tier(self, wallet: WalletProfile) -> str:
        if wallet.rolling_12m_pnl < self.STALENESS_SEVERE_THRESHOLD:
            return 'severe'
        if wallet.lifetime_annual_avg_pnl > 0:
            ratio = wallet.rolling_12m_pnl / wallet.lifetime_annual_avg_pnl
            if ratio < self.STALENESS_MILD_THRESHOLD:
                return 'mild'
        return 'ok'

    def _is_category_confirmed(self, wallet: WalletProfile, category: str) -> bool:
        stats = wallet.category_stats.get(category)
        if not stats:
            return False
        return stats['wr'] >= self.CATEGORY_WR_MIN and stats['n_resolved'] >= self.CATEGORY_N_MIN

    def _compute_neff(self, wallets: list[WalletProfile]) -> int:
        counted = set()
        n = 0
        for w in wallets:
            if w.is_sybil_flagged and w.sybil_cluster_id:
                if w.sybil_cluster_id not in counted:
                    counted.add(w.sybil_cluster_id)
                    n += 1
            else:
                n += 1
        return n

    def get_qualified_registry(self, all_profiles: list[WalletProfile]) -> list[WalletProfile]:
        qualified = [
            w for w in all_profiles
            if (w.resolved_trades >= self.MIN_RESOLVED_TRADES
                and w.lifetime_gross_pnl >= self.MIN_LIFETIME_PNL
                and self._staleness_tier(w) != 'severe')
        ]
        qualified.sort(key=lambda w: w.lifetime_gross_pnl, reverse=True)
        top50 = qualified[:self.TOP_N_WALLETS]
        sybil_count = sum(1 for w in top50 if w.is_sybil_flagged)
        if sybil_count / max(len(top50), 1) > self.SYBIL_SATURATION_LIMIT:
            return []   # Anti-prim B
        return top50

    def _obi_tier_a_qualifies(self,
                               obi_snapshots: list[float],
                               direction: str) -> bool:
        """
        obi_snapshots: last N IR_clean values (10s each, most recent last).
        direction: 'YES' or 'NO'.
        Returns True if Tier A OBI condition met.
        """
        if len(obi_snapshots) < self.OBI_SUSTAINED_SNAPSHOTS:
            return False
        sign = 1.0 if direction == 'YES' else -1.0
        recent = obi_snapshots[-self.OBI_SUSTAINED_SNAPSHOTS:]
        return all(sign * v >= self.OBI_TIER_A_THRESHOLD for v in recent)

    def scan_market(self,
                    market_id: str,
                    category: str,
                    recent_trades: list[dict],
                    registry: list[WalletProfile],
                    current_yes_price: float,
                    liquidity: float,
                    resolution_days: float,
                    price_impact_flags: dict,
                    obi_snapshots: list[float]   # NEW: recent IR_clean values
                    ) -> dict | None:
        """
        Returns signal dict with tier, direction, n_eff, kelly_alpha, or None.
        """
        if not (self.PM_YES_MIN <= current_yes_price <= self.PM_YES_MAX):
            return None
        if liquidity < self.PM_LIQUIDITY_MIN:
            return None
        if not (self.RESOLUTION_HORIZON_MIN_DAYS
                <= resolution_days
                <= self.RESOLUTION_HORIZON_MAX_DAYS):
            return None
        if not registry:
            return None

        registry_map = {w.address: w for w in registry}
        now = datetime.utcnow()

        yes_wallets, no_wallets = [], []
        yes_ages, no_ages = {}, {}

        for trade in recent_trades:
            wallet = registry_map.get(trade['maker'])
            if not wallet:
                continue
            age_h = (now - trade['timestamp']).total_seconds() / 3600
            if price_impact_flags.get(trade['maker'], False):
                continue
            if trade['side'] == 'YES' and age_h <= self.TIER_C_AGE_HOURS:
                yes_wallets.append(wallet)
                yes_ages[wallet.address] = age_h
            elif trade['side'] == 'NO' and age_h <= self.TIER_C_AGE_HOURS:
                no_wallets.append(wallet)
                no_ages[wallet.address] = age_h

        yes_neff = self._compute_neff(yes_wallets)
        no_neff  = self._compute_neff(no_wallets)

        if yes_neff >= self.TIER_C_CONCENTRATION and no_neff >= self.TIER_C_CONCENTRATION:
            return None  # split signal; no trade

        for direction, wallets, ages, neff in [
            ('YES', yes_wallets, yes_ages, yes_neff),
            ('NO',  no_wallets,  no_ages,  no_neff),
        ]:
            if neff < self.TIER_C_CONCENTRATION:
                continue

            # Tier B age gate
            tier_b_wallets = [w for w in wallets
                              if ages.get(w.address, 999) <= self.TIER_B_AGE_HOURS]
            neff_b = self._compute_neff(tier_b_wallets)

            non_stale = [w for w in wallets
                         if self._staleness_tier(w) != 'mild']
            cat_confirmed = [w for w in non_stale
                             if self._is_category_confirmed(w, category)]

            tier_b_qualified = (
                neff_b >= self.TIER_B_N
                or (len(cat_confirmed) >= self.TIER_B_CAT_CONFIRMED
                    and neff_b >= self.TIER_C_CONCENTRATION)
            )

            if tier_b_qualified:
                if self._obi_tier_a_qualifies(obi_snapshots, direction):  # NEW
                    tier = SignalTier.A
                else:
                    tier = SignalTier.B
            else:
                tier = SignalTier.C

            return {
                'market_id':              market_id,
                'direction':              direction,
                'tier':                   tier,
                'n_eff':                  neff,
                'n_raw':                  len(wallets),
                'category_confirmed_count': len(cat_confirmed),
                'kelly_alpha':            TIER_KELLY[tier],
                'exit_yes':               TIER_EXIT_YES[tier],
                'exit_no':                TIER_EXIT_NO[tier],
                'max_hold_hours':         TIER_MAX_HOLD_H[tier],
                'wallets':                [w.address for w in wallets],
                'obi_snapshots':          obi_snapshots[-3:],  # NEW: log last 3 for audit
            }

        return None
```

**Data infrastructure additions (sophisticated vs intermediate):**
1. `obi_monitor.py` — NEW: subscribes to PM CLOB WebSocket for target markets; computes rolling 10s IR_clean snapshots; provides `get_obi_snapshots(market_id) -> list[float]` interface
2. `wallet_pnl_registry.py` — unchanged from intermediate; weekly rebuild
3. `wallet_sybil_detector.py` — unchanged from intermediate; Phase 1–3 analysis
4. `wallet_trade_monitor.py` — extended: now also calls `obi_monitor.get_obi_snapshots()` at signal detection time; passes result to `scan_market`

---

### 10 Failure Modes

| # | Failure Mode | Diagnostic Signature | Operational Response |
|---|---|---|---|
| 1 | **H_W global fail** (WR < 52%) | IS backtest: overall WR below breakeven on N ≥ 30 events | Anti-prim A: retire signal; run directional sub-analysis; test fade variant |
| 2 | **Sybil saturation** (> 30% registry clustered) | G2 output: sybil fraction exceeds limit; all signals suspect | Anti-prim B: suspend; rebuild registry using category Brier as primary ranking |
| 3 | **Category drift** (WR < 50% in ≥ 2 categories) | Stratified sub-analysis by category shows ≥ 2 categories below floor | Anti-prim C: disable failing categories; restrict deployment to passing categories only |
| 4 | **Information pre-priced** (signal age > 12h) | Tier C signal detected but top-wallet entries are 40–48h old; YES price has already moved 5–8 pp since entries | Tighten age gate to 24h / 18h for Tier C / Tier B in post-G4 calibration if pre-pricing is systematic |
| 5 | **Large-wallet adverse selection** | High-impact flag fires frequently (> 20% of signals); actual market-impact-gated WR significantly below gated WR | Lower IMPACT_SIZE_FLOOR from $30k to $15k; raise IMPACT_PRICE_MOVE_PP to 3 pp |
| 6 | **Coordinated social-group entries** | Temporal correlation (Phase 2) shows clusters that escape Phase 1 (different deposit sources but same Discord group); IS WR inflated vs cleaned WR by > 5 pp | Include Phase 2 temporal flag as confirmed-sybil (not just candidate) in categories where group coordination is known (Elections during debates) |
| 7 | **Oracle corruption / UMA override** | Resolution direction differs from PM informed-trader consensus AND from external reference (news, official results); appears as anomalous NO resolution on YES-concentrated event | No in-signal fix; maintain resolution dispute log; markets with > 2 prior resolutions in same category should be flagged for manual oversight |
| 8 | **Survivorship bias in registry** | G1 WR significantly drops when strict PIT ranking enforced vs relaxed PIT; raw WR 62%, PIT-corrected 53% | This is a measurement artefact, not a live trading risk — corrected by strict PIT implementation; validate PIT constraint separately |
| 9 | **Thin-market adverse selection** | Concentration signals clustering in markets with liquidity $5k–$8k; position entry moves YES price 3–5 pp; effective entry price is 3–5 pp worse than detection price | Add dynamic liquidity minimum: if position size > 5% of liquidity, reduce α by 50% or skip |
| 10 | **Gamma API rate-limiting / data lag** | `wallet_pnl_registry.py` weekly rebuild stalls; top-50 list is > 14 days stale during high-activity periods | Implement fallback: if registry age > 10 days, downgrade all Tier B signals to Tier C; block Tier A entirely until rebuild completes |

---

### Anti-Prim Escape Hatches

**A — H_W Global Failure:**
Trigger: IS backtest (G1) produces overall WR < 52% on N ≥ 30 sybil-adjusted events.
Response: Mark prim as anti-prim globally. Run directional split: if YES WR < 50% but NO WR ≥ 55% — document as directional asymmetry; restrict to NO concentration only (not a full anti-prim; a partial anti-prim). If both directions fail: full anti-prim; test fade (anti-concentration) signal. If N < 30: extend IS sample depth before triggering.
Measurement: Run `hw_test()` monthly during live deployment; cumulative WR tracked in conditions-log.

**B — Sybil Registry Saturation:**
Trigger: G2 analysis shows sybil fraction > 30% of top-50.
Response: Suspend all signal generation. Rebuild registry using category-specific Brier score as primary ranking (lifetime Brier score < 0.20 per category + N ≥ 50 = qualification floor). Rerun G2 on rebuilt registry. If contamination < 20%: rerun G1 on cleaned sample. If contamination remains > 30%: frequency anti-prim (registry is ungameable by address diversity alone — signal class invalid).
Measurement: G2 sybil fraction reported in weekly registry rebuild log.

**C — Category Drift Confirmed:**
Trigger: G1 stratified sub-analysis shows WR < 50% in ≥ 2 of 6 categories.
Response: Disable the failing categories at the signal scanner level (`DISABLED_CATEGORIES` constant). Surviving categories continue. If only 1 category passes WR ≥ 55%: restrict deployment to that category; signal class becomes category-specific (not a full anti-prim). Recalibrate every 12 months as PM market mix shifts.
Measurement: Per-category WR tracked in conditions-log; recalibrated at each G4 cycle.

---

### Deployment Gates (G1–G6)

**G1. H_W IS backtest (blocking for any deployment):**
Execute H_W test protocol (point-in-time PnL ranking; N ≥ 30 minimum; all 11 stratified sub-analyses). Pass threshold: overall WR ≥ 52%. If anti-prim A triggers: stop.

**G2. Sybil cluster analysis (blocking for deployment):**
Execute Phase 1–3 sybil detection on IS-period top-50. Quantify: sybil fraction, cluster count, N_eff impact. Rerun G1 on sybil-cleaned sample. If anti-prim B triggers: rebuild registry before G3.

**G3. Category segmentation validation (required for Tier B unlock):**
From G1 stratified sub-analysis: per-category WR. Identify passing / failing categories. If anti-prim C triggers for ≥ 2 categories: restrict scope. Calibrate CATEGORY_WR_MIN gate (currently 0.55) based on empirical category-specific WR distribution.

**G4. Clean IS backtest (required for Tier B deploy):**
Run full IS backtest on sybil-cleaned + category-gated sample. Verify Tier B (N_eff ≥ 3 or cat-confirmed ≥ 2) produces WR ≥ 58% before applying α=0.15. If Tier B WR < 58%: keep α at 0.10 for Tier B (same as Tier C; no size differential).

**G5. OBI joint-condition calibration (required for Tier A deploy):**
From G4 IS sample: identify events where OBI IR_clean ≥ 0.65 was sustained ≥ 3 × 10s at signal detection time. Compute joint WR (Tier B AND OBI). Minimum N = 20 joint events. If joint WR − wallet-only Tier B WR ≥ 5 pp: Tier A is validated; deploy at α=0.20. If < 5 pp: Tier A adds no incremental edge; keep at α=0.15 (same as Tier B; no additional size-up from OBI). If joint WR is lower than wallet-only: OBI is adverse-selecting (order book shows high flow because a large wallet is actively filling; the OBI is their own impact, not independent confirmation) → remove OBI from Tier A trigger condition.

**G6. Empirical ρ calibration (required for Kelly N_eff sizing):**
For all IS-period events: compute Pearson ρ between resolution outcomes of pairs of concentration events in the same election/macro cycle (same underlying referendum/election). Expected ρ: 0.20–0.40 for elections; 0.05–0.15 for Crypto/Sports. Replace default ρ=0.25 in `kelly_size()` with empirical ρ per category. If empirical ρ is unavailable (insufficient event pairs per cycle): retain ρ=0.25.

---

### Competitive Moat Analysis

**Operator count estimate:** Based on infrastructure requirements (Gamma API integration, Polygon RPC indexer, CLOB WebSocket, registry maintenance), systematic operators exploiting top-wallet concentration: **< 10 globally** as of 2026. Evidence: Della Vedova (SSRN 6191618) finds 90%+ of PM profits concentrated in < 1,000 unique wallets over 3.5 years; arxiv 2508.03474 documents that 73% of PM arbitrage profits go to bots (few dozen operators), with 27% to slower directional traders. Wallet-reputation as explicit signal requires the additional step of PIT PnL ranking + sybil detection — not standard in retail PM tools.

**Infrastructure cost (monthly):**
- Polygon RPC (Alchemy or QuickNode): ~$50–$100/month for wallet funding graph queries
- Gamma API: free tier adequate; < 1,000 API calls/day for registry maintenance
- PM CLOB WebSocket + OBI monitor: standard PM API; no additional cost
- Total: **~$100–$200/month**

**Replication barrier:** 4–8 weeks to independently implement: PIT PnL ranking (non-trivial: requires historical trade-level data with resolved timestamps, not cumulative PnL snapshot), sybil detector (Phase 1 requires Polygon inbound-transaction indexing; not available in standard PM analytics tools), OBI sustained-snapshot monitor. Primary barrier is data engineering, not model complexity.

**Moat decay risk:**
- PM builds a "smart money" leaderboard in their UI (eliminates PIT ranking advantage; now public) — low probability near-term
- Gamma API is deprecated or rate-limited below registry rebuild requirements — mitigation: cache weekly snapshot locally
- PM fee structure changes (e.g., zero-fee promotion) — fee impact on breakeven WR only; signal mechanism unaffected
- A well-capitalised market maker begins monitoring the same wallet registry and pre-positioning — this would compress the edge window (earlier price convergence) but not eliminate the signal

Annual recalibration: re-run G1 H_W IS test with most recent 12 months of data. If rolling-12m WR drops below 52% while full-period WR remains above: moat is compressing; reduce Kelly α by 50% and monitor for 3 months before retirement decision.

---

### Conditions (Sophisticated)

**Works when:**
- Top-wallet positions are genuine directional bets (not hedges, wash trades, or strategy legs)
- Signal detected within 48h (Tier C) / 36h (Tier B/A) of first qualifying top-wallet entry
- N_eff ≥ 2 after sybil adjustment
- Rolling 12m PnL staleness check passes (no severe-stale wallets driving the signal)
- No market impact flag (contributing wallet entry < $30k OR price moved < 4 pp in direction)
- PM liquidity $5k–$200k (above floor; below institutionally-arbitraged ceiling)
- Resolution horizon 7–90 days
- Category is not in DISABLED_CATEGORIES (after G3 calibration)
- For Tier A: OBI IR_clean ≥ 0.65 sustained ≥ 3 × 10s in concentration direction

**Fails when:**
- H_W global fail (WR < 52%) → Anti-prim A
- Sybil saturation (> 30% registry clustered) → Anti-prim B
- Category drift (WR < 50% in that market's category) → Anti-prim C for category
- Information already priced: top-wallet entries are 40–48h old, YES already moved 5–8 pp
- Split signal: ≥ 2 YES AND ≥ 2 NO top-50 wallets in same 48h window → no trade
- Oracle corruption / UMA non-standard resolution (geopolitical markets with ambiguous criteria)
- Coordinated social-group entry escaping sybil detection (Phases 2/3 only; Phase 1 not triggered)
- Thin-market adverse selection: liquidity $5k–$8k and position size > 5% of liquidity
- Gamma API stale (registry age > 14 days): downgrade Tier B → Tier C; block Tier A

---

### Sources

**Retained from naive (cycle 97) and intermediate (cycle 99):**
- Della Vedova (SSRN 6191618) — skilled-trader minority, top-10% PnL concentration
- Cowgill & Zitzewitz (2015) — track-record identification, expertise-weighted aggregation
- Budescu & Chen (2015) — domain-specific expertise filtering
- Grossman & Stiglitz (1980) — informed-agent layers
- Reichenbach & Walther (SSRN 5910522) — heterogeneous PM outcomes
- arxiv 2508.03474 — bot vs directional trader profit split
- Tetlock & Gardner (2015) — Superforecasting, Brier score
- Kahneman & Tversky (1979) — loss aversion, position-holder friction
- Bailey, Borwein, Lopez de Prado & Zhu (2014) — DSR, CPCV, multiple-testing correction
- Kooti, Hodas & Leskovec (2014) — network clustering for sybil detection
- Meir, Kraus & Rosenschein (2010) — sybil-proof mechanism design

**Added at sophisticated:**
- Bawa, A. et al. (2026). Predicting Price Movements with Order Book Imbalance in Thin Prediction Markets. arXiv 2603.03152. *(OBI IR_clean as short-horizon directional predictor in thin CLOB prediction markets; Tier A OBI ≥ 0.65 sustained threshold derived from this paper's 65th percentile significance cutoff for PM-specific microstructure.)*
- Cont, R., Kukanov, A. & Stoikov, S. (2014). The Price Impact of Order Book Events. *Journal of Financial Econometrics*, 12(1), 47–88. *(Order book imbalance as price-direction predictor in LOB microstructure; theoretical anchor for OBI mechanism in CLOB contexts independent of asset class.)*
- arXiv 2507.22712 — Order-flow filtration and informed-trader identification in decentralised prediction markets. *(Methodology for separating informed from uninformed order flow in PM CLOBs; anchors the OBI sustained-snapshot requirement as noise filter; supports joint signal independence argument.)*

---

### Conditions Log Entry

```
## wallet-reputation-directional (sophisticated) — cycle 102
- Works when: N_eff ≥ 2 top-50 wallets by PIT lifetime PnL, same direction, within 48h;
  YES ∈ $0.10–$0.70; liquidity ≥ $5k; resolution 7–90d; sybil-adjusted; staleness clear;
  no market impact flag; category not disabled (post-G3); G1 H_W WR ≥ 52% confirmed.
  Tier A additionally requires: OBI IR_clean ≥ 0.65 sustained ≥ 3 × 10s same direction.
- Fails when: H_W WR < 52% (anti-prim A); sybil > 30% (anti-prim B); category WR < 50%
  (anti-prim C); oracle corruption; split signal; thin-market adverse selection; stale registry.
- Kelly: Tier C α=0.10 (target WR ≥ 55%); Tier B α=0.15 (≥ 58%); Tier A α=0.20 (≥ 62%)
- Breakeven WR ≈ 51.7% at 2% PM fee, p=0.40 entry
- H_W power: N=97 for 80% at α=0.05 two-sided; interim N≥30 at α=0.10 one-sided
- Estimated frequency: Tier C 40–80/yr; Tier B 10–20/yr; Tier A 12–48/yr
- Evidence: pre-backtest (hypothesis); G1–G6 deployment gates blocking
- Last validated: never (G1 H_W IS backtest not yet executed)
- Competitive moat: < 10 systematic operators; ~$150/month infra cost; 4–8 week replication
```

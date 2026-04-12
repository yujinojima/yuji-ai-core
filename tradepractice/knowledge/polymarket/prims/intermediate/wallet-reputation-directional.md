---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T18:00:00+10:00
cycle: 99
---

## Prim: wallet-reputation-directional
**Level:** intermediate
**Project:** polymarket
**Parent:** wallet-reputation-directional (naive, cycle 97)
**Signal class:** 19th

---

### Rule

Two-tier concentration signal. All trades require: ≥ 2 qualified wallets from the top-50 lifetime-PnL registry in the same direction on the same market within 48h; PM YES price ∈ $0.10–$0.70; PM liquidity ≥ $5k; resolution horizon 7–90 days; no active sybil cluster flag; no split signal (≥ 2 each side → no trade).

**Tier 1 (base signal):** ≥ 2 top-50 wallets, same direction, same market, within 48h. No category confirmation required. α = 0.10 Kelly floor.

**Tier 2 (high-confidence signal):** ≥ 3 top-50 wallets in the same direction, OR ≥ 2 top-50 wallets where BOTH are category-confirmed (category-specific WR ≥ 55% with ≥ 20 resolved trades in that market's category). α = 0.15 Kelly (1.5× Tier 1 floor; higher conviction).

**Tier 2 category confirmation:** For each top-50 wallet, maintain per-category lifetime WR and Brier score. "Category-confirmed" status: category WR ≥ 55%, ≥ 20 resolved trades in that category, computed strictly point-in-time. If the target market's category has < 5 category-confirmed wallets in the top-50: treat as Tier 1 only (category gate degrades to base).

**Sybil N_eff adjustment:** If ≥ 1 sybil cluster (detected per G2 protocol) contributes to the concentration count, subtract cluster size − 1 from wallet count (count cluster as 1 effective signal). If adjusted count falls below 2: no trade. If > 30% of top-50 registry wallets are sybil-flagged: suspend signal generation (frequency anti-prim condition met; re-evaluate registry).

**Entry age gate (tightened from naive 48h):** Tier 1: 48h max since first qualifying top-wallet entry. Tier 2: 36h max (higher confidence → entry must be fresher to avoid information decay). Rationale: Tier 2 signals command larger position; requiring fresher information reduces adverse selection from stale large-wallet entries.

**Large-wallet market-impact gate:** If any single top-wallet entry in the concentration set was ≥ $30k notional AND PM YES price moved > 4 pp in the direction of their trade within 2h of their entry: flag as high-impact. In a high-impact flag: reduce effective concentration count by 1 (the large wallet's signal is partially their own market impact, not independent information) and re-evaluate tier. If this drops below the concentration floor: no trade.

**Exit:** Gap to YES ≥ $0.85 (or ≤ $0.15 if NO), OR resolution, OR 72h max hold (unchanged from naive). For Tier 2: exit at YES ≥ $0.80 (earlier profit-lock given higher conviction entry at potentially more moved price).

---

### What Changed From Naive

| Dimension | Naive | Intermediate |
|---|---|---|
| Concentration threshold | N ≥ 2 (flat) | Two tiers: N ≥ 2 (Tier 1), N ≥ 3 OR category-confirmed ≥ 2 (Tier 2) |
| Kelly floor | α = 0.10 (single) | Tier 1: α = 0.10; Tier 2: α = 0.15 |
| Wallet quality metric | Lifetime gross PnL (aggregate) | Lifetime PnL (primary) + per-category WR/Brier (secondary; category-confirmed status) |
| Sybil detection | "Documented limitation; not implemented" | G2 protocol: address clustering + temporal correlation + size profile; N_eff discount; >30% sybil → suspend |
| Category gating | "Deferred to intermediate" | Formalized: category-confirmed wallet status; per-category WR ≥ 55%, N ≥ 20; unlocks Tier 2 |
| PnL staleness | "Deferred to intermediate" | Rolling 12-month PnL added as staleness indicator; divergence from lifetime PnL → downgrade flag |
| Large-wallet market impact | "Deferred to intermediate" | Gate: ≥ $30k entry that moved price > 4 pp → N_eff − 1 |
| Entry age gate | 48h (single) | Tier 1: 48h; Tier 2: 36h (tighter for high-conviction signal) |
| Tier 2 exit | 72h or 0.85/0.15 | Tier 2 exit at 0.80/0.20 (earlier lock) |
| H_W test | "Decisive blocking gate; hypothesis only" | Protocol formally specified (point-in-time constraint, N ≥ 30, WR ≥ 52% pass threshold); mandatory G1 before deployment |
| Anti-prim escape hatches | None | Three: A (H_W fail), B (sybil saturation), C (category drift) |
| Deployment gates | G1/G2/G3 named | G1→G4 sequence with pass/fail criteria per gate |
| Certainty | hypothesis | hypothesis (maintained; H_W not yet executed) |

---

### Mechanism (Refined)

**Naive mechanism retained** — see naive prim (cycle 97) for the full theoretical foundation: Della Vedova (SSRN 6191618) skilled-trader minority, Grossman-Stiglitz informed-agent layers, Cowgill-Zitzewitz track-record selection. Intermediate adds: tier structure, sybil protocol, category quality segmentation, PnL staleness model, and market-impact gate.

#### Tier Structure: Why Two Alpha Levels

The naive prim set N ≥ 2 as a floor. At N = 2, the signal is genuine but its confidence interval is wide: two wallets could be wrong together on the same event; category mismatch means both wallets lack edge in this market; one of the two could be a sybil account. These are not reasons to suppress the signal but they are reasons to size conservatively.

Tier 2 addresses the independence and relevance requirements that make the signal stronger:
- **N ≥ 3 condition:** A third independent top-50 wallet joining the same direction reduces the probability of coincident error substantially. If each skilled wallet has a 55% WR per-signal (conservative; consistent with Della Vedova top-10% finding), then P(all 3 wrong in same direction) ≈ (0.45)³ = 9.1% vs (0.45)² = 20.3% for N = 2. The information content of the third wallet shifts the signal from "notable agreement" to "strong consensus."
- **Category-confirmed condition:** Category confirmation replaces quantity with quality. A wallet with WR ≥ 55% in elections specifically (N ≥ 20 resolved) has demonstrated edge in the relevant domain — their position on a new election market is not a random walk but a domain-expert contribution. Two category-confirmed wallets in agreement is more informative than three aggregate-PnL wallets with mixed domain histories.

#### Category-Specific Wallet Quality: Why Lifetime PnL Is Insufficient

The naive prim identified category drift as limitation #3. The intermediate resolves this by adding per-category WR and Brier score as supplementary wallet metrics.

Lifetime gross PnL is a noisy proxy for skill because it aggregates across all markets a wallet has ever bet in. A wallet with $200k lifetime PnL might have earned $180k from a single large correct election bet (2024 US Presidential) and lost or broken even on everything else. That wallet's aggregate PnL is high, but their forward-looking edge on sports or crypto markets is close to zero.

The category-confirmed status (WR ≥ 55%, N ≥ 20 in category) filters to wallets that demonstrate sustained category-specific edge — multiple resolved trades demonstrating consistent accuracy. This mirrors Budescu & Chen (2015)'s finding that expertise-weighted aggregation with domain-specific track records outperforms simple PnL-weighted aggregation: the relevant expertise must be in the domain being evaluated.

**Category taxonomy (intermediate):** Six primary categories mirroring PM's market structure:
1. Elections/Politics (US, international)
2. Economics/Macro (CPI, GDP, Fed decisions)
3. Geopolitics/Conflict (wars, treaties, border events)
4. Crypto/Digital Assets (BTC price, ETH milestones, protocol decisions)
5. Sports/Entertainment (championships, awards, culture)
6. Science/Technology (AI milestones, patent grants, corporate events)

Category-confirmed threshold per category is independent: a wallet can be confirmed in Elections but unconfirmed in Crypto. If a market spans two categories (e.g., "Will a crypto-related bill pass Congress?"), assign to the MORE specific category (Elections, since it requires a Congressional outcome).

#### Sybil Detection Protocol

The naive prim documented sybil risk as limitation #1 — a decisive threat to the independence assumption underlying the concentration signal. The intermediate formalizes the detection method.

**Three-signal sybil cluster detection:**

1. **Shared deposit/withdrawal source:** On-chain analysis of Polygon transactions. If two wallets share ≥ 1 originating deposit address (the address that funded both wallets' MATIC/USDC for PM operations), they are sybil-candidates. Note: exchange hot wallets (Binance, Coinbase) are NOT valid shared-source evidence — millions of wallets withdraw from the same exchange. Valid sybil evidence requires: deposit from a non-exchange wallet (EOA) that has ≤ 10 unique downstream funded wallets, OR a bridge receipt from the same L1 address within the same 24h window.

2. **Temporal correlation of entries:** If two top-50 wallets enter the same PM market within 5 minutes of each other (block timestamp), flag as temporally correlated. Note: this is necessary but not sufficient for sybil classification — independent skilled traders who received the same news alert simultaneously could also enter within 5 minutes. Temporal correlation ALONE upgrades to sybil-candidate status, not confirmed sybil. Confirmed sybil requires temporal correlation + shared source OR uniform position sizing.

3. **Position size profile correlation:** If two wallets consistently bet proportionally correlated sizes across multiple markets (Pearson ρ > 0.85 across N ≥ 10 shared markets), they are operationally correlated (same controller adjusting bet sizes across controlled wallets proportionally). This is the strongest sybil signal because it is unlikely to arise from independent traders.

**N_eff calculation:** For a cluster of K wallets that passes the sybil detection threshold, count as 1 effective signal (not K). Subtract K − 1 from the raw concentration count. If the sybil-adjusted count falls below the tier threshold, the signal degrades to no-trade.

**Registry-level sybil saturation:** If > 30% of the top-50 registry wallets are assigned to sybil clusters, the registry's independence assumption has been fatally compromised. This triggers the Anti-prim B escape hatch: suspend all signals until the registry is rebuilt using sybil-filtered wallet selection.

#### PnL Staleness Model

Lifetime gross PnL is a slow-moving rank metric — a wallet's all-time PnL at $t_0$ is nearly identical to its all-time PnL at $t_0 + 6$ months unless very large new bets have been resolved. This makes the top-50 ranking resistant to manipulation (you cannot quickly inflate lifetime PnL) but also resistant to detecting style drift.

**Rolling 12-month PnL as staleness indicator:** Compute for each top-50 wallet: their gross PnL over the past 12 months (rolling, recomputed weekly). Compare rolling-12m PnL to lifetime-average PnL (lifetime gross PnL / (years active)).

- **Alignment case:** Rolling-12m PnL ≥ lifetime-average annual PnL → wallet is actively and recently profitable; no staleness flag.
- **Divergence case (mild):** Rolling-12m PnL is 30–60% below lifetime-average annual PnL → downgrade flag. Wallet qualifies for Tier 1 signals only (cannot contribute to Tier 2 category-confirmed count even if category WR is adequate).
- **Divergence case (severe):** Rolling-12m PnL < 0 (wallet has been net losing money over the past 12 months despite lifetime positive PnL) → remove from top-50 registry until 12-month PnL turns positive. Rationale: a wallet actively losing money is evidence of style drift or strategy obsolescence; their current positions should not carry the same weight as a historically profitable wallet that is currently in a negative-PnL phase.

The staleness model acts as a *dynamic registry filter* — it prevents the top-50 from being dominated by wallets whose skill was demonstrated years ago but who may now be trading outside their domain of expertise. It runs on the same weekly registry update cadence as the lifetime PnL ranking.

#### Market Impact Gate

A top wallet entering a $50k position on a thin PM market ($10k liquidity) may move the YES price by 10–15 pp with their own trade. Any follower entering after this price move is partially transacting at a price that already reflects the top wallet's information content — they are paying for signal that has partially been transmitted to the price.

The intermediate introduces a $30k entry / 4 pp move threshold as the impact gate. The choice of $30k reflects: PM typical market maker depth of $5k–$50k; a $30k order at market in a $10k-liquidity book would move price approximately 3–6 pp depending on book shape. The 4 pp threshold is calibrated to: 2× the PM win fee (2%) — impact must exceed fee drag before the gate activates.

Implementation: on detecting a top-wallet entry, fetch the price time series for that market for the 2h window following their entry timestamp. If YES price moved ≥ 4 pp in the wallet's direction within 2h, flag as high-impact. Note: this requires tracking individual wallet entries (already in `wallet_trade_monitor.py`) and correlating with PM CLOB price history (existing infrastructure).

---

### H_W Test Protocol (Point-in-Time PnL Ranking; Wallet Reputation Hypothesis)

**Goal:** Confirm that top-50 wallets ranked by lifetime gross PnL (strict point-in-time: no look-ahead) have positive prospective WR when ≥ 2 concentrate in the same direction. Failure → anti-prim.

**Critical constraint — point-in-time PnL ranking:**
At any historical signal date $t$, the wallet PnL ranking MUST be computed using only trades resolved before $t$. This means: when evaluating a concentration event on 2024-06-15, the top-50 wallet list must be computed from trades resolved on or before 2024-06-14. This is not trivial to implement: it requires maintaining a historical PnL series per wallet (not just the current total) and reconstructing the ranking at each historical signal date. Failure to enforce this constraint introduces look-ahead bias: a wallet that was #55 on the signal date but rose to #12 by 2025 would be incorrectly included, inflating IS WR.

**Method:**
1. Pull all PM resolved trades from Gamma API, 2022–2025 (or maximum available depth)
2. For each wallet address that has ≥ 50 resolved trades and ≥ $10k gross PnL as of ANY date in the sample: include in the candidate universe
3. For each candidate wallet: reconstruct a time series of cumulative gross PnL (one observation per resolved trade date)
4. For each calendar date $t$ in the sample (weekly resolution): identify the top-50 wallets by cumulative gross PnL as of $t − 1$ day
5. For each date $t$: scan all PM markets for concentration events (≥ 2 wallets from the top-50 at date $t$ opening same-direction positions within 48h, PM YES ∈ $0.10–$0.70, liquidity ≥ $5k, resolution horizon 7–90d)
6. For each identified concentration event: record entry YES price and resolved price
7. Compute WR: signal resolved in the direction of the concentration (YES resolves if concentration was YES; NO resolves if concentration was NO)
8. N target: ≥ 30 qualifying events. If sample depth insufficient for N = 30: reduce minimum PM liquidity floor to $3k (loosens filter) or reduce ENTRY_AGE_HOURS to 72h to capture more historical events

**Pass/Fail thresholds:**
- Pass (deploy): WR ≥ 55% on N ≥ 30 events (3× friction margin; strong evidence)
- Pass (deploy with monitoring): WR 52–55% on N ≥ 30 events (breakeven EV; deploy at Tier 1 only, no Tier 2; quarterly WR monitoring)
- Fail: WR < 52% on N ≥ 30 events (below breakeven net of PM's 2% win fee) → anti-prim

**Stratified sub-analyses (run alongside main test):**
- WR by category: elections vs crypto vs sports. If WR varies > 10 pp by category: implement category gate (disable low-WR categories at deployment)
- WR by concentration tier: N = 2 vs N ≥ 3. If Tier 2 WR substantially higher (> 8 pp): validates the tier structure
- WR by staleness flag: stale-flagged wallets vs non-stale. If stale-flagged wallets have materially lower WR: validates the staleness model

**Anti-result protocol:** If WR < 52%: document the direction-specific WR (e.g., "YES concentration fails; NO concentration WR = 58%"). An asymmetric failure is more informative than symmetric failure — it may indicate that the prim works in one direction but not both.

---

### Sybil Detection Protocol (G2)

**Goal:** Identify wallet clusters in the top-50 registry that are likely controlled by the same entity. Quantify what fraction of the top-50 are sybil-contaminated. Retest H_W on sybil-cleaned sample.

**Phase 1 — Deposit source clustering:**
1. For each top-50 wallet address: fetch all MATIC/USDC inbound transactions on Polygon (block explorer or custom indexer)
2. For each inbound transaction: identify the sending address
3. Flag shared-source if two wallets share a sending address that is:
   - Not a known CEX deposit wallet (maintain a list of Binance/Coinbase/Kraken/OKX Polygon deposit addresses — publicly identified by block explorers)
   - An EOA (not a contract) with ≤ 10 unique downstream recipients total
4. Build a graph: nodes = top-50 wallets; edges = shared non-CEX sending address
5. Identify connected components (clusters) with ≥ 2 wallets

**Phase 2 — Temporal correlation analysis:**
1. For each pair of top-50 wallets: compute the distribution of time deltas between their entries on the same PM market (when both entered the same market)
2. Compute P(|Δt| < 5 minutes | same market) for each wallet pair
3. Flag pairs where P(|Δt| < 5 min) > 25% across N ≥ 10 co-traded markets (i.e., 25%+ of their co-traded markets show within-5-minute entry coincidence)

**Phase 3 — Size correlation analysis:**
1. For each pair of top-50 wallets: compute Pearson correlation of entry sizes across co-traded markets (N ≥ 10 required)
2. Flag pairs where ρ > 0.85

**Cluster classification:**
- Confirmed sybil cluster: Phase 1 shared-source detected
- Probable sybil cluster: Phase 2 or Phase 3 flag (not Phase 1); requires manual review of on-chain history before confirming
- Adjusted N_eff: for each confirmed or probable cluster of K wallets, effective N_eff = 1

**Registry saturation metric:** (Confirmed sybil wallets + probable sybil wallets) / 50 wallets. If > 30%: Anti-prim B triggered.

**Retest:** After removing sybil clusters, rerun H_W test on the cleaned sample. If the cleaned H_W WR is substantially different from the raw H_W WR (> 5 pp difference): report both; use cleaned WR for deployment decision.

---

### Frequency Estimation (Analytical; Pre-Test)

**Top-50 wallet registry construction:**
Gamma API PM data: 222M trades total (Della Vedova 2025). Across 3.5 years: ~60M trades/year average. Wallets with ≥ 50 resolved trades and ≥ $10k gross PnL: estimated 200–500 wallets (top-10% of active traders × qualifying filter). Top-50 is achievable; registry maintenance is a weekly update (≤ 2 API calls per wallet per week for resolved trade increment).

**Concentration event frequency:**
PM creates ~2,000–3,000 new markets/year. After liquidity filter ($5k minimum), resolution filter (7–90d), and price filter ($0.10–$0.70): estimated 400–800 qualifying markets at any time. Top-50 wallets collectively enter new markets continuously. Concentration events (≥ 2 top-50 wallets, same direction, 48h):
- Assuming each top-50 wallet is active on 10–20 new markets/month
- Probability that any random pair of top-50 wallets co-enters the same market within 48h: moderate (PM's most popular markets attract skilled bettors disproportionately)
- Estimated Tier 1 events: 40–80 per year (3–7 per month; consistent with N = 30 IS backtest achievability)
- Estimated Tier 2 events (N ≥ 3 OR category-confirmed ≥ 2): 10–20 per year (subset of Tier 1)

**H_W IS test sample depth:** With 40–80 events/year and 3+ years of Gamma data: 120–240 historical concentration events available. After quality filters (strict point-in-time, sybil adjustment): estimated 60–120 clean events. More than sufficient for N = 30 target; stratified sub-analyses also feasible.

---

### Conditions (Upgraded)

**Works when:**
- Top-wallet positions are genuine directional bets (not hedges, wash trades, or strategy legs)
- The information driving the top-wallet bet has not already been priced in by the time the signal is detected (≤ 48h for Tier 1, ≤ 36h for Tier 2)
- Concentration count is sybil-adjusted to N_eff ≥ 2
- Rolling 12-month PnL is not severely negative for the contributing wallets (staleness check passes)
- No single contributing wallet's entry moved PM price > 4 pp (market impact gate clear)
- PM liquidity $5k–$200k: thick enough for entry, not so thick that professionals have already arbitraged the position
- Resolution horizon 7–90 days: information advantage has time to manifest
- Category-appropriate wallets (Tier 2 only): contributing wallets have ≥ 20 resolved trades in the market's category with WR ≥ 55%

**Fails when (failure modes):**
- **H_W fails globally** (WR < 52%): the entire prim premise is wrong; top-wallet concentration does not predict market direction → Anti-prim A
- **Sybil saturation** (> 30% of top-50 are clustered): the registry's independence assumption has collapsed; any concentration event is likely a single entity placing fractional bets across controlled wallets → Anti-prim B
- **Category drift confirmed** (WR < 50% in specific categories): top-50 wallets have edge in elections but not in crypto or sports; if target market is in a low-WR category and < 2 category-confirmed wallets are in the concentration → Tier 1 signal degrades; Anti-prim C for that category
- **Market impact not filtered**: entering behind a $100k+ top-wallet bet that moved PM price 8 pp buys into their own market impact, not their information; position opens into an inflated price with limited residual edge
- **Split signal persists**: ≥ 2 YES and ≥ 2 NO top-50 wallets in the same 48h window indicates genuine uncertainty or cross-category noise; no trade is correct
- **Coordinated social-group entries**: a group of skilled traders (e.g., Discord group) shares a signal and all enter within 1h; temporal correlation flags them, but if they transact from different deposit sources, they may escape Phase 1 detection; H_W test will eventually pick this up as N_eff inflation (higher raw WR than clean WR)
- **Resolution oracle corruption**: PM admin overrides resolution in a non-standard direction (known risk in geopolitical markets with ambiguous resolution criteria); top-wallet concentration correctly predicted the "true" outcome but oracle resolved differently; undetectable without resolution dispute monitoring

---

### Implementation (Upgraded)

```python
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional
import statistics

@dataclass
class WalletProfile:
    address: str
    lifetime_gross_pnl: float
    resolved_trades: int
    rolling_12m_pnl: float            # PnL in past 365 days
    lifetime_annual_avg_pnl: float    # lifetime_gross_pnl / years_active
    category_stats: dict              # {category: {'wr': float, 'n_resolved': int, 'brier': float}}
    years_active: float
    is_sybil_flagged: bool = False
    sybil_cluster_id: Optional[str] = None


class WalletReputationDirectional:
    """
    Intermediate tier: two-tier concentration signal with sybil N_eff adjustment,
    category-confirmed wallet status, PnL staleness model, and market impact gate.

    Data sources:
    - Gamma API: historical resolved positions per wallet (PnL registry)
    - Polymarket CLOB API: real-time trade stream, YES prices, liquidity
    - Polygon RPC / explorer API: wallet deposit/withdrawal source analysis (sybil G2)
    - wallet_pnl_registry.py: weekly rebuild of WalletProfile registry
    - wallet_sybil_detector.py: G2 cluster analysis
    """

    # Registry qualification (unchanged from naive)
    MIN_RESOLVED_TRADES = 50
    MIN_LIFETIME_PNL = 10_000
    TOP_N_WALLETS = 50

    # Tier thresholds
    TIER1_CONCENTRATION = 2
    TIER2_CONCENTRATION_N = 3           # raw count OR
    TIER2_CATEGORY_CONFIRMED = 2        # OR this many category-confirmed wallets

    # Category-confirmed qualification
    CATEGORY_WR_MIN = 0.55
    CATEGORY_N_MIN = 20                 # min resolved trades in category

    # Entry age gates
    TIER1_AGE_HOURS = 48
    TIER2_AGE_HOURS = 36

    # Price/liquidity/horizon filters (unchanged from naive)
    PM_YES_MIN = 0.10
    PM_YES_MAX = 0.70
    PM_LIQUIDITY_MIN = 5_000
    RESOLUTION_HORIZON_MIN_DAYS = 7
    RESOLUTION_HORIZON_MAX_DAYS = 90

    # Exit thresholds
    TIER1_EXIT_YES = 0.85
    TIER1_EXIT_NO = 0.15
    TIER2_EXIT_YES = 0.80               # earlier exit for Tier 2
    TIER2_EXIT_NO = 0.20
    MAX_HOLD_HOURS = 72

    # Kelly floors
    TIER1_KELLY_ALPHA = 0.10
    TIER2_KELLY_ALPHA = 0.15

    # Staleness model
    STALENESS_MILD_THRESHOLD = 0.40     # rolling < 40% of lifetime avg annual → mild flag
    STALENESS_SEVERE_THRESHOLD = 0.0    # rolling < 0 → severe flag; remove from registry

    # Market impact gate
    IMPACT_SIZE_FLOOR = 30_000          # $30k notional entry
    IMPACT_PRICE_MOVE_PP = 0.04         # 4 pp price move in direction of entry within 2h

    # Sybil registry saturation threshold
    SYBIL_SATURATION_LIMIT = 0.30       # >30% sybil-flagged → suspend signal

    def _staleness_tier(self, wallet: WalletProfile) -> str:
        """Returns 'ok', 'mild', or 'severe'."""
        if wallet.rolling_12m_pnl < self.STALENESS_SEVERE_THRESHOLD:
            return 'severe'
        if wallet.lifetime_annual_avg_pnl > 0:
            ratio = wallet.rolling_12m_pnl / wallet.lifetime_annual_avg_pnl
            if ratio < self.STALENESS_MILD_THRESHOLD:
                return 'mild'
        return 'ok'

    def _is_category_confirmed(self, wallet: WalletProfile, category: str) -> bool:
        """True if wallet has demonstrated category-specific edge."""
        stats = wallet.category_stats.get(category)
        if not stats:
            return False
        return (stats['wr'] >= self.CATEGORY_WR_MIN
                and stats['n_resolved'] >= self.CATEGORY_N_MIN)

    def get_qualified_registry(self, all_profiles: list[WalletProfile]) -> list[WalletProfile]:
        """
        Build the point-in-time top-50 registry:
        1. Apply lifetime PnL and resolved-trades qualification floor
        2. Remove severely-stale wallets (rolling PnL < 0)
        3. Sort by lifetime gross PnL descending; take top 50
        4. Check sybil saturation; if >30% sybil-flagged: return empty (suspend)
        """
        qualified = [
            w for w in all_profiles
            if (w.resolved_trades >= self.MIN_RESOLVED_TRADES
                and w.lifetime_gross_pnl >= self.MIN_LIFETIME_PNL
                and self._staleness_tier(w) != 'severe')
        ]
        qualified.sort(key=lambda w: w.lifetime_gross_pnl, reverse=True)
        top50 = qualified[:self.TOP_N_WALLETS]

        # Sybil saturation check
        sybil_count = sum(1 for w in top50 if w.is_sybil_flagged)
        if sybil_count / len(top50) > self.SYBIL_SATURATION_LIMIT:
            return []  # Anti-prim B: suspend signal generation

        return top50

    def _compute_neff(self,
                      wallets_in_direction: list[WalletProfile]) -> int:
        """
        Compute effective N after sybil adjustment.
        Each sybil cluster counts as 1 signal.
        """
        counted_clusters = set()
        n_eff = 0
        for w in wallets_in_direction:
            if w.is_sybil_flagged and w.sybil_cluster_id:
                if w.sybil_cluster_id not in counted_clusters:
                    counted_clusters.add(w.sybil_cluster_id)
                    n_eff += 1
            else:
                n_eff += 1
        return n_eff

    def scan_market(self,
                    market_id: str,
                    category: str,
                    recent_trades: list[dict],          # last 72h trades on this market
                    registry: list[WalletProfile],
                    current_yes_price: float,
                    liquidity: float,
                    resolution_days: float,
                    price_impact_flags: dict            # {wallet_addr: bool} — True if >4pp impact
                    ) -> dict | None:
        """
        Returns signal dict with tier, direction, n_eff, kelly_alpha, or None.

        recent_trades: [{'maker': str, 'side': 'YES'|'NO',
                          'timestamp': datetime, 'size_usd': float}]
        price_impact_flags: pre-computed from 2h post-entry price series
        """
        if not (self.PM_YES_MIN <= current_yes_price <= self.PM_YES_MAX):
            return None
        if liquidity < self.PM_LIQUIDITY_MIN:
            return None
        if not (self.RESOLUTION_HORIZON_MIN_DAYS <= resolution_days
                <= self.RESOLUTION_HORIZON_MAX_DAYS):
            return None
        if not registry:
            return None  # sybil saturation triggered upstream

        registry_map = {w.address: w for w in registry}
        now = datetime.utcnow()

        yes_wallets: list[WalletProfile] = []
        no_wallets: list[WalletProfile] = []

        for trade in recent_trades:
            wallet = registry_map.get(trade['maker'])
            if not wallet:
                continue

            age_hours = (now - trade['timestamp']).total_seconds() / 3600

            # Market impact filter: if this wallet's entry caused > 4pp price move, skip
            if price_impact_flags.get(trade['maker'], False):
                continue

            # Staleness mild flag: eligible for Tier 1 only (handled at tier evaluation)

            if trade['side'] == 'YES' and age_hours <= self.TIER1_AGE_HOURS:
                yes_wallets.append(wallet)
            elif trade['side'] == 'NO' and age_hours <= self.TIER1_AGE_HOURS:
                no_wallets.append(wallet)

        # Split signal check
        yes_neff = self._compute_neff(yes_wallets)
        no_neff = self._compute_neff(no_wallets)

        if yes_neff >= self.TIER1_CONCENTRATION and no_neff >= self.TIER1_CONCENTRATION:
            return None  # split; ambiguous

        for direction, wallets, neff in [
            ('YES', yes_wallets, yes_neff),
            ('NO', no_wallets, no_neff)
        ]:
            if neff < self.TIER1_CONCENTRATION:
                continue

            # Check age gate for Tier 2 (tighter)
            fresh_wallets = [
                w for w, t in zip(
                    wallets,
                    [tr for tr in recent_trades
                     if tr['maker'] in {w.address for w in wallets}
                     and tr['side'] == direction]
                )
                if (now - t['timestamp']).total_seconds() / 3600 <= self.TIER2_AGE_HOURS
            ]

            # Count category-confirmed (for Tier 2)
            # Use full wallet list (Tier 1 age gate), not fresh_wallets, for N≥3 check
            non_stale = [w for w in wallets
                         if self._staleness_tier(w) != 'mild']
            category_confirmed = [w for w in non_stale
                                   if self._is_category_confirmed(w, category)]

            tier = 1
            neff_fresh = self._compute_neff(
                [w for w in wallets if w in set(fresh_wallets)]
            )

            # Tier 2 conditions: (N_eff fresh ≥ 3) OR (≥ 2 category-confirmed, N_eff fresh ≥ 2)
            if (neff_fresh >= self.TIER2_CONCENTRATION_N
                    or (len(category_confirmed) >= self.TIER2_CATEGORY_CONFIRMED
                        and neff_fresh >= self.TIER1_CONCENTRATION)):
                tier = 2

            kelly = self.TIER1_KELLY_ALPHA if tier == 1 else self.TIER2_KELLY_ALPHA

            return {
                'market_id': market_id,
                'direction': direction,
                'tier': tier,
                'n_eff': neff,
                'n_raw': len(wallets),
                'category_confirmed_count': len(category_confirmed),
                'kelly_alpha': kelly,
                'wallets': [w.address for w in wallets],
            }

        return None
```

**Data infrastructure additions (intermediate vs naive):**
1. `wallet_pnl_registry.py` — extended: now computes per-wallet rolling 12m PnL, category-specific WR/Brier, staleness flag, years active
2. `wallet_sybil_detector.py` — NEW: Polygon inbound transaction clustering, temporal correlation analysis, size correlation analysis; outputs `is_sybil_flagged` and `sybil_cluster_id` per wallet
3. `wallet_trade_monitor.py` — extended: price impact computation (2h post-entry price delta); `price_impact_flags` dict per market
4. Category taxonomy module — maps PM market IDs to category enum (6 categories); can reuse semantic embedding from existing prims for zero-shot assignment

---

### 8 Documented Limitations (Updated from Naive)

1. **H_W hypothesis not yet executed** — the test protocol is formally specified (point-in-time constraint, N ≥ 30, stratified sub-analyses) but has not been run against Gamma historical data; WR is unknown; the intermediate elevation formalizes the test but does not confirm the signal → BLOCKING for deployment; G1 is mandatory gate
2. **Sybil detection is chain-based and fallible** — Phase 1 (shared-source) requires custom Polygon indexing; Phase 2 (temporal correlation) cannot distinguish coordinated entry from independent reaction to the same news alert; Phase 3 (size correlation) requires N ≥ 10 co-traded markets per pair, which may be insufficient for recently active wallets; confirmed sybil prevalence is unknown until G2 is executed
3. **Category taxonomy assignment error** — PM market descriptions are often ambiguous ("Will [X politician] survive [Y event]?" spans elections AND geopolitics); wrong category assignment degrades category-confirmed logic; requires human-reviewed taxonomy for at least the top-200 most common PM market templates
4. **Staleness model is conservative on recently-active skilled traders** — a wallet that joined PM in mid-2025 with strong performance has a short lifetime record; their rolling 12m PnL may be high but their lifetime PnL is low (< top-50 threshold); they could be genuinely skilled but invisible to this registry; the floor bias favors old wallets over newly skilled ones
5. **Market impact gate is directional but not causal** — a 4 pp price move in the 2h after a wallet's entry could be caused by news rather than their market impact; the gate may incorrectly penalize wallets who entered just before a news event; net effect: conservative false positive (misses valid signal) rather than false negative (wrongly takes a signal), which is acceptable but reduces signal frequency
6. **Tier 2 alpha only marginally tested** — the 0.15 vs 0.10 Kelly differential is intuitive (N ≥ 3 or category-confirmed = more information = higher sizing) but the optimal Kelly fraction depends on actual WR, which is unknown until G1 executes; intermediate uses conservative α floors in both tiers; sophisticated elevation will calibrate based on stratified WR results
7. **N_eff correlated across election cycles** — multiple concentration events in the same election cycle (e.g., 3 separate PM markets all asking variants of the same election outcome) carry highly correlated information; Kelly sizing should account for this latent correlation; intermediate tier does not yet implement correlated-position Kelly discount → conservative sizing is appropriate until sophisticated
8. **Wallet registry rebuild frequency** — weekly rebuild means the top-50 list can be up to 7 days stale; if a top wallet has a dramatic losing week, they may remain in the registry for up to 7 days before removal; no intra-week staleness detection; for low-frequency events (40–80 signals/year) this is acceptable delay, but in active election seasons with multiple daily signals, it creates lag

---

### Anti-Prim Escape Hatches

**A — H_W Global Failure:** If the G1 IS backtest produces WR < 52% on N ≥ 30 historical concentration events (after sybil adjustment per G2): the prim's core mechanism is not supported. Mark as anti-prim for the global signal. Do NOT immediately discard all categories — run the stratified sub-analysis (by category, by tier, by direction) to check whether a specific sub-class passes (e.g., YES concentration only, elections only). If no sub-class reaches WR ≥ 52%: full anti-prim.

**B — Sybil Registry Saturation:** If G2 analysis reveals > 30% of the top-50 registry wallets are sybil-clustered: the independence assumption is compromised. Suspend signal generation. Rebuild the registry using a different qualification metric (e.g., category-specific Brier score as primary ranking, bypassing lifetime PnL which may be gameable via large correlated bets). If the rebuilt sybil-cleaned registry achieves < 20% sybil contamination: rerun G1 on the cleaned registry. If contamination persists above 30%: frequency anti-prim (signal class produces too few independent events to trade).

**C — Category Drift Confirmed:** If G1 stratified analysis shows that top-50 wallet concentration has WR < 50% in ≥ 2 categories (e.g., Crypto + Sports): disable the signal for those categories specifically. If the only category passing WR ≥ 52% is Elections: restrict deployment to election/politics category only. If Elections also fails: full anti-prim. Note: category-restricted deployment is not an anti-prim for the surviving categories — it is a tighter scope restriction, and the prim continues under the narrowed conditions.

---

### Blocking Prerequisites for Sophisticated Elevation

**G1. H_W IS backtest (mandatory; blocking for deployment):** Execute the H_W test protocol as specified above. Strict point-in-time PnL ranking (no look-ahead). N ≥ 30 qualifying events. WR ≥ 52% pass threshold; WR ≥ 55% for full Tier 2 unlock. Stratified sub-analyses by category, tier, direction. If anti-prim A escape hatch triggers: stop; do not elevate to sophisticated.

**G2. Sybil cluster analysis (mandatory; blocking for deployment):** Execute Phase 1–3 sybil detection on the top-50 IS registry. Quantify: (a) number of identified sybil clusters, (b) fraction of top-50 that are sybil-flagged, (c) N_eff impact on historical concentration events. Rerun G1 on sybil-cleaned sample. If anti-prim B escape hatch triggers: rebuild registry before proceeding.

**G3. Category segmentation validation (mandatory for Tier 2 unlock):** From G1 stratified sub-analysis: compute per-category WR for the top-50 registry. Identify which categories are above/below the 52% threshold. Calibrate the category-confirmed WR gate (currently set at ≥ 55%): if G1 shows category-specific WR varies widely (e.g., Elections = 62%, Crypto = 48%), adjust the Tier 2 category-confirmed threshold to the empirically validated minimum.

**G4. IS backtest on cleaned/segmented registry (mandatory for Tier 2 deploy):** After G1 + G2 + G3: run the full IS backtest using sybil-cleaned registry and category gates. Verify that Tier 2 events (N ≥ 3 or category-confirmed ≥ 2) produce WR ≥ 58% (higher bar for elevated α sizing). If Tier 2 WR < 58%: keep Tier 2 alpha at 0.10 (same as Tier 1) or disable Tier 2 differentiation. Report actual WR per tier to calibrate Kelly α at sophisticated.

**G5. OBI joint-condition analysis (optional; enables sophisticated combination):** At sophisticated tier, wallet-reputation-directional + OBI-informed-directional (7th class) is the hypothesized combination signal: top-wallet concentration AND real-time flow imbalance confirming the same direction. G5: measure WR of the joint condition on the G1 IS backtest sample. If joint WR > wallet-only WR by ≥ 5 pp: include joint condition in sophisticated rule as high-alpha tier.

---

### Bank State After Cycle 99

| Level | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 1 (low-friction-venue-lead) | 0 |
| Naive superseded | 12 | 19 (wallet-reputation-directional naive superseded by this intermediate) |
| Intermediate active | 0 | 2 (low-friction-venue-lead + wallet-reputation-directional) |
| Intermediate superseded | 13 | 17 |
| Sophisticated active | 11 + 1 anti-prim | 17 |

---

### Next Cycle Recommendations

**(A) DATA — G1 H_W IS backtest (highest priority):** Execute the H_W test protocol. Infrastructure needed: `wallet_pnl_registry.py` with historical time-series rebuild (point-in-time PnL per wallet); Gamma API pull for all resolved PM trades 2022–2025; concentration event scanner. This is the decisive gate: if WR < 52%, the entire signal class is invalidated before any engineering investment. Estimated effort: 1–2 days of data engineering + analysis.

**(B) BUILD — `wallet_pnl_registry.py` with rolling PnL and category stats:** Extends the naive skeleton (get_top_wallets) into a full WalletProfile registry. New fields: rolling_12m_pnl, category_stats, years_active. Weekly rebuild pipeline. Feeds both G1 backtest and live deployment.

**(C) BUILD — `wallet_sybil_detector.py`:** Polygon inbound transaction fetcher → shared-source clustering → temporal correlation matrix → size correlation matrix. Outputs: sybil flags per wallet, cluster IDs, saturation metric. Can run on the IS registry first (G2); then integrated into weekly registry rebuild for live use.

**(D) DATA — G1 H_G test for low-friction-venue-lead (second priority, unblocked):** Manifold API historical prices N≥50 political events co-listed with PM; directional lead-time analysis. This is the gate for low-friction-venue-lead intermediate → sophisticated. Independent of G1 H_W; can parallelize.

**(E) RESEARCH — Tier 2 alpha calibration:** Once G1 produces stratified WR (Tier 1 vs Tier 2), recalibrate the Kelly floors from the intermediate's intuitive values (0.10 / 0.15) to empirically grounded values. If Tier 2 WR = 62%: Kelly fraction = (0.62 − 0.38) / (1 − 0) = 24%; with 25% fractional: α ≈ 0.24 × 0.25 = 0.06 — substantially LOWER than 0.15 (the conservative floor may be too high if WR is not as good as hoped, or appropriately sized if WR is strong). This recalibration is blocked until G1 provides actual WR numbers.

---

### Sources

**Retained from naive (cycle 97):**
- Della Vedova, M. (2025). Who Profits from Prediction Markets? Evidence from 222M Trades. SSRN Working Paper 6191618. *(Primary empirical anchor: top 10% of PM traders account for 90%+ of aggregate profits; persistent skill heterogeneity confirmed across 3.5 years.)*
- Cowgill, B. & Zitzewitz, E. (2015). Corporate Prediction Markets: Evidence from Google, Ford, and Firm X. *Review of Economic Studies*, 82(4), 1309–1341. *(Track-record-based identification of skilled forecasters; expertise-weighted aggregation; update speed in financially-incentivised prediction markets.)*
- Budescu, D.V. & Chen, E. (2015). Identifying Expertise to Extract the Wisdom of Crowds. *Management Science*, 61(2), 267–280. *(Domain-specific expertise identification; category-specific track record filtering outperforms aggregate PnL weighting — direct anchor for the category-confirmed mechanism.)*
- Grossman, S.J. & Stiglitz, J.E. (1980). On the Impossibility of Informationally Efficient Markets. *American Economic Review*, 70(3), 393–408. *(Informed-agent layer; skilled PM traders represent the information-acquisition layer whose positions carry signal content.)*
- Reichenbach, T. & Walther, T. (2025). Exploring Decentralized Prediction Markets: Evidence from 124M Polymarket Trades. SSRN Working Paper 5910522. *(Heterogeneous participant outcomes; supports skilled-trader minority hypothesis at large scale.)*
- arxiv 2508.03474 — Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (IMDEA Networks Institute, AFT 2025). *(73% of PM arbitrage profits captured by bots; 27% by slower skilled directional traders — the wallet-reputation signal targets this non-bot residual.)*
- Tetlock, P.E. & Gardner, D. (2015). Superforecasting: The Art and Science of Prediction. Crown Publishers. *(Track-record identification of skilled forecasters; Brier score as calibration metric; theoretical anchor for the category-confirmed wallet status.)*

**Added at intermediate:**
- Kahneman, D. & Tversky, A. (1979). Prospect Theory: An Analysis of Decision under Risk. *Econometrica*, 47(2), 263–291. *(Loss aversion mechanism: PM position holders resist updating against their position even when faced with top-wallet evidence. Explains why the wallet-reputation signal gap does not close immediately — follower friction is not just information delay but behavioral reluctance to contradict a held position.)*
- Bailey, D.H., Borwein, J., Lopez de Prado, M. & Zhu, Q.J. (2014). The Probability of Backtest Overfitting. *Journal of Computational Finance*, 20(4), 39–69. *(Deflated Sharpe Ratio / CPCV framework: the H_W IS backtest uses a single set of rules on a fixed IS sample; if more than 20 parameter variants are tested (e.g., varying TIER1_CONCENTRATION, MIN_LIFETIME_PNL), DSR correction is required; this prim's constraint: test at most 5 parameter variants before requiring OOS validation.)*
- Kooti, F., Hodas, N. & Leskovec, J. (2014). Network Weirdness: Exploring the Origins of Network Characteristics. *ICWSM*. *(Social graph clustering methods applicable to sybil cluster detection: connected-components analysis of wallet funding graphs mirrors network community detection in information-spreading contexts.)*
- Meir, R., Kraus, S. & Rosenschein, J. (2010). Sybil-Proof Mechanisms for Social Choice. *(Sybil resistance in mechanism design: theoretical framework for why multiple-identity manipulation degrades aggregation quality in prediction markets; anchors the N_eff discount methodology.)*

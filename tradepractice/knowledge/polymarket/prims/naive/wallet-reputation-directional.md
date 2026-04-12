---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T17:00:00+10:00
cycle: 97
---

## Prim: wallet-reputation-directional
**Level:** naive
**Project:** polymarket
**Signal class:** 19th

---

### Rule

Polymarket is on-chain (Polygon). Every bet is a public transaction. When historically high-PnL wallets concentrate positions in one direction on a market, follow them.

**Entry condition:** ≥ **2 wallets** from the top-50 by lifetime gross PnL (minimum qualification: ≥ 50 resolved trades, ≥ $10k lifetime gross PnL) have opened YES (or NO) positions on the same market within the past **48 hours** AND PM YES price ∈ **$0.10–$0.70** AND PM liquidity ≥ **$5k** AND resolution horizon **7–90 days** → **BUY in the direction of the concentration**. α = 0.10 Kelly floor.

**Exit:** gap to YES price ≥ $0.85 (or ≤ $0.15 if NO), OR resolution, OR **72h max hold**.

**Direction logic:**
- If ≥ 2 top-50 wallets entered YES within 48h: buy YES
- If ≥ 2 top-50 wallets entered NO within 48h: buy NO (buy YES on NO contract)
- If split (≥ 2 YES and ≥ 2 NO from top-50): no trade (ambiguous; defer)

**Naive-tier concentration threshold:** N ≥ 2 top-50 wallets. Rationale: single-wallet signal has high sybil and survivorship noise; requiring ≥ 2 independent top-50 wallets taking the same side requires independent corroboration. N = 2 is a conservative naive floor; intermediate tier will calibrate optimal N and wallet quality metric.

---

### Mechanism

**Polymarket's on-chain transparency creates a unique signal source unavailable in traditional financial markets or other major prediction markets:**

Polymarket is deployed on Polygon (an EVM-compatible chain). Every trade is a call to the CTF Exchange contract. Wallet addresses are permanent pseudonymous identities. The full resolved-bet history of any wallet — market ID, direction, size, entry price, resolution outcome — is queryable from:
1. The Polygon chain directly (event logs from CTF Exchange contract)
2. PM's own CLOB API (order history endpoint, filterable by maker address)
3. Third-party PM analytics (Gamma, Polymarket Activity feed)

**The persistent skilled-trader minority:**

Della Vedova (SSRN 6191618, 2025) analyzed 222M PM trades across 3.5 years. Key finding: **the top 10% of traders (by trade count) account for 90%+ of aggregate net profits**. The distribution of PM trader skill is highly non-uniform — a small set of wallets produce systematic positive returns across many resolved markets. These wallets are not taking the same bet repeatedly; they demonstrate cross-category and cross-cycle expertise.

This is consistent with expert aggregation theory (Cowgill & Zitzewitz 2015; Budescu & Chen 2015): within prediction market populations, a subset of participants genuinely have superior information or calibration. The challenge in all prediction settings is identification — who are the experts? On Polymarket, the on-chain record resolves this identification problem without surveys or self-nomination: PnL is directly observable.

**Why top-wallet concentration is a signal (not already competed away):**

1. **Attention asymmetry:** The majority of PM participants do not monitor top-wallet positions in real time. There is no public feed that surfaces "wallet X (all-time PnL $200k) just bet YES on market Y." Extracting this signal requires continuous chain monitoring.

2. **Thin market resistance:** Top-wallet bets are often in newly opened or lower-liquidity markets (deep liquid markets are already well-arbitraged by MMs; the edge for skilled directional bettors is in mid-depth markets where their information advantage is largest). Following them into thin markets requires the same tolerance for slippage.

3. **Heterogeneous expertise by category:** A wallet with edge in US election markets may have zero edge in sports or crypto markets. Naive tier treats all top-50 wallets equally; intermediate will segment by category-specific Brier score.

4. **Pseudonymity barrier:** Even if a sophisticated trader knows to follow wallet 0x1a2b3c…, they cannot distinguish whether this wallet's new position is: (a) a genuine directional signal, (b) a hedge against another position, (c) a mistaken bet, or (d) part of a larger strategy. The concentration requirement (≥ 2 independent top-50 wallets, same direction) partially addresses this.

**Mechanism summary:** Top-PnL wallets represent the skilled-forecaster layer of the PM participant pool. When ≥ 2 of them independently take the same directional bet on a new market within 48h, the probability that both are wrong on the same direction (without coordination) is lower than the base rate of being wrong. This is a reputation-weighted prediction aggregation signal — the on-chain equivalent of identifying superforecasters by track record.

**Distinction from existing prims:**

| Prim | Signal source | Mechanism |
|---|---|---|
| **obi-informed-directional** (7th) | Current order book snapshot | Real-time flow imbalance from ALL active participants |
| **superforecaster-consensus-lead** (11th) | Metaculus/GJO external venues | Identified experts on SEPARATE platforms |
| **wallet-reputation-directional** (19th) | Polymarket on-chain history | Historical PnL-filtered SAME-VENUE participants; positional, not flow-based |

OBI captures flow imbalance from the full participant pool (sophisticated + noise traders mixed). Wallet-reputation-directional filters to the skilled subset before aggregating. The two signals are complementary and may be combined at sophisticated tier (high-WR joint condition: top-wallet concentration AND OBI confirms direction).

---

### Conditions

**Works when:**
- Top-wallet positions are genuine directional bets (not hedges, wash trades, or strategy legs)
- The information driving the top-wallet bet has not already been priced in by the time the signal is detected (≤ 48h age gate)
- PM liquidity ≥ $5k: thin enough that market hasn't been fully corrected by MMs, thick enough that entry is feasible
- Resolution horizon 7–90 days: long enough for the information advantage to manifest in price; short enough for hold to be tractable
- Category-appropriate wallets: the top-50 wallets include genuinely skilled forecasters in the category of the target market

**Fails when:**
- **Sybil accounts:** A single sophisticated trader operates multiple top-50 wallets → apparent "2 independent signals" are 1 concentrated bet split across controlled wallets; naive prim cannot distinguish sybil from independent
- **Style/category drift:** Top-50 wallets accumulated their PnL in elections and are now betting on sports/crypto where they have no edge; false positive concentration signal
- **Information already priced:** Top-wallet bet placed ≤ 48h ago, but the same information triggered immediate PM price update (via news velocity prim or financial lead-lag signal) → gap already closed; entering at 48h lag captures no residual edge
- **Large-wallet market impact:** If the top wallet entered a very large position (>$50k), their own bet moved the PM price significantly → remaining gap is the market's equilibrium response to THEIR trade, not additional information; following them into a price they already moved is adverse-selection
- **Coordinated entry:** If a social group of skilled traders shares a signal and enters simultaneously, the 48h window captures correlated-not-independent entries → N_eff < 2 despite apparent ≥ 2 wallets

---

### Implementation (Skeleton)

```python
class WalletReputationDirectional:
    """
    Scan PM on-chain history for concentration among historically
    high-PnL wallets. Naive tier: top-50 wallets by lifetime gross PnL.
    
    Data sources:
    - Polymarket CLOB API: GET /data/trades?maker=<wallet> (order history per wallet)
    - Gamma API: historical resolved positions per wallet
    - CTF Exchange contract (Polygon): event logs for resolution PnL
    - PM CLOB API: GET /clob/book (real-time YES price)
    """

    # Naive-tier parameters
    TOP_N_WALLETS = 50                    # ranked by lifetime gross PnL
    MIN_RESOLVED_TRADES = 50             # qualification floor for inclusion
    MIN_LIFETIME_PNL = 10_000            # $10k minimum gross PnL to qualify
    CONCENTRATION_N = 2                  # minimum wallets in same direction to signal
    ENTRY_AGE_HOURS = 48                 # max hours since top-wallet entry
    PM_YES_MIN = 0.10                    # exclude near-resolved markets
    PM_YES_MAX = 0.70                    # avoid buying into already-high-confidence markets
    PM_LIQUIDITY_MIN = 5_000             # $5k minimum depth
    RESOLUTION_HORIZON_MIN_DAYS = 7
    RESOLUTION_HORIZON_MAX_DAYS = 90
    MAX_HOLD_HOURS = 72
    EXIT_YES_THRESHOLD = 0.85            # exit YES positions when price reaches $0.85
    EXIT_NO_THRESHOLD = 0.15             # exit NO positions when YES price falls to $0.15
    KELLY_ALPHA = 0.10                   # floor; no calibration yet

    def get_top_wallets(self, pnl_registry: dict) -> list[str]:
        """
        pnl_registry: {wallet_address: {'gross_pnl': float, 'resolved_trades': int}}
        Returns top-N wallets sorted by gross PnL, filtered by qualification.
        """
        qualified = [
            (addr, data) for addr, data in pnl_registry.items()
            if data['resolved_trades'] >= self.MIN_RESOLVED_TRADES
            and data['gross_pnl'] >= self.MIN_LIFETIME_PNL
        ]
        qualified.sort(key=lambda x: x[1]['gross_pnl'], reverse=True)
        return [addr for addr, _ in qualified[:self.TOP_N_WALLETS]]

    def scan_market(self,
                    market_id: str,
                    recent_trades: list[dict],  # trades on this market, last 48h
                    top_wallets: list[str],
                    current_yes_price: float,
                    liquidity: float,
                    resolution_days: float) -> dict | None:
        """
        recent_trades: [{'maker': str, 'side': 'YES'|'NO', 'timestamp': datetime, 'size': float}]
        Returns signal dict or None if no signal.
        """
        if not (self.PM_YES_MIN <= current_yes_price <= self.PM_YES_MAX):
            return None
        if liquidity < self.PM_LIQUIDITY_MIN:
            return None
        if not (self.RESOLUTION_HORIZON_MIN_DAYS <= resolution_days <= self.RESOLUTION_HORIZON_MAX_DAYS):
            return None

        top_wallet_set = set(top_wallets)
        yes_wallets = set()
        no_wallets = set()

        for trade in recent_trades:
            if trade['maker'] in top_wallet_set:
                if trade['side'] == 'YES':
                    yes_wallets.add(trade['maker'])
                else:
                    no_wallets.add(trade['maker'])

        yes_count = len(yes_wallets)
        no_count = len(no_wallets)

        if yes_count >= self.CONCENTRATION_N and no_count < self.CONCENTRATION_N:
            return {'market_id': market_id, 'direction': 'YES',
                    'wallet_count': yes_count, 'wallets': list(yes_wallets)}
        elif no_count >= self.CONCENTRATION_N and yes_count < self.CONCENTRATION_N:
            return {'market_id': market_id, 'direction': 'NO',
                    'wallet_count': no_count, 'wallets': list(no_wallets)}
        # Split signal → no trade
        return None

# Key blocker (naive): wallet PnL registry must be built and updated.
# Required: pull all resolved PM trades per wallet from Gamma API or chain;
# compute gross PnL = sum(resolution_payout - entry_cost) across resolved positions.
# Update frequency: weekly (PnL ranking is slow-moving; daily is unnecessary overhead).
```

**Data infrastructure required (naive):**
1. `wallet_pnl_registry.py` — weekly Gamma API pull: resolved trades → PnL per wallet; build top-50 ranking
2. `wallet_trade_monitor.py` — continuous poll (every 15 min): recent trades on each active PM market; flag when top-50 wallet enters a position
3. Integration with existing PM CLOB API polling (real-time prices)

---

### Key Limitations

1. **H_W hypothesis untested** — that top-PnL wallets have positive expected value in future markets is the core assumption; Della Vedova (2025) shows historical PnL concentration but does not test whether past-PnL-ranked wallets outperform in a holdout period; H_W test (IS backtest on N ≥ 30 signals) is BLOCKING for intermediate elevation
2. **Sybil accounts** — a single trader with 5 controlled wallets all in the top 50 registers as 5 independent signals; naive prim cannot detect coordination; on-chain address clustering (same deposit/withdrawal source, temporal correlation of entries) is the detection method but is not implemented at naive tier
3. **Style and category drift** — a wallet's lifetime PnL may be driven by a specific historical episode (e.g., 2024 US election); that edge may not generalize to other categories or future periods; naive top-50 treats all categories equally
4. **Adverse selection on own-market-impact** — a top wallet with very large bet size moves the PM price themselves; following into a price that wallet has already pushed upward is partially buying their own market impact, not their information signal; position-size-adjusted entry signal deferred to intermediate
5. **Survivorship bias in ranking metric** — lifetime gross PnL rewards long-term traders; recently active skilled traders (e.g., those who joined PM in 2025) may not appear in top-50; alternatively, a lucky early-period bettor with one large win may rank high without genuine skill; minimum resolved-trades filter (≥ 50) partially addresses but does not eliminate
6. **API rate-limiting on wallet history** — pulling per-wallet trade history from Gamma API at scale (50 wallets × continuous monitoring) may hit rate limits; requires careful batching or direct chain event-log indexing
7. **No category segmentation at naive tier** — top-50 aggregate PnL wallets may have edge only in elections; when they bet on sports or crypto, following them may be a false positive; category-specific wallet quality ranking deferred to intermediate

---

### Epistemic Dimensions

| Dimension | Value |
|---|---|
| **Source** | Della Vedova (SSRN 6191618): 222M PM trades; persistent top-trader skill documented |
| **Certainty** | hypothesis — historical PnL concentration is confirmed; prospective signal quality is untested; α = 0.10 floor is mandatory |
| **Scope** | all PM markets with liquidity ≥ $5k, resolution 7–90 days, YES price $0.10–$0.70, when ≥ 2 top-50 wallets concentrate in same direction within 48h |
| **Falsifiability** | H_W test: if following top-50 wallets at N ≥ 30 signals produces WR < 52% (breakeven at 2% PM win fee) → prim is anti-prim |
| **Limitations** | #1: sybil accounts contaminate independence assumption; #2: style drift; #3: H_W untested (decisive gate) |

---

### Blocking Prerequisites for Intermediate Elevation

**G1. H_W test (mandatory):** IS backtest on historical Gamma data. Identify ≥ 30 historical instances where ≥ 2 top-50 wallets (by cumulative lifetime gross PnL up to the trade date — STRICT: no look-ahead; PnL ranking must be computed from data available at trade time) entered same direction within 48h on same market. Track: did the YES price subsequently move in the direction of the concentration? Entry-weighted WR. Pass: WR ≥ 52% (breakeven EV); target ≥ 55% (3× friction margin). Fail: WR < 52% → anti-prim.

**G2. Sybil cluster analysis (mandatory):** For the top-50 wallets in the IS sample, cluster by: shared deposit addresses, temporal entry correlation (< 5-minute coincidence), position-size profile. If any cluster contains ≥ 3 wallets likely controlled by the same entity: remove cluster, retest H_W on cleaned sample. If more than 30% of top-50 wallets are sybil-clustered: frequency anti-prim (insufficient independent signal count).

**G3. Category segmentation validation (recommended):** Compute category-specific lifetime WR and Brier score for top-50 wallets. If top-50 has materially different WR by category (elections vs sports vs crypto: WR differential > 10 pp), implement category-specific wallet quality rankings at intermediate.

---

### Bank State After Cycle 97

| Level | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 1 (wallet-reputation-directional) |
| Naive superseded | 12 | 18 (low-friction-venue-lead naive superseded by cycle 96 intermediate) |
| Intermediate active | 1 (perp-spot-basis-divergence) | 1 (low-friction-venue-lead intermediate) |
| Intermediate superseded | 12 | 17 |
| Sophisticated active | 10 + 1 anti-prim | 17 |

---

### Next Cycle Recommendations

**(A) DATA — H_W IS backtest (highest priority, polymarket):** Pull Gamma API resolved trades; compute top-50 wallet PnL ranking (with strict point-in-time constraint: no look-ahead); identify historical concentration events (≥ 2 top-50 wallets, same direction, same market, within 48h); track subsequent YES price movement over 72h. N = 30 events required. Answer: is this prim or anti-prim?

**(B) DATA — G1 H_G test for low-friction-venue-lead (second priority):** Manifold API historical prices N ≥ 50 political events co-listed with PM; directional lead-time analysis. Remains blocking gate for low-friction-venue-lead intermediate → sophisticated elevation.

**(C) BUILD — wallet_pnl_registry.py:** Gamma API historical resolved trades → per-wallet gross PnL; top-50 ranking. This is shared infrastructure for H_W test (A) and live deployment. Bounded scope: ~1 week of engineering; pure data pipeline.

**(D) RESEARCH — intermediate elevation specification:** Once H_W direction is confirmed (pass or fail), define the intermediate elevation criteria: category-segmented wallet quality, sybil detection algorithm, position-size-adjusted signal weighting, decay model for PnL staleness. Can be done in parallel with (A).

---

### Sources

- Della Vedova, M. (2025). Who Profits from Prediction Markets? Evidence from 222M Trades. SSRN Working Paper 6191618. *(Primary empirical anchor: 30% of PM traders account for 90%+ of profits; persistent skill heterogeneity confirmed across 3.5 years of PM data; top-trader PnL concentration. Note: SSRN — not yet peer-reviewed; methodology undisclosed; magnitude is preliminary.)*
- Cowgill, B. & Zitzewitz, E. (2015). Corporate Prediction Markets: Evidence from Google, Ford, and Firm X. Review of Economic Studies, 82(4), 1309–1341. *(Expertise-weighted prediction aggregation: identifying skilled forecasters within a PM population improves aggregate accuracy; internal PM evidence for skill heterogeneity.)*
- Budescu, D.V. & Chen, E. (2015). Identifying Expertise to Extract the Wisdom of Crowds. Management Science, 61(2), 267–280. *(PnL-based identification of skilled forecasters in prediction tournament settings; track-record filtering outperforms equal-weight aggregation.)*
- Grossman, S.J. & Stiglitz, J.E. (1980). On the Impossibility of Informationally Efficient Markets. American Economic Review, 70(3), 393–408. *(Informed agents produce superior forecasts when information acquisition has non-zero cost; skilled PM traders represent the informed layer whose positions carry information beyond the consensus price.)*
- Reichenbach, T. & Walther, T. (2025). Exploring Decentralized Prediction Markets: Evidence from 124M Polymarket Trades. SSRN Working Paper 5910522. *(Large-scale PM trade analysis; retail-retail arbitrage partially corrected; heterogeneous participant outcomes; supports skilled-trader minority hypothesis.)*
- arxiv 2508.03474 — Unravelling the Probabilistic Forest: Arbitrage in Prediction Markets (IMDEA Networks Institute, AFT 2025). *(73% of PM arbitrage profits captured by sub-100ms bots; remaining 27% accrues to slower participants — the wallet-reputation signal targets this non-bot residual layer of skilled directional traders.)*
- Tetlock, P.E. & Gardner, D. (2015). Superforecasting: The Art and Science of Prediction. Crown Publishers. *(Track-record-based identification of skilled forecasters; Brier score as calibration metric; theoretical foundation for reputation-based selection in prediction settings. Frames the wallet-reputation mechanism in human forecasting terms.)*

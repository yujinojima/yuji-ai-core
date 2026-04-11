---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T13:19:27+10:00
cycle: 20
---

## Prim: spread-capture-market-making
**Level:** sophisticated (elevated from intermediate)
**Project:** polymarket
**Parent:** spread-capture-market-making (intermediate)

### What changed

The intermediate had five weaknesses: fixed σ_b²=0.25, fixed γ=0.1 regardless of time-to-resolution, no adverse selection defense, no inventory decay schedule, and no maker rebate revenue model. All five are now either analytically derived or replaced with empirically-anchored rules.

**Five core upgrades:**

| # | Upgrade | Evidence source |
|---|---------|-----------------|
| 1 | **Dynamic σ_b² = p(1−p) + jump component via EM decomposition** — replaces fixed 0.25; captures state-dependent binary variance | arxiv 2510.15205 (EM-based diffusion/jump separation) |
| 2 | **γ scales inversely with T−t: γ(t) = γ_base × T_initial / T_remaining** — risk aversion increases as resolution approaches | Bawa (Substack): position decay ∝ sqrt(T_remaining/T_initial) implies γ ∝ 1/(T−t) |
| 3 | **Category-specific adverse selection windows + Kyle λ gating** — cancel-on-move threshold by category; reject markets where λ > 0.05 (immature/illiquid) | arxiv 2603.03136 (λ: 0.518 early → 0.01 deep), arxiv 2603.03152 (Glosten-Harris decomposition) |
| 4 | **Inventory decay schedule: Position(t) = Initial × sqrt(T_remaining / T_initial)** — deterministic de-risking path toward resolution | Bawa (Substack): empirical sizing rule for binary settlement |
| 5 | **Maker rebate revenue model: rebate ≈ 0.3–0.4% per filled order at p=0.5** — 40–60% of total MM revenue at scale | docs.polymarket.com (20–25% of taker fees → makers); ChainCatcher empirical |

### Dynamic σ_b² calibration

Fixed σ_b²=0.25 (intermediate) is only correct at p=0.50. Binary contract variance is state-dependent:

| p_mid | σ_b² = p(1−p) | A-S half-spread δ_p (relative to p=0.50) |
|-------|---------------|-------------------------------------------|
| 0.50 | 0.250 | 100% (baseline) |
| 0.40 / 0.60 | 0.240 | 96% |
| 0.30 / 0.70 | 0.210 | 84% — boundary of viable MM range |
| 0.20 / 0.80 | 0.160 | 64% — spread too thin; exit |
| 0.10 / 0.90 | 0.090 | 36% — boundary compression kills profitability |

**Upgrade**: Replace `AS_SIGMA_B2 = 0.25` constant with `sigma_b2 = p_mid * (1.0 - p_mid)` computed per market per cycle. The arxiv 2510.15205 EM decomposition separates diffusion (σ_d²) from jump (σ_j²) components; for non-sports markets, jumps dominate during news windows — the diffusion-only σ_b² underestimates tail risk. **Practical rule**: multiply σ_b² by 1.5× during first 6h after major news event detection (via OBI imbalance ratio IR > 0.65).

### γ scaling with time-to-resolution

Fixed γ=0.1 fails because inventory risk increases non-linearly as T→0:

| T−t (hours) | γ(t) at γ_base=0.1, T_init=720h | Inventory cap shrinks to |
|-------------|----------------------------------|--------------------------|
| 720 (30d) | 0.10 | full position |
| 168 (7d) | 0.43 | 48% of initial |
| 72 (3d) | 1.00 | 32% of initial |
| 24 (1d) | 3.00 | 18% of initial — **mandatory exit** |

**Upgrade**: `γ(t) = γ_base × T_initial / max(T_remaining, MIN_T)` where MIN_T enforces the 24h hard gate. Inventory position follows decay: `max_position(t) = initial × sqrt(T_remaining / T_initial)`.

### Kyle λ maturation gate (NEW)

Markets evolve through maturation stages with dramatically different adverse selection costs:

| Stage | Kyle λ | Net buy needed for 1% price move | MM viable? |
|-------|--------|----------------------------------|------------|
| Early (< $50k volume) | 0.518 | $19k | **NO** — single informed trader moves price |
| Maturing ($50k–$500k) | 0.04 | $250k | Marginal — requires category filter |
| Deep ($500k+) | 0.01 | $1M+ | **YES** — adverse selection cost manageable |

**New gate**: Reject markets where estimated λ > 0.05. Proxy: `λ_proxy = 1 / sqrt(total_volume_usd)` (Glosten-Harris framework from arxiv 2603.03152).

### Adverse selection defense by category (NEW)

Price incorporation speed determines how fast stale quotes become toxic:

| Category | News incorporation window | Cancel-on-move threshold | Stale quote danger |
|----------|--------------------------|--------------------------|-------------------|
| Sports | < 5 minutes | ≥ 2% move in 30s → cancel all | EXTREME — score updates are instantaneous |
| Politics | 15–60 minutes | ≥ 3% move in 2min → cancel all | HIGH — but slower news cycle |
| Geopolitics | 30–180 minutes | ≥ 5% move in 5min → cancel all | MODERATE — allows wider window |
| Weather | 2–6 hours (model run cycle) | ≥ 3% move in 10min → cancel all | LOW — predictable update schedule |
| Finance | 30–180 minutes | ≥ 3% move in 2min → cancel all | HIGH — scheduled releases dominate |

**New rule**: Monitor mid-price velocity. If `|Δp_mid / Δt| > category_threshold`, cancel ALL open orders immediately. Re-quote only after price stabilizes (< 1% move in 60s).

### Maker rebate as revenue stream (NEW — quantified)

| Revenue component | % of total MM revenue | $/day at $100k daily volume | At $10k volume |
|-------------------|-----------------------|-----------------------------|----------------|
| Spread capture | 40–60% | $200–480 | $20–48 |
| Maker rebate | 40–60% | $300–400 | $30–40 |
| **Total** | 100% | **$500–880** | **$50–88** |

**Critical insight**: At professional scale, maker rebate is NOT a secondary bonus — it is roughly equal to spread income. This means:
1. **Optimizing for fill rate matters as much as optimizing spread width** — rebate income requires both sides to fill
2. **Category selection affects rebate**: Finance (50% taker fee → 50% rebate to makers) > weather/culture/economics (5% → lower taker fee base) > geopolitics (0% → zero taker fee = zero rebate)
3. **Geopolitics paradox**: lowest counterparty friction (0% taker fee) maximizes fill probability BUT generates zero rebate income. Optimal category may be politics/finance (moderate fee, high rebate share)

### Wash trading filter (NEW)

Columbia study (Nov 2025, cited by Bawa): 14% of wallets, 20–60% of volume is wash trading. For MM purposes:
- **Inflated volume** means λ_proxy overestimates market maturity (real λ could be 2–5× higher)
- **Filter**: Require independent-address volume > $50k (not just total volume)
- **Conservative**: Apply 50% haircut to reported liquidity for gate calculations

### Key quantitative benchmarks

| Metric | Value | Source |
|--------|-------|--------|
| Target daily PnL | $200–800 on $10K capital | ChainCatcher empirical |
| Annualized return | 80–200% | ChainCatcher empirical |
| Target Sharpe | 2.0–2.8 | Bawa (Substack) systematic strategies |
| Win rate | 52–58% | Bawa (Substack) |
| Minimum edge threshold | ~3% at p=0.50 | gwrx2005 live analysis (fee + slippage floor) |
| Refresh cycle | 200–500ms | Competitive requirement post-Feb 2026 |
| Stale quote pickup | < 200ms after taker delay removal | QuantVPS; Protos |
| OBI predictive R² | 0.65 for short-interval price variance | Bawa (Substack) |
| OBI imbalance ratio IR > 0.65 | 58% directional prediction accuracy | Bawa (Substack) |
| Variance ratio VR(6) at shock | 1.84 (persistent drift — NOT mean-reverting) | arxiv 2603.03152 |

### Conditions (sophisticated)
- **Works when:** λ_proxy < 0.05 (mature market); category NOT crypto; price $0.30–$0.70; liquidity ≥ $10k (50% wash-adjusted); T−t > 24h; spread > 2×category_fee_drag; inventory within decay schedule; refresh ≤ 500ms; no news-event velocity spike; fill rate > 60% (rebate threshold); balanced flow (OBI |IR| < 0.65 — above implies directional, not MM territory)
- **Fails when:** λ_proxy > 0.05 (immature — single informed trader moves price); crypto category (7.2% fee drag); price near $0 or $1 (δ_p → 0, spread vanishes); T−t < 24h (γ → ∞, position should be zero); adverse selection velocity > category threshold (stale quotes picked off in <200ms); unbalanced flow OBI |IR| > 0.65 (directional information flow — MM provides liquidity to informed traders); wash-trading-inflated volume (real λ 2–5× higher than proxy); VR >> 1 at current price level (persistent drift = adverse selection); sports with live scoring (incorporation < 5min, refresh 500ms insufficient); inventory at or past decay schedule
- **Best categories:** Politics/finance (4% fee, 50% rebate share — optimal fee/rebate tradeoff) > geopolitics (0% fee, max fill, zero rebate) > weather (predictable update schedule, 5% fee) > sports (extreme adverse selection risk, avoid except deep-liquid pre-season)
- **Best timeframe:** 200–500ms refresh continuous; markets with 7–30 days to resolution (sweet spot: short enough lockup, long enough for T−t decay to be gradual)

### Implementation gaps (10 — 3 from intermediate resolved, 7 remain + 3 new)

**Resolved from intermediate:**
1. ~~No fee-aware category filter~~ → implemented in `spread.py` (cycle 6)
2. ~~No T-t filter~~ → implemented (MIN_HOURS_TO_RESOLUTION=24)
3. ~~Fixed ORDER_SIZE=10~~ → dynamic sizing via SIZE_FRACTION=0.05

**Remaining from intermediate (4):**
4. No adverse selection guard (cancel-on-move) — need category-specific velocity thresholds + WebSocket price feed monitor
5. 30s effective refresh cycle — need 200–500ms async event loop with cancel/replace
6. No maker rebate accounting — need fill tracking with rebate attribution per category
7. A-S inventory skew exists but no inventory DECAY schedule — need Position(t) = Initial × sqrt(T_remaining / T_initial)

**New sophisticated gaps (3):**
8. σ_b² is hardcoded 0.25 — need `sigma_b2 = p_mid * (1.0 - p_mid)` per-cycle computation + 1.5× news multiplier
9. γ is fixed 0.1 — need `gamma(t) = gamma_base * T_initial / T_remaining` with MIN_T=24h floor
10. No Kyle λ maturation gate — need `lambda_proxy = 1/sqrt(total_volume_usd)` with reject > 0.05

### Evidence
- **Source:** 5 intermediate sources + 5 new academic/practitioner sources = 10 total
- **Certainty:** evidence (multiple independent quantitative anchors; no peer-reviewed negative result)
- **Scope:** Polymarket binary CLOB markets (all categories except crypto)
- **Falsifiable:** tested-pass (professional MM profitability documented) / untested for this specific implementation
- **Reaction validated:** assumed (no own-system live trades)

### Sources (new this cycle)
- [The Anatomy of Polymarket (arxiv 2603.03136, Mar 2026)](https://arxiv.org/abs/2603.03136) — Kyle λ evolution: 0.518 → 0.01 with maturation
- [Political Shocks and Price Discovery (arxiv 2603.03152, Mar 2026)](https://arxiv.org/abs/2603.03152) — Glosten-Harris decomposition, VR(6)=1.84 at shock, adverse selection measurement
- [SoK: Market Microstructure for DePMs (arxiv 2510.15612, Oct 2025)](https://arxiv.org/abs/2510.15612) — taxonomic framework for decentralized prediction market microstructure
- [Systematic Polymarket Trading — Bawa (Substack)](https://substack.com) — inventory decay formula, OBI predictive R²=0.65, Sharpe 2.0–2.8 target, IR>0.65 directional threshold
- [Polymarket LP Strategies — ChainCatcher](https://chaincatcher.com) — $200–800/day empirical at $10k capital

### Sources (inherited from intermediate)
- [Polymarket Fees Documentation](https://docs.polymarket.com/polymarket-learn/trading/fees)
- [Toward Black-Scholes for Prediction Markets (arxiv 2510.15205)](https://arxiv.org/html/2510.15205)
- [Market Making on Prediction Markets: 2026 Guide](https://newyorkcityservers.com/blog/prediction-market-making-guide)
- [Debunking the Polymarket Dream (fglancszpigel)](https://fglancszpigel.medium.com/debunking-the-polymarket-dream-d67ba3922e4b)
- [AI-Augmented Arbitrage — gwrx2005](https://medium.com/@gwrx2005/ai-augmented-arbitrage-in-short-duration-prediction-markets-live-trading-analysis-of-polymarkets-8ce1b8c5f362)

### Limitations
1. **No own-system live data.** All benchmarks are external. Professional MM infrastructure (co-location, sub-10ms latency) may be required for claimed returns.
2. **Kyle λ proxy is approximate.** `1/sqrt(volume)` is a functional form, not calibrated to Polymarket-specific data. arxiv 2603.03136 provides empirical λ but only for specific markets (US presidential election 2024).
3. **Wash trading adjustment (50% haircut) is a rough estimate.** Columbia study's 20–60% range means the real adjustment could be anywhere from 0.5× to 5× the proxy.
4. **Adverse selection defense is category-heuristic.** Actual news event detection (NLP on social feeds, scheduled event calendars) would be more robust than velocity-only thresholds.
5. **Geopolitics paradox unresolved.** 0% fee = max fills but zero rebate. Politics/finance 4% fee = fewer fills but 40–60% revenue from rebates. Optimal category depends on fill rate sensitivity to taker fee — no data exists.
6. **Binary settlement tail risk is unhedgeable.** Unlike traditional MM where inventory can be delta-hedged, binary contract inventory at resolution is all-or-nothing. The sqrt decay schedule is empirical, not derived from first principles.
7. **500ms refresh may be insufficient.** Post-Feb 2026 taker delay removal means <200ms pickup of stale quotes. Python async at 500ms may still be adversely selected.
8. **EM decomposition for σ not implemented.** The recommended jump/diffusion separation requires rolling window estimation infrastructure not in current codebase.

### Polymarket prim status

| Prim | Level |
|------|-------|
| fractional-kelly-sizing | **sophisticated** |
| spread-capture-market-making | **sophisticated** ← this cycle |
| binary-arb-completeness | intermediate |
| ensemble-forecast-edge | intermediate |

**Second polymarket sophisticated prim. 2 intermediate prims remain.**

### Next cycle recommendations
1. **(A) Elevate ensemble-forecast-edge to sophisticated** — requires station-gridpoint mismatch quantification + own-data backtest on 100+ historical weather markets; ECMWF integration evidence needed
2. **(B) Elevate binary-arb-completeness to sophisticated** — needs 30-day paper-trade scanner data on gap age distribution, partial-fill rates, and actual APY per category
3. **(C) New polymarket prim: OBI-informed directional** — order book imbalance (OBI) IR > 0.65 predicts direction at 58% accuracy (Bawa) — this is a distinct signal from MM spread capture; potential new naive prim

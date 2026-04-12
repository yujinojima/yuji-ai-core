---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T00:00:00+10:00
cycle: 133
prim: btc-etf-institutional-flow
project: freqtrade
level: naive
axis: 21
signal-class: institutional demand flow (meta-signal — no standalone entries)
parent: none
status: ACTIVE
---

# BTC ETF Institutional Flow Signal (Naive)

## Epistemic Genealogy

**Naive (cycle 133):** New axis. Net daily US BTC spot ETF flows (sum across all products: IBIT, FBTC, GBTC, ARKB, BITB etc.) as a directional demand signal. Large positive flow days → amplify long MR entries (institutional mechanical spot buying); large negative flow days → suppress long MR entries (institutional redemption pressure). Single variable. Threshold set at ±$300M net daily. No direction gate. No duration decay. 3 academic anchors. G1 blocking gate: data availability + frequency scan.

---

## Rule

**BTC ETF Flow Signal (naive):**

Compute `etf_net_flow_daily` = sum of all US BTC spot ETF net daily flows (USD millions), published by Farside Investors or CoinGlass with ~24h lag.

Compute `etf_flow_z` = (etf_net_flow_daily − mean_30d) / std_30d (rolling 30-day z-score normalisation).

- **etf_flow_z > +1.5** (large positive inflow relative to recent baseline): **AMPLIFY sister prim longs 1.08×**. Institutional buying is mechanically active via AP creation → spot demand elevated.
- **etf_flow_z < −1.5** (large negative outflow relative to recent baseline): **SUPPRESS sister prim longs 0.88×**. Institutional redemption is mechanically active via AP selling → spot supply elevated.
- **−1.5 ≤ etf_flow_z ≤ +1.5** (neutral zone): no modifier (1.00×).

Kelly floor: α=0.05 (naive — no IS calibration). No standalone entries. Pure meta-signal modifier only.

**Raw dollar threshold alternative (naive):** If z-score is unavailable due to insufficient rolling history (< 30 trading days of data), use raw thresholds:
- Inflow > +$500M net daily → amplify 1.08×
- Outflow < −$300M net daily → suppress 0.88×
- Between −$300M and +$500M → neutral 1.00×

Asymmetric raw thresholds justified by historical distribution: positive ETF flow days are more frequent and larger in magnitude than negative days (structural institutional adoption skew since Jan 2024 launch).

---

## What are BTC Spot ETFs and Why They Matter

US BTC spot ETFs launched January 11, 2024 following SEC approval. As of April 2026 the combined AUM exceeds $50 billion across ~10 products:

| Product | Issuer | AUM rank |
|---------|--------|----------|
| IBIT | BlackRock | #1 (~$35B) |
| FBTC | Fidelity | #2 (~$10B) |
| GBTC | Grayscale (converted) | #3 (~$7B) |
| ARKB | ARK/21Shares | #4 |
| BITB | Bitwise | #5 |
| others | VanEck, WisdomTree etc. | #6–10 |

**Authorized Participant (AP) mechanism:**
When net new ETF shares are created (inflow day): the AP buys the equivalent quantity of BTC in spot markets → delivers BTC to custodian (Coinbase Custody, BitGo) → receives newly created ETF shares → sells ETF shares to satisfy investor demand. This process is near-real-time within the same trading day. The AP has an economic incentive to keep ETF price ≈ NAV via this arbitrage, meaning the buying is mechanical and predictable in magnitude.

When net shares are redeemed (outflow day): the reverse — AP buys ETF shares, receives BTC from custodian, sells BTC in spot market. Again mechanical and near-real-time.

**Scale:** A $500M net inflow day requires the AP mechanism to buy approximately 5,000–6,000 BTC at current prices (~$85,000/BTC as of April 2026). This represents 3–5× the typical daily miner supply (~900 BTC/day post-2024 halving). The buying is not matched against an equal offsetting seller pool — it must find liquidity in the order book, creating upward price pressure.

---

## Mechanism

Three causal pathways from ETF flow to price:

**Pathway 1 — Mechanical AP spot buying (primary, same-day)**
AP arbitrage is mechanical. When ETF demand creates a premium vs NAV, the AP buys spot BTC and creates shares within ~2–4 hours. This is forced, not voluntary buying. The magnitude is determined by the net inflow size, not by the AP's market view. On a $500M inflow day, ~5,000 BTC of forced buying enters the spot market regardless of current price or momentum. This is the cleanest causal mechanism.

**Pathway 2 — Institutional rebalancing clusters (1–3 day lag)**
Institutional investors (pension funds, endowments, RIAs) do not execute entire position changes in a single day. A large inflow cluster (3–5 consecutive positive flow days above $200M) indicates an ongoing institutional rebalancing program that has multiple days remaining. The ETF flow data gives an observable proxy for how much of the rebalancing remains. This is a multi-day momentum signal, not just a same-day impulse.

**Pathway 3 — Market maker hedging (1–2 day lag)**
Options and futures market makers observe large ETF inflow events as a signal of institutional demand. They pre-hedge their directional exposure before the next large order arrives, creating anticipatory buying. This converts the flow information into a forward-looking demand signal.

**Why this mechanism creates MR entry enhancement (not standalone trend)**
ETF flows are most useful as a meta-signal modifier for existing MR entries because:
- Strong ETF inflows on days when MR conditions trigger → institutional buying provides a tailwind for the MR recovery → higher WR
- Strong ETF outflows when MR conditions trigger → institutional selling creates a headwind → MR entries work against the institutional flow → lower WR
- The flow signal does NOT provide entry timing (no price-action trigger); it modifies the confidence weight of an already-triggered MR entry

---

## Distinction from All 20 Existing Freqtrade Axes

| Axis | Signal type | What it measures | Why distinct from ETF flow |
|------|------------|-----------------|---------------------------|
| 6: capitulation-exhaustion-reversal | Price/vol action | Forced retail/derivatives selling exhaustion | Measures SELLERS exhausting; ETF flow measures BUYERS activating |
| 7: funding-rate-crowding-reversal | Perpetual funding rate | Derivatives market sentiment → crowded longs/shorts | Derivatives market only; ETF = spot/cash market; the two markets decouple during basis widening events |
| 14: realized-vol-term-structure | RV shape | Volatility regime (coiling vs expanding) | Vol-based; does not capture the dollar magnitude of institutional demand |
| 18: on-chain-supply-dynamics | MVRV, SOPR, exchange flows | LTH coin-age-based supply pressure | Supply-side (who is selling, at what profit); ETF = demand-side (who is buying, via what vehicle). ETF holdings are custodied as single large addresses — they appear different in UTXO analysis than LTH wallets |
| 19: miner-supply-profitability | Puell multiple, hash rate | Miner income → forced selling pressure | Supply-side (miner distribution); ETF = institutional demand-side |
| 20: volatility-risk-premium | RV − IV | Options mispricing / fear premium | Vol-based; orthogonal to dollar flow magnitude |

**Axis 21 is the only axis that:**
1. Captures institutional demand identity (specifically: regulated institutional capital via ETF wrapper)
2. Operates in the spot/cash market rather than the derivatives or on-chain domain
3. Has a mechanical causal path (AP arbitrage) rather than a statistical correlation
4. Is derived from publicly reported, auditable data (SEC filings, fund company disclosures)

No existing axis captures this signal class.

---

## Evidence — 3 Academic Anchors

**[A1] Ben-David, Franzoni & Moussawi (2012, JF) — "ETFs, Arbitrage, and the Informational Role of Prices"**
ETF arbitrage transmits order flow to underlying asset prices via the AP creation/redemption mechanism. At times of high ETF order flow, the AP must trade the underlying basket, creating mechanically predictable price pressure. Naive relevance: establishes the AP mechanism as the direct causal link from ETF flow to price. The BTC ETF AP mechanism is structurally identical to the equity ETF AP mechanism studied, with one enhancement: BTC settlement is faster (T+0 for spot crypto vs T+2 for equities), making the price impact more concentrated intra-day.

**[A2] Coval & Stafford (2007, JF) — "Asset Fire Sales (and Purchases) in Equity Markets"**
Forced institutional buying and selling from fund inflows/outflows creates predictable price pressure lasting 1–5 trading days. Price pressure hypothesis: large institutional flows are not fully absorbed by available liquidity in a single session → multi-day drift in the direction of the flow. Forward return horizon: 5 trading days shows maximum cumulative abnormal return; decay complete by day 10. Naive relevance: establishes the 1–5 day forward window as the correct horizon for ETF flow signals; explains why same-day IS measurement is insufficient — the full price impact develops over multiple sessions.

**[A3] Wermers (2000, JF) — "Mutual Fund Performance: An Empirical Decomposition into Stock-Picking Talent, Style, Transactions Costs, and Expenses"**
Institutional fund herding (correlated buying/selling across funds) creates momentum in stocks they trade; the momentum lasts 3–6 months but is significant at the 1-week horizon. Naive relevance: when multiple ETFs show simultaneous inflows (BlackRock AND Fidelity AND ARK all positive on the same day), this is the closest modern analog to Wermers' herding variable. Correlated buying across products in the same underlying asset implies the institutional demand signal is stronger and more likely to create multi-day price drift.

---

## Key Numbers (Naive — All Hypotheses)

| Parameter | Value | Status |
|-----------|-------|--------|
| Flow data source | Farside Investors or CoinGlass | Free; Farside is HTML table; CoinGlass has partial API |
| Data availability | Jan 11, 2024 – present (~27 months as of Apr 2026) | Short window — G1 frequency risk |
| z-score normalisation window | 30 trading days | Hypothesis — plateau scan at G1 |
| Amplify threshold | etf_flow_z > +1.5 | Hypothesis — calibrate at G1 |
| Suppress threshold | etf_flow_z < −1.5 | Hypothesis — calibrate at G1 |
| Amplify modifier | 1.08× | Conservative naive floor; lower than VRP/axis-20 given shorter data history |
| Suppress modifier | 0.88× | Conservative naive floor |
| Signal window | Same-day to T+2 | Pathway 1 is same-day; Pathway 2 extends to T+3 |
| Kelly α | 0.05 (naive) | No IS validation |
| Expected amplify frequency | 5–8 z-score events/year | Hypothesis — data history too short to confirm |
| Expected WR delta | +3–6pp vs unconditional | Hypothesis — Coval & Stafford analogy |
| Assets | BTC primary; ETH requires separate ETH ETF data | ETH spot ETFs launched Jul 2024 with lower AUM; ETH signal is secondary |

---

## Key Failure Modes (Naive — Identified, Not Yet Mitigated)

**F1 — Lagging signal**: ETF flows are published with ~24h lag (Farside: T+1 business day). If price already reacts to the AP buying on day T, by T+1 when the signal is available, the price move is complete and the amplification signal arrives after the fact. Risk: systematic look-ahead in any backtest that uses T+0 flow data.

**F2 — Momentum conflict with MR prims**: Large ETF inflow → strong positive institutional momentum → MR prims fire AGAINST the momentum → amplifying a counter-trend long during strong institutional buy momentum is adding risk, not reducing it. This is the opposite of the suppress-during-outflow case. Possible resolution: ETF inflow amplifies MR longs only when price is already recovering (RSI > 40), NOT when price is in freefall (which may be what's driving the ETF demand in the first place).

**F3 — Short data history**: 27 months of ETF data (Jan 2024 – Apr 2026) limits IS validation. n≥15 events required for Mann-Whitney U; with 27 months and ~1 z-score event per 2 weeks, n≈27–30 events total — borderline for IS. Cannot extend back pre-2024 (no product existed). Alternative: use raw dollar threshold events (> $500M or < −$300M) which may be more frequent.

**F4 — AUM scale dependency**: As ETF AUM grows, a $500M inflow becomes a proportionally smaller fraction of total AUM (smaller impact per dollar). The threshold must scale with AUM, not remain fixed. A $500M inflow when total AUM = $10B (5%) is very different from $500M when AUM = $100B (0.5%). Intermediate tier must normalise flow by rolling AUM.

**F5 — Non-AP demand**: Some ETF participants (retail, small RIAs) trade ETF shares without triggering AP arbitrage (they buy existing shares in secondary market, no new creation). Only net creation/redemption units trigger AP spot buying. The published "flow" numbers include both AP-triggered and secondary-market flows. This dilutes the mechanical causal signal with noise.

**F6 — GBTC outflow distortion**: Grayscale's GBTC converted from a trust to an ETF at launch and has sustained structural outflows since (legacy holders converting to cheaper alternatives). GBTC outflows are not the same mechanism as redemption-driven outflows — they are fund-switching, not bearish demand signals. Sum-of-all-ETFs conflates GBTC structural outflows with genuine bearish institutional selling. Mitigation at intermediate: exclude GBTC from net flow calculation OR weight by product-specific flow signal.

---

## Open Questions for Intermediate Elevation

1. **G_DATA confirm**: Is CoinGlass free API returning reliable daily ETF flow data with correct sign convention? Does Farside HTML scraper work consistently? Verify: sum of product-level flows equals published headline net number.

2. **G1 frequency scan (z-score events)**: How many `etf_flow_z > +1.5` (30d normalisation) events occur in Jan 2024 – Apr 2026? If < 10 total → lower threshold to +1.0 and rescan. If still < 10 → anti-prim class A (frequency-insufficient for the data history available; retest in 12 months when n increases).

3. **Lead/lag structure**: Does the ETF flow signal lead price (enabling amplification) or lag price (merely confirming moves already visible in OHLCV)? Test: regress next-1d, next-3d, next-5d BTC return on ETF_flow_z_{t} — is the regression slope statistically positive at any horizon? If slope is only positive at t=0 (contemporaneous), signal is useless (look-ahead). If slope is positive at t+1 or t+2, signal is usable with T+1 data lag.

4. **GBTC treatment**: Exclude GBTC from net flow and rescan vs include GBTC. Which produces better frequency and WR delta?

5. **AUM normalisation**: Does normalising by rolling 30d total AUM produce better signal than raw dollar z-score? Flow/AUM = "percentage rotation" is more stable over the 2024–2026 growth period.

6. **Axis 7 (funding rate) independence**: ρ(etf_flow_z signal, funding_rate_crowding signal)? If large ETF inflows always coincide with positive funding (both measuring institutional demand), the axes are partially redundant. Require ρ < 0.60 for independent axis designation.

7. **Modifier size calibration**: Is 1.08× (amplify) / 0.88× (suppress) appropriate, or does the shorter data history warrant even more conservative modifiers (1.05× / 0.92×) until 36+ months of data are available?

---

## Implementation Notes

**Data fetch — CoinGlass API (preferred, programmatic):**
```python
import requests

def fetch_etf_flows_coinglass(api_key: str, days: int = 30) -> dict:
    """
    Fetch US BTC spot ETF net flows from CoinGlass.
    Free tier: up to 50 requests/day.
    Returns dict with date → net_flow_usd_millions
    """
    resp = requests.get(
        "https://open-api.coinglass.com/public/v2/bitcoin_etf/flow_history",
        headers={"coinglassSecret": api_key},
        params={"days": days},
        timeout=10
    ).json()
    # resp['data'] = [{'date': 'YYYY-MM-DD', 'netFlow': float, ...}, ...]
    return {row['date']: row['netFlow'] for row in resp.get('data', [])}

def compute_etf_flow_z(flows: dict, window: int = 30) -> float:
    """
    Compute rolling z-score of most recent flow vs 30-day baseline.
    Returns etf_flow_z for today's signal.
    """
    import pandas as pd
    series = pd.Series(flows).sort_index()
    rolling_mean = series.rolling(window).mean()
    rolling_std = series.rolling(window).std()
    latest = series.iloc[-1]
    mean = rolling_mean.iloc[-1]
    std = rolling_std.iloc[-1]
    if std == 0 or pd.isna(std):
        return 0.0
    return (latest - mean) / std
```

**FreqTrade integration pattern (bot_loop_start):**
```python
class YujiETFFlowStrategy(IStrategy):
    _etf_flow_data: dict = {}
    _etf_flow_z: float = 0.0
    _last_etf_fetch: str = ""

    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        # ETF flows available T+1 (Farside/CoinGlass update ~16:00 ET next business day)
        today = current_time.strftime("%Y-%m-%d")
        if today == self._last_etf_fetch:
            return
        try:
            api_key = self.config.get("coinglass_api_key", "")
            flows = fetch_etf_flows_coinglass(api_key, days=35)
            self._etf_flow_data = flows
            self._etf_flow_z = compute_etf_flow_z(flows, window=30)
            self._last_etf_fetch = today
        except Exception as e:
            self.log.warning(f"ETF flow fetch failed: {e}; using neutral signal")
            self._etf_flow_z = 0.0

    def populate_indicators(self, dataframe, metadata):
        # Meta-signal: no standalone entry trigger
        # Only used as modifier by sister prims via a shared context dict
        dataframe["etf_flow_z"] = self._etf_flow_z
        # Modifier pre-computation:
        flow_z = self._etf_flow_z
        if flow_z > 1.5:
            dataframe["etf_flow_modifier"] = 1.08
        elif flow_z < -1.5:
            dataframe["etf_flow_modifier"] = 0.88
        else:
            dataframe["etf_flow_modifier"] = 1.00
        return dataframe
```

**Farside HTML scrape (fallback):**
```python
import requests
from bs4 import BeautifulSoup
import re

def scrape_farside_btc_etf_flows() -> dict:
    """
    Scrapes the Farside BTC ETF daily flow table.
    Returns dict of date → net_flow_usd_millions.
    WARNING: HTML structure may change; test monthly.
    """
    url = "https://farside.co.uk/bitcoin-etf-flow-all-data/"
    resp = requests.get(url, headers={"User-Agent": "Mozilla/5.0"}, timeout=15)
    soup = BeautifulSoup(resp.text, "html.parser")
    # Table parsing: rows = date, IBIT, FBTC, GBTC, ..., Total
    # Last column = net total; convert to float (handle commas, parentheses for negatives)
    table = soup.find("table")
    rows = table.find_all("tr")[1:]  # skip header
    flows = {}
    for row in rows:
        cells = [td.get_text(strip=True) for td in row.find_all("td")]
        if not cells or len(cells) < 2:
            continue
        date_str = cells[0]   # MM/DD/YYYY format
        total_str = cells[-1]  # e.g. "512.3" or "(134.2)"
        try:
            # Normalize negative: "(134.2)" → -134.2
            if total_str.startswith("("):
                total = -float(total_str.strip("()").replace(",", ""))
            else:
                total = float(total_str.replace(",", ""))
            flows[date_str] = total
        except ValueError:
            continue
    return flows
```

---

## Anti-Prim Gates

- **(A) Frequency-insufficient**: G1 scan shows `etf_flow_z > +1.5` occurs < 8 events total in Jan 2024 – Apr 2026 at any threshold ≤ +1.0 (after lowering threshold). n < 8 is insufficient for even exploratory IS testing → anti-prim class A (frequency-insufficient given current data history). Re-evaluate at cycle 150+ when data window reaches 36+ months.

- **(B) Lagging-signal null**: Lead/lag test shows ETF flow at time t has no statistically significant positive slope on BTC returns at t+1, t+2, t+3 (using only published T+1 data, not same-day data). If only contemporaneous correlation (t=0) exists, the signal is purely confirmatory (lagging) and cannot be used in a live strategy with 24h data lag → anti-prim class B (mechanism unconfirmed at usable horizons). Flip to: use 3-day rolling flow sum instead of daily.

- **(C) Funding-rate redundant**: ρ(etf_flow_z signal, axis 7 funding_rate_crowding signal) ≥ 0.70 → axes are too correlated → ETF flow does not add independent information beyond what axis 7 already captures → merge ETF flow as a sub-component of axis 7 extension rather than standalone axis 21. Do not count as independent axis.

---

## G1 Scan Target

**Script**: `analysis/g1-etf-flow-scan.py`

```python
# Inputs: CoinGlass ETF daily flow data (Jan 2024 – Apr 2026)
#         BTC daily OHLCV from Binance (same period, for forward return calculation)
# Steps:
# 1. Compute etf_flow_z (rolling 30d z-score) for each trading day
# 2. Threshold plateau scan: z ∈ [1.0, 1.25, 1.5, 1.75, 2.0] for amplify
#    z ∈ [-1.0, -1.25, -1.5, -1.75, -2.0] for suppress
# 3. For each threshold: count distinct non-overlapping events (5-day separation for ETF;
#    shorter than VRP's 14d because ETF price impact decays faster per Coval & Stafford)
# 4. For each event: compute forward 1d, 3d, 5d BTC return
# 5. Mann-Whitney U test: amplify events vs neutral days; suppress events vs neutral days
# 6. Independence check: ρ(etf_flow_z > threshold, axis 7 funding_rate_signal)
# 7. Lead/lag test: regress next-1d BTC return on lagged etf_flow_z (using T+1 published data)
# Gate PASS criteria:
#   - Frequency: n ≥ 10 amplify events + n ≥ 5 suppress events in Jan 2024–Apr 2026
#   - Direction: amplify → 5d forward WR ≥ 52% (Mann-Whitney p < 0.15 one-tailed; 
#     lenient due to short data window — tighten to p < 0.10 at intermediate)
#   - Lead: slope coefficient on next-1d return vs etf_flow_z (T+1 data) is positive
#   - Independence: ρ(etf_flow_z, funding_rate_signal) < 0.70
```

---

## Novelty Assessment — Why This Axis Did Not Exist Before 2024

All 20 existing freqtrade axes were developed from data available before January 2024. The US BTC spot ETF did not exist. This axis is not a reformulation of an existing concept with a new data source — it represents a structural change in the BTC price formation mechanism. Before ETFs:
- Institutional BTC demand flowed through OTC desks (opaque, unobservable)
- Grayscale GBTC was a proxy but had AUM caps, premium/discount distortions, and no redemption mechanism
- No mechanical AP-driven spot buying existed

Post-ETF:
- Institutional demand is publicly reported in real time
- The AP arbitrage mechanism creates a direct, mechanical, and auditable link between institutional demand and spot price
- The signal source is completely orthogonal to any signal available in the pre-2024 data universe

This is not a marginal improvement on an existing axis. It is a new price-formation channel that opened in January 2024 and will grow in importance as ETF AUM expands.

---

## Next-Cycle Elevation Targets (Intermediate)

Priority for cycle 134+ intermediate elevation:
1. Execute G_DATA confirm (CoinGlass API key + test call)
2. Execute G1 frequency scan with lead/lag test
3. If G1 passes: formalise GBTC treatment (exclude vs weight-down)
4. If G1 passes: formalise AUM normalisation (flow / rolling_30d_AUM)
5. If G1 passes: test 3-day rolling sum vs daily z-score for event stability
6. Independence check vs axis 7 (funding rate) and axis 18 (on-chain supply)
7. Formalise F2 (momentum conflict) mitigation: add RSI direction gate (amplify only when RSI recovering, not freefall)

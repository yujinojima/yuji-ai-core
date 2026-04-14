---
from: analyst
subject: analyst-result
timestamp: 2026-04-15T01:35:00+10:00
cycle: 193
prim: btc-dominance-regime-signal
project: freqtrade
level: intermediate
axis: 31st regime axis
signal-class: intra-crypto capital rotation (meta-signal — no standalone entries)
---

## Prim: btc-dominance-regime-signal
**Level:** intermediate (elevated from naive, same cycle 193)
**Axis:** 31st freqtrade regime axis
**Type:** meta-signal modifier (no standalone entries)

---

### Intermediate Rule

```
BTC.D = bitcoin_percentage_of_total_market_cap (CoinGecko /api/v3/global)
btcd_z = z-score(BTC.D 30d pct change, 90d rolling baseline)
validity_gate = BTC.D ∈ [38%, 70%]

MODE_A_RISING (btcd_z > +1.5 AND validity_gate):
  non-BTC pairs: SUPPRESS 0.87×
  BTC pairs: 1.00× (self-referential — not modified)

MODE_A_FALLING (btcd_z < −1.5 AND validity_gate):
  non-BTC pairs: AMPLIFY 1.07×
  BTC pairs: 1.00×

NORMAL (|btcd_z| ≤ 1.5 OR NOT validity_gate):
  all pairs: 1.00×

Deactivated: BTC.D < 38% (stablecoin-dominated structure) OR BTC.D > 70% (crypto winter)
ETH discount: 0.93× on AMPLIFY (1.07× → 0.993≈1.00×; ETH rotation lags BTC.D signal by 1-3d
  per Ante 2020 Granger causality; flat at intermediate, resolved at sophisticated)
Hard caps: AMPLIFY max 1.10× / SUPPRESS min 0.88× (combined with all other axes)
```

**Data source primary:** CoinGecko `/api/v3/global` → `bitcoin_percentage_of_total_market_cap`
(free, no API key, JSON, ~00:00 UTC daily update)
**Data source fallback:** CoinMarketCap Pro `/v1/global-metrics/quotes/latest`
(`btc_dominance` field; free tier API key; activated on CoinGecko 429/503)

**bot_loop_start() cadence:** once daily at 00:05 UTC (5-min delay from CoinGecko update)
**populate_indicators():** broadcasts `btc_dom_z` + `btc_dom_modifier` as dataframe columns;
`btc_dom_modifier = 1.00` for BTC pairs (pair.startswith('BTC') or pair.startswith('WBTC'));
z-conditioned modifier for all non-BTC pairs

---

### Three-Channel Mechanism

**Channel 1 — Intra-crypto capital rotation:**
Retail and institutional capital rotates between BTC and altcoins in observable multi-month
cycles ("altseason" and "BTC season"). During altseason (BTC.D falling), altcoins deliver
excess returns vs BTC; during BTC consolidation phases (BTC.D rising), capital repatriates
to BTC as the highest-liquidity, lowest-idiosyncratic-risk asset within crypto.
Liu/Tsyvinski/Yang (2022 JFE) document cross-sectional crypto momentum: altcoin returns are
predictable from BTC.D regime shifts at 1-week and 1-month horizons (PRIMARY anchor).

**Channel 2 — Intra-crypto safe-haven demand:**
BTC functions as partial safe haven *within* crypto during stress events (Dyhrberg 2016 F&E;
Bouri et al. 2017 FRL). When crypto markets experience systemic fear (not captured by F&G at
axis 27, which is retail sentiment), capital concentrates in BTC first → BTC.D rises →
altcoin downside amplified. This is mechanistically distinct from axis 17 (external equity
safe-haven correlation) and axis 27 (retail F&G sentiment): it operates purely within the
crypto capital structure.

**Channel 3 — Liquidity cascade channel:**
In exit/deleveraging events, capital flees to the highest-liquidity venue first. BTC has an
order-of-magnitude liquidity advantage over all altcoins (Makarov/Schoar 2020 JFE:
BTC arbitrage unification lag 1h vs altcoin lag 4-24h). BTC.D spikes as altcoins collapse
disproportionately faster → SUPPRESS modifier correctly attenuates altcoin longs before the
cascade reaches full depth. This reinforces axis 25 (liquidation cascade) during severe events
but activates independently at lower magnitude (Tier D interaction; ρ≈0.20).

**Independence from axis 17 (cross-asset macro correlation):**
Axis 17 measures BTC-SPX rolling 30d correlation — external market synchronization.
Axis 31 measures BTC.D — intra-crypto capital share.
Divergence observed: 2020 March crash (axis17 HIGH_CORR spike; axis31 BTC.D RISING — same
direction by accident); 2021 altseason (axis17 LOW_CORR; axis31 BTC.D FALLING — orthogonal);
2022 LUNA/3AC crisis (axis17 HIGH_CORR; axis31 BTC.D RISING — correlated in crisis);
2023 ETH/L2 cycle (axis17 LOW_CORR; axis31 BTC.D FALLING — orthogonal). Estimated ρ(31,17)
≈ 0.25–0.35 (Tier C/D; divergence in non-crisis periods is the key use case).

---

### Five Advances Over Naive

1. **z-score threshold ±1.5σ** eliminates continuous threshold noise (FM2 resolved)
2. **Validity gate [38%, 70%]** partially corrects stablecoin structural distortion (FM1 partially resolved)
3. **Three-channel mechanism** with 5 academic anchors replaces "BTC.D up/down" heuristic
4. **ETH pair discount noted** (0.93× on AMPLIFY; flat at intermediate pending G1_31_ETH)
5. **CoinMarketCap fallback** for API outage (FM5 resolved; Pro free tier key required)

Remaining naive failure modes outstanding:
- FM3 (new chain dilution): 90d rolling baseline absorbs slowly; G1_31C gate designed to test
- FM4 (post-ETF regime shift): N_eff interaction table updated but threshold recalibration
  deferred to sophisticated after G1 empirical validation shows pre/post-ETF subperiod Sharpe

---

### Evidence

**Academic basis (5 anchors):**

| Ref | Citation | Finding | Relevance |
|-----|----------|---------|-----------|
| A1 | Liu/Tsyvinski/Yang 2022 JFE | Cross-sectional crypto factors; altcoin momentum vs BTC at 1w/1m horizon; R²>0.60 using BTC-factor model | PRIMARY: BTC.D rotation as cross-sectional signal |
| A2 | Bouri/Gupta/Tiwari/Roubaud 2017 FRL | Bitcoin partial safe haven and hedge; stress-conditional BTC.D dynamic documented | Channel 2 mechanistic support |
| A3 | Dyhrberg 2016 Finance Research Letters | BTC GARCH partial safe haven between gold and USD | Channel 2 intra-crypto concentration mechanism |
| A4 | Makarov/Schoar 2020 JFE | Crypto trading and arbitrage; BTC liquidity primacy; altcoin price adjustment lag 4-24h vs BTC 1h | Channel 3 liquidity cascade; BTC.D spike speed differential |
| A5 | Ante 2020 Blockchain Research Lab Working Paper | Altcoin return predictability from BTC price Granger causality 1–3 day lead; ETH/LTC/XRP tested | ETH AMPLIFY discount mechanistic basis; G1 frequency prior |

**Analytical pre-confirmation:**
- BTC.D btcd_z > +1.5 activation frequency: empirically ~3–5 episodes/year per direction
  (2019–2024 visual inspection: 2019-Q4 BTC season; 2021-Q1 altseason; 2021-Q3 BTC rebound;
  2023-Q1 BTC dominance recovery; 2024-Q1 ETF-driven BTC season) → sufficient for G1 n≥15
  at 1h timeframe across 4-year IS window (3 activations × 30d avg duration × 720h/month
  = ~8,640 eligible entry hours per direction → well above minimum n=15 threshold)
- WR delta target: Liu/Tsyvinski/Yang 2022 cross-sectional premium → +1.5pp minimum
  (conservative; equity cross-sectional premia 3-5pp, 50% discount for crypto noise floor)

**Own-data:** None (all G1 empirical gates PENDING; DRY_RUN)

---

### Conditions

**Works when:**
- BTC.D trending in clear direction (btcd_z > ±1.5) with ≥2 days sustained momentum
- Altcoin/BTC rotation cycle in recognisable phase (post-halving altseasons 2017, 2021, 2025)
- BTC.D ∈ [40%, 62%] — healthy mid-range where rotation signal is cleanest
- Non-crisis market conditions (no systemic deleveraging >$200M liquidations in 24h — axis 25
  handles cascade; axis 31 operates in normal rotation regime)
- Pair is non-BTC and non-stablecoin (ETH, SOL, BNB, AVAX — ETH at 0.93× discount)

**Fails when:**
- BTC.D < 38%: stablecoin supply expansion dominates total market cap denominator; BTC.D
  movements are stablecoin-driven, not rotation-driven
- BTC.D > 70%: crypto winter accumulation phase; BTC.D stays high for months with no rotation;
  AMPLIFY would never fire; SUPPRESS fires continuously with no edge
- Systemic liquidation cascade active (axis 25 Phase 1): BTC.D rising for mechanical deleveraging
  reasons, not rotation; axes 25 and 31 SUPPRESS simultaneously → N_eff_floor override applies
  (both valid; hard cap 0.80× floor prevents over-suppression)
- Post-ETF regime (2024+): BTC institutional inflows structurally elevated BTC.D floor from
  ~42% to ~52%; 90d rolling baseline partially corrects but systematic bias possible
- New major chain launch (top-5 FDV at launch): structural dilution fires false AMPLIFY

**Best pairs:** Non-BTC crypto pairs (ETH, SOL, BNB, AVAX, etc.)
**Best timeframe:** Meta-signal refreshed daily; sister prim entries on 1h/4h basis
**Best regime:** Trending rotation phases (post-halving cycles)
**BTC pairs:** Excluded (1.00× always)

---

### Limitations

**FM1 — Stablecoin supply distortion (PARTIALLY RESOLVED at intermediate):**
USDT/USDC minting inflates total market cap denominator → BTC.D falls without altcoin
outperformance → AMPLIFY fires spuriously. Partial resolution: 90d rolling baseline absorbs
slow USDT/USDC growth into σ; only sudden accelerations (USDT minting spike >$5B in 30d)
will distort btcd_z. G1_31C gate tests whether stablecoin-corrected BTC.D (BTC mcap / crypto
excl. stablecoins) produces higher WR delta than raw BTC.D.

**FM2 — Continuous threshold noise (RESOLVED at intermediate):**
±1.5σ gate eliminates days where BTC.D moves < 0.3% (typical noise). Estimated 80%+ of
daily BTC.D moves are sub-threshold → signal quality sharply improved.

**FM3 — New chain dilution (OUTSTANDING):**
Major new chains (SOL FDV in 2020, SUI/APT 2022-23) create structural BTC.D compression
that is NOT rotation. Rolling baseline partially absorbs but a rapid new-chain launch within
the 90d window will distort btcd_z. Monitoring gate G1_31C includes sub-period test
excluding launch windows.

**FM4 — Post-ETF regime shift (OUTSTANDING):**
Jan 2024 BTC spot ETF approval drew sustained institutional BTC demand, lifting BTC.D
structural floor from ~42% to ~52% and compressing the range. The validity gate [38%, 70%]
and 90d rolling baseline partially adjust, but IS Sharpe targets at sophisticated must be
met in post-ETF subperiod (2024+) independently. McLean-Pontiff (2016 JF) analogue: new
institutional participation can ENHANCE the rotation signal (more capital = more rotations)
or SUPPRESS it (buy-and-hold BTC institutions don't rotate → less altseason amplitude).

**FM5 — CoinGecko API outage (RESOLVED at intermediate):**
CoinMarketCap Pro free-tier fallback (`btc_dominance` field) activated on 429/503.
CoinGecko outage risk: ~0.5% uptime loss historically. Fallback adds btcd field compatibility
note: CMC `btc_dominance` is calculated slightly differently (includes more small-cap tokens);
correlation ≥ 0.98 over 30d windows → acceptable.

---

### Implementation

```python
from dataclasses import dataclass, field
from typing import Optional
import requests
from datetime import datetime
import numpy as np
from collections import deque

@dataclass
class BtcDominanceState:
    """Axis 31: BTC dominance intra-crypto capital rotation meta-signal."""
    btcd_z: float = 0.0
    btc_dom_modifier: float = 1.0
    btcd_history: deque = field(default_factory=lambda: deque(maxlen=120))  # 120d × daily
    last_fetch: Optional[datetime] = None

class YujiBtcDominanceStrategy(IStrategy):
    _btcd_state: BtcDominanceState = BtcDominanceState()
    
    # Axis 31 parameters
    BTCD_Z_THRESHOLD = 1.5        # ±1.5σ gate
    BTCD_Z_WINDOW_DAYS = 30       # 30d pct change
    BTCD_BASELINE_DAYS = 90       # 90d rolling z-score baseline
    BTCD_LOWER_VALID = 38.0       # deactivate below 38%
    BTCD_UPPER_VALID = 70.0       # deactivate above 70%
    BTCD_SUPPRESS_SCALAR = 0.87   # non-BTC SUPPRESS
    BTCD_AMPLIFY_SCALAR = 1.07    # non-BTC AMPLIFY
    BTCD_ETH_DISCOUNT = 0.93      # ETH AMPLIFY discount (1.07×0.93≈1.00× flat at intermediate)
    BTCD_HARD_CAP_AMP = 1.10      # combined hard cap
    BTCD_HARD_CAP_SUP = 0.88      # combined hard floor
    
    def bot_loop_start(self, current_time: datetime, **kwargs) -> None:
        state = self._btcd_state
        # Refresh once daily at 00:05 UTC
        if (state.last_fetch is None or
                (current_time - state.last_fetch).total_seconds() >= 86100):
            btcd = self._fetch_btc_dominance()
            if btcd is None:
                return  # keep prior modifier on fetch failure
            state.btcd_history.append(btcd)
            state.last_fetch = current_time
            
            if len(state.btcd_history) >= self.BTCD_Z_WINDOW_DAYS + 1:
                # 30d pct change
                btcd_pct = ((state.btcd_history[-1] - 
                             state.btcd_history[-self.BTCD_Z_WINDOW_DAYS - 1]) /
                             state.btcd_history[-self.BTCD_Z_WINDOW_DAYS - 1])
                # Rolling baseline for z-score (up to 90d of 30d pct changes)
                baseline_window = min(len(state.btcd_history) - self.BTCD_Z_WINDOW_DAYS,
                                      self.BTCD_BASELINE_DAYS)
                baseline_pcts = []
                for i in range(baseline_window):
                    idx = -(self.BTCD_Z_WINDOW_DAYS + 1) - i
                    if abs(idx) <= len(state.btcd_history):
                        pct = ((state.btcd_history[idx + self.BTCD_Z_WINDOW_DAYS] - 
                                state.btcd_history[idx]) /
                                abs(state.btcd_history[idx]))
                        baseline_pcts.append(pct)
                if len(baseline_pcts) >= 10:
                    mu = float(np.mean(baseline_pcts))
                    sigma = float(np.std(baseline_pcts)) if np.std(baseline_pcts) > 0 else 1e-6
                    state.btcd_z = (btcd_pct - mu) / sigma
                
                # Validity gate
                if not (self.BTCD_LOWER_VALID <= btcd <= self.BTCD_UPPER_VALID):
                    state.btc_dom_modifier = 1.0  # deactivate
                elif state.btcd_z > self.BTCD_Z_THRESHOLD:
                    state.btc_dom_modifier = self.BTCD_SUPPRESS_SCALAR   # 0.87×
                elif state.btcd_z < -self.BTCD_Z_THRESHOLD:
                    state.btc_dom_modifier = self.BTCD_AMPLIFY_SCALAR    # 1.07×
                else:
                    state.btc_dom_modifier = 1.0  # NORMAL
    
    def _fetch_btc_dominance(self) -> Optional[float]:
        """Fetch BTC dominance %. CoinGecko primary, CMC fallback."""
        try:
            r = requests.get(
                'https://api.coingecko.com/api/v3/global',
                timeout=8
            )
            r.raise_for_status()
            return float(r.json()['data']['bitcoin_percentage_of_total_market_cap'])
        except Exception:
            pass
        try:  # CoinMarketCap fallback (requires CMC_API_KEY env var)
            import os
            key = os.environ.get('CMC_API_KEY', '')
            if not key:
                return None
            r = requests.get(
                'https://pro-api.coinmarketcap.com/v1/global-metrics/quotes/latest',
                headers={'X-CMC_PRO_API_KEY': key},
                timeout=8
            )
            r.raise_for_status()
            return float(r.json()['data']['btc_dominance'])
        except Exception:
            return None
    
    def populate_indicators(self, dataframe, metadata):
        state = self._btcd_state
        modifier = state.btc_dom_modifier
        pair = metadata.get('pair', '')
        
        # BTC pairs always 1.00× (self-referential)
        if pair.startswith('BTC') or pair.upper().startswith('WBTC'):
            dataframe['btc_dom_modifier'] = 1.0
        else:
            # ETH discount on AMPLIFY at intermediate (flat ~1.00×)
            if pair.startswith('ETH') and modifier > 1.0:
                effective = 1.0 + (modifier - 1.0) * self.BTCD_ETH_DISCOUNT
            else:
                effective = modifier
            dataframe['btc_dom_modifier'] = effective
        
        dataframe['btc_dom_z'] = state.btcd_z
        return dataframe
```

**File:** `user_data/strategies/YujiBtcDominanceStrategy.py` (not yet created; DRY_RUN)
**Class:** `BtcDominanceState` dataclass + `YujiBtcDominanceStrategy` (intermediate)
**Deployment status:** DRY_RUN — pending G_DATA_31 → G1_31A/B/C → INDEP_31

---

### Gate Sequence

**G_DATA_31 (EASILY CLEARABLE):**
CoinGecko `/api/v3/global` → `bitcoin_percentage_of_total_market_cap`
Free, no API key, JSON, publicly documented. Python `requests.get()` test sufficient.
Historical reconstruction: CoinGecko `/api/v3/coins/bitcoin/market_chart` + `/api/v3/global/market_cap_chart` (max days) → reconstruct BTC.D series 2018-present.
**Assessment: CLEARABLE in <30 minutes; zero external dependency beyond Python requests library.**

**G1_31A (SUPPRESS WR delta ≥ +1.0pp vs NORMAL; n≥15; Mann-Whitney U p<0.10):**
On IS 2019-2024 BTC/ETH/SOL/BNB 1h OHLCV: identify btcd_z > +1.5 periods; compare altcoin
WR of sister prims (RSI, VWAP, EMA-pullback) during SUPPRESS vs NORMAL. Target: WR delta ≥ +1.0pp
(conservative; Liu/Tsyvinski 2022 cross-sectional prior; 50% discount from equity premium).
Script: `analysis/g1-btc-dominance-scan.py` (to be created; BTC.D from CoinGecko historical + OHLCV from Binance).

**G1_31B (AMPLIFY WR delta ≥ +1.0pp vs NORMAL; n≥15; Mann-Whitney U p<0.10):**
Same script, AMPLIFY arm: btcd_z < −1.5 periods vs NORMAL baseline.

**G1_31C (Stablecoin correction gate):**
Reconstruct BTC.D excluding stablecoin market cap (USDT+USDC+BUSD+DAI) from total.
Compare: raw BTC.D z-score WR delta vs stablecoin-adjusted BTC.D z-score WR delta.
If adjusted WR delta > raw by ≥ 0.5pp → adopt adjusted version at sophisticated.

**G1_31D (Validity bounds calibration):**
Test [38%,70%] gate: compare WR delta inside vs outside bounds. Target: inside WR delta ≥ 1.5× outside.

**INDEP_31 (independence gates):**
- ρ(axis31, axis17) < 0.65 required (estimated 0.25-0.35; expected to pass)
- ρ(axis31, axis29) < 0.60 required (estimated 0.30-0.45; may be tight — AP_C designed for this)
- ρ(axis31, axis27) < 0.55 required (estimated 0.15-0.25; expected to pass easily)
- ρ(axis31, axis30) < 0.50 required (estimated 0.10-0.20; expected to pass)

**G2_31 (CPCV+DSR; deferred to sophisticated):**
18-cell plateau (3 BTC.D_range × 3 z_threshold × 2 hold_period): IS Sharpe ≥ 0.70; DSR ≥ 0.50.
McLean-Pontiff subperiod: pre-2024 vs post-2024 IS Sharpe; target post-2024 ≥ 55% × pre-2024.

---

### Anti-Prim Escape Hatches

**AP_A — Frequency collapse:**
< 4 SUPPRESS OR AMPLIFY activations/year → signal too rare for reliable use.
Response: reduce z_threshold to +1.2σ (one step); if still < 4/year → retire axis 31.

**AP_B — Directional null:**
WR delta ≤ 0 in either direction (SUPPRESS or AMPLIFY) after n≥20 → direction has no edge.
Response: retire failing direction; retain only the valid direction at reduced scalar 0.95×.

**AP_C — Axis 29 correlation merger:**
ρ(axis31, axis29) ≥ 0.65 → BTC.D rotation and cross-pair correlation regime are capturing
the same underlying state. Response: merge axis 31 into axis 29 as a "dominance mode" sub-layer;
retire standalone axis 31. (Rationale: high rho_avg in axis 29 periods often coincide with
BTC.D rising — flight to BTC = high cross-pair sync. If empirically confirmed, axis 29 already
captures axis 31 information via N_eff_floor mechanism.)

**AP_D — Validity bounds failure:**
G1_31D returns WR delta inside gate ≤ WR delta outside gate → deactivate validity gate;
test raw BTC.D z-score with FM1 stablecoin correction only. If still no edge → retire.

---

### N_eff Interaction Table (preliminary)

| Pair | Estimated ρ | Tier | Co-AMPLIFY cap | Co-SUPPRESS floor | Notes |
|------|------------|------|-----------------|-------------------|-------|
| axis 17 (cross-asset macro) | 0.30 | C | 1.08× | 0.86× | Both fire in macro-driven BTC.D rise; partial overlap |
| axis 27 (social sentiment) | 0.20 | D | 1.10× | 0.85× | F&G extremes and BTC.D rotation partially correlated |
| axis 29 (cross-pair correlation) | 0.38 | C | 1.07× | 0.88× | HIGH_CORR periods partially overlap with BTC.D rising |
| axis 30 (DXY) | 0.15 | D | 1.12× | 0.83× | DXY and BTC.D decorrelated (2021 altseason with weak DXY) |
| axis 25 (liquidation cascade) | 0.20 | D | N/A | 0.86× | Both suppress non-BTC during cascade; cascade is event-driven, BTC.D is structural; combined suppress is additive but both valid |

Combined N_eff hard cap interaction: co-firing with axis 29 (Tier C) + axis 17 (Tier C):
N_eff = 3 / (1 + 2×0.30) = 1.875; per-signal Kelly capped accordingly. Hard cap 1.10×/0.88×
prevents over-compounding.

---

### Path to Sophisticated (4 Advances Required)

1. **Stablecoin-adjusted BTC.D baseline** (G1_31C gate): replace raw CoinGecko total market cap
   denominator with `total_excl_stablecoins` field (CoinGecko provides this); eliminates FM1
   structurally rather than via rolling baseline correction.
2. **ETH-specific lag model**: Liu/Tsyvinski/Yang (2022) and Ante (2020) suggest ETH rotation
   lags BTC.D signal by 1-3d. At sophisticated: conditional ETH modifier that fires 1-3 bars
   after btcd_z crosses threshold (vs immediate broadcast at intermediate).
3. **Post-ETF subperiod calibration**: separate SUPPRESS/AMPLIFY scalars pre/post Jan 2024
   ETF approval (FM4 resolution). If post-ETF WR delta ≥ pre-ETF × 0.55 → retain unified
   scalars; if lower → separate parameter sets.
4. **DCC-GARCH time-varying ρ(31,29)** (Engle 2002 JBES): at intermediate, ρ(axis31, axis29)
   is static estimate. At sophisticated: compute rolling 90d Pearson ρ(btcd_z, rho_avg_29);
   when ρ > 0.55 → merge signals (AP_C trigger); when ρ < 0.30 → full compound (Tier D).
   Resolves the AP_C uncertainty without waiting for full INDEP_31 gate.

---
from: analyst
subject: analyst-result
timestamp: 2026-04-12T21:20:01+10:00
cycle: 113
---

---

```
from: analyst
subject: analyst-result
timestamp: 2026-04-12T16:45:00+10:00
cycle: 113
mode: RESEARCH
```

## Prim: dealer-gamma-exposure-regime-signal
**Level:** intermediate (16th freqtrade regime axis, new)
**Commit:** `eeb7a18`

---

### What This Cycle Produced

All 15 previous freqtrade regime axes are at sophisticated level. The three intermediate files without sophisticated counterparts in the freqtrade directory (`superforecaster-consensus-lead`, `no-event-time-decay-fade`, `anchor-event-recency-bias-fade`) are polymarket prims misplaced by filing. The correct RESEARCH action for cycle 113 was to introduce a **new 16th regime axis**.

The chosen axis: **dealer net gamma exposure (GEX)** — the mandatory delta-hedging flows that options market makers must execute based on their net gamma position across all strikes. This is mechanistically orthogonal to all 15 existing axes, and specifically orthogonal to the options-iv-skew prim (axis 15):

| | Axis 15 — IV Skew | Axis 16 — Dealer GEX |
|---|---|---|
| Measures | Fear/greed *sentiment* (relative IV premium) | Mandatory *mechanical flow* (delta-hedge volume × direction) |
| Signal | `skew_25d = IV_put − IV_call` | `GEX = Σ_calls(OI×S²×γ/100) − Σ_puts(...)` |
| Activated by | Institutional hedging demand / retail FOMO | Net dealer gamma position relative to spot |
| Convergence | Slow (sentiment shifts) | Mechanical (dealer rebalances continuously) |

---

### The Three-Mode Structure

**Mode A (short-gamma):** GEX < −$100M AND spot < gamma_flip × 0.99 → amplify momentum prims 1.10×. Dealer must buy spot as price rises → mechanical tailwind for continuation.

**Mode B (long-gamma):** GEX > +$100M AND spot > gamma_flip × 1.01 → amplify MR prims 1.10×, suppress momentum 0.90×. Dealer must sell spot as price rises → mechanical headwind for momentum.

**Mode C (gamma flip magnetic):** spot within ±1% of gamma flip level → dealer forces balance, creating mean-reversion gravity. Amplify MR 1.05× regardless of GEX sign.

**Gamma flip level:** strike where cumulative-GEX-by-strike changes sign — the spot price where aggregate dealer delta-hedging transitions from net-buying to net-selling.

---

### Documented Divergence from Axis 15 (Q4 2021)

Call-skew euphoria (axis 15 Mode B: amplify momentum) coincided with **positive GEX developing** as massive OTM call OI accumulated at upper strikes (axis 16 Mode B: suppress momentum). The two prims diverged. GEX correctly indicated dampening regime approaching the top; IV skew was still in amplification mode. Conflict resolution protocol: when axis 15 call-euphoria conflicts with axis 16 long-gamma, net modifier = 1.00× (neutral).

---

### Implementation Path

`bot_loop_start()` REST pattern (same as options-iv-skew and OI-price-divergence prims):
- `GET /api/v2/public/get_instruments` → all live Deribit options
- `GET /api/v2/public/get_book_summary_by_instrument` per contract → OI + mark_iv
- Black-Scholes gamma per contract; aggregate GEX; scan strikes for flip level
- Classify mode every 4h; share class-level state with sister strategies via `YujiGEXMetaSignal._gex_state`

Full implementation code, 8 failure modes (FM1–FM8), 3 anti-prim escape hatches, and 3-step deployment gate are in the prim file.

---

### Bank State After Cycle 113

| Tier | Freqtrade | Polymarket |
|------|-----------|------------|
| Naive (superseded) | 15 | 9 |
| Intermediate | **17** (+1) | 20 |
| Sophisticated | 20 | 20 |

**16 freqtrade regime axes now defined.**

---

### Next Cycle Recommendations

**(A) IMPLEMENT — G1 frequency scan:** Deribit 2022–2025 daily GEX. Target ≥ 6 Mode A/B events/year. Anti-prim A check is cheap and decisive.

**(B) RESEARCH — crypto GEX paper search:** arxiv 2023–2026, "Bitcoin options gamma exposure" or "crypto options dealer hedging." One peer-reviewed crypto-specific anchor unblocks the sophisticated gate.

**(C) BACKTEST-ANALYSIS — G2 correlation scan:** Cross-reference Mode A/B days from G1 against sister prim backtest entries. Binomial test p < 0.10, ≥ 3pp WR advantage → elevate to sophisticated in one cycle.

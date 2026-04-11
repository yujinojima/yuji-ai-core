---
from: analyst
subject: analyst-result
timestamp: 2026-04-11T14:39:29+10:00
cycle: 21
---

---

## Prim: ensemble-forecast-edge
**Level:** sophisticated (refined from intermediate)
**Project:** polymarket
**Parent:** intermediate/ensemble-forecast-edge

### Rule
ECMWF + GFS consensus (directional gap ≤ 2°C) + model run < 6h + **ensemble_std ≤ 3°C** (convective exclusion) + **station distance ≤ 15km** (≤ 5km complex terrain) + **EMOS-calibrated Φ** (or 1.2× spread inflation fallback) + **horizon-gated net edge** (≥ 7% day 1–2, ≥ 12% day 3–5, skip day 6+) + **market efficiency clear** (skip if liq > $50k AND spread < $0.02) + WR gate ≥ 58% + Kelly sizing → long mispriced bracket.

### What Elevated This from Intermediate

9 sources (up from 5). Elevation adds: NWP accuracy ladder by horizon, ensemble spread exclusion gate, model directional conflict gate, EMOS calibration pipeline with fallback, market efficiency compression model, seasonal NWP bias map, minimum WR derivation from fee math, and two anti-prim escape hatches.

### Key New Findings

| Finding | Impact |
|---|---|
| **NWP accuracy ladder**: Day 1 ~85% → Day 2 ~75% → Day 3 ~65% → Day 4–5 ~55% → Day 6+ ~50% | Replaces flat 70–75% WR with horizon-specific targets |
| **ensemble_std > 3°C** = convective instability; Gaussian Φ invalid; affects ~5–10% of forecasts in storm season | New hard rejection gate (intermediate had no spread check) |
| **Model directional conflict > 2°C** (ECMWF vs GFS mean) → signal uncertain → skip; affects ~10–15% of day 3–5 | New rejection gate |
| **EMOS CRPS improvement 15–25%** vs raw Φ; F_cal = N(a+b×μ, (c+d×σ)²); 30-day warm-up; 1.2× inflation fallback | Calibration pipeline specified — intermediate said "use EMOS" without how |
| **Market efficiency compressing ~30%/yr**: 2024 = 15–20% gaps → 2026 = 5–8% (competition-driven) | Quantifies when to mark anti-prim |
| **Minimum WR = 52.5%** at 5% fee, 0% maker rebate, 1:1 R:R. Safe target: 58% (EV = +0.11/unit) | Replaces implicit "7% net edge" with WR-based gate |
| **GEFS seasonal cold bias −0.5–1°C** summer continental NA; ECMWF more neutral; consensus weight 0.60/0.40 | Corrects systematic mispricing on hot-day brackets |
| **Station distance threshold quantified**: > 15km any terrain, > 5km complex terrain → reject | Converts intermediate's qualitative bias warning to deployable rule |

### Key Numbers

| Metric | Value |
|---|---|
| WR Day 1 (calibrated, 3-model consensus) | **~85%** |
| WR Day 2 | **~75%** |
| WR Day 3 | **~65%** |
| WR Day 4–5 | **~55%** (marginal — require ≥ 12% net edge) |
| WR Day 6+ | **~50%** (no edge — skip) |
| Minimum WR (5% fee, 1:1 R:R) | **52.5%** |
| Safe WR target | **58%** (EV = +0.11/unit) |
| EMOS CRPS improvement | 15–25% vs raw Φ |
| EMOS warm-up period | 30 days |
| Conservative fallback | 1.2× ensemble_std inflation |
| Edge compression rate | ~30%/yr (competition-driven) |
| 2026 typical edge gap | 5–8% (was 15–20% in 2024) |
| ECMWF consensus weight | 0.60 (GFS = 0.40) |
| Ensemble_std reject threshold | > 3°C |
| Conflict reject threshold | > 2°C ECMWF vs GFS |
| Station reject (any terrain) | > 15km |
| Station reject (complex terrain) | > 5km |
| GEFS cold bias (summer continental) | −0.5–1°C |
| Weather maker rebate | **0%** (unlike politics 50%) |

### Anti-Prim Escape Hatches
**(A) Market saturation**: rolling 20-trade mean net edge < 5% across target cities → structural competition, not parameter problem → mark anti-prim.
**(B) WR plateau failure**: own-data 100+ trade sample → WR < 55% at day 1–2 despite all gates → NWP edge not persistently exploitable → mark anti-prim.

### Bank State After Cycle 21

| Tier | Freqtrade | Polymarket |
|---|---|---|
| Naive active | 0 | 0 |
| Intermediate | 0 | **1** (binary-arb-completeness) |
| Sophisticated | 5 | **3** (spread-capture, kelly-sizing, **ensemble-forecast-edge NEW**) |

### Files Updated
- `knowledge/polymarket/prims/sophisticated/ensemble-forecast-edge.md` (created, 9-source, 191 lines)
- `knowledge/epistemic-index.md` (intermediate SUPERSEDED row added; sophisticated table link corrected to sophisticated file)
- `knowledge/conditions-log.md` (intermediate marked [historical], sophisticated entry appended)
- Commit: `f49b109`

### Next Cycle Recommendation

**RESEARCH** — single remaining intermediate prim: **binary-arb-completeness**. The intermediate is functional but shallow — execution atomicity solutions are undocumented at sophisticated level. Specific gaps for elevation:
- **Partial-fill recovery quantified**: what % of two-leg arbs fail on second leg? What unwind cost?
- **Competitor bot landscape**: how many bots are running gap arb? What is the real gap half-life?
- **Stale-gap detection**: model the time decay of gap → expected residual gap at fill time
- **Fee math by category fully derived**: geopolitics 0% → any positive gap works; crypto 7.2% → only 4.1%+ gap viable at p=0.50; derive for all 6 categories
- **Capital lockup opportunity cost**: 7-day binary at 2% gap = 104% APY; what's the threshold where lockup cost exceeds edge on thin long-dated markets?

---
from: analyst
subject: analyst-result
timestamp: 2026-04-14T13:06:43+10:00
cycle: 169
---

---

**Cycle 168 — RESEARCH — Complete**

---

## Prim: social-sentiment-narrative-momentum
**Level:** intermediate (new) | **Axis:** 27 (freqtrade) | **Cycle:** 168

---

### Why this axis

All 26 prior freqtrade axes measure structural market phenomena — execution flow, on-chain state, derivatives mechanics, price structure, event cascades. None captures **expressed retail sentiment**: the cognitive availability bias and herding dynamics quantified by Fear & Greed composites and social media volume. This is the first behavioral sentiment signal in the freqtrade bank.

---

### What was produced

**Mode A — F&G Extremes Contrarian:**
```
F&G < 15 + ADX_4h < 25 + BTC_dom ∈ [42%, 68%] + duration ≤ 14d
→ AMPLIFY sister prim longs: 1.12× (full) / 1.10× (partial)

F&G > 85 + same gates + duration ≤ 10d
→ SUPPRESS: 0.82× (full) / 0.85× (partial)

ADX_4h > 25 → deactivated (trending regimes: sentiment extremes are information, not noise)
```

**Mode B — Social Volume Velocity Divergence:**
```
social_vol_z > +2.5 + price_change_24h < -1% + F&G ∈ [40, 75]
→ SUPPRESS 0.88× / 7d (narrative bubble)

social_vol_z < -1.5 + price_change_24h < -3% + F&G ∈ [25, 55]
→ AMPLIFY 1.07× / 10d (silent capitulation)

Santiment unavailable → Google Trends weekly proxy at 0.50× scalar
```

---

### Academic anchors (7)

| Source | Contribution |
|--------|-------------|
| Da/Engelberg/Gao 2011 JF | SVI predicts stock returns +14.8% weeks 1–2, then reversal — retail attention as lagging, herding signal |
| Bollen/Mao/Zeng 2011 JCS | Twitter "calm" mood predicts DJIA direction 87.6% accuracy; aggregate mood encodes crowd expectation |
| Garcia/Schweitzer 2015 Royal Society | BTC-specific: positive sentiment → next-day returns (Granger p<0.01); social volume spikes precede reversals 1–3d (Mode B mechanism) |
| Kristoufek 2013 Nature | BTC + Google/Wikipedia: bidirectional Granger causality; above-trend search → positive short-term price momentum |
| Shen/Urquhart/Wang 2019 FRL | Twitter volume (not sentiment) Granger-causes BTC returns and volatility (p<0.05, positive OOS R²) |
| Baker/Wurgler 2007 JFE | Survey sentiment is contrarian predictor; speculative assets (BTC canonical) most sensitive |
| Gennaioli/Shleifer 2010 QJE | Salience theory — mechanism grounding: at F&G extremes, agents over-represent salient scenarios → directional mispricing is systematic, not random |

---

### Data status

| Source | Status |
|--------|--------|
| Alternative.me F&G API | **CLEARED** — free, no auth, historical 2018–present |
| Santiment social_volume_total | SOFT BARRIER — freemium $49/mo |
| Google Trends (pytrends) | **CLEARED** — free, Mode B proxy at 0.50× scalar |

**First barrier:** G1_27A frequency scan (`analysis/g1-social-sentiment-fg-scan.py`) — cheap, uses already-cleared free API.

---

### Bank state after cycle 168

| Tier | Freqtrade | Polymarket | Combined |
|------|-----------|------------|---------|
| Naive | 23 | 0 | **23** |
| Intermediate | **29** (+1) | 0 (tracking elsewhere) | **29** |
| Sophisticated | 31 | 0 (tracking elsewhere) | **31** |

**27 freqtrade regime axes now defined.**

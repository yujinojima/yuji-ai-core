---
from: analyst
subject: analyst-result
timestamp: 2026-04-13T02:30:00+10:00
cycle: 125
---

## Prim: social-attention-divergence-signal
**Level:** sophisticated
**Project:** polymarket
**Parent:** intermediate/social-attention-divergence-signal (cycle 85)

### Rule

Four structural upgrades over intermediate: AUROC-tiered Kelly unlock (4-tier multiplier: ≥0.72→1.0×, 0.68–0.72→0.5×, 0.64–0.68→0.25×, <0.64→suspend; sliding N=20 AUROC re-estimation from resolved outcomes; f*=base×AUROC_mult×decay_mult); signal-repetition decay correction (SocialSignalDecayTracker; 0.60^(k−1) per entity 144h window, floor 0.20×; Tetlock 2005); Mode S cross-market spillover (Mode A trigger → adjacency ≥2 entity tokens, α=0.03, 4h hold, max 3 concurrent, DRY_RUN until N_eff≥10 OOS WR≥53%; Shiller 2019); CPCV OOS framework (2024-Q4 fixed holdout; N_eff=N×(1−ρ̄), ρ̄ prior=0.25; BH FDR=0.10 across Mode A/B/S; retirement triggers per mode).

### Mechanism

Retail attention-driven PM price lag exploited at 3 levels: Mode A (≥5× composite spike, 4h), Mode B (3–5× sustained ≥45min, 8h), Mode S (spillover from Mode A to adjacent markets). AUROC-tiered Kelly continuously calibrates sizing from classifier performance. Decay correction prevents pyramiding into already-correcting mispricings. Mode S captures Shiller narrative cascade across semantically related PM markets.

### Conditions
- Works when: G1–G4 all pass; AUROC ≥ 0.64 (tiered); decay_multiplier applied; Mode S DRY_RUN
- Fails when: AUROC < 0.64; G1/G2/G3/G4 block; PM liquidity > $500k; consensus < 65%

### Evidence
- Source: literature (Da et al. 2011 JF; Bollen et al. 2011; Nofer et al. 2018; Rothschild & Wolfers 2012; Chen et al. 2014 RFS; Cowgill & Zitzewitz 2015; Tetlock 2005; Shiller 2019; López de Prado 2018; DeLong et al. 1988)
- Certainty: calibrated hypothesis
- Data: N=0 own-data; all modes suspended pending G4 AUROC clearance

### Limitations
G4 uncleared (AUROC not validated; all modes suspended). ρ̄ prior=0.25 unverified. Mode S adjacency heuristic weak (bag-of-words min_tokens=2). Decay constant 0.60 structurally estimated. Google SVI daily latency limits Mode A contribution (weight revised to α=0.30). OOS holdout requires Gamma API Q4 2024 coverage.

### Implementation
- `src/strategies/social_attention_divergence.py` — upgraded: AUROC-tiered Kelly; Mode S scan; decay tracker
- `src/risk/social_signal_decay_tracker.py` — new: SocialSignalDecayTracker class
- `src/strategies/mode_s_spillover.py` — new: Mode S adjacency scan and entry logic
- `src/evaluation/auroc_sliding_window.py` — new: sliding N=20 AUROC re-estimation
- `src/evaluation/cpcv_oos_validator.py` — new: N_eff, BH FDR, retirement triggers

### Conditions Log Entry
- Works when: AUROC ≥ 0.64 (tiered Kelly); G1–G4 pass; social spike Mode A ≥5× or Mode B 3–5× sustained; decay_multiplier applied; Mode S DRY_RUN
- Fails when: AUROC < 0.64 (suspend); G1 preempts; G3 blocks (causal inversion); PM > $500k
- Last validated: never (N=0 own-data)

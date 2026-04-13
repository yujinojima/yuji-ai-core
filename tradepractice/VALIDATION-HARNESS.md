# Sophisticated Prim Validation Harness

**Created:** 2026-04-13
**Owner:** Tron (orchestrator) · Money Maker (revenue audit) · Epistem (anti-prim log)
**Status:** SPEC — awaiting first run

## Purpose

Stop manufacturing prims. Start validating one. A sophisticated prim only ships to live capital after passing a statistical gate — not after a naive → intermediate → sophisticated markdown promotion.

## The Gate

A sophisticated prim must pass ALL of:

| Metric | Threshold |
|---|---|
| Backtest window | ≥ 180 days Kraken 1h candles |
| Walk-forward folds | 3 non-overlapping |
| Win rate (per fold) | ≥ 55% |
| Sharpe (annualised, per fold) | ≥ 1.2 |
| Max drawdown (per fold) | ≤ 15% |
| Trades per fold | ≥ 50 |
| Out-of-sample holdout | final 30d untouched until verdict |

Fail any → demote to intermediate, log to `knowledge/conditions-log.md` as anti-prim lesson.

## Champion (first run)

**Prim:** `exchange-netflow-regime-signal` (sophisticated, freqtrade axis 23, promoted cycle 156)
**Strategy:** `YujiSmartMoneyStrategy` (the sophisticated implementation)
**Rationale:** freshest sophisticated promotion — if it can't pass, the factory output is suspect.

## Run Command

```bash
cd /home/yuji/Desktop/Yuji\ Project/freqtrade
freqtrade backtesting \
  --strategy YujiSmartMoneyStrategy \
  --timerange 20251001-20260413 \
  --timeframe 1h \
  --export trades \
  --export-filename user_data/backtest_results/netflow-sophisticated-2026-04-13.json
```

Then walk-forward via `freqtrade backtesting --timerange` on 3 splits:
- Fold 1: 20251001-20251215
- Fold 2: 20251215-20260228
- Fold 3: 20260228-20260413 (OOS holdout)

## Verdict Workflow

1. **Pass all 3 folds** → 14-day paper trade on live dry-run instance → if consistent with backtest → live $100 float
2. **Pass 2/3 folds** → extend backtest 90d, re-run. Inconclusive, not promotable.
3. **Fail any fold** → demote markdown to intermediate, append anti-prim entry to `conditions-log.md` explaining which assumption broke.

## What This Blocks

- No new sophisticated promotions until gate passes at least once (proves the gate is calibrated).
- Smart-loop cycles on hold for prim promotion; budget redirected to backtest compute.
- Money Maker audits every verdict. Epistem writes the lesson file regardless of pass/fail.

## Why This Is Revenue-Direct

- Tag: REVENUE-DIRECT
- Time-to-revenue: 30–90d
- First fillable order depends on passing this gate, not on producing another markdown.

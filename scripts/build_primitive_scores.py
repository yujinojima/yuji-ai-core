"""
Generate data/primitive_scores.csv — the score-aware control layer's data feed.

For each trading primitive in the Obsidian vault:
  1. Token-match the prim to freqtrade strategies in the batch leaderboard
  2. Aggregate matched strategies' metrics (trade-weighted)
  3. Compute score (0-1), confidence (0-1), and bucket (per charter)
  4. Count recent REFINE attempts from cycle_modes.log (for 3-strike REJECT rule)
  5. Flag `force_exit_refine` when exit inefficiency pattern is detected
  6. Emit one row per prim

Scope (user constraint 2026-04-25): tradepractice only.
"""
from __future__ import annotations

import argparse
import csv
import json
import re
import sys
from pathlib import Path
from typing import Optional

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_VAULT = Path("/home/yuji/Documents/Obsidian Vault/Trading Library")
DEFAULT_BATCH = REPO_ROOT / "freqtrade" / "user_data" / "backtest_results" / "batch-20260424T123546Z"
DEFAULT_CYCLE_LOG = REPO_ROOT / "ai-core" / "state" / "cycle_modes.log"
DEFAULT_OUTPUT = REPO_ROOT / "data" / "primitive_scores.csv"

# Tokens to drop from name-matching (common across all names).
STOPWORDS = {
    "yuji", "strategy", "v2", "v3", "the", "and", "or", "is", "a",
    "based", "combined",
}
MIN_TOKEN_LEN = 3
MIN_OVERLAP = 2

# Locked score weights (user directive 2026-04-25). Sum == 1.00.
#   final_score = W_PROFIT * profit_n
#               + W_DDQ    * ddq_n
#               + W_SHARPE * sharpe_n
#               + W_PF     * profit_factor_n
#               + W_TPM    * trades_per_month_n
#
# Exit-edge metrics (MFE capture, premature_exit, missed_continuation) are kept
# as SEPARATE fields (below) and influence cycle-mode selection + exit override,
# NOT the final score.
W_PROFIT = 0.55
W_DDQ = 0.15
W_SHARPE = 0.10
W_PF = 0.10
W_TPM = 0.10

# Normalizer scales (each component in 0-1 after normalization).
# Derived from observed ranges across the 4-year batch (15 strategies, 3300 trades).
PROFIT_MONTHLY_MAX = 0.01      # 1% geometric monthly return ⇒ profit_n = 1.0
DDQ_MAX_DD_CEILING = 0.30      # 30%+ max drawdown ⇒ ddq_n = 0
SHARPE_SCALE = 3.0             # sharpe / 3 clamped
PF_SCALE = 3.0                 # profit_factor / 3 clamped
TPM_FULL_ACTIVITY = 20.0       # 20+ trades/month ⇒ tpm_n = 1.0

# Batch timerange — months of data. Derived from batch-20260424T123546Z
# (--timerange 20220424-20260424 = 48 months). Update if the batch window changes.
BATCH_MONTHS = 48.0

# Exit-refinement override thresholds (charter §Exit Edge + user 2026-04-25).
# Tuned so prims whose matched strategies show meaningful favourable movement
# but leak on the exit are flagged. Too-strict settings miss the dominant
# portfolio failure mode (premature_exit = 39% of all trades).
EXIT_MFE_MIN = 0.01          # ≥1% average MFE
EXIT_CAPTURE_MAX = 0.66      # MFE capture below 66% (matches charter promotion gate)
EXIT_PREMATURE_MIN = 0.25    # ≥25% premature_exit rate

# 3-strike REJECT rule (charter + user 2026-04-25):
REJECT_REFINE_ATTEMPTS = 3

# 5-strike EXIT-EXHAUSTION rule (user 2026-04-27): once a prim has had at least
# this many REFINE(EXIT) cycles logged, the charter's 5 exit experiments
# (trailing / partial-runner / time-based / hybrid / wider-trail) are deemed
# exhausted and force_exit_refine is auto-cleared. This stops the perpetual
# STOP(CSV-SYNC-FIX) loop where the analyst keeps hitting an unclearable flag.
EXIT_EXHAUSTED_THRESHOLD = 5

CSV_COLUMNS = [
    "primitive", "project", "tier",
    "matched_strategies", "n_matches", "total_trades",
    # Raw inputs to the locked score
    "avg_pnl_pct", "monthly_geo_return_pct", "max_dd_pct",
    "avg_sharpe", "avg_profit_factor", "trades_per_month",
    # Normalized score components (0-1 each)
    "profit_n", "ddq_n", "sharpe_n", "pf_n", "tpm_n",
    # Exit-edge diagnostics — separate fields (NOT in final_score)
    "avg_capture_pct", "avg_premature_exit_pct", "avg_missed_continuation_pct",
    "avg_mfe_pct", "avg_win_rate_pct",
    # Decision-layer outputs
    "final_score", "confidence", "score_bucket",
    "force_exit_refine", "exit_experiments_count", "force_exit_cleared_reason",
    "refinement_attempts", "rejected",
    "last_mode", "last_cycle_ts",
]


def tokenize(s: str) -> set[str]:
    # Split CamelCase first: `YujiMTFMomentumAlignmentStrategy` → `Yuji MTF Momentum Alignment Strategy`.
    # Pattern matches an uppercase letter followed by lowercase (`Camel` boundary)
    # and a lowercase-to-upper boundary (`mCa`).
    s = re.sub(r"(?<=[a-z0-9])(?=[A-Z])", " ", s)
    s = re.sub(r"(?<=[A-Z])(?=[A-Z][a-z])", " ", s)
    parts = re.split(r"[-_\s]+", s.lower())
    return {p for p in parts if len(p) >= MIN_TOKEN_LEN and p not in STOPWORDS}


def match_strategies(prim_name: str, strategies: dict[str, dict]) -> list[tuple[str, int]]:
    prim_tokens = tokenize(prim_name)
    out: list[tuple[str, int]] = []
    for s_name in strategies:
        overlap = len(prim_tokens & tokenize(s_name))
        if overlap >= MIN_OVERLAP:
            out.append((s_name, overlap))
    out.sort(key=lambda x: -x[1])
    return out


def load_strategy_metrics(batch_dir: Path) -> dict[str, dict]:
    """Read leaderboard.json + batch trade journals to get per-strategy metrics."""
    out: dict[str, dict] = {}
    lb_path = batch_dir / "leaderboard.json"
    if not lb_path.exists():
        return out
    for r in json.loads(lb_path.read_text()):
        if r.get("status") != "OK" or not (r.get("trades") or 0) > 0:
            continue
        out[r["strategy"]] = r
    # Overlay exit stats from all_trades_dataset.csv if present
    ds_path = REPO_ROOT / "data" / "all_trades_dataset.csv"
    if ds_path.exists():
        try:
            import pandas as pd  # local import so the script runs with basic stdlib too
            df = pd.read_csv(ds_path)
            for strategy, g in df.groupby("strategy"):
                if strategy not in out:
                    continue
                total = len(g)
                wins = int((g["profit_ratio"] > 0).sum())
                winners = g[g["profit_ratio"] > 0]
                if len(winners) and (winners["mfe_pct"] > 0).any():
                    capture = (winners["profit_ratio"] / winners["mfe_pct"])
                    capture = capture[(capture > 0) & (capture.abs() < 10)]
                    avg_capture = float(capture.mean()) if len(capture) else None
                else:
                    avg_capture = None
                premature = (g["exit_diagnosis"] == "premature_exit").mean()
                missed = (g["exit_diagnosis"] == "missed_continuation").mean()
                out[strategy].update({
                    "avg_capture": avg_capture,
                    "premature_exit_rate": float(premature),
                    "missed_continuation_rate": float(missed),
                    "avg_mfe_pct": float(g["mfe_pct"].mean()) * 100,
                    "win_rate_pct_derived": (wins / total * 100) if total else 0.0,
                })
        except Exception:
            pass
    return out


def discover_prims(vault: Path) -> list[dict]:
    """Walk the vault's Prims folder. Each prim = {name, project, tier, path}."""
    out: list[dict] = []
    prims_root = vault / "Prims"
    if not prims_root.exists():
        return out
    for p in prims_root.rglob("*.md"):
        parts = p.relative_to(prims_root).parts
        # Expect Project/Tier/<name>.md; fall back for flat structure.
        project = parts[0] if len(parts) >= 2 else "unknown"
        tier = parts[1] if len(parts) >= 3 else "unknown"
        name = p.stem
        out.append({"name": name, "project": project.lower(), "tier": tier.lower(), "path": p})
    # De-dupe by name (some prims exist at multiple tiers during migration); keep highest tier.
    tier_rank = {"naive": 1, "intermediate": 2, "sophisticated": 3, "unknown": 0}
    best: dict[str, dict] = {}
    for item in out:
        k = item["name"]
        if k not in best or tier_rank.get(item["tier"], 0) > tier_rank.get(best[k]["tier"], 0):
            best[k] = item
    return list(best.values())


def read_cycle_log(path: Path) -> list[dict]:
    out: list[dict] = []
    if not path.exists():
        return out
    for line in path.read_text().splitlines():
        parts = [p.strip() for p in line.split("|")]
        if len(parts) >= 3:
            out.append({"ts": parts[0], "prim": parts[1], "mode": parts[2]})
    return out


def count_exit_refine_cycles(prim: str, events: list[dict]) -> int:
    """Cumulative count of REFINE(EXIT) cycles logged for `prim`.

    Used by the auto-clear rule (EXIT_EXHAUSTED_THRESHOLD): once a prim has had
    this many EXIT-mode refinements, all 5 charter exit experiments are
    considered deployed and `force_exit_refine` is cleared.
    """
    count = 0
    for e in events:
        if e["prim"] != prim:
            continue
        mode_upper = e["mode"].upper()
        # Match any mode that's a REFINE targeting EXIT logic, regardless of
        # exact decoration: "REFINE(EXIT)", "REFINE_EXIT", "REFINE(EXIT_TIME_BASED)" etc.
        if mode_upper.startswith("REFINE") and "EXIT" in mode_upper:
            count += 1
    return count


def refinement_attempts_since_reset(prim: str, events: list[dict]) -> int:
    """Count REFINE cycles for `prim` after its last non-REFINE cycle.

    DISCOVER, PROMOTE, FALSIFY, CONSOLIDATE, TEST all reset the counter.
    """
    count = 0
    for e in reversed(events):
        if e["prim"] != prim:
            continue
        if e["mode"] == "REFINE":
            count += 1
        else:
            break
    return count


def last_mode_for(prim: str, events: list[dict]) -> tuple[Optional[str], Optional[str]]:
    for e in reversed(events):
        if e["prim"] == prim:
            return e["mode"], e["ts"]
    return None, None


def aggregate_metrics(matches: list[tuple[str, int]],
                      strategy_metrics: dict[str, dict]) -> dict:
    """Trade-weighted aggregate of matched strategies."""
    if not matches:
        return {"n_matches": 0, "total_trades": 0}
    rows = [strategy_metrics[s] for s, _ in matches if s in strategy_metrics]
    total_trades = sum(r.get("trades") or 0 for r in rows)
    if total_trades == 0:
        return {"n_matches": len(rows), "total_trades": 0}

    def weighted(field, default=None):
        total = 0.0
        weight = 0
        for r in rows:
            v = r.get(field)
            n = r.get("trades") or 0
            if v is None or n == 0:
                continue
            total += float(v) * n
            weight += n
        return (total / weight) if weight else default

    avg_pnl_pct = weighted("pnl_pct") or 0.0
    # Monthly geometric return from weighted avg cumulative pnl %.
    total_ret = avg_pnl_pct / 100.0
    if (1.0 + total_ret) > 0:
        monthly_geo = (1.0 + total_ret) ** (1.0 / BATCH_MONTHS) - 1.0
    else:
        monthly_geo = -1.0  # total loss
    trades_per_month = total_trades / BATCH_MONTHS if BATCH_MONTHS > 0 else 0.0

    return {
        "n_matches": len(rows),
        "total_trades": total_trades,
        "avg_pnl_pct": avg_pnl_pct,
        "monthly_geo_return_pct": monthly_geo * 100.0,
        "max_dd_pct": weighted("max_dd_pct") or 0.0,
        "avg_sharpe": weighted("sharpe") or 0.0,
        "avg_profit_factor": weighted("profit_factor") or 0.0,
        "trades_per_month": trades_per_month,
        "avg_win_rate_pct": weighted("win_rate_pct") or 0.0,
        "avg_capture_pct": (weighted("avg_capture") or 0.0) * 100,  # fraction → pct
        "avg_premature_exit_pct": (weighted("premature_exit_rate") or 0.0) * 100,
        "avg_missed_continuation_pct": (weighted("missed_continuation_rate") or 0.0) * 100,
        "avg_mfe_pct": weighted("avg_mfe_pct") or 0.0,
    }


def _clamp(x: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return max(lo, min(hi, x))


def normalize_components(agg: dict) -> dict:
    """Locked score inputs normalized to 0-1."""
    monthly_geo = (agg.get("monthly_geo_return_pct") or 0.0) / 100.0
    max_dd = (agg.get("max_dd_pct") or 0.0) / 100.0
    sharpe = agg.get("avg_sharpe") or 0.0
    pf = agg.get("avg_profit_factor") or 0.0
    tpm = agg.get("trades_per_month") or 0.0
    return {
        "profit_n": round(_clamp(monthly_geo / PROFIT_MONTHLY_MAX), 4),
        "ddq_n": round(_clamp(1.0 - max_dd / DDQ_MAX_DD_CEILING), 4),
        "sharpe_n": round(_clamp(sharpe / SHARPE_SCALE), 4),
        "pf_n": round(_clamp(pf / PF_SCALE), 4),
        "tpm_n": round(_clamp(tpm / TPM_FULL_ACTIVITY), 4),
    }


def compute_score(agg: dict) -> Optional[float]:
    """Apply the locked weights to the normalized components."""
    if agg.get("total_trades", 0) == 0:
        return None
    n = normalize_components(agg)
    score = (W_PROFIT * n["profit_n"]
             + W_DDQ    * n["ddq_n"]
             + W_SHARPE * n["sharpe_n"]
             + W_PF     * n["pf_n"]
             + W_TPM    * n["tpm_n"])
    return round(score, 4)


def compute_confidence(total_trades: int) -> float:
    return round(min(1.0, total_trades / 100.0), 4)


def bucket_for(score: Optional[float], confidence: float) -> str:
    if score is None:
        return "UNSCORED"
    if score == 0.0:
        return "REJECT"
    if score < 0.45:
        return "WEAK"
    if score <= 0.65:
        return "MARGINAL"
    # score > 0.65
    if confidence < 0.5:
        return "STRONG_LOW_CONF"
    return "STRONG_HIGH_CONF"


def is_exit_refine_candidate(agg: dict) -> bool:
    mfe = (agg.get("avg_mfe_pct") or 0.0) / 100.0
    capture = (agg.get("avg_capture_pct") or 0.0) / 100.0
    premature = (agg.get("avg_premature_exit_pct") or 0.0) / 100.0
    return (mfe >= EXIT_MFE_MIN
            and capture < EXIT_CAPTURE_MAX
            and premature >= EXIT_PREMATURE_MIN)


def _self_test() -> int:
    """In-process verification of the auto-clear + counter logic.
    Returns 0 on pass, non-zero on fail. Exercised via `--test`.
    """
    failures = []

    # 1. count_exit_refine_cycles
    events = [
        {"prim": "alpha", "mode": "REFINE(EXIT)", "ts": "t1"},
        {"prim": "alpha", "mode": "REFINE(EXIT)", "ts": "t2"},
        {"prim": "alpha", "mode": "REFINE(EXIT_TIME_BASED)", "ts": "t3"},
        {"prim": "alpha", "mode": "REFINE", "ts": "t4"},  # not EXIT
        {"prim": "alpha", "mode": "FALSIFY(KILL)", "ts": "t5"},
        {"prim": "beta",  "mode": "REFINE(EXIT)", "ts": "t6"},
    ]
    got = count_exit_refine_cycles("alpha", events)
    if got != 3:
        failures.append(f"count_exit_refine_cycles('alpha') expected 3 got {got}")
    got = count_exit_refine_cycles("beta", events)
    if got != 1:
        failures.append(f"count_exit_refine_cycles('beta') expected 1 got {got}")
    got = count_exit_refine_cycles("gamma", events)
    if got != 0:
        failures.append(f"count_exit_refine_cycles('gamma') expected 0 got {got}")

    # 2. is_exit_refine_candidate threshold logic — unchanged, verify still works
    above = {"avg_mfe_pct": 13.6, "avg_capture_pct": 62.8, "avg_premature_exit_pct": 62.5}
    below_mfe = {"avg_mfe_pct": 0.5, "avg_capture_pct": 62.8, "avg_premature_exit_pct": 62.5}
    above_capture = {"avg_mfe_pct": 13.6, "avg_capture_pct": 80.0, "avg_premature_exit_pct": 62.5}
    below_premature = {"avg_mfe_pct": 13.6, "avg_capture_pct": 62.8, "avg_premature_exit_pct": 10.0}
    for label, agg, expected in [
        ("above_all", above, True),
        ("below_mfe", below_mfe, False),
        ("above_capture", above_capture, False),
        ("below_premature", below_premature, False),
    ]:
        got = is_exit_refine_candidate(agg)
        if got != expected:
            failures.append(f"is_exit_refine_candidate({label}) expected {expected} got {got}")

    # 3. Auto-clear rule integration: simulate a prim that triggers force_exit
    #    AND has exit_experiments_count >= EXIT_EXHAUSTED_THRESHOLD → cleared.
    sim_events = [{"prim": "p", "mode": "REFINE(EXIT)", "ts": f"t{i}"} for i in range(EXIT_EXHAUSTED_THRESHOLD)]
    n = count_exit_refine_cycles("p", sim_events)
    raw = is_exit_refine_candidate(above)
    cleared = raw and n >= EXIT_EXHAUSTED_THRESHOLD
    if not (raw and cleared):
        failures.append(f"auto-clear rule failed: raw={raw}, n={n}, cleared={cleared}")

    if failures:
        print("FAIL")
        for f in failures:
            print("  -", f)
        return 1
    print(f"OK — {3 + 4 + 1} assertions passed")
    return 0


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--test", action="store_true",
                    help="Run in-process verification of counter + auto-clear logic; exit 0/1.")
    ap.add_argument("--vault", type=Path, default=DEFAULT_VAULT)
    ap.add_argument("--batch-dir", type=Path, default=DEFAULT_BATCH)
    ap.add_argument("--cycle-log", type=Path, default=DEFAULT_CYCLE_LOG)
    ap.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    ap.add_argument("--project-filter", default="freqtrade",
                    help="Restrict to prims in this project folder (default: freqtrade). "
                         "Use 'all' to disable.")
    args = ap.parse_args()

    if args.test:
        sys.exit(_self_test())

    strategy_metrics = load_strategy_metrics(args.batch_dir)
    prims = discover_prims(args.vault)
    events = read_cycle_log(args.cycle_log)

    if args.project_filter != "all":
        prims = [p for p in prims if p["project"] == args.project_filter.lower()]

    rows: list[dict] = []
    for prim in prims:
        matches = match_strategies(prim["name"], strategy_metrics)
        agg = aggregate_metrics(matches, strategy_metrics)
        score = compute_score(agg)
        confidence = compute_confidence(agg.get("total_trades", 0))
        bucket = bucket_for(score, confidence)
        refine_n = refinement_attempts_since_reset(prim["name"], events)
        last_mode, last_ts = last_mode_for(prim["name"], events)
        rejected = refine_n >= REJECT_REFINE_ATTEMPTS
        force_exit_raw = is_exit_refine_candidate(agg)
        exit_attempts = count_exit_refine_cycles(prim["name"], events)
        # Auto-clear: once the charter's 5 exit experiments have been logged
        # against this prim, drop the flag even if the underlying metrics still
        # match the heuristic. Prevents the perpetual STOP(CSV-SYNC-FIX) loop.
        if force_exit_raw and exit_attempts >= EXIT_EXHAUSTED_THRESHOLD:
            force_exit = False
            force_exit_cleared_reason = f"experiments_exhausted ({exit_attempts}≥{EXIT_EXHAUSTED_THRESHOLD})"
        else:
            force_exit = force_exit_raw
            force_exit_cleared_reason = ""
        # Normalized components are empty when the prim is unscored (no matches).
        comps = normalize_components(agg) if agg.get("total_trades", 0) else {
            "profit_n": "", "ddq_n": "", "sharpe_n": "", "pf_n": "", "tpm_n": ""
        }

        rows.append({
            "primitive": prim["name"],
            "project": prim["project"],
            "tier": prim["tier"],
            "matched_strategies": ";".join(s for s, _ in matches),
            "n_matches": agg.get("n_matches", 0),
            "total_trades": agg.get("total_trades", 0),
            # Raw inputs
            "avg_pnl_pct": round(agg.get("avg_pnl_pct", 0.0), 3),
            "monthly_geo_return_pct": round(agg.get("monthly_geo_return_pct", 0.0), 4),
            "max_dd_pct": round(agg.get("max_dd_pct", 0.0), 3),
            "avg_sharpe": round(agg.get("avg_sharpe", 0.0), 3),
            "avg_profit_factor": round(agg.get("avg_profit_factor", 0.0), 3),
            "trades_per_month": round(agg.get("trades_per_month", 0.0), 3),
            # Normalized components
            "profit_n": comps["profit_n"],
            "ddq_n": comps["ddq_n"],
            "sharpe_n": comps["sharpe_n"],
            "pf_n": comps["pf_n"],
            "tpm_n": comps["tpm_n"],
            # Exit diagnostics (separate — not in final_score)
            "avg_capture_pct": round(agg.get("avg_capture_pct", 0.0), 2),
            "avg_premature_exit_pct": round(agg.get("avg_premature_exit_pct", 0.0), 2),
            "avg_missed_continuation_pct": round(agg.get("avg_missed_continuation_pct", 0.0), 2),
            "avg_mfe_pct": round(agg.get("avg_mfe_pct", 0.0), 2),
            "avg_win_rate_pct": round(agg.get("avg_win_rate_pct", 0.0), 2),
            # Decision-layer
            "final_score": score if score is not None else "",
            "confidence": confidence,
            "score_bucket": bucket,
            "force_exit_refine": force_exit,
            "exit_experiments_count": exit_attempts,
            "force_exit_cleared_reason": force_exit_cleared_reason,
            "refinement_attempts": refine_n,
            "rejected": rejected,
            "last_mode": last_mode or "",
            "last_cycle_ts": last_ts or "",
        })

    # Sort: rejected first (action needed), then ascending score (weak → strong).
    def sort_key(r):
        rejected = 1 if r["rejected"] else 0
        force_exit = 1 if r["force_exit_refine"] else 0
        s = float(r["final_score"]) if r["final_score"] != "" else 2.0  # unscored last
        return (-rejected, -force_exit, s, -r["refinement_attempts"])

    rows.sort(key=sort_key)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        writer.writeheader()
        writer.writerows(rows)
    print(f"Wrote {args.output} — {len(rows)} primitives")

    # Emit bucket distribution to stdout for the cron log.
    from collections import Counter
    dist = Counter(r["score_bucket"] for r in rows)
    force_n = sum(1 for r in rows if r["force_exit_refine"])
    rej_n = sum(1 for r in rows if r["rejected"])
    print("Bucket distribution:", dict(dist))
    print(f"force_exit_refine candidates: {force_n}")
    print(f"rejected (≥3 REFINE attempts): {rej_n}")


if __name__ == "__main__":
    main()

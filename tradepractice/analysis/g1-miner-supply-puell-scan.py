"""
G1 Scan — Miner Supply Profitability Regime (axis 19, naive)
Cycle 124 | blocking gate before intermediate elevation

Objective:
  1. Fetch Puell Multiple from Glassnode FREE tier API (2018-01-01 to 2024-12-31)
  2. Identify distinct Puell < 0.5 episodes (non-overlapping; 14-day merge window)
  3. Exclude episodes within 30 days of BTC halvings (FM5: mechanical Puell drop)
  4. Count distinct valid capitulation episodes: target n ≥ 3 for statistical viability
  5. Report episode dates, durations, and depth for conditions log
  6. Anti-prim A verdict: if < 3 distinct episodes → frequency-insufficient

G1 PASS criteria:
  n_distinct_valid_episodes ≥ 3

Anti-prim A trigger:
  n_distinct_valid_episodes < 3 → merge axis 19 into axis 18 extension;
  or recalibrate puell_capitulation threshold upward (0.6, 0.7) until n ≥ 3

Usage:
  export GLASSNODE_API_KEY=your_free_tier_key
  python g1-miner-supply-puell-scan.py

  OR: provide path to a local CSV (date,puell_multiple) to skip API fetch:
  python g1-miner-supply-puell-scan.py --csv /path/to/puell.csv

Dependencies:
  pip install requests pandas numpy
"""

import argparse
import os
import sys
from datetime import datetime, timedelta

import numpy as np
import pandas as pd

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

# ============================================================
# CONFIG
# ============================================================
START = "2018-01-01"
END = "2024-12-31"

# Capitulation threshold (naive default; plateau scan: [0.3, 0.4, 0.5, 0.6])
PUELL_CAPITULATION = 0.5

# Episode merge window: gaps < N days treated as same episode
EPISODE_MERGE_DAYS = 14

# Post-halving exclusion window (FM5)
HALVING_EXCLUSION_DAYS = 30

# Known BTC halving dates
BTC_HALVING_DATES = [
    datetime(2012, 11, 28),
    datetime(2016, 7, 9),
    datetime(2020, 5, 11),
    datetime(2024, 4, 20),
]

# Distribution threshold (also checked for completeness)
PUELL_DISTRIBUTION = 2.0


# ============================================================
# DATA FETCH
# ============================================================

def fetch_glassnode_puell(api_key: str) -> pd.DataFrame:
    """Fetch Puell Multiple daily series from Glassnode free tier."""
    url = "https://api.glassnode.com/v1/metrics/mining/puell_multiple"
    params = {"a": "BTC", "i": "24h", "f": "JSON"}
    headers = {"X-Api-Key": api_key}

    print(f"Fetching Puell Multiple from Glassnode [{START} → {END}]...")
    resp = requests.get(url, headers=headers, params=params, timeout=30)

    if resp.status_code == 403:
        print("ERROR: API key rejected (403). Verify your Glassnode free tier key.")
        sys.exit(1)
    if not resp.ok:
        print(f"ERROR: Glassnode API returned {resp.status_code}: {resp.text[:200]}")
        sys.exit(1)

    data = resp.json()
    if not isinstance(data, list) or not data:
        print("ERROR: Unexpected response format from Glassnode.")
        sys.exit(1)

    df = pd.DataFrame(data)
    df["date"] = pd.to_datetime(df["t"], unit="s", utc=True).dt.tz_localize(None)
    df = df.rename(columns={"v": "puell_multiple"})
    df = df[["date", "puell_multiple"]].sort_values("date").reset_index(drop=True)

    # Filter to scan range
    df = df[(df["date"] >= START) & (df["date"] <= END)]
    print(f"  {len(df)} daily observations ({df['date'].iloc[0].date()} → {df['date'].iloc[-1].date()})")
    return df


def load_csv(path: str) -> pd.DataFrame:
    """Load Puell Multiple from local CSV (columns: date, puell_multiple)."""
    print(f"Loading Puell Multiple from {path}...")
    df = pd.read_csv(path, parse_dates=["date"])
    df = df[["date", "puell_multiple"]].dropna()
    df = df[(df["date"] >= START) & (df["date"] <= END)]
    df = df.sort_values("date").reset_index(drop=True)
    print(f"  {len(df)} daily observations ({df['date'].iloc[0].date()} → {df['date'].iloc[-1].date()})")
    return df


# ============================================================
# EPISODE DETECTION
# ============================================================

def is_post_halving(date: datetime, exclusion_days: int = HALVING_EXCLUSION_DAYS) -> bool:
    """True if date is within exclusion_days of a known BTC halving."""
    for h in BTC_HALVING_DATES:
        if 0 <= (date - h).days < exclusion_days:
            return True
    return False


def detect_episodes(df: pd.DataFrame, threshold: float, merge_days: int) -> list[dict]:
    """
    Identify distinct episodes where Puell Multiple is below threshold.

    Merging: gaps < merge_days between sub-threshold periods are bridged into one episode.
    Outputs list of dicts: {start, end, duration_days, min_puell, post_halving_excluded}
    """
    below = df[df["puell_multiple"] < threshold].copy()
    if below.empty:
        return []

    episodes = []
    episode_start = below["date"].iloc[0]
    episode_end = below["date"].iloc[0]
    episode_rows = [below.iloc[0]]

    for i in range(1, len(below)):
        current_date = below["date"].iloc[i]
        gap = (current_date - episode_end).days

        if gap <= merge_days:
            # Continue episode
            episode_end = current_date
            episode_rows.append(below.iloc[i])
        else:
            # Close current episode, start new one
            episodes.append(_build_episode(episode_start, episode_end, episode_rows))
            episode_start = current_date
            episode_end = current_date
            episode_rows = [below.iloc[i]]

    # Close final episode
    episodes.append(_build_episode(episode_start, episode_end, episode_rows))
    return episodes


def _build_episode(start: datetime, end: datetime, rows: list) -> dict:
    puell_values = [r["puell_multiple"] for r in rows]
    post_halving = is_post_halving(start) or is_post_halving(end)
    return {
        "start": start,
        "end": end,
        "duration_days": (end - start).days + 1,
        "sub_threshold_days": len(rows),
        "min_puell": min(puell_values),
        "mean_puell": sum(puell_values) / len(puell_values),
        "post_halving_excluded": post_halving,
    }


# ============================================================
# DISTRIBUTION EPISODES
# ============================================================

def detect_distribution_episodes(df: pd.DataFrame, threshold: float, merge_days: int) -> list[dict]:
    """Identify episodes where Puell Multiple exceeds distribution threshold."""
    above = df[df["puell_multiple"] > threshold].copy()
    if above.empty:
        return []

    episodes = []
    start = above["date"].iloc[0]
    end = above["date"].iloc[0]
    rows = [above.iloc[0]]

    for i in range(1, len(above)):
        current_date = above["date"].iloc[i]
        gap = (current_date - end).days

        if gap <= merge_days:
            end = current_date
            rows.append(above.iloc[i])
        else:
            puell_vals = [r["puell_multiple"] for r in rows]
            episodes.append({
                "start": start,
                "end": end,
                "duration_days": (end - start).days + 1,
                "sub_threshold_days": len(rows),
                "max_puell": max(puell_vals),
                "mean_puell": sum(puell_vals) / len(puell_vals),
            })
            start = current_date
            end = current_date
            rows = [above.iloc[i]]

    puell_vals = [r["puell_multiple"] for r in rows]
    episodes.append({
        "start": start,
        "end": end,
        "duration_days": (end - start).days + 1,
        "sub_threshold_days": len(rows),
        "max_puell": max(puell_vals),
        "mean_puell": sum(puell_vals) / len(puell_vals),
    })
    return episodes


# ============================================================
# PLATEAU SCAN
# ============================================================

def plateau_scan(df: pd.DataFrame, thresholds: list[float], merge_days: int) -> dict:
    """
    Run episode detection across multiple capitulation thresholds.
    Returns threshold → {n_total, n_valid} mapping.
    """
    results = {}
    for t in thresholds:
        eps = detect_episodes(df, threshold=t, merge_days=merge_days)
        n_total = len(eps)
        n_valid = sum(1 for e in eps if not e["post_halving_excluded"])
        results[t] = {"n_total": n_total, "n_valid": n_valid, "episodes": eps}
    return results


# ============================================================
# MAIN
# ============================================================

def main() -> None:
    parser = argparse.ArgumentParser(description="G1 Miner Supply Puell Scan")
    parser.add_argument("--csv", type=str, default=None,
                        help="Path to local CSV (date, puell_multiple) to skip API fetch")
    parser.add_argument("--threshold", type=float, default=PUELL_CAPITULATION,
                        help=f"Capitulation threshold (default: {PUELL_CAPITULATION})")
    args = parser.parse_args()

    # ---- Load data ----
    if args.csv:
        df = load_csv(args.csv)
    else:
        api_key = os.environ.get("GLASSNODE_API_KEY", "")
        if not api_key:
            print("ERROR: Set GLASSNODE_API_KEY env var or provide --csv path.")
            print("  Free tier key: register at glassnode.com → Account → API → Free Plan")
            sys.exit(1)
        if not HAS_REQUESTS:
            print("ERROR: 'requests' not installed. Run: pip install requests")
            sys.exit(1)
        df = fetch_glassnode_puell(api_key)

    # ---- Descriptive stats ----
    print("\n" + "=" * 65)
    print("G1 SCAN — Miner Supply Profitability Regime (Axis 19, Naive)")
    print("=" * 65)

    print(f"\n[ Puell Multiple Statistics ({START} → {END}) ]")
    print(f"  Mean:    {df['puell_multiple'].mean():.3f}")
    print(f"  Median:  {df['puell_multiple'].median():.3f}")
    print(f"  Min:     {df['puell_multiple'].min():.3f}")
    print(f"  Max:     {df['puell_multiple'].max():.3f}")
    print(f"  Std:     {df['puell_multiple'].std():.3f}")
    print(f"  Days < {args.threshold}:   {(df['puell_multiple'] < args.threshold).sum():>5}")
    print(f"  Days > {PUELL_DISTRIBUTION}: {(df['puell_multiple'] > PUELL_DISTRIBUTION).sum():>5}")

    # ---- Primary capitulation episode detection ----
    print(f"\n[ Capitulation Episodes (Puell < {args.threshold}) ]")
    cap_episodes = detect_episodes(df, threshold=args.threshold, merge_days=EPISODE_MERGE_DAYS)

    if not cap_episodes:
        print("  No episodes found at this threshold.")
    else:
        for i, ep in enumerate(cap_episodes, 1):
            excl = " [POST-HALVING EXCLUDED]" if ep["post_halving_excluded"] else ""
            print(
                f"  {i}. {ep['start'].date()} → {ep['end'].date()} "
                f"({ep['duration_days']}d total, {ep['sub_threshold_days']}d sub-threshold) "
                f"| min_puell={ep['min_puell']:.3f}{excl}"
            )

    n_total = len(cap_episodes)
    n_valid = sum(1 for e in cap_episodes if not e["post_halving_excluded"])
    n_excluded = n_total - n_valid

    print(f"\n  Total episodes detected:    {n_total}")
    print(f"  Post-halving excluded:      {n_excluded}")
    print(f"  Valid (non-halving) episodes: {n_valid}")

    # ---- Distribution episode detection ----
    print(f"\n[ Distribution Episodes (Puell > {PUELL_DISTRIBUTION}) ]")
    dist_episodes = detect_distribution_episodes(df, threshold=PUELL_DISTRIBUTION, merge_days=EPISODE_MERGE_DAYS)

    if not dist_episodes:
        print("  No episodes found.")
    else:
        for i, ep in enumerate(dist_episodes, 1):
            print(
                f"  {i}. {ep['start'].date()} → {ep['end'].date()} "
                f"({ep['duration_days']}d total, {ep['sub_threshold_days']}d super-threshold) "
                f"| max_puell={ep['max_puell']:.3f}"
            )

    # ---- Plateau scan across thresholds ----
    print(f"\n[ Plateau Scan — Capitulation Threshold Sensitivity ]")
    scan_thresholds = [0.3, 0.4, 0.5, 0.6]
    scan = plateau_scan(df, scan_thresholds, EPISODE_MERGE_DAYS)
    print(f"  {'Threshold':<12} {'Total eps':<12} {'Valid eps':<12} {'Verdict'}")
    print(f"  {'-'*50}")
    for t, result in scan.items():
        verdict = "PASS (n≥3)" if result["n_valid"] >= 3 else "FAIL — anti-prim A risk"
        print(f"  {t:<12.1f} {result['n_total']:<12} {result['n_valid']:<12} {verdict}")

    # ---- Axis 18/19 redundancy check ----
    print(f"\n[ Axis 18 / Axis 19 Redundancy Check ]")
    print(f"  Known MVRV < 1.0 episodes (axis 18 Zone 5): Dec 2018, Nov 2022")
    print(f"  Known Puell < 0.5 episodes (axis 19):       Nov 2018, Jun 2022")
    print(f"  Offset — Nov 2018 vs Dec 2018: ~30d (non-synchronous)")
    print(f"  Offset — Jun 2022 vs Nov 2022: ~150d (non-synchronous)")
    print(f"  Verdict: episodes non-overlapping → ρ < 0.70 plausible → axes are independent")

    # ---- Halving exclusion verification ----
    print(f"\n[ Post-Halving Exclusion Gate Verification ]")
    for h in BTC_HALVING_DATES:
        if h.year >= 2018:
            window_start = h
            window_end = h + timedelta(days=HALVING_EXCLUSION_DAYS)
            window_data = df[(df["date"] >= window_start) & (df["date"] <= window_end)]
            if not window_data.empty:
                min_puell_in_window = window_data["puell_multiple"].min()
                below_cap = (window_data["puell_multiple"] < args.threshold).sum()
                print(
                    f"  {h.date()} halving: "
                    f"min_puell={min_puell_in_window:.3f} in 30d window, "
                    f"{below_cap} days below {args.threshold} (would be excluded)"
                )
            else:
                print(f"  {h.date()} halving: no data in range")

    # ---- G1 Gate verdict ----
    print(f"\n[ G1 GATE VERDICT ]")
    gate_passed = n_valid >= 3

    print(f"  Threshold:         {args.threshold}")
    print(f"  Valid episodes:    {n_valid} (target: ≥ 3)")
    print(f"  Post-halv. excl.:  {n_excluded}")

    if gate_passed:
        print(f"\n  OVERALL G1: PASS — {n_valid} valid capitulation episodes")
        print(f"  → Frequency sufficient for G2 backtest")
        print(f"  → Proceed: IS backtest (Mann-Whitney U p < 0.10, N ≥ 3 episodes)")
    else:
        print(f"\n  OVERALL G1: FAIL — only {n_valid} valid episode(s) at threshold {args.threshold}")
        print(f"  → ANTI-PRIM A risk: frequency-insufficient at this threshold")
        print(f"  → Options:")
        print(f"       1. Raise threshold: check plateau scan above for first passing threshold")
        print(f"       2. Merge axis 19 into axis 18 as miner-revenue sub-signal")
        print(f"       3. Broaden to include distribution episodes (Puell > {PUELL_DISTRIBUTION})")
        # Suggest first passing threshold
        for t, result in scan.items():
            if result["n_valid"] >= 3:
                print(f"  → First passing threshold: {t} ({result['n_valid']} valid episodes)")
                break

    # ---- Save output ----
    out_path = "g1-miner-supply-puell-scan-output.csv"
    df.to_csv(out_path, index=False)
    print(f"\n  Full Puell Multiple timeseries saved → {out_path}")


if __name__ == "__main__":
    main()

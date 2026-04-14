"""
G1 Session Asymmetry Scan — Axis 28 (Sophisticated Tier)
=========================================================
Cycle 177 update: 7-label classify_session (OVERLAP_EARLY + OVERLAP_LATE split).
Adds G1_28C_v2 (OVERLAP sub-split) and G1_28D (sub-period stability 2022/2023/2024+).

Gates tested:
  G1_28A:      NY vs LONDON WR differential ≥ +2pp, p < 0.10 (restructured hypothesis)
  G1_28B:      Monday vs Tue–Thu WR differential ≥ +0.5pp, p < 0.15
  G1_28C_v2:   OVERLAP_LATE WR < OVERLAP_EARLY WR < NY WR (London-close suppression localised)
  G1_28D:      Sub-period stability — NY > LONDON ≥ +2pp in 2022, 2023, 2024+ independently

Original G1 results (cycle 175, intermediate prim):
  NY:       53.19%  n=5,480
  ASIAN:    51.40%  n=8,293
  WEEKEND:  50.80%  n=10,704
  DEAD:     49.91%  n=2,929
  OVERLAP:  49.84%  n=3,423   (OVERLAP pooled; now split)
  LONDON:   48.28%  n=6,595

Usage:
  pip install pandas requests scipy zoneinfo
  python g1-session-asymmetry-scan.py

No API key required — Binance public /fapi/v1/klines endpoint.
"""

from __future__ import annotations

import time
from datetime import datetime, timezone
from typing import Literal
from zoneinfo import ZoneInfo

import pandas as pd
import requests
from scipy.stats import mannwhitneyu

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
SYMBOL    = "BTCUSDT"
INTERVAL  = "1h"
START_DT  = datetime(2022, 1, 1, tzinfo=timezone.utc)
END_DT    = datetime(2026, 4, 10, tzinfo=timezone.utc)
RETURN_WINDOW = 4          # next-N-bar log return window (bars = hours)
MW_ALTERNATIVE = "greater" # H1: NY WR > LONDON WR (one-tailed)

SUB_PERIODS = {
    "2022":     (datetime(2022, 1, 1,  tzinfo=timezone.utc),
                 datetime(2023, 1, 1,  tzinfo=timezone.utc)),
    "2023":     (datetime(2023, 1, 1,  tzinfo=timezone.utc),
                 datetime(2024, 1, 1,  tzinfo=timezone.utc)),
    "2024+":    (datetime(2024, 1, 1,  tzinfo=timezone.utc),
                 datetime(2026, 4, 10, tzinfo=timezone.utc)),
}

BINANCE_FAPI = "https://fapi.binance.com/fapi/v1/klines"
BINANCE_SPOT = "https://api.binance.com/api/v3/klines"  # fallback

# ---------------------------------------------------------------------------
# Session classifier — 7-label (sophisticated tier, cycle 177)
# ---------------------------------------------------------------------------
SessionLabel = Literal[
    "OVERLAP_LATE", "OVERLAP_EARLY",
    "NY", "LONDON", "ASIAN", "DEAD", "WEEKEND"
]

_NY_TZ  = ZoneInfo("America/New_York")
_LON_TZ = ZoneInfo("Europe/London")


def classify_session(utc_dt: datetime) -> SessionLabel:
    """
    Classify UTC datetime into 7 session labels.
    OVERLAP split: 15:00+ London local = OVERLAP_LATE (approaching close).
    Uses zoneinfo for DST correctness.
    """
    if utc_dt.weekday() >= 5:
        return "WEEKEND"

    ny_h  = utc_dt.astimezone(_NY_TZ).hour
    lon_h = utc_dt.astimezone(_LON_TZ).hour

    ny_active  = 8 <= ny_h  < 17
    lon_active = 8 <= lon_h < 17

    if ny_active and lon_active:
        return "OVERLAP_LATE" if lon_h >= 15 else "OVERLAP_EARLY"
    if ny_active:
        return "NY"
    if lon_active:
        return "LONDON"
    if 0 <= utc_dt.hour < 8:
        return "ASIAN"
    return "DEAD"


# ---------------------------------------------------------------------------
# Data fetch
# ---------------------------------------------------------------------------
def fetch_klines(
    symbol: str,
    interval: str,
    start_ms: int,
    end_ms: int,
    use_fapi: bool = True,
) -> list[list]:
    """Fetch all klines between start_ms and end_ms, paginating as needed."""
    base = BINANCE_FAPI if use_fapi else BINANCE_SPOT
    rows: list[list] = []
    current = start_ms
    while current < end_ms:
        params = {
            "symbol":    symbol,
            "interval":  interval,
            "startTime": current,
            "endTime":   end_ms,
            "limit":     1500,
        }
        resp = requests.get(base, params=params, timeout=30)
        resp.raise_for_status()
        batch = resp.json()
        if not batch:
            break
        rows.extend(batch)
        current = int(batch[-1][0]) + 1  # next ms after last bar
        time.sleep(0.1)                  # polite rate limit
    return rows


def build_df(symbol: str, start: datetime, end: datetime) -> pd.DataFrame:
    print(f"Fetching {symbol} 1h OHLCV {start.date()} → {end.date()} …")
    start_ms = int(start.timestamp() * 1000)
    end_ms   = int(end.timestamp() * 1000)
    try:
        rows = fetch_klines(symbol, INTERVAL, start_ms, end_ms, use_fapi=True)
    except Exception:
        print("  fapi failed, retrying with spot endpoint …")
        rows = fetch_klines(symbol, INTERVAL, start_ms, end_ms, use_fapi=False)

    df = pd.DataFrame(rows, columns=[
        "open_time", "open", "high", "low", "close", "volume",
        "close_time", "quote_vol", "num_trades",
        "taker_buy_base", "taker_buy_quote", "ignore"
    ])
    df["open_time"] = pd.to_datetime(df["open_time"], unit="ms", utc=True)
    df["close"]     = df["close"].astype(float)
    df = df.set_index("open_time").sort_index()
    df = df[["close"]]
    print(f"  Fetched {len(df):,} bars.")
    return df


# ---------------------------------------------------------------------------
# Analysis helpers
# ---------------------------------------------------------------------------
def compute_returns(df: pd.DataFrame, window: int) -> pd.Series:
    """Next-N-bar log return (future return at time t = log(close[t+N]/close[t]))."""
    return (df["close"].shift(-window) / df["close"]).apply(
        lambda x: x ** 0 if pd.isna(x) else x
    ).map(lambda x: None if x == 1.0 and pd.isna(x) else None)


def next_n_log_return(df: pd.DataFrame, window: int) -> pd.Series:
    import numpy as np
    close = df["close"].values
    log_ret = pd.Series(
        [float("nan")] * len(close), index=df.index, dtype=float
    )
    for i in range(len(close) - window):
        log_ret.iloc[i] = float(
            pd.Series([close[i + window] / close[i]]).map(
                lambda x: __import__("math").log(x)
            ).iloc[0]
        )
    return log_ret


def win_rate(returns: pd.Series) -> float:
    """Fraction of positive returns."""
    valid = returns.dropna()
    if len(valid) == 0:
        return float("nan")
    return (valid > 0).sum() / len(valid)


def mw_test(a: pd.Series, b: pd.Series, alternative: str = "greater") -> tuple[float, float]:
    """Mann-Whitney U test: H0: a == b, H1: a {alternative} b. Returns (U, p)."""
    a_v = a.dropna()
    b_v = b.dropna()
    if len(a_v) < 5 or len(b_v) < 5:
        return float("nan"), float("nan")
    stat, p = mannwhitneyu(a_v, b_v, alternative=alternative)
    return float(stat), float(p)


def print_gate(gate: str, condition: bool, detail: str = "") -> None:
    status = "PASS" if condition else "FAIL"
    marker = "✓" if condition else "✗"
    print(f"  [{marker}] {gate}: {status}  {detail}")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main() -> None:
    import math

    # 1. Fetch data
    df = build_df(SYMBOL, START_DT, END_DT)

    # 2. Classify sessions
    print("Classifying session labels …")
    df["session"] = df.index.map(classify_session)

    # 3. Compute next-4h log returns (vectorised)
    print("Computing next-4h log returns …")
    close = df["close"]
    future_close = close.shift(-RETURN_WINDOW)
    df["log_ret_4h"] = (future_close / close).map(
        lambda x: math.log(x) if pd.notna(x) and x > 0 else float("nan")
    )
    df = df.dropna(subset=["log_ret_4h"])

    # 4. Session summary table
    print("\n" + "=" * 60)
    print("SESSION WR SUMMARY (full period 2022-01-01 → 2026-04-09)")
    print("=" * 60)
    session_order = [
        "NY", "ASIAN", "WEEKEND", "DEAD", "OVERLAP_EARLY", "OVERLAP_LATE", "LONDON"
    ]
    session_stats: dict[str, dict] = {}
    for s in session_order:
        subset = df.loc[df["session"] == s, "log_ret_4h"]
        wr = win_rate(subset)
        session_stats[s] = {"n": len(subset), "wr": wr, "returns": subset}
        wr_pct = f"{wr * 100:.2f}%" if not math.isnan(wr) else "N/A"
        print(f"  {s:<16}  WR={wr_pct:<8}  n={len(subset):,}")

    # -----------------------------------------------------------------------
    # G1_28A: NY vs LONDON WR differential (restructured hypothesis)
    # -----------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("G1_28A: NY vs LONDON (restructured hypothesis)")
    print("  Target: NY WR − LONDON WR ≥ +2pp, one-tailed MW p < 0.10")
    print("=" * 60)
    ny_ret  = session_stats["NY"]["returns"]
    lon_ret = session_stats["LONDON"]["returns"]
    ny_wr   = session_stats["NY"]["wr"]
    lon_wr  = session_stats["LONDON"]["wr"]
    delta_g1a = (ny_wr - lon_wr) * 100
    u_g1a, p_g1a = mw_test(ny_ret, lon_ret, alternative="greater")
    print(f"  NY WR={ny_wr*100:.2f}%  n={len(ny_ret):,}")
    print(f"  LONDON WR={lon_wr*100:.2f}%  n={len(lon_ret):,}")
    print(f"  Δ={delta_g1a:+.2f}pp  MW p={p_g1a:.4f}")
    g1a_pass = delta_g1a >= 2.0 and p_g1a < 0.10
    print_gate("G1_28A", g1a_pass, f"Δ={delta_g1a:+.2f}pp (need ≥+2pp), p={p_g1a:.4f} (need <0.10)")

    # -----------------------------------------------------------------------
    # G1_28B: Monday vs Tue–Thu DOW differential
    # -----------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("G1_28B: Monday vs Tue–Thu WR differential")
    print("  Target: Monday WR − Tue-Thu WR ≥ +0.5pp, p < 0.15")
    print("=" * 60)
    df["dow"] = df.index.day_of_week   # 0=Mon … 6=Sun
    weekday_df = df[df["session"].isin(["NY", "LONDON", "OVERLAP_EARLY", "OVERLAP_LATE", "ASIAN", "DEAD"])]
    mon_ret   = weekday_df.loc[weekday_df["dow"] == 0, "log_ret_4h"]
    mid_ret   = weekday_df.loc[weekday_df["dow"].isin([1, 2, 3]), "log_ret_4h"]
    mon_wr  = win_rate(mon_ret)
    mid_wr  = win_rate(mid_ret)
    delta_g1b = (mon_wr - mid_wr) * 100
    u_g1b, p_g1b = mw_test(mon_ret, mid_ret, alternative="greater")
    print(f"  Monday WR={mon_wr*100:.2f}%  n={len(mon_ret):,}")
    print(f"  Tue-Thu WR={mid_wr*100:.2f}%  n={len(mid_ret):,}")
    print(f"  Δ={delta_g1b:+.2f}pp  MW p={p_g1b:.4f}")
    g1b_pass = delta_g1b >= 0.5 and p_g1b < 0.15
    print_gate("G1_28B", g1b_pass, f"Δ={delta_g1b:+.2f}pp (need ≥+0.5pp), p={p_g1b:.4f} (need <0.15)")

    # -----------------------------------------------------------------------
    # G1_28C_v2: OVERLAP sub-split confirmation
    # -----------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("G1_28C_v2: OVERLAP_LATE < OVERLAP_EARLY < NY (London-close suppression localised)")
    print("  Target: OVERLAP_LATE WR < OVERLAP_EARLY WR; OVERLAP_EARLY WR < NY WR")
    print("=" * 60)
    oe_ret  = session_stats["OVERLAP_EARLY"]["returns"]
    ol_ret  = session_stats["OVERLAP_LATE"]["returns"]
    oe_wr   = session_stats["OVERLAP_EARLY"]["wr"]
    ol_wr   = session_stats["OVERLAP_LATE"]["wr"]
    ny_wr_c = session_stats["NY"]["wr"]

    print(f"  OVERLAP_EARLY WR={oe_wr*100:.2f}%  n={len(oe_ret):,}")
    print(f"  OVERLAP_LATE  WR={ol_wr*100:.2f}%  n={len(ol_ret):,}")
    print(f"  NY            WR={ny_wr_c*100:.2f}%  n={len(ny_ret):,}")

    u_c2_ol_oe, p_c2_ol_oe = mw_test(oe_ret, ol_ret, alternative="greater")   # EARLY > LATE
    u_c2_oe_ny, p_c2_oe_ny = mw_test(ny_ret, oe_ret, alternative="greater")   # NY > EARLY

    late_lt_early = oe_wr > ol_wr
    early_lt_ny   = ny_wr_c > oe_wr
    print(f"  OVERLAP_LATE < OVERLAP_EARLY: {late_lt_early}  (Δ={( oe_wr - ol_wr)*100:+.2f}pp, MW p={p_c2_ol_oe:.4f})")
    print(f"  OVERLAP_EARLY < NY:           {early_lt_ny}  (Δ={(ny_wr_c - oe_wr)*100:+.2f}pp, MW p={p_c2_oe_ny:.4f})")
    g1c_v2_pass = late_lt_early and early_lt_ny
    print_gate("G1_28C_v2", g1c_v2_pass, "OVERLAP_LATE < OVERLAP_EARLY < NY monotonic ordering")

    # -----------------------------------------------------------------------
    # G1_28D: Sub-period stability (McLean-Pontiff decay guard)
    # -----------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("G1_28D: Sub-period stability (McLean-Pontiff decay guard)")
    print("  Target: NY > LONDON ≥ +2pp in ALL sub-periods: 2022, 2023, 2024+")
    print("=" * 60)
    g1d_results: dict[str, bool] = {}
    for period_name, (p_start, p_end) in SUB_PERIODS.items():
        sub = df[(df.index >= p_start) & (df.index < p_end)]
        sub_ny  = sub.loc[sub["session"] == "NY", "log_ret_4h"]
        sub_lon = sub.loc[sub["session"] == "LONDON", "log_ret_4h"]
        sub_ny_wr  = win_rate(sub_ny)
        sub_lon_wr = win_rate(sub_lon)
        delta_sub  = (sub_ny_wr - sub_lon_wr) * 100
        u_sub, p_sub = mw_test(sub_ny, sub_lon, alternative="greater")
        pass_sub = delta_sub >= 2.0 and p_sub < 0.15   # relaxed threshold for sub-periods
        g1d_results[period_name] = pass_sub
        status = "PASS" if pass_sub else "FAIL"
        print(f"  {period_name:<8}  NY WR={sub_ny_wr*100:.2f}% (n={len(sub_ny):,})  "
              f"LON WR={sub_lon_wr*100:.2f}% (n={len(sub_lon):,})  "
              f"Δ={delta_sub:+.2f}pp  p={p_sub:.4f}  → {status}")
    g1d_pass = all(g1d_results.values())
    print_gate("G1_28D", g1d_pass, f"All 3 sub-periods NY > LONDON ≥ +2pp: {g1d_results}")

    # -----------------------------------------------------------------------
    # Summary
    # -----------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("GATE SUMMARY — Axis 28 Sophisticated (cycle 177)")
    print("=" * 60)
    all_gates = {
        "G1_28A (NY>LONDON ≥+2pp)":         g1a_pass,
        "G1_28B (Monday DOW ≥+0.5pp)":      g1b_pass,
        "G1_28C_v2 (LATE<EARLY<NY)":         g1c_v2_pass,
        "G1_28D (sub-period stability)":     g1d_pass,
    }
    for gate_name, passed in all_gates.items():
        print_gate(gate_name, passed)

    all_pass = all(all_gates.values())
    print()
    if all_pass:
        print("  ALL G1 GATES CLEARED → G2_28 CPCV+DSR unblocked")
    else:
        failing = [k for k, v in all_gates.items() if not v]
        print(f"  BLOCKING gates: {failing}")
        print("  G2_28 remains BLOCKED until all G1 gates clear.")

    # -----------------------------------------------------------------------
    # Full session WR table for conditions-log
    # -----------------------------------------------------------------------
    print("\n" + "=" * 60)
    print("FULL SESSION WR TABLE (conditions-log ready)")
    print("=" * 60)
    for s in session_order:
        stats = session_stats[s]
        wr_pct = f"{stats['wr'] * 100:.2f}%" if not math.isnan(stats['wr']) else "N/A"
        print(f"  {s:<16}  WR={wr_pct}  n={stats['n']:,}")


if __name__ == "__main__":
    main()

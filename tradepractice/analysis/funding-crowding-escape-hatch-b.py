"""
Escape Hatch (B) Analysis: Funding-Rate-Crowding-Reversal
==========================================================
Tests whether the funding-rate-crowding-reversal meta-indicator has a
null effect on sister-prim win rate.

Methodology (from sophisticated prim doc):
  Crowding-active  = funding > 0.10%/8h AND OI_24h_change < +2% AND 3+
                     consecutive 8h periods above threshold
  Parabolic bypass = OI_24h_change > +5% → skip suppression (not crowding)

  H0 (anti-prim B): WR_crowding_on >= WR_crowding_off  → prim is null
  H1 (prim valid):  WR_crowding_on <  WR_crowding_off  → suppression justified

Data sources:
  - Binance futures funding rate:  fapi.binance.com/fapi/v1/fundingRate
  - Binance futures OI history:    fapi.binance.com/futures/data/openInterestHist
    (NOTE: Binance OI API max lookback ~30 days; falls back to OHLCV volume proxy)
  - OHLCV volume proxy:            user_data/data/binance/*-4h.feather
  - Sister prim trades:            freqtrade backtest result zips

Usage:
  python3 analysis/funding-crowding-escape-hatch-b.py [backtest_zip_path]
"""

import json
import time
import zipfile
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests
import pandas as pd
import numpy as np

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
BACKTEST_DIR = Path("/home/yuji/Desktop/Yuji Project/freqtrade/user_data/backtest_results")
OHLCV_DIR    = Path("/home/yuji/Desktop/Yuji Project/freqtrade/user_data/data/binance")
SYMBOLS = ["BTCUSDT", "ETHUSDT"]

# Crowding filter thresholds (from sophisticated prim)
FUNDING_THRESHOLD        = 0.0010   # 0.10% per 8h
OI_CHANGE_CROWDED_MAX    = 0.02     # < +2% OI change  → crowded gate active
OI_CHANGE_PARABOLIC_MIN  = 0.05     # > +5% OI change  → bypass (parabolic)
CONSECUTIVE_PERIODS      = 3        # 3+ consecutive 8h periods triggers
SUPPRESSION_WINDOW_H     = 72       # 72h suppression window after trigger

# Analysis date range
START_TS_MS = int(datetime(2022, 1, 1, tzinfo=timezone.utc).timestamp() * 1000)
END_TS_MS   = int(datetime(2026, 1, 2, tzinfo=timezone.utc).timestamp() * 1000)


# ---------------------------------------------------------------------------
# Binance API helpers
# ---------------------------------------------------------------------------
def fetch_funding_rates(symbol: str) -> pd.DataFrame:
    """Fetch all 8h funding rate records from Binance futures (paginated)."""
    url = "https://fapi.binance.com/fapi/v1/fundingRate"
    records = []
    start = START_TS_MS

    while start < END_TS_MS:
        params = {"symbol": symbol, "startTime": start, "limit": 1000}
        r = requests.get(url, params=params, timeout=30)
        r.raise_for_status()
        batch = r.json()
        if not batch:
            break
        records.extend(batch)
        last_ts = batch[-1]["fundingTime"]
        if last_ts >= END_TS_MS or len(batch) < 1000:
            break
        start = last_ts + 1
        time.sleep(0.15)

    if not records:
        return pd.DataFrame()

    df = pd.DataFrame(records)
    df["ts"] = pd.to_datetime(df["fundingTime"], unit="ms", utc=True)
    df["funding_rate"] = df["fundingRate"].astype(float)
    df = df[["ts", "funding_rate"]].sort_values("ts").drop_duplicates("ts")
    print(f"  {symbol} funding: {len(df)} records "
          f"({df['ts'].min().date()} → {df['ts'].max().date()})")
    return df


def fetch_oi_recent(symbol: str) -> pd.DataFrame:
    """
    Fetch OI history from Binance futures (most-recent ~30 days only).
    The Binance openInterestHist API does not accept startTime older than
    ~30 days. Returns empty if coverage is insufficient for multi-year analysis.
    """
    url = "https://fapi.binance.com/futures/data/openInterestHist"
    params = {"symbol": symbol, "period": "4h", "limit": 500}
    r = requests.get(url, params=params, timeout=30)
    r.raise_for_status()
    records = r.json()

    if not records:
        return pd.DataFrame()

    df = pd.DataFrame(records)
    df["ts"] = pd.to_datetime(df["timestamp"].astype(int), unit="ms", utc=True)
    df["oi"] = df["sumOpenInterest"].astype(float)
    df = df[["ts", "oi"]].sort_values("ts").drop_duplicates("ts")
    span_days = (df["ts"].max() - df["ts"].min()).total_seconds() / 86400
    print(f"  {symbol} OI (recent): {len(df)} records, {span_days:.0f}d span "
          f"({df['ts'].min().date()} → {df['ts'].max().date()})")
    return df


def load_volume_proxy(pair_base: str) -> pd.DataFrame:
    """
    Load 4h OHLCV feather and compute volume-based OI proxy.
    Volume 24h % change ≈ OI direction (approximation).
    """
    path = OHLCV_DIR / f"{pair_base}_USDT-4h.feather"
    if not path.exists():
        return pd.DataFrame()

    df = pd.read_feather(str(path))
    df["ts"] = pd.to_datetime(df["date"], utc=True)
    # 6 × 4h = 24h look-back for volume change
    df["vol_24h_change"] = df["volume"].pct_change(periods=6)
    df = df[["ts", "volume", "vol_24h_change"]].dropna().reset_index(drop=True)
    print(f"  {pair_base} volume proxy: {len(df)} rows "
          f"({df['ts'].min().date()} → {df['ts'].max().date()})")
    return df


# ---------------------------------------------------------------------------
# Crowding signal computation
# ---------------------------------------------------------------------------
def build_crowding_signal(
    funding_df: pd.DataFrame,
    oi_df: pd.DataFrame,
    proxy_df: pd.DataFrame,
) -> pd.DataFrame:
    """
    Compute the crowding suppression signal on the 8h funding grid.

    OI gate source precedence:
      1. Actual OI if span >= 180 days
      2. Volume proxy (4h OHLCV) if actual OI too short
      3. Funding-only (no OI gate) as last resort

    Returns DataFrame with crowding_trigger and crowding_active columns.
    """
    if funding_df.empty:
        return pd.DataFrame()

    df = funding_df.copy().sort_values("ts").reset_index(drop=True)
    df["funding_spike"] = df["funding_rate"] > FUNDING_THRESHOLD

    # Determine OI gate source
    oi_span_days = 0
    if not oi_df.empty:
        oi_span_days = (oi_df["ts"].max() - oi_df["ts"].min()).total_seconds() / 86400

    if oi_span_days >= 180:
        # Use actual OI
        oi_8h = oi_df.set_index("ts").resample("8h").mean().reset_index()
        oi_8h.columns = ["ts", "oi"]
        df = pd.merge_asof(df, oi_8h, on="ts", direction="nearest",
                           tolerance=pd.Timedelta("4h"))
        df["oi_24h_change"] = df["oi"].pct_change(periods=3)
        oi_source = "actual_oi"
    elif proxy_df is not None and not proxy_df.empty:
        # Use volume proxy (resample from 4h to 8h)
        prx = proxy_df.set_index("ts")["vol_24h_change"].resample("8h").last().reset_index()
        prx.columns = ["ts", "oi_24h_change"]
        df = pd.merge_asof(df, prx, on="ts", direction="nearest",
                           tolerance=pd.Timedelta("4h"))
        oi_source = "volume_proxy"
    else:
        df["oi_24h_change"] = float("nan")
        oi_source = "funding_only"

    print(f"    OI gate source: {oi_source}")

    # Apply OI gate
    if df.get("oi_24h_change") is not None and not df["oi_24h_change"].isna().all():
        chg = df["oi_24h_change"].fillna(0)
        crowded_gate = chg < OI_CHANGE_CROWDED_MAX
        parabolic    = chg > OI_CHANGE_PARABOLIC_MIN
        df["is_crowded_raw"] = df["funding_spike"] & crowded_gate & ~parabolic
    else:
        df["is_crowded_raw"] = df["funding_spike"]
        oi_source = "funding_only"

    df["oi_gate_source"] = oi_source

    # Rolling consecutive count
    consec, count = [], 0
    for v in df["is_crowded_raw"]:
        count = count + 1 if v else 0
        consec.append(count)
    df["crowded_consec"] = consec
    df["crowding_trigger"] = df["crowded_consec"] >= CONSECUTIVE_PERIODS

    # Suppression window propagation
    sup_ends = []
    active_end = pd.Timestamp.min.tz_localize("UTC")
    for row in df.itertuples():
        if row.crowding_trigger:
            active_end = row.ts + pd.Timedelta(hours=SUPPRESSION_WINDOW_H)
        sup_ends.append(active_end)
    df["suppression_end"] = sup_ends
    df["crowding_active"] = df["ts"] < pd.Series(sup_ends, index=df.index)

    return df.reset_index(drop=True)


# ---------------------------------------------------------------------------
# Backtest trade extraction
# ---------------------------------------------------------------------------
def load_backtest_trades(zip_path: Path) -> pd.DataFrame:
    """Extract all closed long trades from a freqtrade backtest zip."""
    rows = []
    with zipfile.ZipFile(zip_path) as z:
        for name in z.namelist():
            if not name.endswith(".json") or name.endswith(".meta.json"):
                continue
            with z.open(name) as jf:
                d = json.load(jf)
                for strat, data in d.get("strategy", {}).items():
                    for t in data.get("trades", []):
                        if t.get("is_open", False):
                            continue
                        rows.append({
                            "strategy": strat,
                            "pair": t.get("pair", ""),
                            "open_ts": pd.to_datetime(
                                t.get("open_timestamp"), unit="ms", utc=True),
                            "profit_ratio": t.get("profit_ratio", 0.0),
                            "is_short": t.get("is_short", False),
                        })

    df = pd.DataFrame(rows)
    if df.empty:
        return df
    df["is_win"] = df["profit_ratio"] > 0
    df = df[~df["is_short"]].reset_index(drop=True)
    return df


# ---------------------------------------------------------------------------
# Label trades with crowding signal
# ---------------------------------------------------------------------------
def label_trades(
    trades_df: pd.DataFrame,
    crowding_by_base: dict,
) -> pd.DataFrame:
    """Assign crowding_active label to each trade based on its open timestamp."""

    def suppressed(row):
        base = "BTC" if "BTC" in row["pair"] else "ETH" if "ETH" in row["pair"] else None
        if base is None or base not in crowding_by_base:
            return False
        crowding = crowding_by_base[base]
        if crowding.empty:
            return False
        prior = crowding[crowding["ts"] <= row["open_ts"]]
        if prior.empty:
            return False
        return bool(prior.iloc[-1]["crowding_active"])

    df = trades_df.copy()
    df["suppressed"] = df.apply(suppressed, axis=1)
    return df


# ---------------------------------------------------------------------------
# Statistical test
# ---------------------------------------------------------------------------
def conditional_wr_test(trades_df: pd.DataFrame) -> dict:
    """Compute conditional WR and chi-squared p-value for crowding-on vs off."""
    on  = trades_df[trades_df["suppressed"]]
    off = trades_df[~trades_df["suppressed"]]

    def wr(df):
        return df["is_win"].mean() if len(df) > 0 else float("nan"), len(df)

    wr_on,  n_on  = wr(on)
    wr_off, n_off = wr(off)
    wr_all, n_all = wr(trades_df)

    p_val = float("nan")
    if n_on > 0 and n_off > 0:
        try:
            from scipy.stats import chi2_contingency
            wins_on  = int(on["is_win"].sum())
            wins_off = int(off["is_win"].sum())
            table = [[wins_on, n_on - wins_on], [wins_off, n_off - wins_off]]
            _, p_val, _, _ = chi2_contingency(table, correction=False)
        except Exception:
            pass

    return {
        "n_total": n_all,
        "wr_total": wr_all,
        "n_crowding_on": n_on,
        "wr_crowding_on": wr_on,
        "n_crowding_off": n_off,
        "wr_crowding_off": wr_off,
        "wr_delta": float(wr_off) - float(wr_on) if not (
            pd.isna(wr_on) or pd.isna(wr_off)) else float("nan"),
        "p_value": p_val,
    }


# ---------------------------------------------------------------------------
# Report crowding episodes
# ---------------------------------------------------------------------------
def print_episodes(crowding: pd.DataFrame, base: str):
    episodes = []
    prev = False
    for row in crowding.itertuples():
        if row.crowding_trigger and not prev:
            episodes.append(row)
        prev = row.crowding_trigger

    print(f"\n  {base}: {len(episodes)} crowding episodes "
          f"(OI gate: {crowding['oi_gate_source'].iloc[0] if len(crowding) > 0 else 'n/a'})")
    for ep in episodes[:25]:
        chg = ep.oi_24h_change * 100 if not pd.isna(ep.oi_24h_change) else float("nan")
        print(f"    {ep.ts.strftime('%Y-%m-%d %H:%M')} | "
              f"funding={ep.funding_rate*100:.4f}% | "
              f"OI/vol_24h={chg:.2f}% | "
              f"suppress_until={ep.suppression_end.strftime('%Y-%m-%d %H:%M')}")
    if len(episodes) > 25:
        print(f"    ... {len(episodes)-25} more not shown")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
def main():
    # Select backtest zip
    if len(sys.argv) > 1:
        zip_path = Path(sys.argv[1])
    else:
        zips = sorted(BACKTEST_DIR.glob("*.zip"))
        if not zips:
            print("ERROR: No backtest zips in", BACKTEST_DIR)
            sys.exit(1)
        zip_path = zips[-1]
        print(f"Using: {zip_path.name}")

    print("\n=== Escape Hatch (B): Conditional Sister-Prim WR Test ===")
    print("Prim: funding-rate-crowding-reversal\n")

    # 1. Load trades
    print("[1/3] Loading backtest trades...")
    trades = load_backtest_trades(zip_path)
    if trades.empty:
        print("ERROR: No closed long trades in zip.")
        sys.exit(1)

    for s in trades["strategy"].unique():
        sub = trades[trades["strategy"] == s]
        print(f"  {s}: {len(sub)} trades, WR={sub['is_win'].mean()*100:.1f}%, "
              f"{sub['open_ts'].min().date()} → {sub['open_ts'].max().date()}")

    # 2. Fetch funding + OI
    print("\n[2/3] Fetching Binance funding + OI/proxy data...")
    crowding_by_base = {}
    for symbol in SYMBOLS:
        base = symbol.replace("USDT", "")
        print(f"  --- {base} ---")
        funding_df = fetch_funding_rates(symbol)
        oi_df      = fetch_oi_recent(symbol)
        proxy_df   = load_volume_proxy(base)

        crowding = build_crowding_signal(funding_df, oi_df, proxy_df)
        crowding_by_base[base] = crowding

        if not crowding.empty:
            n_trig = crowding["crowding_trigger"].sum()
            n_act  = crowding["crowding_active"].sum()
            print(f"    Trigger events: {n_trig} × 8h periods")
            print(f"    Active suppression: {n_act} × 8h periods "
                  f"({n_act*8/(24*365):.2f} yr equiv)")

    # 3. Label trades and run test
    print("\n[3/3] Labelling trades + computing conditional WR...")
    trades_labeled = label_trades(trades, crowding_by_base)
    results = conditional_wr_test(trades_labeled)

    print("\n" + "="*50)
    print("RESULTS")
    print("="*50)
    print(f"  Total long trades:   {results['n_total']}")
    print(f"  Baseline WR:         {results['wr_total']*100:.1f}%")
    print(f"  Crowding-ON  n:      {results['n_crowding_on']}")
    print(f"  WR (crowding ON):    {results['wr_crowding_on']*100:.1f}%"
          if results['n_crowding_on'] > 0 else "  WR (crowding ON):    N/A")
    print(f"  Crowding-OFF n:      {results['n_crowding_off']}")
    print(f"  WR (crowding OFF):   {results['wr_crowding_off']*100:.1f}%"
          if results['n_crowding_off'] > 0 else "  WR (crowding OFF):   N/A")
    if not pd.isna(results['wr_delta']):
        print(f"  WR delta (off−on):   {results['wr_delta']*100:+.1f}pp")
    print(f"  χ² p-value:          {results['p_value']:.3f}"
          if not pd.isna(results['p_value']) else "  χ² p-value:          N/A")

    print("\n" + "="*50)
    print("VERDICT")
    print("="*50)
    n_on = results["n_crowding_on"]
    if n_on == 0:
        verdict = "INCONCLUSIVE — no trades in crowding-active windows"
        explanation = (
            "Post-filter event freq ~3-5/yr. Backtest period too short or "
            "strategy trade freq too low. Extend to 3+ years with higher-freq strategy."
        )
    elif pd.isna(results["wr_delta"]):
        verdict = "INCONCLUSIVE — insufficient data"
        explanation = "Could not compute WR delta."
    elif results["wr_delta"] <= 0.0:
        verdict = "ANTI-PRIM (B) TRIGGERED — suppression has null effect"
        explanation = (
            f"WR crowding-on ({results['wr_crowding_on']*100:.1f}%) >= "
            f"crowding-off ({results['wr_crowding_off']*100:.1f}%). "
            "Retire the prim."
        )
    elif results["p_value"] < 0.10:
        verdict = "PRIM VALIDATED — statistically significant WR degradation in crowded periods"
        explanation = (
            f"WR delta = {results['wr_delta']*100:+.1f}pp, p={results['p_value']:.3f}. "
            "Implement suppression in strategy code."
        )
    else:
        verdict = f"INCONCLUSIVE — WR delta present ({results['wr_delta']*100:+.1f}pp) but p={results['p_value']:.3f}"
        explanation = (
            f"n_crowding_on={n_on}. Need n_eff ≥ 30 (post-filter freq ~3-5/yr "
            f"× 1.2 n_eff/event = need 5-8yr of data). Accumulate more."
        )

    print(f"  {verdict}")
    print(f"  {explanation}")

    # Print episode log
    for base, crowding in crowding_by_base.items():
        if not crowding.empty:
            print_episodes(crowding, base)

    return results


if __name__ == "__main__":
    main()

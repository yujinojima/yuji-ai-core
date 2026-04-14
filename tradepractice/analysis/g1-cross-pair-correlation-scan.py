"""
G1 Gate Scan — Cross-Pair Correlation Regime (freqtrade axis 29)
Cycle 175 — 2026-04-14

Gates tested by this script:
  G1_29A  HIGH_CORR regime: ETH signal WR lags NORMAL by ≥ 1.0pp (n≥20, Mann-Whitney p<0.10)
  G1_29B  Regime switching: ≥ 4 HIGH or LOW episodes/year (plausibility gate)
  G1_29C  ρ(axis29_regime_state, axis5_BBW) < 0.70 (independence gate)
  G1_29D  LOW_CORR regime: ETH signal WR > NORMAL by ≥ 0.5pp (anti-prim AP_D test)

Data:
  BTC/USDT, ETH/USDT, SOL/USDT, BNB/USDT — 4h OHLCV from Binance public REST
  Date range: 2021-01-01 → 2026-04-14 (~4.3 years, ~9,400 bars per pair)
  No API key required.

Usage:
  pip install requests pandas numpy scipy
  python g1-cross-pair-correlation-scan.py

Output:
  Console: G1_29A/B/C/D PASS/FAIL with statistics
  CSV: g1-cross-pair-correlation-results.csv (regime-labelled bar data)
"""

import time
import json
import numpy as np
import pandas as pd
from datetime import datetime, timezone
from scipy import stats

# ---------------------------------------------------------------------------
# CONFIG
# ---------------------------------------------------------------------------
PAIRS = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT"]
INTERVAL = "4h"
START_MS = int(datetime(2021, 1, 1, tzinfo=timezone.utc).timestamp() * 1000)
END_MS   = int(datetime(2026, 4, 14, tzinfo=timezone.utc).timestamp() * 1000)

CORR_WINDOW = 180        # 30d × 6 bars/day
HIGH_THRESH = 0.75
LOW_THRESH  = 0.40

# Episode definition: ≥ 7 consecutive calendar days in HIGH/LOW regime
EPISODE_MIN_BARS = 42    # 7d × 6 bars/day

BINANCE_BASE = "https://api.binance.com"

# ---------------------------------------------------------------------------
# DATA FETCH
# ---------------------------------------------------------------------------

def fetch_klines(symbol: str, interval: str, start_ms: int, end_ms: int) -> pd.DataFrame:
    """Fetch all klines for symbol from Binance REST, paginating as needed."""
    url = f"{BINANCE_BASE}/api/v3/klines"
    limit = 1000
    all_rows = []
    current_start = start_ms

    while current_start < end_ms:
        params = {
            "symbol":    symbol,
            "interval":  interval,
            "startTime": current_start,
            "endTime":   end_ms,
            "limit":     limit,
        }
        try:
            import urllib.request
            req_url = url + "?" + "&".join(f"{k}={v}" for k, v in params.items())
            with urllib.request.urlopen(req_url, timeout=30) as resp:
                data = json.loads(resp.read())
        except Exception as e:
            print(f"  Fetch error for {symbol}: {e}; retrying in 5s...")
            time.sleep(5)
            continue

        if not data:
            break

        all_rows.extend(data)
        last_open_ms = data[-1][0]
        if last_open_ms >= end_ms or len(data) < limit:
            break
        current_start = last_open_ms + 1
        time.sleep(0.12)  # Binance rate limit: ~10 req/s weight

    df = pd.DataFrame(all_rows, columns=[
        "open_time", "open", "high", "low", "close", "volume",
        "close_time", "quote_vol", "num_trades",
        "taker_buy_base", "taker_buy_quote", "ignore"
    ])
    df["open_time"] = pd.to_datetime(df["open_time"], unit="ms", utc=True)
    df["close"] = df["close"].astype(float)
    df = df.set_index("open_time").sort_index()
    return df[["close"]]


# ---------------------------------------------------------------------------
# ROLLING CORRELATION
# ---------------------------------------------------------------------------

def compute_rho_avg(price_df: pd.DataFrame, window: int) -> pd.Series:
    """
    Compute rolling mean of all pairwise Pearson correlations.
    price_df: columns = pair symbols, index = datetime, values = close prices.
    """
    log_ret = np.log(price_df / price_df.shift(1)).dropna()
    pair_cols = log_ret.columns.tolist()

    # Build pairwise correlation series
    from itertools import combinations
    pair_corrs = []
    for a, b in combinations(pair_cols, 2):
        rolling_corr = log_ret[a].rolling(window).corr(log_ret[b])
        pair_corrs.append(rolling_corr)

    corr_matrix = pd.concat(pair_corrs, axis=1)
    rho_avg = corr_matrix.mean(axis=1)
    return rho_avg


# ---------------------------------------------------------------------------
# REGIME CLASSIFICATION
# ---------------------------------------------------------------------------

def classify_regime(rho_avg: pd.Series) -> pd.Series:
    """Return 'HIGH_CORR', 'NORMAL', or 'LOW_CORR' per bar."""
    regime = pd.Series("NORMAL", index=rho_avg.index)
    regime[rho_avg >= HIGH_THRESH] = "HIGH_CORR"
    regime[rho_avg < LOW_THRESH]   = "LOW_CORR"
    return regime


# ---------------------------------------------------------------------------
# G1 TESTS
# ---------------------------------------------------------------------------

def g1_29a_eth_wr_by_regime(regime: pd.Series, eth_ret: pd.Series) -> dict:
    """
    G1_29A: Does HIGH_CORR regime show lower ETH forward WR than NORMAL?
    Uses next-4h ETH return as proxy: positive return = WIN.
    Target: HIGH_CORR WR < NORMAL WR by ≥ 1.0pp, p < 0.10 (Mann-Whitney).
    """
    aligned = pd.DataFrame({"regime": regime, "eth_ret": eth_ret}).dropna()

    high_wr_series = (aligned[aligned["regime"] == "HIGH_CORR"]["eth_ret"] > 0).astype(int)
    norm_wr_series = (aligned[aligned["regime"] == "NORMAL"]["eth_ret"] > 0).astype(int)
    low_wr_series  = (aligned[aligned["regime"] == "LOW_CORR"]["eth_ret"] > 0).astype(int)

    n_high = len(high_wr_series)
    n_norm = len(norm_wr_series)
    n_low  = len(low_wr_series)

    high_wr = high_wr_series.mean() * 100 if n_high > 0 else float("nan")
    norm_wr = norm_wr_series.mean() * 100 if n_norm > 0 else float("nan")
    low_wr  = low_wr_series.mean()  * 100 if n_low  > 0 else float("nan")

    delta_high_vs_norm = norm_wr - high_wr  # positive = HIGH_CORR underperforms NORMAL

    # Mann-Whitney U: HIGH vs NORMAL
    if n_high >= 5 and n_norm >= 5:
        _, p_val = stats.mannwhitneyu(
            aligned[aligned["regime"] == "HIGH_CORR"]["eth_ret"],
            aligned[aligned["regime"] == "NORMAL"]["eth_ret"],
            alternative="greater"  # NORMAL > HIGH_CORR
        )
    else:
        p_val = float("nan")

    result = {
        "gate": "G1_29A",
        "n_high": n_high,
        "n_norm": n_norm,
        "n_low":  n_low,
        "high_wr_pct":  round(high_wr, 2),
        "norm_wr_pct":  round(norm_wr, 2),
        "low_wr_pct":   round(low_wr, 2),
        "delta_high_vs_norm_pp": round(delta_high_vs_norm, 2),
        "p_value": round(p_val, 4) if not np.isnan(p_val) else "N/A",
        "pass": n_high >= 20 and n_norm >= 20 and delta_high_vs_norm >= 1.0 and p_val < 0.10,
    }
    return result


def g1_29b_episode_frequency(regime: pd.Series) -> dict:
    """
    G1_29B: Plausibility gate — ≥ 4 HIGH_CORR or LOW_CORR episodes per year.
    An episode is a run of ≥ EPISODE_MIN_BARS consecutive bars in HIGH/LOW.
    """
    years_covered = (regime.index[-1] - regime.index[0]).days / 365.25

    def count_episodes(target_regime):
        in_episode = False
        run = 0
        episodes = 0
        for r in regime:
            if r == target_regime:
                run += 1
                if not in_episode and run >= EPISODE_MIN_BARS:
                    in_episode = True
                    episodes += 1
            else:
                run = 0
                in_episode = False
        return episodes

    high_episodes = count_episodes("HIGH_CORR")
    low_episodes  = count_episodes("LOW_CORR")
    total_episodes = high_episodes + low_episodes
    episodes_per_year = total_episodes / years_covered if years_covered > 0 else 0

    return {
        "gate": "G1_29B",
        "years_covered": round(years_covered, 1),
        "high_episodes": high_episodes,
        "low_episodes":  low_episodes,
        "episodes_per_year": round(episodes_per_year, 1),
        "pass": episodes_per_year >= 4,
    }


def g1_29c_independence_from_axis5(regime: pd.Series, btc_close: pd.Series,
                                    window: int = 125) -> dict:
    """
    G1_29C: ρ(axis29_regime_numeric, axis5_BBW) < 0.70.
    axis5 proxy: Bollinger Band Width = (BB_upper - BB_lower) / BB_middle.
    regime encoded as: HIGH_CORR=1, NORMAL=0, LOW_CORR=-1.
    """
    regime_numeric = regime.map({"HIGH_CORR": 1, "NORMAL": 0, "LOW_CORR": -1})

    # Bollinger Band Width (20-bar, 2σ)
    bb_mid = btc_close.rolling(20).mean()
    bb_std = btc_close.rolling(20).std()
    bbw = ((2 * bb_std) / bb_mid).dropna()

    aligned = pd.DataFrame({"regime_num": regime_numeric, "bbw": bbw}).dropna()
    if len(aligned) < 50:
        return {"gate": "G1_29C", "n": len(aligned), "rho": float("nan"), "pass": False}

    rho, p = stats.pearsonr(aligned["regime_num"], aligned["bbw"])
    return {
        "gate": "G1_29C",
        "n": len(aligned),
        "rho_axis29_vs_axis5_BBW": round(abs(rho), 3),
        "p_value": round(p, 4),
        "pass": abs(rho) < 0.70,
        "independence_tier": (
            "Tier D (< 0.30)" if abs(rho) < 0.30 else
            "Tier C (0.30–0.50)" if abs(rho) < 0.50 else
            "Tier B (0.50–0.70)" if abs(rho) < 0.70 else
            "FAIL (≥ 0.70 → AP_C fires → merge into axis 5)"
        ),
    }


def g1_29d_low_corr_uplift(g1a_result: dict) -> dict:
    """
    G1_29D: LOW_CORR ETH WR > NORMAL WR by ≥ 0.5pp.
    Anti-prim AP_D fires if this fails (LOW_CORR amplify removed).
    """
    norm_wr = g1a_result["norm_wr_pct"]
    low_wr  = g1a_result["low_wr_pct"]
    n_low   = g1a_result["n_low"]
    delta   = low_wr - norm_wr if not (np.isnan(low_wr) or np.isnan(norm_wr)) else float("nan")
    return {
        "gate": "G1_29D",
        "n_low": n_low,
        "low_wr_pct": low_wr,
        "norm_wr_pct": norm_wr,
        "delta_low_vs_norm_pp": round(delta, 2) if not np.isnan(delta) else "N/A",
        "pass": n_low >= 20 and not np.isnan(delta) and delta >= 0.5,
        "note": "Anti-prim AP_D fires on FAIL → LOW_CORR set to 1.00× neutral",
    }


# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------

def main():
    print("=" * 70)
    print("G1 Gate Scan — cross-pair-correlation-regime (axis 29) — cycle 175")
    print("=" * 70)

    # 1. Fetch data
    print("\n[1/4] Fetching 4h OHLCV from Binance REST...")
    dfs = {}
    for pair in PAIRS:
        print(f"  Fetching {pair}...")
        dfs[pair] = fetch_klines(pair, INTERVAL, START_MS, END_MS)
        print(f"    {len(dfs[pair])} bars ({dfs[pair].index[0].date()} → {dfs[pair].index[-1].date()})")

    # 2. Align and compute rho_avg
    print("\n[2/4] Computing rolling 30d cross-pair correlation (6 pairs)...")
    price_df = pd.concat({p: dfs[p]["close"] for p in PAIRS}, axis=1).dropna()
    print(f"  Aligned bars: {len(price_df)}")

    rho_avg = compute_rho_avg(price_df, CORR_WINDOW)
    regime  = classify_regime(rho_avg)

    regime_counts = regime.value_counts()
    print(f"  Regime distribution: HIGH_CORR={regime_counts.get('HIGH_CORR',0)} "
          f"NORMAL={regime_counts.get('NORMAL',0)} LOW_CORR={regime_counts.get('LOW_CORR',0)}")
    print(f"  rho_avg range: [{rho_avg.min():.3f}, {rho_avg.max():.3f}], "
          f"mean={rho_avg.mean():.3f}")

    # 3. ETH next-bar return (forward-shifted)
    eth_ret = np.log(price_df["ETHUSDT"] / price_df["ETHUSDT"].shift(1)).shift(-1)

    # 4. Run G1 gates
    print("\n[3/4] Running G1 gates...")
    r_a = g1_29a_eth_wr_by_regime(regime, eth_ret)
    r_b = g1_29b_episode_frequency(regime)
    r_c = g1_29c_independence_from_axis5(regime, price_df["BTCUSDT"])
    r_d = g1_29d_low_corr_uplift(r_a)

    # 5. Print results
    print("\n[4/4] Results:")
    print("-" * 70)

    for r in [r_a, r_b, r_c, r_d]:
        status = "PASS" if r["pass"] else "FAIL"
        print(f"\n  {r['gate']} — {status}")
        for k, v in r.items():
            if k not in ("gate", "pass"):
                print(f"    {k}: {v}")

    print("\n" + "=" * 70)
    print("SUMMARY")
    print("=" * 70)
    all_pass = all(r["pass"] for r in [r_a, r_b, r_c])
    g1a_clear = r_a["pass"]
    g1b_clear = r_b["pass"]
    g1c_clear = r_c["pass"]
    g1d_clear = r_d["pass"]
    ap_c_fires = not g1c_clear  # ρ ≥ 0.70 → merge into axis 5
    ap_d_fires = not g1d_clear  # LOW_CORR uplift null → set LOW_CORR to 1.00×

    print(f"  G1_29A (HIGH_CORR suppress):   {'PASS' if g1a_clear else 'FAIL'}")
    print(f"  G1_29B (episode frequency):     {'PASS' if g1b_clear else 'FAIL'}")
    print(f"  G1_29C (indep from axis5 BBW): {'PASS' if g1c_clear else 'FAIL'}")
    print(f"  G1_29D (LOW_CORR amplify):      {'PASS' if g1d_clear else 'FAIL'}")
    print()
    if ap_c_fires:
        print("  *** AP_C FIRES: ρ(axis29,axis5) ≥ 0.70 → retire axis 29, merge into axis 5 ***")
    elif ap_d_fires:
        print("  AP_D fires: LOW_CORR amplify removed; HIGH_CORR suppress retained.")
    if g1a_clear and g1b_clear and g1c_clear:
        print("  → G1 CLEARED: axis 29 eligible for intermediate elevation.")
        print("    Next: 5 intermediate advances + G2 CPCV+DSR (cell count TBD)")
    elif not g1a_clear:
        print("  → G1_29A BLOCKED: HIGH_CORR ETH WR delta insufficient.")
        print("    Consider: (1) reduce HIGH_THRESH to 0.70; (2) extend date range;")
        print("    (3) use strategy-specific WR (not raw return) as proxy.")

    # 6. Save CSV
    out = pd.DataFrame({
        "rho_avg": rho_avg,
        "regime":  regime,
        "eth_ret": eth_ret,
    })
    out.to_csv("g1-cross-pair-correlation-results.csv")
    print("\n  Output saved to g1-cross-pair-correlation-results.csv")


if __name__ == "__main__":
    main()

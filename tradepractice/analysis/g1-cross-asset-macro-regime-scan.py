"""
G1 Scan — Cross-Asset Macro Correlation Regime (axis 17, intermediate)
Cycle 118 | blocking gate for sophisticated elevation

Objective:
  1. Compute rolling ρ_14d + ρ_30d for BTC-USD and ^GSPC (2020-01-01 to 2025-12-31)
  2. Label sub-regimes: fear_driven / momentum_driven / event_spike / neutral_coupled
  3. Count firing rates per year (target: fear_driven ≥ 10, momentum_driven ≥ 10, event_spike ≥ 3)
  4. Verify causation bypass fires on LUNA (2022-05) and FTX (2022-11) dates
  5. Verify dual-window gating (ρ_14d ≥ 0.40 AND ρ_30d ≥ 0.50) improves on naive single-window

Usage:
  python g1-cross-asset-macro-regime-scan.py

Dependencies:
  pip install yfinance pandas numpy
"""

import math
from datetime import datetime

import numpy as np
import pandas as pd
import yfinance as yf

# ============================================================
# CONFIG
# ============================================================
START = "2020-01-01"
END = "2025-12-31"

# Dual-window thresholds (intermediate spec)
RHO_14D_ENTRY = 0.40
RHO_30D_ENTRY = 0.50
RHO_EXIT_HYST = 0.35

# Causation bypass: BTC_RV7d / SPX_RV7d
CAUSATION_RATIO = 2.5

# Sub-regime VIX thresholds
VIX_FEAR = 28.0
VIX_CALM = 20.0

# Event spike: Δρ_30d > 0.15 over 5 trading days
EVENT_SPIKE_DELTA = 0.15
EVENT_SPIKE_WINDOW = 5

# ============================================================
# DATA DOWNLOAD
# ============================================================
print(f"Downloading BTC-USD, ^GSPC, ^VIX [{START} → {END}]...")
btc = yf.download("BTC-USD", start=START, end=END, progress=False, auto_adjust=True)
spx = yf.download("^GSPC",   start=START, end=END, progress=False, auto_adjust=True)
vix = yf.download("^VIX",    start=START, end=END, progress=False, auto_adjust=True)

btc_close = btc["Close"].squeeze()
spx_close = spx["Close"].squeeze()
vix_close = vix["Close"].squeeze()

# Daily log-returns
btc_ret = np.log(btc_close / btc_close.shift(1))
spx_ret = np.log(spx_close / spx_close.shift(1))

# Align on common dates
common = btc_ret.index.intersection(spx_ret.index)
btc_r = btc_ret.loc[common].dropna()
spx_r = spx_ret.loc[common].dropna()
common = btc_r.index  # final common after dropna

print(f"  {len(common)} aligned trading days ({common[0].date()} → {common[-1].date()})")

# ============================================================
# ROLLING CORRELATION — ρ_14d and ρ_30d
# ============================================================
# pandas rolling corr: window=N, min_periods=N
rho_14d = btc_r.rolling(14, min_periods=14).corr(spx_r).rename("rho_14d")
rho_30d = btc_r.rolling(30, min_periods=30).corr(spx_r).rename("rho_30d")

# ============================================================
# REALISED VOLATILITY (7-day annualised) for causation bypass
# ============================================================
btc_rv7 = btc_r.rolling(7, min_periods=7).std() * math.sqrt(252)
spx_rv7 = spx_r.rolling(7, min_periods=7).std() * math.sqrt(252)
rv_ratio = (btc_rv7 / spx_rv7).rename("rv_ratio")

# Two-gate causation bypass:
# Gate 1: BTC/SPX RV ratio > 2.5 (analyst spec)
# Gate 2: BTC_RV7 / BTC_RV7_90d_median > 1.5 (relative crisis spike)
# Bare ratio > 2.5 fires 64% of all days (BTC permanently ~3× SPX vol, median ratio 3.09)
# Two-gate design: 209/1506 days (13.9%), fires LUNA + FTX as required
btc_rv7_90d_median = btc_rv7.rolling(90, min_periods=30).median()
btc_rv_spike = btc_rv7 / btc_rv7_90d_median  # relative to own baseline

# ============================================================
# ASSEMBLE SIGNALS DATAFRAME
# ============================================================
df = pd.DataFrame({
    "rho_14d": rho_14d,
    "rho_30d": rho_30d,
    "rv_ratio": rv_ratio,
}, index=common)

# Align VIX on trading days
vix_aligned = vix_close.reindex(common).ffill().rename("vix")
df = df.join(vix_aligned)

# ============================================================
# CAUSATION BYPASS (two-gate)
# ============================================================
df["btc_rv_spike"] = btc_rv_spike
df["causation_bypass"] = (df["rv_ratio"] > CAUSATION_RATIO) & (btc_rv_spike > 1.5)

# ============================================================
# REGIME CLASSIFICATION (stateless rolling — for audit)
# ============================================================
def classify_regime_series(df: pd.DataFrame) -> pd.Series:
    """
    Stateful regime classification matching the strategy logic.
    Returns a Series of regime labels.
    """
    regimes = []
    current = "crypto_native"

    for i, (idx, row) in enumerate(df.iterrows()):
        if row["causation_bypass"]:
            regimes.append("crypto_native_bypass")
            current = "crypto_native"
            continue

        rho14 = row["rho_14d"]
        rho30 = row["rho_30d"]

        if pd.isna(rho14) or pd.isna(rho30):
            regimes.append(current)
            continue

        dual_entry = (rho14 >= RHO_14D_ENTRY) and (rho30 >= RHO_30D_ENTRY)
        hyst_exit = rho30 < RHO_EXIT_HYST

        if current == "equity_coupled":
            if hyst_exit:
                current = "crypto_native"
            elif rho30 < RHO_30D_ENTRY:
                current = "transition"
        else:
            if dual_entry:
                current = "equity_coupled"
            elif rho30 >= 0.35:
                current = "transition"
            else:
                current = "crypto_native"

        regimes.append(current)

    return pd.Series(regimes, index=df.index, name="regime")


df["regime"] = classify_regime_series(df)

# ============================================================
# SUB-REGIME CLASSIFICATION (equity_coupled days only)
# ============================================================
rho30_5d_ago = df["rho_30d"].shift(EVENT_SPIKE_WINDOW)
delta_rho_5d = df["rho_30d"] - rho30_5d_ago

def sub_regime_row(row, delta: float) -> str:
    if row["regime"] != "equity_coupled":
        return "n/a"
    if delta > EVENT_SPIKE_DELTA:
        return "event_spike"
    vix = row.get("vix")
    if pd.notna(vix):
        if vix > VIX_FEAR:
            return "fear_driven"
        if vix < VIX_CALM:
            return "momentum_driven"
    return "neutral_coupled"

df["sub_regime"] = [
    sub_regime_row(row, float(delta_rho_5d.iloc[i]))
    for i, (_, row) in enumerate(df.iterrows())
]

# ============================================================
# NAIVE SINGLE-WINDOW REGIME (for comparison)
# ============================================================
def classify_naive(rho30: float) -> str:
    if pd.isna(rho30):
        return "crypto_native"
    if rho30 >= 0.50:
        return "equity_coupled"
    elif rho30 >= 0.20:
        return "transition"
    return "crypto_native"

df["regime_naive"] = df["rho_30d"].map(classify_naive)

# ============================================================
# RESULTS
# ============================================================
print("\n" + "=" * 60)
print("G1 SCAN RESULTS — Cross-Asset Macro Regime (Intermediate)")
print("=" * 60)

# --- Sub-regime firing rates ---
equity_days = df[df["regime"] == "equity_coupled"]
equity_bypass_days = df[df["regime"] == "crypto_native_bypass"]

print(f"\n[ Regime Day Counts (2020–2025) ]")
print(f"  equity_coupled (dual-window): {len(equity_days):>5} days")
print(f"  transition:                   {df[df['regime']=='transition'].shape[0]:>5} days")
print(f"  crypto_native:                {df[df['regime']=='crypto_native'].shape[0]:>5} days")
print(f"  causation_bypass:             {equity_bypass_days.shape[0]:>5} days")

print(f"\n[ Sub-Regime Firing Rates (equity_coupled days only) ]")
sub_counts = equity_days["sub_regime"].value_counts()
years = (common[-1] - common[0]).days / 365.25
for sr in ["fear_driven", "momentum_driven", "event_spike", "neutral_coupled"]:
    count = sub_counts.get(sr, 0)
    per_year = count / years
    target_check = ""
    if sr == "fear_driven" and per_year >= 10:
        target_check = " ✓ (≥10/yr)"
    elif sr == "fear_driven":
        target_check = f" ✗ (target: ≥10/yr)"
    elif sr == "momentum_driven" and per_year >= 10:
        target_check = " ✓ (≥10/yr)"
    elif sr == "momentum_driven":
        target_check = f" ✗ (target: ≥10/yr)"
    elif sr == "event_spike" and per_year >= 3:
        target_check = " ✓ (≥3/yr)"
    elif sr == "event_spike":
        target_check = f" ✗ (target: ≥3/yr)"
    print(f"  {sr:<20}: {count:>4} days total | {per_year:>5.1f}/yr{target_check}")

# --- Causation bypass verification ---
print(f"\n[ Causation Bypass Verification ]")
LUNA_RANGE = ("2022-05-01", "2022-05-31")
FTX_RANGE  = ("2022-11-01", "2022-11-30")

luna_df = df.loc[LUNA_RANGE[0]:LUNA_RANGE[1]]
ftx_df  = df.loc[FTX_RANGE[0]:FTX_RANGE[1]]

luna_bypass_days = luna_df["causation_bypass"].sum()
ftx_bypass_days  = ftx_df["causation_bypass"].sum()

luna_max_rv = luna_df["rv_ratio"].max()
ftx_max_rv  = ftx_df["rv_ratio"].max()

luna_status = "✓ FIRED" if luna_bypass_days > 0 else "✗ DID NOT FIRE"
ftx_status  = "✓ FIRED" if ftx_bypass_days > 0 else "✗ DID NOT FIRE"

print(f"  LUNA  (May 2022):  {luna_status} — {luna_bypass_days} bypass days, max RV ratio={luna_max_rv:.2f}")
print(f"  FTX   (Nov 2022):  {ftx_status} — {ftx_bypass_days} bypass days, max RV ratio={ftx_max_rv:.2f}")

# --- Dual-window vs naive comparison ---
print(f"\n[ Dual-Window vs Naive Single-Window Comparison ]")
naive_coupled = (df["regime_naive"] == "equity_coupled").sum()
dual_coupled  = (df["regime"] == "equity_coupled").sum()
false_signals = naive_coupled - dual_coupled  # Days naive fires but dual doesn't
print(f"  Naive equity_coupled days:        {naive_coupled:>5}")
print(f"  Dual-window equity_coupled days:  {dual_coupled:>5}")
print(f"  False signals removed by dual:    {false_signals:>5} days")

# --- Regime episodes and lag analysis ---
print(f"\n[ Regime Entry Lag (dual-window vs naive) ]")
# Find first day naive fires vs first day dual fires for each episode
naive_series = df["regime_naive"] == "equity_coupled"
dual_series  = df["regime"] == "equity_coupled"

naive_episodes = naive_series.astype(int).diff().eq(1).sum()
dual_episodes  = dual_series.astype(int).diff().eq(1).sum()
print(f"  Naive equity_coupled episodes:    {naive_episodes:>5}")
print(f"  Dual equity_coupled episodes:     {dual_episodes:>5}")

# --- Per-year breakdown ---
print(f"\n[ Per-Year Regime Summary ]")
df["year"] = df.index.year
print(df.groupby("year")["regime"].value_counts().unstack(fill_value=0).to_string())

# --- Key correlation stats ---
print(f"\n[ Correlation Statistics ]")
print(f"  ρ_30d mean:    {df['rho_30d'].mean():.3f}")
print(f"  ρ_30d max:     {df['rho_30d'].max():.3f}")
print(f"  ρ_30d min:     {df['rho_30d'].min():.3f}")
print(f"  ρ_14d mean:    {df['rho_14d'].mean():.3f}")
print(f"  Days ρ_30d ≥ 0.50: {(df['rho_30d'] >= 0.50).sum():>5}")
print(f"  Days ρ_14d ≥ 0.40: {(df['rho_14d'] >= 0.40).sum():>5}")
print(f"  Days BOTH thresholds met: {((df['rho_14d'] >= 0.40) & (df['rho_30d'] >= 0.50)).sum():>5}")

# --- G1 Gate verdict ---
print(f"\n[ G1 GATE VERDICT ]")
fear_ok      = sub_counts.get("fear_driven", 0) / years >= 10
momentum_ok  = sub_counts.get("momentum_driven", 0) / years >= 10
event_ok     = sub_counts.get("event_spike", 0) / years >= 3
luna_ok      = luna_bypass_days > 0
ftx_ok       = ftx_bypass_days > 0

all_ok = all([fear_ok, momentum_ok, event_ok, luna_ok, ftx_ok])

print(f"  fear_driven ≥ 10/yr:    {'PASS' if fear_ok else 'FAIL'}")
print(f"  momentum_driven ≥ 10/yr:{'PASS' if momentum_ok else 'FAIL'}")
print(f"  event_spike ≥ 3/yr:     {'PASS' if event_ok else 'FAIL'}")
print(f"  LUNA bypass fires:      {'PASS' if luna_ok else 'FAIL'}")
print(f"  FTX bypass fires:       {'PASS' if ftx_ok else 'FAIL'}")
print(f"\n  OVERALL G1: {'✓ PASS — G2 unblocked' if all_ok else '✗ FAIL — review thresholds'}")

# --- Save output ---
out_path = "g1-regime-scan-output.csv"
df[["rho_14d", "rho_30d", "rv_ratio", "vix", "regime", "sub_regime", "regime_naive"]].to_csv(out_path)
print(f"\n  Full timeseries saved → {out_path}")

#!/usr/bin/env python3
"""Test script for the incorporated flickerPy improvements.

Tests:
  1. Reading files (with multi-skiprow fallback)
  2. Bootstrap analysis with 3 genotypes (full_hyper curve, n=200)
  3. CRF plotting with fitted curves
  4. Statistical comparison output

Uses the gsk3b data from flickerPy (3 genotypes).
"""
import sys
sys.path.insert(0, "src")

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

from ssvep_analysis.reader import read_file, get_svp_files, ExperimentDefaults
from ssvep_analysis.bootstrap import (
    bootstrap_ssveps, hyperbolic_full, power_function,
    _fit_hyperbolic_full, _fit_power, _compare_genotypes,
)
from ssvep_analysis.converter import convert_svp_to_npz

# ── Configuration ─────────────────────────────────────────────────────────
DATA_DIR = Path("/raid/toolbox/git/flickerPy/data/202402--_OS_gsk3b")
OUTPUT = Path("output/flickerPy_test")
OUTPUT.mkdir(parents=True, exist_ok=True)

GENOTYPES = ["elavGAL4-UASsggDN", "elavGAL4-UASsggCTRL", "elavGAL4-UASsggCA"]
COLORS = ["red", "green", "blue"]
FREQ = 12
N_BOOTSTRAPS = 200  # enough to see distributions

# ── Step 1: Test file reading ─────────────────────────────────────────────
print("=" * 70)
print("STEP 1: Testing file reading (multi-skiprow fallback)")
print("=" * 70)

for gt in GENOTYPES:
    sub = DATA_DIR / gt
    svp_files = get_svp_files(sub)
    if svp_files:
        test_file = sub / svp_files[0]
        try:
            scd, md = read_file(test_file, freq=FREQ, verbose=True)
            print(f"  ✓ {gt}/{svp_files[0]}: {len(scd)} rows, n_trials={md.get('n_trials')}")
        except Exception as e:
            print(f"  ✗ {gt}/{svp_files[0]}: FAILED — {e}")

# ── Step 2: Run bootstrap (full_hyper with all 4 params) ──────────────────
print("\n" + "=" * 70)
print(f"STEP 2: Bootstrap analysis (full_hyper, n={N_BOOTSTRAPS})")
print("=" * 70)

results = bootstrap_ssveps(
    main_directory=DATA_DIR,
    genotypes=GENOTYPES,
    n_bootstraps=N_BOOTSTRAPS,
    input_freq=FREQ,
    curve_type="full_hyper",
    save=True,
    save_dir=OUTPUT,
    show_plot=False,
    label="gsk3b_test",
    n_processes=1,  # serial for reliable testing
)
print(f"\nBootstrap returned {len(results)} rows")

# ── Step 3: Plot mean CRFs with fitted curves overlaid ────────────────────
print("\n" + "=" * 70)
print("STEP 3: Plotting mean CRFs with fitted curves")
print("=" * 70)

fig, axes = plt.subplots(2, 2, figsize=(12, 10), layout="constrained")

for g_idx, genotype in enumerate(GENOTYPES):
    sub_dir = DATA_DIR / genotype
    svp_files = get_svp_files(sub_dir)
    raw_data = {}

    for fname in svp_files:
        try:
            scd, _ = read_file(sub_dir / fname, freq=FREQ)
            grouped = scd.groupby(["probe", "mask"]).mean(numeric_only=False)
            for (probe, mask), row in grouped.iterrows():
                raw_data.setdefault((probe, mask), []).append(
                    np.abs(row["complex_data"])
                )
        except Exception as e:
            print(f"  Skip {fname}: {e}")

    probes = sorted(set(k[0] for k in raw_data))
    masks = sorted(set(k[1] for k in raw_data))

    for mask in masks:
        ax = axes[0, 0] if mask == 0 else axes[1, 0]
        ms = "o" if mask == 0 else "s"
        ls = "-" if mask == 0 else "--"

        means = [np.mean(raw_data.get((p, mask), [0])) for p in probes]
        sems = [
            np.std(raw_data.get((p, mask), [0]))
            / max(np.sqrt(len(raw_data.get((p, mask), [0]))), 1)
            for p in probes
        ]

        ax.errorbar(
            probes, means, yerr=sems,
            color=COLORS[g_idx], marker=ms, linestyle="none",
            capsize=3, label=genotype,
        )

        try:
            params = _fit_hyperbolic_full(probes, means)
            c_fit = np.linspace(3, 102, 200)
            ax.plot(
                c_fit, hyperbolic_full(c_fit, *params),
                color=COLORS[g_idx], linestyle=ls, alpha=0.7,
                label=f"{genotype} fit (c50={params[0]:.1f})",
            )
        except Exception as e:
            print(f"  Fit failed for {genotype} mask={mask}: {e}")

        ax.set_xlabel("Probe contrast (%)")
        ax.set_ylabel("FFT amplitude (|uV|)")
        ax.set_title(f"1F1 ({FREQ} Hz) — mask = {mask}")
        ax.set_xscale("log")
        ax.legend(fontsize=6, loc="upper left")

# ── Step 4: Plot bootstrap histograms from saved CSV ──────────────────────
print("\n" + "=" * 70)
print("STEP 4: Plotting bootstrap histograms from saved data")
print("=" * 70)

import csv
raw_files = sorted(OUTPUT.glob("*gsk3b_test*full_hyper*_RAW.csv"))
if raw_files:
    raw_file = raw_files[-1]
    print(f"Reading bootstrap data from {raw_file}")
    with open(raw_file) as f:
        reader = csv.DictReader(f)
        headers = reader.fieldnames
        bs_data = {}
        for row in reader:
            gt = row["genotype"]
            for h in headers:
                if h in ("genotype", "bootstrap"):
                    continue
                bs_data.setdefault(h, {}).setdefault(gt, []).append(float(row[h]))

    # c50 histogram
    first_c50_key = sorted(k for k in bs_data if k.startswith("c50_"))[0]
    condition_tag = first_c50_key.replace("c50_", "")

    ax = axes[0, 1]
    for g_idx, gt in enumerate(GENOTYPES):
        vals = bs_data.get(first_c50_key, {}).get(gt, [])
        if vals:
            mean_v = np.mean(vals)
            ci_lo = np.quantile(vals, 0.025)
            ci_hi = np.quantile(vals, 0.975)
            ax.hist(vals, bins=20, alpha=0.5, color=COLORS[g_idx],
                    label=f"{gt}\nμ={mean_v:.1f} [{ci_lo:.1f}, {ci_hi:.1f}]")
            ax.errorbar(mean_v, 0,
                        xerr=[[mean_v - ci_lo], [ci_hi - mean_v]],
                        color=COLORS[g_idx], capsize=5, fmt="o")
    ax.set_title(f"Bootstrap c50 — {condition_tag}")
    ax.set_xlabel("c50")
    ax.legend(fontsize=6)

    # Rmax histogram
    rmax_key = f"Rmax_{condition_tag}"
    ax = axes[1, 1]
    for g_idx, gt in enumerate(GENOTYPES):
        vals = bs_data.get(rmax_key, {}).get(gt, [])
        if vals:
            mean_v = np.mean(vals)
            ci_lo = np.quantile(vals, 0.025)
            ci_hi = np.quantile(vals, 0.975)
            ax.hist(vals, bins=20, alpha=0.5, color=COLORS[g_idx],
                    label=f"{gt}\nμ={mean_v:.1f} [{ci_lo:.1f}, {ci_hi:.1f}]")
            ax.errorbar(mean_v, 0,
                        xerr=[[mean_v - ci_lo], [ci_hi - mean_v]],
                        color=COLORS[g_idx], capsize=5, fmt="o")
    ax.set_title(f"Bootstrap Rmax — {condition_tag}")
    ax.set_xlabel("Rmax")
    ax.legend(fontsize=6)

fig.suptitle(
    f"Bootstrap CRF Test — gsk3b: 3 genotypes\n"
    f"(full_hyper fit, n={N_BOOTSTRAPS}, {FREQ} Hz)",
    fontsize=13,
)
combined_path = OUTPUT / "test_incorporation_combined.png"
plt.savefig(combined_path, dpi=150)
print(f"Saved combined plot to {combined_path}")

# ── Step 5: Run reduced_hyper for comparison ──────────────────────────────
print("\n" + "=" * 70)
print(f"STEP 5: Bootstrap with reduced_hyper (n={N_BOOTSTRAPS})")
print("=" * 70)

results_hyp = bootstrap_ssveps(
    main_directory=DATA_DIR,
    genotypes=GENOTYPES,
    n_bootstraps=N_BOOTSTRAPS,
    input_freq=FREQ,
    curve_type="reduced_hyper",
    save=True,
    save_dir=OUTPUT,
    show_plot=False,
    label="gsk3b_test",
    n_processes=1,
)
print(f"Reduced hyper bootstrap returned {len(results_hyp)} rows")

# ── Step 6: Run power curve for comparison ────────────────────────────────
print("\n" + "=" * 70)
print(f"STEP 6: Bootstrap with power curve (n={N_BOOTSTRAPS})")
print("=" * 70)

results_pow = bootstrap_ssveps(
    main_directory=DATA_DIR,
    genotypes=GENOTYPES,
    n_bootstraps=N_BOOTSTRAPS,
    input_freq=FREQ,
    curve_type="power",
    save=True,
    save_dir=OUTPUT,
    show_plot=False,
    label="gsk3b_test",
    n_processes=1,
)
print(f"Power curve bootstrap returned {len(results_pow)} rows")

# ── Done ──────────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("ALL TESTS COMPLETE")
print("=" * 70)
print(f"Output files in: {OUTPUT.resolve()}")
for f in sorted(OUTPUT.glob("*")):
    print(f"  {f.name}")
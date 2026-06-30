#!/usr/bin/env python3
"""Analyze GAL80_hSNCA-raw dataset.

4 genotypes × 5 timepoints × 10 flies.
Generates CRF plots and bootstrap comparisons for each timepoint.
"""
import sys
sys.path.insert(0, "src")

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

from ssvep_analysis.reader import read_file, get_svp_files
from ssvep_analysis.bootstrap import (
    bootstrap_ssveps, hyperbolic_full, _fit_hyperbolic_full,
)

# ── Configuration ─────────────────────────────────────────────────────────
DATA_DIR = Path("/raid/data/SITRAN/GAL80_hSNCA-raw")
OUTPUT = Path("output/hSNCA")
OUTPUT.mkdir(parents=True, exist_ok=True)

TIMEPOINTS = ["7dpe", "14dpe", "21dpe", "28dpe", "35dpe"]
GENOTYPE_BASES = ["GAL80LACZ", "GAL80SNCAWT", "GAL80A53T", "GAL80A30P"]
COLORS = ["black", "blue", "green", "red"]
COLOR_MAP = dict(zip(GENOTYPE_BASES, COLORS))
FREQ = 12
N_BOOTSTRAPS = 200

# ── Step 1: Verify file reading ───────────────────────────────────────────
print("=" * 70)
print("STEP 1: Verifying file reading")
print("=" * 70)

for gt in GENOTYPE_BASES:
    subdir = DATA_DIR / f"{gt}_7dpe"
    svp_files = get_svp_files(subdir)
    if svp_files:
        try:
            scd, md = read_file(subdir / svp_files[0], freq=FREQ, verbose=True)
            print(f"  ✓ {gt}_7dpe/{svp_files[0]}: {len(scd)} rows, n_trials={md.get('n_trials')}")
            probes = sorted(scd['probe'].unique())
            masks = sorted(scd['mask'].unique())
            print(f"    probes={probes}, masks={masks}")
        except Exception as e:
            print(f"  ✗ {gt}_7dpe/{svp_files[0]}: FAILED — {e}")

# ── Step 2: Plot CRFs per timepoint ──────────────────────────────────────
print("\n" + "=" * 70)
print("STEP 2: CRF plots per timepoint (all 4 genotypes)")
print("=" * 70)

fig_crf, axes_crf = plt.subplots(1, 5, figsize=(20, 5), sharey=True, layout="constrained")

for tp_idx, tp in enumerate(TIMEPOINTS):
    ax = axes_crf[tp_idx]

    for gt_base, color in zip(GENOTYPE_BASES, COLORS):
        subdir = DATA_DIR / f"{gt_base}_{tp}"
        svp_files = get_svp_files(subdir)
        if not svp_files:
            print(f"  No files for {gt_base}_{tp}")
            continue

        raw_data = {}
        n_valid = 0
        for fname in svp_files:
            try:
                scd, _ = read_file(subdir / fname, freq=FREQ)
                grouped = scd.groupby(["probe", "mask"]).mean(numeric_only=False)
                for (probe, mask), row in grouped.iterrows():
                    raw_data.setdefault((probe, mask), []).append(
                        np.abs(row["complex_data"])
                    )
                n_valid += 1
            except Exception as e:
                pass  # silently skip

        probes = sorted(set(k[0] for k in raw_data))

        # Unmasked (mask=0)
        means = [np.mean(raw_data.get((p, 0), [0])) for p in probes]
        sems = [
            np.std(raw_data.get((p, 0), [0]))
            / max(np.sqrt(len(raw_data.get((p, 0), [0]))), 1)
            for p in probes
        ]
        ax.errorbar(probes, means, yerr=sems, color=color, marker="o",
                    linestyle="none", capsize=3, label=f"{gt_base} (n={n_valid})")

        # Fit curve
        try:
            params = _fit_hyperbolic_full(probes, means)
            c_fit = np.linspace(3, 102, 200)
            ax.plot(c_fit, hyperbolic_full(c_fit, *params),
                    color=color, alpha=0.5, linewidth=1)
        except Exception:
            pass

    ax.set_xlabel("Probe contrast (%)")
    ax.set_title(f"{tp}")
    ax.set_xscale("log")
    if tp_idx == 0:
        ax.set_ylabel("FFT amplitude (|uV|)")
    if tp_idx == 4:
        ax.legend(fontsize=6, loc="upper left")

fig_crf.suptitle("GAL80 hSNCA: Contrast-Response Functions (1F1, 12 Hz, unmasked)")
crf_path = OUTPUT / "hSNCA_CRF_all_timepoints.png"
fig_crf.savefig(crf_path, dpi=150)
print(f"Saved CRF plot to {crf_path}")

# ── Step 3: Bootstrap per timepoint ──────────────────────────────────────
print("\n" + "=" * 70)
print("STEP 3: Bootstrap analysis per timepoint")
print("=" * 70)

genotypes_for_bootstrap = []
for tp in TIMEPOINTS:
    genotypes_for_bootstrap.append([f"{gt}_{tp}" for gt in GENOTYPE_BASES])

for tp_idx, tp in enumerate(TIMEPOINTS):
    print(f"\n--- {tp} ---")
    gt_names = genotypes_for_bootstrap[tp_idx]
    results = bootstrap_ssveps(
        main_directory=DATA_DIR,
        genotypes=gt_names,
        n_bootstraps=N_BOOTSTRAPS,
        input_freq=FREQ,
        curve_type="reduced_hyper",
        save=True,
        save_dir=OUTPUT,
        show_plot=False,
        label=f"hSNCA_{tp}",
        n_processes=1,
    )
    print(f"  {tp}: {len(results)} rows")

# ── Step 4: Summary CRF with error bars on histograms ────────────────────
print("\n" + "=" * 70)
print("STEP 4: Summary — time-course of Rmax and c50 by genotype")
print("=" * 70)

# Read all summary CSVs
import csv
fig_summary, axes_sum = plt.subplots(2, 2, figsize=(12, 8), layout="constrained")

for gt_idx, gt_base in enumerate(GENOTYPE_BASES):
    c50_per_tp = []
    rmax_per_tp = []
    c50_ci_per_tp = []
    rmax_ci_per_tp = []

    for tp in TIMEPOINTS:
        sum_files = sorted(OUTPUT.glob(f"*hSNCA_{tp}*reduced_hyper*SUM.csv"))
        if not sum_files:
            c50_per_tp.append(np.nan)
            rmax_per_tp.append(np.nan)
            c50_ci_per_tp.append([np.nan, np.nan])
            rmax_ci_per_tp.append([np.nan, np.nan])
            continue

        sum_file = sum_files[-1]
        with open(sum_file) as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["genotype"] == f"{gt_base}_{tp}":
                    param = row["parameter"]
                    mean_val = float(row["mean"])
                    lo = float(row["lower_bound"])
                    hi = float(row["upper_bound"])
                    if param == "c50":
                        c50_per_tp.append(mean_val)
                        c50_ci_per_tp.append([lo, hi])
                    elif param == "Rmax":
                        rmax_per_tp.append(mean_val)
                        rmax_ci_per_tp.append([lo, hi])

    tp_nums = [7, 14, 21, 28, 35]
    color = COLORS[gt_idx]

    # c50 time-course
    ax = axes_sum[0, 0]
    ax.errorbar(tp_nums, c50_per_tp,
                yerr=[[c50_per_tp[i] - c50_ci_per_tp[i][0] for i in range(5)],
                      [c50_ci_per_tp[i][1] - c50_per_tp[i] for i in range(5)]],
                color=color, marker="o", capsize=3, label=gt_base)
    ax.set_xlabel("Days post-eclosion")
    ax.set_ylabel("c50")
    ax.set_title("c50 vs age")

    # Rmax time-course
    ax = axes_sum[0, 1]
    ax.errorbar(tp_nums, rmax_per_tp,
                yerr=[[rmax_per_tp[i] - rmax_ci_per_tp[i][0] for i in range(5)],
                      [rmax_ci_per_tp[i][1] - rmax_per_tp[i] for i in range(5)]],
                color=color, marker="o", capsize=3, label=gt_base)
    ax.set_xlabel("Days post-eclosion")
    ax.set_ylabel("Rmax")
    ax.set_title("Rmax vs age")

# Normalized (to 7dpe) plots
for gt_idx, gt_base in enumerate(GENOTYPE_BASES):
    c50_norm = []
    rmax_norm = []

    for tp in TIMEPOINTS:
        sum_files = sorted(OUTPUT.glob(f"*hSNCA_{tp}*reduced_hyper*SUM.csv"))
        if not sum_files:
            c50_norm.append(np.nan)
            rmax_norm.append(np.nan)
            continue
        with open(sum_files[-1]) as f:
            reader = csv.DictReader(f)
            for row in reader:
                if row["genotype"] == f"{gt_base}_{tp}":
                    if row["parameter"] == "c50":
                        c50_norm.append(float(row["mean"]))
                    elif row["parameter"] == "Rmax":
                        rmax_norm.append(float(row["mean"]))

    if c50_norm and c50_norm[0] and not np.isnan(c50_norm[0]):
        c50_norm = [v / c50_norm[0] for v in c50_norm]
    if rmax_norm and rmax_norm[0] and not np.isnan(rmax_norm[0]):
        rmax_norm = [v / rmax_norm[0] for v in rmax_norm]

    tp_nums = [7, 14, 21, 28, 35]
    color = COLORS[gt_idx]

    ax = axes_sum[1, 0]
    ax.plot(tp_nums, c50_norm, color=color, marker="o", label=gt_base)
    ax.set_xlabel("Days post-eclosion")
    ax.set_ylabel("c50 / c50(7dpe)")
    ax.set_title("c50 normalized to 7dpe")
    ax.axhline(1, color="gray", linestyle="--", alpha=0.5)

    ax = axes_sum[1, 1]
    ax.plot(tp_nums, rmax_norm, color=color, marker="o", label=gt_base)
    ax.set_xlabel("Days post-eclosion")
    ax.set_ylabel("Rmax / Rmax(7dpe)")
    ax.set_title("Rmax normalized to 7dpe")
    ax.axhline(1, color="gray", linestyle="--", alpha=0.5)

for ax in axes_sum.flat:
    ax.legend(fontsize=7)

fig_summary.suptitle("GAL80 hSNCA: Parameter time-course (bootstrap CIs)")
summary_path = OUTPUT / "hSNCA_timecourse.png"
fig_summary.savefig(summary_path, dpi=150)
print(f"Saved summary to {summary_path}")

# ── Done ──────────────────────────────────────────────────────────────────
print("\n" + "=" * 70)
print("ALL DONE")
print("=" * 70)
for f in sorted(OUTPUT.glob("*.png")):
    print(f"  {f.name}")
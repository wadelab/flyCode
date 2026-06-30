#!/usr/bin/env python3
"""Generate time-course summary plot from existing hSNCA bootstrap CSVs."""
import sys
sys.path.insert(0, "src")

import csv
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path

OUTPUT = Path("output/hSNCA")
TIMEPOINTS = ["7dpe", "14dpe", "21dpe", "28dpe", "35dpe"]
GENOTYPE_BASES = ["GAL80LACZ", "GAL80SNCAWT", "GAL80A53T", "GAL80A30P"]
COLORS = ["black", "blue", "green", "red"]

# ── Read all summary CSVs ─────────────────────────────────────────────────
fig, axes = plt.subplots(2, 2, figsize=(12, 8), layout="constrained")

for gt_idx, gt_base in enumerate(GENOTYPE_BASES):
    c50_per_tp = []
    rmax_per_tp = []
    c50_ci = []
    rmax_ci = []

    for tp in TIMEPOINTS:
        sum_files = sorted(OUTPUT.glob(f"*hSNCA_{tp}*reduced_hyper*SUM.csv"))
        if not sum_files:
            c50_per_tp.append(np.nan); rmax_per_tp.append(np.nan)
            c50_ci.append([np.nan, np.nan]); rmax_ci.append([np.nan, np.nan])
            continue

        with open(sum_files[-1]) as f:
            found_c50 = found_rmax = False
            for row in csv.DictReader(f):
                if row["genotype"] == f"{gt_base}_{tp}" and row["harmonic"] == "1F1" and row["mask"] == "0":
                    mean_val = float(row["mean"])
                    lo = float(row["lower_bound"])
                    hi = float(row["upper_bound"])
                    if row["parameter"] == "c50" and not found_c50:
                        c50_per_tp.append(mean_val)
                        c50_ci.append([lo, hi])
                        found_c50 = True
                    elif row["parameter"] == "Rmax" and not found_rmax:
                        rmax_per_tp.append(mean_val)
                        rmax_ci.append([lo, hi])
                        found_rmax = True
            if not found_c50:
                c50_per_tp.append(np.nan); c50_ci.append([np.nan, np.nan])
            if not found_rmax:
                rmax_per_tp.append(np.nan); rmax_ci.append([np.nan, np.nan])

    tp_nums = [7, 14, 21, 28, 35]
    color = COLORS[gt_idx]

    # c50
    ax = axes[0, 0]
    ax.errorbar(tp_nums, c50_per_tp,
                yerr=[[c50_per_tp[i] - c50_ci[i][0] for i in range(5)],
                      [c50_ci[i][1] - c50_per_tp[i] for i in range(5)]],
                color=color, marker="o", capsize=3, label=gt_base)
    # Rmax
    ax = axes[0, 1]
    ax.errorbar(tp_nums, rmax_per_tp,
                yerr=[[rmax_per_tp[i] - rmax_ci[i][0] for i in range(5)],
                      [rmax_ci[i][1] - rmax_per_tp[i] for i in range(5)]],
                color=color, marker="o", capsize=3, label=gt_base)

    # Normalised
    if c50_per_tp and c50_per_tp[0] and not np.isnan(c50_per_tp[0]):
        c50_norm = [v / c50_per_tp[0] for v in c50_per_tp]
        axes[1, 0].plot(tp_nums, c50_norm, color=color, marker="o", label=gt_base)
    if rmax_per_tp and rmax_per_tp[0] and not np.isnan(rmax_per_tp[0]):
        rmax_norm = [v / rmax_per_tp[0] for v in rmax_per_tp]
        axes[1, 1].plot(tp_nums, rmax_norm, color=color, marker="o", label=gt_base)

axes[0, 0].set_title("c50 vs age"); axes[0, 0].set_ylabel("c50")
axes[0, 1].set_title("Rmax vs age"); axes[0, 1].set_ylabel("Rmax")
axes[1, 0].set_title("c50 normalised to 7dpe"); axes[1, 0].set_ylabel("c50 / c50(7dpe)")
axes[1, 0].axhline(1, color="gray", linestyle="--", alpha=0.5)
axes[1, 1].set_title("Rmax normalised to 7dpe"); axes[1, 1].set_ylabel("Rmax / Rmax(7dpe)")
axes[1, 1].axhline(1, color="gray", linestyle="--", alpha=0.5)

for ax in axes.flat:
    ax.set_xlabel("Days post-eclosion")
    ax.legend(fontsize=7)

fig.suptitle("GAL80 hSNCA: Parameter time-course (reduced hyperbolic, bootstrap CIs)")
out = OUTPUT / "hSNCA_timecourse.png"
fig.savefig(out, dpi=150)
print(f"Saved {out}")
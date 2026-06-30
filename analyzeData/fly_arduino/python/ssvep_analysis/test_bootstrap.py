#!/usr/bin/env python3
"""Test bootstrap CRF fitting and plot results with fitted curves overlaid on data."""
import sys
sys.path.insert(0, "src")

import csv
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path
from ssvep_analysis.reader import read_file, get_svp_files
from ssvep_analysis.bootstrap import (
    bootstrap_ssveps, power_function, _fit_power
)

DATA_DIR = Path("/raid/data/SITRAN/DJ1_data_15_08_24")
OUTPUT = Path("output")
OUTPUT.mkdir(exist_ok=True)

# -- Step 1: Run bootstrap --
print("=" * 60)
print("STEP 1: Running bootstrap (n=50, power curve)")
print("=" * 60)

results = bootstrap_ssveps(
    main_directory=DATA_DIR,
    genotypes=["DJ1aDJ1b_1dpe", "DJ1aDJ1b_28dpe"],
    n_bootstraps=50,
    input_freq=12,
    curve_type="power",
    save=True,
    save_dir=OUTPUT,
    show_plot=False,
    label="test",
)
print(f"Bootstrap returned {len(results)} rows")

# -- Step 2: Plot CRFs with fitted curves --
print("\n" + "=" * 60)
print("STEP 2: Plotting CRFs with fitted curves")
print("=" * 60)

genotypes = ["DJ1aDJ1b_1dpe", "DJ1aDJ1b_28dpe"]
colors_g = ["red", "blue"]

fig, axes = plt.subplots(2, 2, figsize=(12, 10), layout="constrained")

for g_idx, genotype in enumerate(genotypes):
    sub_dir = DATA_DIR / genotype
    svp_files = get_svp_files(sub_dir)
    raw_data = {}

    for fname in svp_files:
        try:
            scd, _ = read_file(sub_dir / fname, freq=12)
            grouped = scd.groupby(["probe", "mask"]).mean(numeric_only=False)
            for (probe, mask), row in grouped.iterrows():
                raw_data.setdefault((probe, mask), []).append(np.abs(row["complex_data"]))
        except Exception as e:
            print(f"  Skip {fname}: {e}")

    probes = sorted(set(k[0] for k in raw_data))
    masks = sorted(set(k[1] for k in raw_data))

    for mask in masks:
        ax = axes[0, 0] if mask == 0 else axes[1, 0]
        ms = "o" if mask == 0 else "s"
        ls = "-" if mask == 0 else "--"

        means = [np.mean(raw_data.get((p, mask), [0])) for p in probes]
        sems = [np.std(raw_data.get((p, mask), [0])) / max(np.sqrt(len(raw_data.get((p, mask), [0]))), 1) for p in probes]

        ax.errorbar(probes, means, yerr=sems, color=colors_g[g_idx],
                    marker=ms, linestyle="none", capsize=3, label=genotype)

        try:
            params = _fit_power(probes, means)
            c_fit = np.linspace(3, 102, 200)
            ax.plot(c_fit, power_function(c_fit, *params),
                    color=colors_g[g_idx], linestyle=ls, alpha=0.7,
                    label=f"{genotype} fit (exp={params[0]:.2f})")
        except Exception as e:
            print(f"  Fit failed for {genotype} mask={mask}: {e}")

        ax.set_xlabel("Probe contrast (%)")
        ax.set_ylabel("FFT amplitude (|uV|)")
        ax.set_title(f"1F1 (12 Hz) -- mask = {mask}")
        ax.set_xscale("log")
        ax.legend(fontsize=6, loc="upper left")

# -- Step 2b: Bootstrap histograms --
raw_files = sorted(OUTPUT.glob("*test*_RAW.csv"))
if raw_files:
    raw_file = [f for f in raw_files if "power" in f.name]
    if raw_file:
        raw_file = raw_file[-1]
        print(f"\nReading bootstrap data from {raw_file}")
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

        first_key = sorted(k for k in bs_data if k.startswith("c50_"))[0]
        condition_tag = first_key.replace("c50_", "")

        ax = axes[0, 1]
        for g_idx, gt in enumerate(genotypes):
            vals = bs_data.get(first_key, {}).get(gt, [])
            if vals:
                ax.hist(vals, bins=15, alpha=0.5, color=colors_g[g_idx],
                        label=f"{gt} (mu={np.mean(vals):.3f})")
        ax.set_title(f"Bootstrap exponent -- {condition_tag}")
        ax.set_xlabel("exponent")
        ax.legend(fontsize=7)

        rmax_key = f"Rmax_{condition_tag}"
        ax = axes[1, 1]
        for g_idx, gt in enumerate(genotypes):
            vals = bs_data.get(rmax_key, {}).get(gt, [])
            if vals:
                ax.hist(vals, bins=15, alpha=0.5, color=colors_g[g_idx],
                        label=f"{gt} (mu={np.mean(vals):.2f})")
        ax.set_title(f"Bootstrap scale -- {condition_tag}")
        ax.set_xlabel("scale")
        ax.legend(fontsize=7)

fig.suptitle("Bootstrap CRF Test -- DJ1aDJ1b: 1dpe vs 28dpe\n(power fit, n=50)", fontsize=13)
out_path = OUTPUT / "test_bootstrap_crf.png"
plt.savefig(out_path, dpi=150)
print(f"\nSaved combined plot to {out_path}")

# -- Step 3: Also run reduced_hyper --
print("\n" + "=" * 60)
print("STEP 3: Running bootstrap with reduced_hyper (n=50)")
print("=" * 60)

results_hyp = bootstrap_ssveps(
    main_directory=DATA_DIR,
    genotypes=["DJ1aDJ1b_1dpe", "DJ1aDJ1b_28dpe"],
    n_bootstraps=50,
    input_freq=12,
    curve_type="reduced_hyper",
    save=True,
    save_dir=OUTPUT,
    show_plot=False,
    label="test_hyper",
)
print(f"Reduced hyper bootstrap returned {len(results_hyp)} rows")
print("\nAll tests completed!")
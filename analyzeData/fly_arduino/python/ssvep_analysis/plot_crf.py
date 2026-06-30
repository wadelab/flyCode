"""Plot mean contrast-response functions (CRFs) from all genotypes."""
import sys
sys.path.insert(0, "src")

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from pathlib import Path
from ssvep_analysis.reader import read_file

DATA_DIR = Path("/raid/data/SITRAN/DJ1_data_15_08_24")
GENOTYPES = ["DJ1aDJ1b_1dpe", "DJ1aDJ1b_7dpe", "DJ1aDJ1b_14dpe", "DJ1aDJ1b_21dpe", "DJ1aDJ1b_28dpe"]
COLORS = ["red", "orange", "gold", "green", "blue"]
FREQ = 12

fig, axes = plt.subplots(1, 2, figsize=(12, 5), sharey=True)

for g_idx, genotype in enumerate(GENOTYPES):
    sub_dir = DATA_DIR / genotype
    svp_files = sorted(f.name for f in sub_dir.iterdir() if "SVP" in f.name)

    # Read all files for both harmonics
    all_1f1 = {}  # (probe, mask) -> list of |amp|
    all_2f1 = {}

    for fname in svp_files:
        try:
            scd, _ = read_file(sub_dir / fname, freq=[12, 24])
            for f in [12, 24]:
                subset = scd[scd["freq"] == f]
                grouped = subset.groupby(["probe", "mask"]).mean(numeric_only=False)
                for (probe, mask), row in grouped.iterrows():
                    val = np.abs(row["complex_data"])
                    target = all_1f1 if f == 12 else all_2f1
                    target.setdefault((probe, mask), []).append(val)
        except Exception as e:
            print(f"Skip {fname}: {e}")

    # Plot 1F1 (left panel)
    ax = axes[0]
    probes_no_mask = sorted(k[0] for k in all_1f1 if k[1] == 0)
    means_no_mask = [np.mean(all_1f1[(p, 0)]) for p in probes_no_mask]
    sems_no_mask = [np.std(all_1f1[(p, 0)]) / np.sqrt(len(all_1f1[(p, 0)])) for p in probes_no_mask]

    probes_mask = sorted(k[0] for k in all_1f1 if k[1] == 30)
    means_mask = [np.mean(all_1f1[(p, 30)]) for p in probes_mask]
    sems_mask = [np.std(all_1f1[(p, 30)]) / np.sqrt(len(all_1f1[(p, 30)])) for p in probes_mask]

    ax.errorbar(probes_no_mask, means_no_mask, yerr=sems_no_mask,
                color=COLORS[g_idx], marker="o", label=genotype, linestyle="-")
    ax.errorbar(probes_mask, means_mask, yerr=sems_mask,
                color=COLORS[g_idx], marker="s", linestyle="--", alpha=0.6)
    ax.set_xlabel("Probe contrast (%)")
    ax.set_ylabel("FFT amplitude (µV)")
    ax.set_title("1F1 (12 Hz)")
    ax.set_xscale("log")
    ax.legend(fontsize=7)

    # Plot 2F1 (right panel)
    ax = axes[1]
    probes_no_mask = sorted(k[0] for k in all_2f1 if k[1] == 0)
    means_no_mask = [np.mean(all_2f1[(p, 0)]) for p in probes_no_mask]
    sems_no_mask = [np.std(all_2f1[(p, 0)]) / np.sqrt(len(all_2f1[(p, 0)])) for p in probes_no_mask]

    probes_mask = sorted(k[0] for k in all_2f1 if k[1] == 30)
    means_mask = [np.mean(all_2f1[(p, 30)]) for p in probes_mask]
    sems_mask = [np.std(all_2f1[(p, 30)]) / np.sqrt(len(all_2f1[(p, 30)])) for p in probes_mask]

    ax.errorbar(probes_no_mask, means_no_mask, yerr=sems_no_mask,
                color=COLORS[g_idx], marker="o", label=genotype, linestyle="-")
    ax.errorbar(probes_mask, means_mask, yerr=sems_mask,
                color=COLORS[g_idx], marker="s", linestyle="--", alpha=0.6)
    ax.set_xlabel("Probe contrast (%)")
    ax.set_title("2F1 (24 Hz)")

plt.suptitle("Contrast-Response Functions · DJ1aDJ1b time-course\n(solid=no mask, dashed=mask 30%)", fontsize=12)
plt.tight_layout()
out = "output/CRF_DJ1aDJ1b.png"
Path("output").mkdir(exist_ok=True)
plt.savefig(out, dpi=150)
print(f"Saved to {out}")
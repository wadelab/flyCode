#!/usr/bin/env python3
"""Generate time-course summary plot from existing hSNCA bootstrap CSVs."""
import sys
sys.path.insert(0, "src")

import csv
import warnings
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.patches import Patch
from pathlib import Path
from scipy.stats import f as f_dist
from scipy.stats import studentized_range

from ssvep_analysis.bootstrap import CURVE_SPECS
from ssvep_analysis.reader import get_svp_files, read_file

DATA_DIR = Path("/raid/data/SITRAN/GAL80_hSNCA-raw")
OUTPUT = Path("output/hSNCA")
TIMEPOINTS = ["7dpe", "14dpe", "21dpe", "28dpe", "35dpe"]
GENOTYPE_BASES = ["GAL80LACZ", "GAL80SNCAWT", "GAL80A53T", "GAL80A30P"]
COLORS = ["black", "blue", "green", "red"]
PARAMETERS = ["c50", "Rmax"]
FIT_TYPES = ["reduced_hyper", "power", "full_hyper", "fixed_c50_hyper"]
FREQ = 12
N_BOOTSTRAPS = 200
RNG_SEED = 0

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


def latest_file(pattern):
    files = sorted(OUTPUT.glob(pattern))
    return files[-1] if files else None


def condition_keys_from_header(fieldnames):
    keys = []
    for field in fieldnames:
        parts = field.split("_", 2)
        if len(parts) == 3 and parts[0] == "c50":
            keys.append((parts[1], parts[2]))
    return keys


def read_raw_bootstrap_values():
    values = {}
    condition_keys = []

    for tp in TIMEPOINTS:
        raw_file = latest_file(f"*hSNCA_{tp}*reduced_hyper*RAW.csv")
        if raw_file is None:
            continue

        with open(raw_file, newline="") as f:
            reader = csv.DictReader(f)
            if not condition_keys:
                condition_keys = condition_keys_from_header(reader.fieldnames or [])

            for row in reader:
                for gt_base in GENOTYPE_BASES:
                    if row["genotype"] != f"{gt_base}_{tp}":
                        continue

                    for parameter in PARAMETERS:
                        for mask, harmonic in condition_keys:
                            col = f"{parameter}_{mask}_{harmonic}"
                            if not row.get(col):
                                continue

                            val = float(row[col])
                            if np.isfinite(val):
                                key = (parameter, mask, harmonic, gt_base, tp)
                                values.setdefault(key, []).append(val)

    return values, condition_keys


def draw_parameter_boxplots(
    values,
    condition_keys,
    parameters=PARAMETERS,
    title="GAL80 hSNCA: bootstrap parameter boxplots by age and genotype",
    output_name="hSNCA_parameter_boxplots.png",
):
    if not condition_keys:
        print("No RAW bootstrap columns found; skipped boxplots")
        return

    fig_box, axes_box = plt.subplots(
        len(parameters),
        len(condition_keys),
        figsize=(4.2 * len(condition_keys), 3.75 * len(parameters)),
        sharex=True,
        layout="constrained",
    )
    axes_box = np.asarray(axes_box).reshape(len(parameters), len(condition_keys))

    n_genotypes = len(GENOTYPE_BASES)
    group_width = n_genotypes + 1
    age_positions = [
        tp_idx * group_width + (n_genotypes - 1) / 2
        for tp_idx in range(len(TIMEPOINTS))
    ]

    for row_idx, parameter in enumerate(parameters):
        for col_idx, (mask, harmonic) in enumerate(condition_keys):
            ax = axes_box[row_idx, col_idx]
            box_values = []
            box_positions = []
            box_colors = []

            for tp_idx, tp in enumerate(TIMEPOINTS):
                group_start = tp_idx * group_width
                for gt_idx, gt_base in enumerate(GENOTYPE_BASES):
                    vals = values.get((parameter, mask, harmonic, gt_base, tp), [])
                    if vals:
                        box_values.append(vals)
                        box_positions.append(group_start + gt_idx)
                        box_colors.append(COLORS[gt_idx])

            if box_values:
                bp = ax.boxplot(
                    box_values,
                    positions=box_positions,
                    widths=0.68,
                    patch_artist=True,
                    showfliers=False,
                    whis=(2.5, 97.5),
                )
                for patch, color in zip(bp["boxes"], box_colors):
                    patch.set_facecolor(color)
                    patch.set_alpha(0.35)
                    patch.set_edgecolor(color)
                    patch.set_linewidth(1.2)
                for median in bp["medians"]:
                    median.set_color("black")
                    median.set_linewidth(1.1)
                for whisker in bp["whiskers"]:
                    whisker.set_color("0.35")
                    whisker.set_linewidth(0.9)
                for cap in bp["caps"]:
                    cap.set_color("0.35")
                    cap.set_linewidth(0.9)

            for boundary_idx in range(1, len(TIMEPOINTS)):
                ax.axvline(
                    boundary_idx * group_width - 0.5,
                    color="0.85",
                    linewidth=0.8,
                    zorder=0,
                )

            ax.set_title(f"{harmonic}, mask {mask}", fontsize=10)
            ax.set_xticks(age_positions)
            ax.set_xticklabels(TIMEPOINTS)
            ax.set_xlim(-0.8, (len(TIMEPOINTS) - 1) * group_width + n_genotypes - 0.2)
            ax.grid(axis="y", color="0.9", linewidth=0.8)
            if col_idx == 0:
                ax.set_ylabel(parameter)
            if row_idx == len(parameters) - 1:
                ax.set_xlabel("Age")

    legend_handles = [
        Patch(facecolor=color, edgecolor=color, alpha=0.35, label=gt_base)
        for gt_base, color in zip(GENOTYPE_BASES, COLORS)
    ]
    fig_box.legend(
        handles=legend_handles,
        loc="center left",
        ncol=1,
        bbox_to_anchor=(1.01, 0.5),
        fontsize=8,
    )
    fig_box.suptitle(title, y=1.02)
    out_box = OUTPUT / output_name
    fig_box.savefig(out_box, dpi=150, bbox_inches="tight")
    print(f"Saved {out_box}")


raw_values, raw_condition_keys = read_raw_bootstrap_values()
draw_parameter_boxplots(raw_values, raw_condition_keys)


def reduced_hyperbolic(c, c50, rmax):
    c = np.asarray(c, dtype=float)
    return rmax * (c ** 2 / (c50 ** 2 + c ** 2))


def read_reduced_hyper_fit_params(condition_keys):
    params = {}

    for tp in TIMEPOINTS:
        sum_file = latest_file(f"*hSNCA_{tp}*reduced_hyper*SUM.csv")
        if sum_file is None:
            continue

        with open(sum_file, newline="") as f:
            for row in csv.DictReader(f):
                for gt_base in GENOTYPE_BASES:
                    if row["genotype"] != f"{gt_base}_{tp}":
                        continue

                    key = (tp, gt_base, row["harmonic"], row["mask"])
                    params.setdefault(key, {})[row["parameter"]] = float(row["mean"])

    return params


def read_reduced_hyper_bootstrap_pairs(condition_keys):
    pairs = {}

    for tp in TIMEPOINTS:
        raw_file = latest_file(f"*hSNCA_{tp}*reduced_hyper*RAW.csv")
        if raw_file is None:
            continue

        with open(raw_file, newline="") as f:
            for row in csv.DictReader(f):
                for gt_base in GENOTYPE_BASES:
                    if row["genotype"] != f"{gt_base}_{tp}":
                        continue

                    for mask, harmonic in condition_keys:
                        c50_col = f"c50_{mask}_{harmonic}"
                        rmax_col = f"Rmax_{mask}_{harmonic}"
                        if not row.get(c50_col) or not row.get(rmax_col):
                            continue

                        c50 = float(row[c50_col])
                        rmax = float(row[rmax_col])
                        if np.isfinite(c50) and np.isfinite(rmax):
                            key = (tp, gt_base, harmonic, str(mask))
                            pairs.setdefault(key, []).append((c50, rmax))

    return pairs


def read_crf_observations(condition_keys):
    observations = {}
    frequencies = {"1F1": FREQ, "2F1": FREQ * 2}
    wanted = {(str(mask), harmonic) for mask, harmonic in condition_keys}

    for tp in TIMEPOINTS:
        for gt_base in GENOTYPE_BASES:
            subdir = DATA_DIR / f"{gt_base}_{tp}"
            for fname in get_svp_files(subdir):
                try:
                    scd, _ = read_file(subdir / fname, freq=list(frequencies.values()))
                except Exception:
                    continue

                for harmonic, frequency in frequencies.items():
                    subset = scd[scd["freq"] == frequency]
                    grouped = subset.groupby(["probe", "mask"]).mean(numeric_only=False)["complex_data"]
                    for probe, mask in grouped.index:
                        mask = str(int(mask))
                        if (mask, harmonic) not in wanted:
                            continue

                        key = (tp, gt_base, harmonic, mask, int(probe))
                        observations.setdefault(key, []).append(float(np.abs(grouped[(probe, int(mask))])))

    return observations


def draw_crfs_with_reduced_hyper_fits(condition_keys):
    if not condition_keys:
        print("No conditions found; skipped CRF fit plot")
        return

    fit_params = read_reduced_hyper_fit_params(condition_keys)
    bootstrap_pairs = read_reduced_hyper_bootstrap_pairs(condition_keys)
    observations = read_crf_observations(condition_keys)
    fig_crf, axes_crf = plt.subplots(
        len(condition_keys),
        len(TIMEPOINTS),
        figsize=(4.0 * len(TIMEPOINTS), 3.1 * len(condition_keys)),
        sharex=True,
        layout="constrained",
    )
    axes_crf = np.asarray(axes_crf).reshape(len(condition_keys), len(TIMEPOINTS))

    for row_idx, (mask, harmonic) in enumerate(condition_keys):
        mask = str(mask)
        for tp_idx, tp in enumerate(TIMEPOINTS):
            ax = axes_crf[row_idx, tp_idx]

            for gt_idx, gt_base in enumerate(GENOTYPE_BASES):
                color = COLORS[gt_idx]
                probe_values = {
                    probe: vals
                    for (key_tp, key_gt, key_harm, key_mask, probe), vals in observations.items()
                    if key_tp == tp and key_gt == gt_base and key_harm == harmonic and key_mask == mask
                }
                probes = sorted(probe_values)
                if not probes:
                    continue

                means = [float(np.mean(probe_values[probe])) for probe in probes]
                sems = [
                    float(np.std(probe_values[probe], ddof=1) / np.sqrt(len(probe_values[probe])))
                    if len(probe_values[probe]) > 1 else 0.0
                    for probe in probes
                ]
                ax.errorbar(
                    probes,
                    means,
                    yerr=sems,
                    color=color,
                    marker="o",
                    linestyle="none",
                    capsize=2,
                    markersize=3,
                    label=gt_base if row_idx == 0 and tp_idx == 0 else None,
                )

                params = fit_params.get((tp, gt_base, harmonic, mask), {})
                if "c50" in params and "Rmax" in params:
                    c_fit = np.geomspace(min(probes), max(probes), 200)
                    fit_pairs = bootstrap_pairs.get((tp, gt_base, harmonic, mask), [])
                    if fit_pairs:
                        curves = np.array([
                            reduced_hyperbolic(c_fit, c50, rmax)
                            for c50, rmax in fit_pairs
                        ])
                        lower, upper = np.quantile(curves, [0.025, 0.975], axis=0)
                        ax.fill_between(
                            c_fit,
                            lower,
                            upper,
                            color=color,
                            alpha=0.14,
                            linewidth=0,
                        )
                    ax.plot(
                        c_fit,
                        reduced_hyperbolic(c_fit, params["c50"], params["Rmax"]),
                        color=color,
                        linewidth=1.3,
                        alpha=0.8,
                    )

            if row_idx == 0:
                ax.set_title(tp)
            if tp_idx == 0:
                ax.set_ylabel(f"{harmonic}, mask {mask}\nFFT amplitude")
            if row_idx == len(condition_keys) - 1:
                ax.set_xlabel("Probe contrast (%)")
            ax.set_xscale("log")
            ax.grid(axis="both", color="0.9", linewidth=0.8)

    axes_crf[0, 0].legend(fontsize=7)
    fig_crf.suptitle("GAL80 hSNCA: CRFs with reduced-hyperbolic fits")
    out_crf = OUTPUT / "hSNCA_CRF_reduced_hyper_fits.png"
    fig_crf.savefig(out_crf, dpi=150)
    print(f"Saved {out_crf}")


draw_crfs_with_reduced_hyper_fits(raw_condition_keys)


def read_power_bootstrap_values(condition_keys):
    values = {}
    parameter_labels = {"c50": "exponent", "Rmax": "scale"}

    for tp in TIMEPOINTS:
        raw_file = latest_file(f"*hSNCA_{tp}*power*RAW.csv")
        if raw_file is None:
            continue

        with open(raw_file, newline="") as f:
            for row in csv.DictReader(f):
                for gt_base in GENOTYPE_BASES:
                    if row["genotype"] != f"{gt_base}_{tp}":
                        continue

                    for source_parameter, label in parameter_labels.items():
                        for mask, harmonic in condition_keys:
                            col = f"{source_parameter}_{mask}_{harmonic}"
                            if not row.get(col):
                                continue

                            val = float(row[col])
                            if np.isfinite(val):
                                key = (label, mask, harmonic, gt_base, tp)
                                values.setdefault(key, []).append(val)

    return values


power_values = read_power_bootstrap_values(raw_condition_keys)
draw_parameter_boxplots(
    power_values,
    raw_condition_keys,
    parameters=["exponent", "scale"],
    title="GAL80 hSNCA: power-fit parameter boxplots by age and genotype",
    output_name="hSNCA_power_parameter_boxplots.png",
)


def top_two_mean_for_condition(scd, mask, frequency):
    subset = scd[scd["freq"] == frequency]
    grouped = subset.groupby(["probe", "mask"]).mean(numeric_only=False)["complex_data"]
    mask = int(mask)
    probes = sorted(
        int(probe)
        for probe, probe_mask in grouped.index
        if int(probe_mask) == mask
    )
    top_probes = probes[-2:]
    if len(top_probes) < 2:
        return None

    vals = [np.abs(grouped[(probe, mask)]) for probe in top_probes]
    return float(np.mean(vals))


def read_fly_high_contrast_means(condition_keys):
    values = {}
    frequencies = {"1F1": FREQ, "2F1": FREQ * 2}

    for tp in TIMEPOINTS:
        for gt_base in GENOTYPE_BASES:
            subdir = DATA_DIR / f"{gt_base}_{tp}"
            for fname in get_svp_files(subdir):
                try:
                    scd, _ = read_file(subdir / fname, freq=list(frequencies.values()))
                except Exception:
                    continue

                for mask, harmonic in condition_keys:
                    metric = top_two_mean_for_condition(
                        scd,
                        mask=mask,
                        frequency=frequencies[harmonic],
                    )
                    if metric is None:
                        continue

                    key = (mask, harmonic, gt_base, tp)
                    values.setdefault(key, []).append(metric)

    return values


def save_high_contrast_fly_csv(fly_values, condition_keys):
    out_path = OUTPUT / "hSNCA_high_contrast_mean_FLY.csv"
    with open(out_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["genotype", "timepoint", "harmonic", "mask", "fly_index", "high_contrast_mean"])
        for tp in TIMEPOINTS:
            for gt_base in GENOTYPE_BASES:
                for mask, harmonic in condition_keys:
                    vals = fly_values.get((mask, harmonic, gt_base, tp), [])
                    for fly_idx, val in enumerate(vals):
                        writer.writerow([gt_base, tp, harmonic, mask, fly_idx, val])

    print(f"Saved {out_path}")


def save_high_contrast_jasp_csv(fly_values, condition_keys):
    out_path = OUTPUT / "hSNCA_high_contrast_mean_JASP_wide.csv"
    condition_columns = [
        (mask, harmonic, f"HC_{harmonic}_mask{mask}")
        for mask, harmonic in condition_keys
    ]
    fieldnames = [
        "subject_id",
        "genotype",
        "timepoint",
        "age_days",
        "fly_index",
    ] + [column for _, _, column in condition_columns]

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()

        for tp in TIMEPOINTS:
            age_days = int(tp.replace("dpe", ""))
            for gt_base in GENOTYPE_BASES:
                max_n = max(
                    (
                        len(fly_values.get((mask, harmonic, gt_base, tp), []))
                        for mask, harmonic in condition_keys
                    ),
                    default=0,
                )
                for fly_idx in range(max_n):
                    row = {
                        "subject_id": f"{gt_base}_{tp}_{fly_idx:02d}",
                        "genotype": gt_base,
                        "timepoint": tp,
                        "age_days": age_days,
                        "fly_index": fly_idx,
                    }
                    for mask, harmonic, column in condition_columns:
                        vals = fly_values.get((mask, harmonic, gt_base, tp), [])
                        row[column] = vals[fly_idx] if fly_idx < len(vals) else ""
                    writer.writerow(row)

    print(f"Saved {out_path}")


def bootstrap_high_contrast_means(fly_values):
    rng = np.random.default_rng(RNG_SEED)
    boot_values = {}

    for key, vals in fly_values.items():
        vals = np.asarray(vals, dtype=float)
        if vals.size == 0:
            continue

        sample_idx = rng.integers(0, vals.size, size=(N_BOOTSTRAPS, vals.size))
        boot_values[key] = np.mean(vals[sample_idx], axis=1).tolist()

    return boot_values


def design_matrix(genotypes, timepoints, *, include_genotype, include_time, include_interaction):
    columns = [np.ones(len(genotypes))]

    genotype_cols = []
    if include_genotype:
        for gt in GENOTYPE_BASES[1:]:
            col = np.array([1.0 if value == gt else 0.0 for value in genotypes])
            columns.append(col)
            genotype_cols.append(col)

    time_cols = []
    if include_time:
        for tp in TIMEPOINTS[1:]:
            col = np.array([1.0 if value == tp else 0.0 for value in timepoints])
            columns.append(col)
            time_cols.append(col)

    if include_interaction:
        for g_col in genotype_cols:
            for t_col in time_cols:
                columns.append(g_col * t_col)

    return np.column_stack(columns)


def fit_sse(y, x):
    beta, *_ = np.linalg.lstsq(x, y, rcond=None)
    residuals = y - x @ beta
    return float(np.sum(residuals ** 2)), int(np.linalg.matrix_rank(x))


def collect_anova_values(fly_values, mask, harmonic):
    y_vals = []
    genotypes = []
    timepoints = []

    for tp in TIMEPOINTS:
        for gt_base in GENOTYPE_BASES:
            for val in fly_values.get((mask, harmonic, gt_base, tp), []):
                if np.isfinite(val):
                    y_vals.append(float(val))
                    genotypes.append(gt_base)
                    timepoints.append(tp)

    return np.asarray(y_vals, dtype=float), genotypes, timepoints


def full_anova_error(fly_values, mask, harmonic):
    y, genotypes, timepoints = collect_anova_values(fly_values, mask, harmonic)
    if y.size == 0:
        return np.nan, 0

    x_full = design_matrix(genotypes, timepoints, include_genotype=True, include_time=True, include_interaction=True)
    sse_full, rank_full = fit_sse(y, x_full)
    df_error = y.size - rank_full
    mse_error = sse_full / df_error
    return mse_error, df_error


def two_way_anova_rows(fly_values, mask, harmonic):
    y, genotypes, timepoints = collect_anova_values(fly_values, mask, harmonic)
    if y.size == 0:
        return []

    x_genotype = design_matrix(genotypes, timepoints, include_genotype=True, include_time=False, include_interaction=False)
    x_time = design_matrix(genotypes, timepoints, include_genotype=False, include_time=True, include_interaction=False)
    x_additive = design_matrix(genotypes, timepoints, include_genotype=True, include_time=True, include_interaction=False)
    x_full = design_matrix(genotypes, timepoints, include_genotype=True, include_time=True, include_interaction=True)

    sse_genotype, rank_genotype = fit_sse(y, x_genotype)
    sse_time, rank_time = fit_sse(y, x_time)
    sse_additive, rank_additive = fit_sse(y, x_additive)
    sse_full, rank_full = fit_sse(y, x_full)

    df_error = y.size - rank_full
    mse_error = sse_full / df_error
    effects = [
        ("genotype", sse_time - sse_additive, rank_additive - rank_time),
        ("timepoint", sse_genotype - sse_additive, rank_additive - rank_genotype),
        ("genotype:timepoint", sse_additive - sse_full, rank_full - rank_additive),
    ]

    rows = []
    for effect, ss, df in effects:
        ss = max(float(ss), 0.0)
        ms = ss / df if df > 0 else np.nan
        f_value = ms / mse_error if df > 0 and mse_error > 0 else np.nan
        p_value = f_dist.sf(f_value, df, df_error) if np.isfinite(f_value) else np.nan
        rows.append({
            "harmonic": harmonic,
            "mask": mask,
            "effect": effect,
            "df": df,
            "df_error": df_error,
            "ss": ss,
            "ms": ms,
            "f": f_value,
            "p": p_value,
            "n": y.size,
        })

    return rows


def save_high_contrast_anovas(fly_values, condition_keys):
    out_path = OUTPUT / "hSNCA_high_contrast_mean_2way_anova.csv"
    fieldnames = ["harmonic", "mask", "effect", "df", "df_error", "ss", "ms", "f", "p", "n"]

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for mask, harmonic in condition_keys:
            for row in two_way_anova_rows(fly_values, mask, harmonic):
                writer.writerow(row)

    print(f"Saved {out_path}")


def tukey_kramer_rows(fly_values, condition_keys):
    rows = []

    for mask, harmonic in condition_keys:
        mse_error, df_error = full_anova_error(fly_values, mask, harmonic)
        if not np.isfinite(mse_error) or df_error <= 0:
            continue

        comparison_sets = [("marginal", "all", TIMEPOINTS)]
        comparison_sets.extend(("simple_timepoint", tp, [tp]) for tp in TIMEPOINTS)

        for comparison_scope, timepoint_label, included_timepoints in comparison_sets:
            grouped_values = {}
            for gt_base in GENOTYPE_BASES:
                vals = []
                for tp in included_timepoints:
                    vals.extend(fly_values.get((mask, harmonic, gt_base, tp), []))
                vals = [float(v) for v in vals if np.isfinite(v)]
                if vals:
                    grouped_values[gt_base] = vals

            k = len(grouped_values)
            if k < 2:
                continue

            for i, gt_a in enumerate(GENOTYPE_BASES):
                for gt_b in GENOTYPE_BASES[i + 1:]:
                    if gt_a not in grouped_values or gt_b not in grouped_values:
                        continue

                    vals_a = np.asarray(grouped_values[gt_a], dtype=float)
                    vals_b = np.asarray(grouped_values[gt_b], dtype=float)
                    mean_a = float(np.mean(vals_a))
                    mean_b = float(np.mean(vals_b))
                    diff = mean_a - mean_b
                    se = float(np.sqrt(mse_error * 0.5 * (1 / vals_a.size + 1 / vals_b.size)))
                    q_stat = abs(diff) / se if se > 0 else np.nan
                    p_adj = studentized_range.sf(q_stat, k, df_error) if np.isfinite(q_stat) else np.nan

                    rows.append({
                        "harmonic": harmonic,
                        "mask": mask,
                        "comparison_scope": comparison_scope,
                        "timepoint": timepoint_label,
                        "genotype_a": gt_a,
                        "genotype_b": gt_b,
                        "mean_a": mean_a,
                        "mean_b": mean_b,
                        "difference_a_minus_b": diff,
                        "n_a": vals_a.size,
                        "n_b": vals_b.size,
                        "mse_error": mse_error,
                        "df_error": df_error,
                        "q": q_stat,
                        "p_tukey": p_adj,
                        "significant_0_05": bool(p_adj < 0.05) if np.isfinite(p_adj) else False,
                    })

    return rows


def save_high_contrast_posthocs(fly_values, condition_keys):
    out_path = OUTPUT / "hSNCA_high_contrast_mean_genotype_posthoc_tukey.csv"
    fieldnames = [
        "harmonic", "mask", "comparison_scope", "timepoint",
        "genotype_a", "genotype_b", "mean_a", "mean_b",
        "difference_a_minus_b", "n_a", "n_b", "mse_error",
        "df_error", "q", "p_tukey", "significant_0_05",
    ]

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(tukey_kramer_rows(fly_values, condition_keys))

    print(f"Saved {out_path}")


def fit_fly_condition(scd, mask, harmonic, fit_type):
    frequencies = {"1F1": FREQ, "2F1": FREQ * 2}
    spec = CURVE_SPECS[fit_type]
    subset = scd[scd["freq"] == frequencies[harmonic]]
    if subset.empty:
        return None

    grouped = subset.groupby(["probe", "mask"]).mean(numeric_only=False)["complex_data"]
    target_mask = int(mask)
    probes = sorted(
        int(probe)
        for probe, probe_mask in grouped.index
        if int(probe_mask) == target_mask
    )
    if len(probes) < len(spec.param_names):
        return None

    responses = np.asarray(
        [np.abs(grouped[(probe, target_mask)]) for probe in probes],
        dtype=float,
    )
    if not np.all(np.isfinite(responses)) or np.max(responses) <= 0:
        return None

    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            params = np.asarray(spec.fit_fn(probes, responses.tolist()), dtype=float)
    except Exception:
        return None

    if params.size != len(spec.param_names) or not np.all(np.isfinite(params)):
        return None

    return params


def read_fly_fit_parameters(condition_keys):
    rows = []
    values = {}

    for tp in TIMEPOINTS:
        age_days = int(tp.replace("dpe", ""))
        for gt_base in GENOTYPE_BASES:
            subdir = DATA_DIR / f"{gt_base}_{tp}"
            for fly_idx, fname in enumerate(get_svp_files(subdir)):
                try:
                    scd, _ = read_file(subdir / fname, freq=[FREQ, FREQ * 2])
                except Exception:
                    continue

                subject_id = f"{gt_base}_{tp}_{fly_idx:02d}"
                for fit_type in FIT_TYPES:
                    spec = CURVE_SPECS[fit_type]
                    for mask, harmonic in condition_keys:
                        params = fit_fly_condition(scd, mask, harmonic, fit_type)
                        if params is None:
                            continue

                        for parameter, value in zip(spec.param_names, params):
                            value = float(value)
                            key = (fit_type, parameter, str(mask), harmonic, gt_base, tp)
                            values.setdefault(key, []).append(value)
                            rows.append({
                                "subject_id": subject_id,
                                "source_file": fname,
                                "genotype": gt_base,
                                "timepoint": tp,
                                "age_days": age_days,
                                "fly_index": fly_idx,
                                "fit_type": fit_type,
                                "harmonic": harmonic,
                                "mask": str(mask),
                                "parameter": parameter,
                                "value": value,
                            })

    return rows, values


def save_fit_parameter_fly_csv(rows):
    out_path = OUTPUT / "hSNCA_fit_parameters_FLY_long.csv"
    fieldnames = [
        "subject_id", "source_file", "genotype", "timepoint", "age_days",
        "fly_index", "fit_type", "harmonic", "mask", "parameter", "value",
    ]

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Saved {out_path}")


def fit_parameter_column(fit_type, parameter, harmonic, mask):
    return f"{fit_type}_{parameter}_{harmonic}_mask{mask}"


def save_fit_parameter_jasp_csv(rows, condition_keys):
    out_path = OUTPUT / "hSNCA_fit_parameters_JASP_wide.csv"
    value_columns = [
        fit_parameter_column(fit_type, parameter, harmonic, mask)
        for fit_type in FIT_TYPES
        for mask, harmonic in condition_keys
        for parameter in CURVE_SPECS[fit_type].param_names
    ]
    fieldnames = [
        "subject_id", "genotype", "timepoint", "age_days", "fly_index",
    ] + value_columns

    wide_rows = {}
    for row in rows:
        subject_id = row["subject_id"]
        wide_rows.setdefault(subject_id, {
            "subject_id": subject_id,
            "genotype": row["genotype"],
            "timepoint": row["timepoint"],
            "age_days": row["age_days"],
            "fly_index": row["fly_index"],
        })
        column = fit_parameter_column(
            row["fit_type"],
            row["parameter"],
            row["harmonic"],
            row["mask"],
        )
        wide_rows[subject_id][column] = row["value"]

    def sort_key(item):
        row = item[1]
        return (
            TIMEPOINTS.index(row["timepoint"]),
            GENOTYPE_BASES.index(row["genotype"]),
            int(row["fly_index"]),
        )

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for _, row in sorted(wide_rows.items(), key=sort_key):
            writer.writerow(row)

    print(f"Saved {out_path}")


def collect_fit_anova_values(fit_values, fit_type, parameter, mask, harmonic):
    y_vals = []
    genotypes = []
    timepoints = []

    for tp in TIMEPOINTS:
        for gt_base in GENOTYPE_BASES:
            key = (fit_type, parameter, str(mask), harmonic, gt_base, tp)
            for val in fit_values.get(key, []):
                if np.isfinite(val):
                    y_vals.append(float(val))
                    genotypes.append(gt_base)
                    timepoints.append(tp)

    return np.asarray(y_vals, dtype=float), genotypes, timepoints


def fit_parameter_full_anova_error(fit_values, fit_type, parameter, mask, harmonic):
    y, genotypes, timepoints = collect_fit_anova_values(
        fit_values,
        fit_type,
        parameter,
        mask,
        harmonic,
    )
    if y.size == 0:
        return np.nan, 0

    x_full = design_matrix(genotypes, timepoints, include_genotype=True, include_time=True, include_interaction=True)
    sse_full, rank_full = fit_sse(y, x_full)
    df_error = y.size - rank_full
    if df_error <= 0:
        return np.nan, df_error

    mse_error = sse_full / df_error
    return mse_error, df_error


def fit_parameter_anova_rows(fit_values, fit_type, parameter, mask, harmonic):
    y, genotypes, timepoints = collect_fit_anova_values(
        fit_values,
        fit_type,
        parameter,
        mask,
        harmonic,
    )
    if y.size == 0:
        return []

    x_genotype = design_matrix(genotypes, timepoints, include_genotype=True, include_time=False, include_interaction=False)
    x_time = design_matrix(genotypes, timepoints, include_genotype=False, include_time=True, include_interaction=False)
    x_additive = design_matrix(genotypes, timepoints, include_genotype=True, include_time=True, include_interaction=False)
    x_full = design_matrix(genotypes, timepoints, include_genotype=True, include_time=True, include_interaction=True)

    sse_genotype, rank_genotype = fit_sse(y, x_genotype)
    sse_time, rank_time = fit_sse(y, x_time)
    sse_additive, rank_additive = fit_sse(y, x_additive)
    sse_full, rank_full = fit_sse(y, x_full)

    df_error = y.size - rank_full
    if df_error <= 0:
        return []

    mse_error = sse_full / df_error
    effects = [
        ("genotype", sse_time - sse_additive, rank_additive - rank_time),
        ("timepoint", sse_genotype - sse_additive, rank_additive - rank_genotype),
        ("genotype:timepoint", sse_additive - sse_full, rank_full - rank_additive),
    ]

    rows = []
    for effect, ss, df in effects:
        ss = max(float(ss), 0.0)
        ms = ss / df if df > 0 else np.nan
        f_value = ms / mse_error if df > 0 and mse_error > 0 else np.nan
        p_value = f_dist.sf(f_value, df, df_error) if np.isfinite(f_value) else np.nan
        rows.append({
            "fit_type": fit_type,
            "parameter": parameter,
            "harmonic": harmonic,
            "mask": mask,
            "effect": effect,
            "df": df,
            "df_error": df_error,
            "ss": ss,
            "ms": ms,
            "f": f_value,
            "p": p_value,
            "n": y.size,
        })

    return rows


def save_fit_parameter_anovas(fit_values, condition_keys):
    out_path = OUTPUT / "hSNCA_fit_parameters_2way_anova.csv"
    fieldnames = [
        "fit_type", "parameter", "harmonic", "mask", "effect",
        "df", "df_error", "ss", "ms", "f", "p", "n",
    ]

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for fit_type in FIT_TYPES:
            for parameter in CURVE_SPECS[fit_type].param_names:
                for mask, harmonic in condition_keys:
                    for row in fit_parameter_anova_rows(
                        fit_values,
                        fit_type,
                        parameter,
                        mask,
                        harmonic,
                    ):
                        writer.writerow(row)

    print(f"Saved {out_path}")


def fit_parameter_tukey_rows(fit_values, condition_keys):
    rows = []

    for fit_type in FIT_TYPES:
        for parameter in CURVE_SPECS[fit_type].param_names:
            for mask, harmonic in condition_keys:
                mse_error, df_error = fit_parameter_full_anova_error(
                    fit_values,
                    fit_type,
                    parameter,
                    mask,
                    harmonic,
                )
                if not np.isfinite(mse_error) or df_error <= 0:
                    continue

                comparison_sets = [("marginal", "all", TIMEPOINTS)]
                comparison_sets.extend(("simple_timepoint", tp, [tp]) for tp in TIMEPOINTS)

                for comparison_scope, timepoint_label, included_timepoints in comparison_sets:
                    grouped_values = {}
                    for gt_base in GENOTYPE_BASES:
                        vals = []
                        for tp in included_timepoints:
                            key = (fit_type, parameter, str(mask), harmonic, gt_base, tp)
                            vals.extend(fit_values.get(key, []))
                        vals = [float(v) for v in vals if np.isfinite(v)]
                        if vals:
                            grouped_values[gt_base] = vals

                    k = len(grouped_values)
                    if k < 2:
                        continue

                    for i, gt_a in enumerate(GENOTYPE_BASES):
                        for gt_b in GENOTYPE_BASES[i + 1:]:
                            if gt_a not in grouped_values or gt_b not in grouped_values:
                                continue

                            vals_a = np.asarray(grouped_values[gt_a], dtype=float)
                            vals_b = np.asarray(grouped_values[gt_b], dtype=float)
                            mean_a = float(np.mean(vals_a))
                            mean_b = float(np.mean(vals_b))
                            diff = mean_a - mean_b
                            se = float(np.sqrt(mse_error * 0.5 * (1 / vals_a.size + 1 / vals_b.size)))
                            q_stat = abs(diff) / se if se > 0 else np.nan
                            p_adj = studentized_range.sf(q_stat, k, df_error) if np.isfinite(q_stat) else np.nan

                            rows.append({
                                "fit_type": fit_type,
                                "parameter": parameter,
                                "harmonic": harmonic,
                                "mask": mask,
                                "comparison_scope": comparison_scope,
                                "timepoint": timepoint_label,
                                "genotype_a": gt_a,
                                "genotype_b": gt_b,
                                "mean_a": mean_a,
                                "mean_b": mean_b,
                                "difference_a_minus_b": diff,
                                "n_a": vals_a.size,
                                "n_b": vals_b.size,
                                "mse_error": mse_error,
                                "df_error": df_error,
                                "q": q_stat,
                                "p_tukey": p_adj,
                                "significant_0_05": bool(p_adj < 0.05) if np.isfinite(p_adj) else False,
                            })

    return rows


def save_fit_parameter_posthocs(fit_values, condition_keys):
    out_path = OUTPUT / "hSNCA_fit_parameters_genotype_posthoc_tukey.csv"
    fieldnames = [
        "fit_type", "parameter", "harmonic", "mask",
        "comparison_scope", "timepoint", "genotype_a", "genotype_b",
        "mean_a", "mean_b", "difference_a_minus_b", "n_a", "n_b",
        "mse_error", "df_error", "q", "p_tukey", "significant_0_05",
    ]

    with open(out_path, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(fit_parameter_tukey_rows(fit_values, condition_keys))

    print(f"Saved {out_path}")


def save_high_contrast_csvs(boot_values, condition_keys):
    raw_path = OUTPUT / "hSNCA_high_contrast_mean_RAW.csv"
    sum_path = OUTPUT / "hSNCA_high_contrast_mean_SUM.csv"

    with open(raw_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(
            ["genotype", "bootstrap"]
            + [f"high_contrast_mean_{mask}_{harmonic}" for mask, harmonic in condition_keys]
        )
        for tp in TIMEPOINTS:
            for gt_base in GENOTYPE_BASES:
                genotype = f"{gt_base}_{tp}"
                for b in range(N_BOOTSTRAPS):
                    row = [genotype, b]
                    for mask, harmonic in condition_keys:
                        row.append(boot_values.get((mask, harmonic, gt_base, tp), [np.nan] * N_BOOTSTRAPS)[b])
                    writer.writerow(row)

    with open(sum_path, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow([
            "genotype", "parameter", "harmonic", "mask",
            "min_value", "lower_bound", "mean", "upper_bound", "max_value",
        ])
        for tp in TIMEPOINTS:
            for gt_base in GENOTYPE_BASES:
                genotype = f"{gt_base}_{tp}"
                for mask, harmonic in condition_keys:
                    vals = np.asarray(boot_values.get((mask, harmonic, gt_base, tp), []), dtype=float)
                    if vals.size == 0:
                        continue
                    writer.writerow([
                        genotype, "high_contrast_mean", harmonic, mask,
                        np.min(vals), np.quantile(vals, 0.025), np.mean(vals),
                        np.quantile(vals, 0.975), np.max(vals),
                    ])

    print(f"Saved {raw_path}")
    print(f"Saved {sum_path}")


def draw_high_contrast_boxplots(boot_values, condition_keys):
    if not condition_keys:
        print("No conditions found; skipped high-contrast boxplots")
        return

    fig_high, axes_high = plt.subplots(
        1,
        len(condition_keys),
        figsize=(4.2 * len(condition_keys), 4.6),
        sharex=True,
        layout="constrained",
    )
    axes_high = np.asarray(axes_high).reshape(1, len(condition_keys))[0]

    n_genotypes = len(GENOTYPE_BASES)
    group_width = n_genotypes + 1
    age_positions = [
        tp_idx * group_width + (n_genotypes - 1) / 2
        for tp_idx in range(len(TIMEPOINTS))
    ]

    for col_idx, (mask, harmonic) in enumerate(condition_keys):
        ax = axes_high[col_idx]
        box_values = []
        box_positions = []
        box_colors = []

        for tp_idx, tp in enumerate(TIMEPOINTS):
            group_start = tp_idx * group_width
            for gt_idx, gt_base in enumerate(GENOTYPE_BASES):
                vals = boot_values.get((mask, harmonic, gt_base, tp), [])
                if vals:
                    box_values.append(vals)
                    box_positions.append(group_start + gt_idx)
                    box_colors.append(COLORS[gt_idx])

        if box_values:
            bp = ax.boxplot(
                box_values,
                positions=box_positions,
                widths=0.68,
                patch_artist=True,
                showfliers=False,
                whis=(2.5, 97.5),
            )
            for patch, color in zip(bp["boxes"], box_colors):
                patch.set_facecolor(color)
                patch.set_alpha(0.35)
                patch.set_edgecolor(color)
                patch.set_linewidth(1.2)
            for median in bp["medians"]:
                median.set_color("black")
                median.set_linewidth(1.1)
            for whisker in bp["whiskers"]:
                whisker.set_color("0.35")
                whisker.set_linewidth(0.9)
            for cap in bp["caps"]:
                cap.set_color("0.35")
                cap.set_linewidth(0.9)

        for boundary_idx in range(1, len(TIMEPOINTS)):
            ax.axvline(
                boundary_idx * group_width - 0.5,
                color="0.85",
                linewidth=0.8,
                zorder=0,
            )

        ax.set_title(f"{harmonic}, mask {mask}", fontsize=10)
        ax.set_xticks(age_positions)
        ax.set_xticklabels(TIMEPOINTS)
        ax.set_xlim(-0.8, (len(TIMEPOINTS) - 1) * group_width + n_genotypes - 0.2)
        ax.grid(axis="y", color="0.9", linewidth=0.8)
        ax.set_xlabel("Age")
        if col_idx == 0:
            ax.set_ylabel("Mean response at top two available contrasts")

    legend_handles = [
        Patch(facecolor=color, edgecolor=color, alpha=0.35, label=gt_base)
        for gt_base, color in zip(GENOTYPE_BASES, COLORS)
    ]
    fig_high.legend(
        handles=legend_handles,
        loc="center left",
        ncol=1,
        bbox_to_anchor=(1.01, 0.5),
        fontsize=8,
    )
    fig_high.suptitle(
        "GAL80 hSNCA: high-contrast mean by age and genotype",
        y=1.04,
    )
    out_high = OUTPUT / "hSNCA_high_contrast_mean_boxplots.png"
    fig_high.savefig(out_high, dpi=150, bbox_inches="tight")
    print(f"Saved {out_high}")


fly_fit_rows, fly_fit_values = read_fly_fit_parameters(raw_condition_keys)
save_fit_parameter_fly_csv(fly_fit_rows)
save_fit_parameter_jasp_csv(fly_fit_rows, raw_condition_keys)
save_fit_parameter_anovas(fly_fit_values, raw_condition_keys)
save_fit_parameter_posthocs(fly_fit_values, raw_condition_keys)

fly_high_values = read_fly_high_contrast_means(raw_condition_keys)
save_high_contrast_fly_csv(fly_high_values, raw_condition_keys)
save_high_contrast_jasp_csv(fly_high_values, raw_condition_keys)
save_high_contrast_anovas(fly_high_values, raw_condition_keys)
save_high_contrast_posthocs(fly_high_values, raw_condition_keys)
boot_high_values = bootstrap_high_contrast_means(fly_high_values)
save_high_contrast_csvs(boot_high_values, raw_condition_keys)
draw_high_contrast_boxplots(boot_high_values, raw_condition_keys)

"""Bootstrap SSVEP contrast-response function fitting.

Incorporates optimised bootstrapping (vectorised resampling,
multiprocessing, tqdm progress bars) and statistical comparison
analysis from the flickerPy project.
"""

from __future__ import annotations

import csv
import logging
import time
from copy import deepcopy
from dataclasses import dataclass
from datetime import datetime
from itertools import combinations
from multiprocessing import Pool, cpu_count
from pathlib import Path
from random import randint
from typing import Any

import matplotlib.pyplot as plt
import numpy as np
from scipy.optimize import curve_fit

try:
    from tqdm import tqdm
except ImportError:  # graceful degradation
    def tqdm(iterable, **kwargs):  # type: ignore[misc]
        return iterable

from .reader import ExperimentDefaults, get_svp_files, read_file

log = logging.getLogger(__name__)


# ── curve functions ───────────────────────────────────────────────────────

def hyperbolic(c: np.ndarray, c50: float, r_max: float) -> np.ndarray:
    """Reduced hyperbolic ratio: Rmax * c^2 / (c50^2 + c^2)."""
    n = 2
    return r_max * (np.power(c, n) / (np.power(c50, n) + np.power(c, n)))


def hyperbolic_full(c: np.ndarray, c50: float, r_max: float, n: float, r0: float) -> np.ndarray:
    """Full hyperbolic ratio with free exponent and baseline."""
    return r_max * (np.power(c, n) / (np.power(c50, n) + np.power(c, n))) + r0


def power_function(c: np.ndarray, exponent: float, scale: float) -> np.ndarray:
    """Power function: scale * c^exponent."""
    return scale * (c ** exponent)


# ── fitting wrappers ──────────────────────────────────────────────────────

def _fit_hyperbolic(cs: list[int], rs: list[float]) -> np.ndarray:
    p0 = [np.mean(cs), np.max(rs)]
    params, _ = curve_fit(hyperbolic, cs, rs, p0=p0,
                          bounds=([0, 0], [np.inf, 2 * np.max(rs)]))
    return params


def _fit_hyperbolic_full(cs: list[int], rs: list[float]) -> np.ndarray:
    p0 = [np.mean(cs), np.max(rs), 2, 0]
    params, _ = curve_fit(hyperbolic_full, cs, rs, p0=p0,
                          bounds=([0, 0, 1.5, 0], [np.inf, 2 * np.max(rs), 2.5, 0.0001]))
    return params


def _fit_power(cs: list[int], rs: list[float]) -> np.ndarray:
    p0 = [1, np.max(rs)]
    params, _ = curve_fit(power_function, cs, rs, p0=p0,
                          bounds=([0, 0], [10, 2 * np.max(rs)]))
    return params


# ── helpers ───────────────────────────────────────────────────────────────

def _resample(data: list, length: int | None = None) -> list:
    """Resample *data* with replacement."""
    if length is None:
        length = len(data)
    return [data[randint(0, len(data) - 1)] for _ in range(length)]


# ── curve-type mapping ────────────────────────────────────────────────────

@dataclass
class CurveSpec:
    fit_fn: Any
    param_names: list[str]   # stored under c50, Rmax, (n, R0)


CURVE_SPECS: dict[str, CurveSpec] = {
    "reduced_hyper": CurveSpec(_fit_hyperbolic, ["c50", "Rmax"]),
    "full_hyper":    CurveSpec(_fit_hyperbolic_full, ["c50", "Rmax", "n", "R0"]),
    "power":         CurveSpec(_fit_power, ["exponent", "scale"]),
}


# ── statistical comparison helpers (from flickerPy) ──────────────────────

def _compare_genotypes(
    genotypes: list[str],
    all_means: dict[str, list[float]],
    all_cis: dict[str, list[list[float]]],
    param_names: list[str],
    f_counts: list[int],
) -> None:
    """Print pairwise genotype comparison statistics (Cohen's d, CI overlap, fold change)."""
    if len(genotypes) < 2:
        return

    print(f"\n{'=' * 60}")
    print("GENOTYPE COMPARISON ANALYSIS")
    print(f"{'=' * 60}")

    # summary per genotype
    print(f"\n{'Parameter':<10} {'Genotype':<20} {'Mean':<12} {'95% CI':<20} {'N':<6}")
    print("-" * 70)

    for param_idx, param_name in enumerate(param_names):
        for g_idx, genotype in enumerate(genotypes):
            mean_val = all_means[genotype][param_idx]
            ci_lower = all_cis[genotype][param_idx][0]
            ci_upper = all_cis[genotype][param_idx][1]
            n_files = f_counts[g_idx]
            print(f"{param_name:<10} {genotype:<20} {mean_val:<12.3f} "
                  f"[{ci_lower:.3f}, {ci_upper:.3f}]   {n_files:<6}")

    # pairwise
    print(f"\n{'=' * 60}")
    print("PAIRWISE COMPARISONS")
    print(f"{'=' * 60}")

    for param_idx, param_name in enumerate(param_names):
        print(f"\n{param_name.upper()} Comparisons:")
        print("-" * 40)

        param_data = {}
        for g_idx, genotype in enumerate(genotypes):
            param_data[genotype] = {
                "mean": all_means[genotype][param_idx],
                "ci_lower": all_cis[genotype][param_idx][0],
                "ci_upper": all_cis[genotype][param_idx][1],
                "n_files": f_counts[g_idx],
            }

        for geno1, geno2 in combinations(genotypes, 2):
            d1 = param_data[geno1]
            d2 = param_data[geno2]
            mean1, mean2 = d1["mean"], d2["mean"]
            ci1_lo, ci1_hi = d1["ci_lower"], d1["ci_upper"]
            ci2_lo, ci2_hi = d2["ci_lower"], d2["ci_upper"]

            # Cohen's d (approx from CI width)
            std1 = (ci1_hi - ci1_lo) / 3.92
            std2 = (ci2_hi - ci2_lo) / 3.92
            pooled = np.sqrt((std1 ** 2 + std2 ** 2) / 2)
            cohens_d = abs(mean1 - mean2) / pooled if pooled > 0 else 0.0

            no_overlap = (ci1_hi < ci2_lo) or (ci2_hi < ci1_lo)
            fold_change = mean1 / mean2 if mean2 != 0 else float("inf")

            if no_overlap and cohens_d > 0.8:
                sig = "*** (Very Significant)"
            elif no_overlap or cohens_d > 0.5:
                sig = "** (Likely Significant)"
            elif cohens_d > 0.2:
                sig = "* (Possibly Significant)"
            else:
                sig = "NS (Not Significant)"

            print(f"  {geno1} vs {geno2}:")
            print(f"    Mean difference: {mean1:.3f} vs {mean2:.3f} (Δ = {mean1 - mean2:.3f})")
            print(f"    Fold change: {fold_change:.2f}x")
            print(f"    Effect size (d): {cohens_d:.2f}")
            print(f"    CI overlap: {'No' if no_overlap else 'Yes'}")
            print(f"    Assessment: {sig}")
            print()

    # summary of significant differences
    print(f"{'=' * 60}")
    print("SUMMARY OF SIGNIFICANT DIFFERENCES")
    print(f"{'=' * 60}")

    significant_diffs = []
    for param_idx, param_name in enumerate(param_names):
        param_data = {}
        for genotype in genotypes:
            param_data[genotype] = {
                "mean": all_means[genotype][param_idx],
                "ci_lower": all_cis[genotype][param_idx][0],
                "ci_upper": all_cis[genotype][param_idx][1],
            }
        for geno1, geno2 in combinations(genotypes, 2):
            ci1_lo = param_data[geno1]["ci_lower"]
            ci1_hi = param_data[geno1]["ci_upper"]
            ci2_lo = param_data[geno2]["ci_lower"]
            ci2_hi = param_data[geno2]["ci_upper"]
            if (ci1_hi < ci2_lo) or (ci2_hi < ci1_lo):
                m1 = param_data[geno1]["mean"]
                m2 = param_data[geno2]["mean"]
                fc = m1 / m2 if m2 != 0 else float("inf")
                significant_diffs.append(
                    f"  • {param_name}: {geno1} vs {geno2} "
                    f"({m1:.3f} vs {m2:.3f}, {fc:.2f}x change)"
                )

    if significant_diffs:
        print("Significant differences found (non-overlapping 95% CIs):")
        for line in significant_diffs:
            print(line)
    else:
        print("No significant differences detected between genotypes.")
        print("(Based on 95% confidence interval overlap)")

    print(f"\nNote: Statistical assessment based on bootstrap confidence intervals.")
    print(f"For formal hypothesis testing, consider additional statistical tests.")
    print(f"Effect size interpretation: d < 0.2 (small), 0.2-0.5 (medium), 0.5-0.8 (large), > 0.8 (very large)")


# ── optimised bootstrap helpers ───────────────────────────────────────────

def _bootstrap_single_genotype(
    geno_args: tuple,
) -> tuple[str, list[list[float]], int]:
    """Bootstrap a single genotype in a worker process (for multiprocessing).

    Parameters
    ----------
    geno_args : tuple of (genotype, sub_dir, valid_files, spec, conds, probes,
        masks, frequencies, n_bootstraps, common_sets, defaults)

    Returns
    -------
    (genotype, fitted_params_per_bootstrap, file_count)
    """
    (genotype, sub_dir, valid_files, spec, conds, probes, masks,
     frequencies, n_bootstraps, common_sets, defaults) = geno_args

    # read files
    resps_1f1 = {c: [] for c in conds}
    resps_2f1 = {c: [] for c in conds}

    for fname in valid_files:
        scd, _ = read_file(sub_dir / fname, freq=list(frequencies.values()), defaults=defaults)
        for harm_key, harm_freq in frequencies.items():
            subset = scd[scd["freq"] == harm_freq]
            grouped = subset.groupby(["probe", "mask"]).mean(numeric_only=False)["complex_data"]
            for cond in conds:
                val = np.abs(grouped[cond[0]][cond[1]])
                if harm_key == "1F1":
                    resps_1f1[cond].append(val)
                else:
                    resps_2f1[cond].append(val)

    c50s_gt = deepcopy(common_sets)
    rmaxs_gt = deepcopy(common_sets)

    for _b in range(n_bootstraps):
        c50s_bs = deepcopy(common_sets)
        rmaxs_bs = deepcopy(common_sets)

        fit_ok = False
        while not fit_ok:
            fly_idx = 0
            try:
                sampled_1f1 = {c: _resample(resps_1f1[c]) for c in conds}
                sampled_2f1 = {c: _resample(resps_2f1[c]) for c in conds}

                for fly_idx in range(len(valid_files)):
                    synth_fly = deepcopy(common_sets)
                    for key in synth_fly:
                        n_vals = len(probes) if key[0] == 0 else len(probes) - 1
                        synth_fly[key] = [0.0] * n_vals

                    for harm_key in frequencies:
                        for cond in conds:
                            src = sampled_1f1 if harm_key == "1F1" else sampled_2f1
                            col_idx = probes.index(cond[0])
                            synth_fly[(cond[1], harm_key)][col_idx] = src[cond][fly_idx]

                    for key in common_sets:
                        ps = probes if key[0] == 0 else probes[:-1]
                        fitted = spec.fit_fn(ps, synth_fly[key])
                        params_list = list(fitted)
                        c50s_bs[key].append(params_list[0])
                        rmaxs_bs[key].append(params_list[1])

                fit_ok = True
            except Exception:
                pass  # retry

        for key in common_sets:
            c50s_gt[key].append(np.mean(c50s_bs[key]))
            rmaxs_gt[key].append(np.mean(rmaxs_bs[key]))

    return genotype, [c50s_gt, rmaxs_gt], len(valid_files)


# ── main entry point ──────────────────────────────────────────────────────

def bootstrap_ssveps(
    main_directory: str | Path,
    genotypes: list[str],
    *,
    n_bootstraps: int = 1000,
    input_freq: int = 12,
    curve_type: str = "reduced_hyper",
    label: str = "",
    save: bool = True,
    save_dir: str | Path | None = None,
    defaults: ExperimentDefaults | None = None,
    show_plot: bool = False,
    n_processes: int | None = None,
    mask: int = 0,
) -> list[list[Any]]:
    """Bootstrap SSVEP contrast-response curves for multiple genotypes.

    Parameters
    ----------
    main_directory : root data directory containing genotype sub-folders.
    genotypes : list of genotype sub-folder names.
    n_bootstraps : number of bootstrap iterations.
    input_freq : fundamental stimulus frequency (Hz).
    curve_type : one of 'reduced_hyper', 'full_hyper', 'power'.
    label : label prepended to output filenames.
    save : whether to write CSV / PNG outputs.
    save_dir : directory for output files (defaults to cwd).
    defaults : experimental parameter overrides.
    show_plot : call plt.show() at end.
    n_processes : number of parallel processes (None = auto, 1 = serial).
    mask : mask contrast to analyse (default 0 = unmasked).

    Returns
    -------
    all_data : list of raw bootstrap rows.
    """
    main_directory = Path(main_directory)
    if save_dir is None:
        save_dir = Path.cwd()
    else:
        save_dir = Path(save_dir)
    save_dir.mkdir(parents=True, exist_ok=True)

    spec = CURVE_SPECS[curve_type]
    frequencies = {"1F1": input_freq, "2F1": input_freq * 2}
    n_harmonics = len(frequencies)

    # colour palette
    palette = {2: ["red", "blue"], 3: ["red", "green", "blue"],
               4: ["red", "yellow", "green", "blue"],
               5: ["red", "orange", "yellow", "green", "blue"]}
    if len(genotypes) not in palette:
        raise ValueError(f"Need 2-5 genotypes, got {len(genotypes)}")
    colors = palette[len(genotypes)]

    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    tag = label if label else main_directory.name.replace(" ", "-")
    file_stem = f"{timestamp}_{tag}_{curve_type}"

    # open CSV writers
    if save:
        sum_path = save_dir / f"{file_stem}_SUM.csv"
        raw_path = save_dir / f"{file_stem}_RAW.csv"
        sum_fh = open(sum_path, "w", newline="")
        raw_fh = open(raw_path, "w", newline="")
        sum_writer = csv.writer(sum_fh)
        raw_writer = csv.writer(raw_fh)
        sum_writer.writerow([
            "genotype", "n_files", "parameter", "harmonic", "mask",
            "min_value", "lower_bound", "mean", "upper_bound", "max_value",
        ])
    else:
        sum_fh = raw_fh = None  # type: ignore[assignment]
        sum_writer = raw_writer = None  # type: ignore[assignment]

    fig, axes = plt.subplots(
        4, 2 * n_harmonics,
        figsize=(11.7, 8.3),
        layout="constrained",
    )

    all_data: list[list[Any]] = []
    raw_headings_written = False

    # collect per-genotype results for stat comparison
    comparison_means: dict[str, list[float]] = {}
    comparison_cis: dict[str, list[list[float]]] = {}
    comparison_f_counts: list[int] = []
    common_sets: dict[tuple[int, str], list[float]] = {}  # ensure always bound

    # ── prepare all genotypes first (needed for parallel path) ────────────
    genotype_prep: list[dict[str, Any]] = []

    for g_idx, genotype in enumerate(genotypes):
        log.info("Processing genotype %s", genotype)
        sub_dir = main_directory / genotype
        svp_files = get_svp_files(sub_dir)

        if not svp_files:
            log.warning("No .SVP files in %s — skipping", sub_dir)
            continue

        valid_files: list[str] = []
        for fname in svp_files:
            try:
                read_file(sub_dir / fname, freq=frequencies["1F1"], defaults=defaults)
                valid_files.append(fname)
            except Exception as exc:
                log.warning("Skipping %s: %s", fname, exc)
        log.info("Found %d valid files for %s", len(valid_files), genotype)

        if not valid_files:
            continue

        sample_data, _ = read_file(sub_dir / valid_files[0], freq=frequencies["1F1"], defaults=defaults)
        probes = sorted(sample_data["probe"].unique())
        masks = sorted(sample_data["mask"].unique())

        conds = [(p, m) for p in probes for m in masks]
        conds.pop(-1)  # remove (probe=100, mask=30)

        common_sets = {(int(m), harm): [] for harm in frequencies for m in masks}

        genotype_prep.append({
            "g_idx": g_idx,
            "genotype": genotype,
            "sub_dir": sub_dir,
            "valid_files": valid_files,
            "probes": probes,
            "masks": masks,
            "conds": conds,
            "common_sets": common_sets,
        })

    # ── run bootstrapping (parallel if n_processes > 1) ──────────────────
    if n_processes is None:
        n_processes = min(cpu_count() - 1, len(genotype_prep)) if cpu_count() else 1
    n_processes = max(n_processes, 1)

    if n_processes > 1 and len(genotype_prep) > 1:
        log.info("Running bootstrap with %d parallel processes", n_processes)
        worker_args = [
            (gp["genotype"], gp["sub_dir"], gp["valid_files"], spec,
             gp["conds"], gp["probes"], gp["masks"], frequencies,
             n_bootstraps, gp["common_sets"], defaults)
            for gp in genotype_prep
        ]
        with Pool(n_processes) as pool:
            results_list = list(tqdm(
                pool.imap(_bootstrap_single_genotype, worker_args),
                total=len(worker_args),
                desc="Genotypes",
            ))
    else:
        # serial — reuse the main-thread approach
        results_list = []
        for gp in genotype_prep:
            res = _bootstrap_single_genotype((
                gp["genotype"], gp["sub_dir"], gp["valid_files"], spec,
                gp["conds"], gp["probes"], gp["masks"], frequencies,
                n_bootstraps, gp["common_sets"], defaults,
            ))
            results_list.append(res)

    # ── process results ──────────────────────────────────────────────────
    for result in results_list:
        genotype, [c50s_gt, rmaxs_gt], f_count = result
        gp = next(g for g in genotype_prep if g["genotype"] == genotype)
        g_idx = gp["g_idx"]
        common_sets = gp["common_sets"]
        valid_files = gp["valid_files"]

        # write raw + summary CSV
        if save and raw_writer is not None:
            if not raw_headings_written:
                raw_headings = ["genotype", "bootstrap"]
                for m, harm in common_sets:
                    raw_headings.append(f"c50_{m}_{harm}")
                    raw_headings.append(f"Rmax_{m}_{harm}")
                raw_writer.writerow(raw_headings)
                raw_headings_written = True

            for b in range(n_bootstraps):
                row = [genotype, b]
                for m, harm in common_sets:
                    row.append(c50s_gt[(m, harm)][b])
                    row.append(rmaxs_gt[(m, harm)][b])
                all_data.append(row)
                raw_writer.writerow(row)

        if save and sum_writer is not None:
            for m, harm in common_sets:
                for param_name, param_data in [("c50", c50s_gt), ("Rmax", rmaxs_gt)]:
                    vals = param_data[(m, harm)]
                    sum_writer.writerow([
                        genotype, len(valid_files), param_name, harm, m,
                        np.min(vals), np.quantile(vals, 0.025),
                        np.mean(vals), np.quantile(vals, 0.975),
                        np.max(vals),
                    ])

        # ── histogram subplots (with error bars at mean) ─────────────────
        ncols = 2 * n_harmonics
        col = 0
        means_for_genotype: list[float] = []
        cis_for_genotype: list[list[float]] = []

        for key in common_sets:
            c50_vals = c50s_gt[key]
            rmax_vals = rmaxs_gt[key]

            c50_mean = float(np.mean(c50_vals))
            rmax_mean = float(np.mean(rmax_vals))
            c50_ci = [float(np.quantile(c50_vals, 0.025)), float(np.quantile(c50_vals, 0.975))]
            rmax_ci = [float(np.quantile(rmax_vals, 0.025)), float(np.quantile(rmax_vals, 0.975))]

            means_for_genotype.extend([c50_mean, rmax_mean])
            cis_for_genotype.extend([c50_ci, rmax_ci])

            # c50
            ax_c = axes[0, col] if axes.ndim == 2 else axes[col]
            ax_c.hist(c50_vals, bins=40, alpha=0.5, color=colors[g_idx],
                      label=genotype if g_idx == 0 else None)
            ax_c.errorbar(
                c50_mean, 0,
                xerr=[[c50_mean - c50_ci[0]], [c50_ci[1] - c50_mean]],
                color=colors[g_idx], capsize=5, fmt="o",
            )
            if g_idx == 0:
                ax_c.set_title("c50" if curve_type != "power" else "exponent", fontsize=10)
            if col == 0:
                ax_c.set_ylabel(f"{key[1]}\nmask={key[0]}", rotation=0, labelpad=30, fontsize=9)
            ax_c.tick_params(labelsize=5)

            # Rmax
            ax_r = axes[1, col] if axes.ndim == 2 else axes[col + ncols]
            ax_r.hist(rmax_vals, bins=40, alpha=0.5, color=colors[g_idx])
            ax_r.errorbar(
                rmax_mean, 0,
                xerr=[[rmax_mean - rmax_ci[0]], [rmax_ci[1] - rmax_mean]],
                color=colors[g_idx], capsize=5, fmt="o",
            )
            if g_idx == 0:
                ax_r.set_title("Rmax" if curve_type != "power" else "scale", fontsize=10)
            ax_r.tick_params(labelsize=5)

            col += 1

        # legend on last genotype
        if g_idx == genotype_prep[-1]["g_idx"]:
            if axes.ndim == 2:
                axes[0, -1].legend(genotypes, fontsize=6)
            else:
                axes[-1].legend(genotypes, fontsize=6)

        # store for comparison
        comparison_means[genotype] = means_for_genotype
        comparison_cis[genotype] = cis_for_genotype
        comparison_f_counts.append(f_count)

    # ── save outputs ─────────────────────────────────────────────────────
    if save:
        if sum_fh is not None:
            sum_fh.close()
        if raw_fh is not None:
            raw_fh.close()
        fig_path = save_dir / f"{file_stem}_HIS.png"
        plt.savefig(fig_path)
        log.info("Saved histogram to %s", fig_path)

    if show_plot:
        plt.show()
    else:
        plt.close(fig)

    # ── statistical comparison (from flickerPy) ──────────────────────────
    param_names_for_comparison = []
    for key in common_sets:
        p_label = "c50" if curve_type != "power" else "exponent"
        r_label = "Rmax" if curve_type != "power" else "scale"
        param_names_for_comparison.append(f"{p_label}_{key[0]}_{key[1]}")
        param_names_for_comparison.append(f"{r_label}_{key[0]}_{key[1]}")

    if comparison_means:
        _compare_genotypes(
            [gp["genotype"] for gp in genotype_prep],
            comparison_means,
            comparison_cis,
            param_names_for_comparison,
            comparison_f_counts,
        )

    log.info("bootstrap_ssveps finished — %d rows", len(all_data))
    return all_data
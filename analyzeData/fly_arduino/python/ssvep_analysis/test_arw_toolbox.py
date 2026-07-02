#!/usr/bin/env python3
"""Self-contained checks for the general ``arw_`` toolbox.

Unlike the other ``test_*`` scripts, this one needs no external data: it builds
a synthetic observations table with a known genotype effect and exercises the
fitting, statistics, and plotting functions end to end. Run with::

    .venv/bin/python test_arw_toolbox.py
"""
from __future__ import annotations

import sys
sys.path.insert(0, "src")

import tempfile
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import numpy as np
import pandas as pd

from ssvep_analysis.arw_toolbox import (
    ArwAnalysisConfig,
    arw_anova_table,
    arw_derive_high_contrast,
    arw_fit_observations,
    arw_p_to_stars,
    arw_plot_anova_summary,
    arw_plot_crfs,
    arw_plot_fit_parameter_boxplots,
    arw_plot_high_contrast_boxplots,
    arw_tukey_posthoc,
)

PROBES = [5, 10, 30, 70, 100]
GENOTYPES = ["CTRL", "MUT"]
TIMEPOINTS = ["7dpe", "28dpe"]
# MUT has a markedly higher Rmax so the genotype main effect must be significant.
RMAX = {"CTRL": 20.0, "MUT": 55.0}
C50 = 30.0
N_FLIES = 12


def _hyperbolic(contrast: np.ndarray, c50: float, rmax: float) -> np.ndarray:
    return rmax * (contrast ** 2 / (c50 ** 2 + contrast ** 2))


def make_observations(seed: int = 7) -> pd.DataFrame:
    rng = np.random.default_rng(seed)
    rows = []
    for tp_idx, timepoint in enumerate(TIMEPOINTS):
        age_days = int(timepoint.replace("dpe", ""))
        for genotype in GENOTYPES:
            for fly_idx in range(N_FLIES):
                subject_id = f"{genotype}_{timepoint}_{fly_idx:02d}"
                fly_gain = rng.normal(1.0, 0.12)
                for harmonic, freq in (("1F1", 12), ("2F1", 24)):
                    scale = 1.0 if harmonic == "1F1" else 0.4
                    for probe in PROBES:
                        clean = _hyperbolic(np.array(float(probe)), C50, RMAX[genotype])
                        amp = float(scale * fly_gain * clean + rng.normal(0, 1.5))
                        rows.append({
                            "subject_id": subject_id,
                            "directory": f"{genotype}_{timepoint}",
                            "source_file": f"{subject_id}.SVP",
                            "genotype": genotype,
                            "timepoint": timepoint,
                            "age_days": age_days,
                            "fly_index": fly_idx,
                            "harmonic": harmonic,
                            "frequency_hz": freq,
                            "mask": "0",
                            "probe": probe,
                            "amplitude": max(amp, 0.0),
                        })
    return pd.DataFrame(rows)


def check_stars():
    assert arw_p_to_stars(1e-5) == "****"
    assert arw_p_to_stars(0.005) == "**"
    assert arw_p_to_stars(0.2) == "ns"
    assert arw_p_to_stars(float("nan")) == ""
    print("  ok: p_to_stars notation")


def check_stats(observations):
    high_contrast = arw_derive_high_contrast(observations, n_contrasts=2)
    assert not high_contrast.empty
    assert {"genotype", "timepoint", "value"} <= set(high_contrast.columns)

    fit_parameters = arw_fit_observations(observations, fit_types=("reduced_hyper", "fixed_c50_hyper"))
    assert not fit_parameters.empty
    reduced = fit_parameters[fit_parameters["fit_type"] == "reduced_hyper"]
    fixed = fit_parameters[fit_parameters["fit_type"] == "fixed_c50_hyper"]
    assert set(reduced["parameter"]) == {"c50", "Rmax"}
    assert set(fixed["parameter"]) == {"Rmax"}

    anova = arw_anova_table(
        high_contrast,
        ["metric", "harmonic", "mask"],
        genotype_order=GENOTYPES,
        timepoint_order=TIMEPOINTS,
    )
    effects = set(anova["effect"])
    assert {"genotype", "timepoint", "genotype:timepoint"} <= effects
    geno_1f1 = anova[(anova["effect"] == "genotype") & (anova["harmonic"] == "1F1")]
    assert float(geno_1f1["p"].iloc[0]) < 0.001, "planted genotype effect should be significant"

    posthoc = arw_tukey_posthoc(
        high_contrast,
        ["metric", "harmonic", "mask"],
        genotype_order=GENOTYPES,
        timepoint_order=TIMEPOINTS,
    )
    assert not posthoc.empty
    assert bool(posthoc["significant_0_05"].any())
    print(
        f"  ok: stats — genotype p={float(geno_1f1['p'].iloc[0]):.2e}, "
        f"{int(posthoc['significant_0_05'].sum())} significant post-hoc pairs"
    )
    return high_contrast, fit_parameters, anova, posthoc


def check_plots(observations, high_contrast, fit_parameters, anova, posthoc):
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp)
        config = ArwAnalysisConfig(
            data_dir=".",
            output_dir=out,
            genotype_order=GENOTYPES,
            timepoint_order=TIMEPOINTS,
            crf_bootstrap_n=40,
        )
        crf = arw_plot_crfs(observations, config, output_path=out / "crf.png")
        assert crf.exists() and crf.stat().st_size > 0
        crf_fixed = arw_plot_crfs(
            observations,
            config,
            output_path=out / "crf_fixed.png",
            overlay_fit_type="fixed_c50_hyper",
        )
        assert crf_fixed.exists() and crf_fixed.stat().st_size > 0

        box = arw_plot_high_contrast_boxplots(
            high_contrast, posthoc, config, output_path=out / "hc_box.png", anova=anova,
        )
        assert box is not None and box.exists()

        fit_box = arw_plot_fit_parameter_boxplots(
            fit_parameters, posthoc, config,
            fit_type="reduced_hyper", output_path=out / "fit_box.png", anova=anova,
        )
        assert fit_box is not None and fit_box.exists()

        anova_plot = arw_plot_anova_summary(
            anova, ["harmonic", "mask"],
            lambda group: f"{group[0]} · mask {group[1]}",
            output_path=out / "anova.png", title="synthetic ANOVA",
        )
        assert anova_plot is not None and anova_plot.exists()
        print("  ok: plots — CRF band, boxplots, ANOVA heatmap all written")


def main():
    print("=" * 60)
    print("arw_toolbox self-contained checks (synthetic data)")
    print("=" * 60)
    observations = make_observations()
    print(f"  synthetic observations: {len(observations)} rows, "
          f"{observations['subject_id'].nunique()} flies")
    check_stars()
    high_contrast, fit_parameters, anova, posthoc = check_stats(observations)
    check_plots(observations, high_contrast, fit_parameters, anova, posthoc)
    print("ALL CHECKS PASSED")


if __name__ == "__main__":
    main()

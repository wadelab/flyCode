#!/usr/bin/env python3
"""Apply the general ``arw_`` toolbox to the GAL80 hSNCA dataset.

This is a thin, reproducible wrapper around
:func:`ssvep_analysis.arw_toolbox.arw_analyze_directory`. All processing,
fitting, statistics, and plotting logic lives in the toolbox; this script only
pins the hSNCA-specific ordering and colours.

Run from the package root::

    .venv/bin/python run_hsnca_arw.py
"""
from __future__ import annotations

import sys
sys.path.insert(0, "src")

import matplotlib
matplotlib.use("Agg")

from pathlib import Path

from ssvep_analysis.arw_toolbox import ArwAnalysisConfig, arw_analyze_directory

DATA_DIR = Path("/raid/data/SITRAN/GAL80_hSNCA-raw")
OUTPUT = Path("output/hSNCA_arw")

# Control first, then increasing-severity synucleinopathies; black + colour-blind
# safe blue/green/vermillion (Okabe-Ito).
GENOTYPE_ORDER = ["GAL80LACZ", "GAL80SNCAWT", "GAL80A53T", "GAL80A30P"]
GENOTYPE_COLORS = ["#1f1f1f", "#0072B2", "#009E73", "#D55E00"]
TIMEPOINT_ORDER = ["7dpe", "14dpe", "21dpe", "28dpe", "35dpe"]


def main() -> None:
    config = ArwAnalysisConfig(
        data_dir=DATA_DIR,
        output_dir=OUTPUT,
        output_prefix="hSNCA",
        input_freq=12,
        fit_types=("reduced_hyper", "power", "full_hyper"),
        high_contrast_n=2,
        genotype_order=GENOTYPE_ORDER,
        timepoint_order=TIMEPOINT_ORDER,
        colors=GENOTYPE_COLORS,
    )
    result = arw_analyze_directory(config=config)

    print(f"Flies processed:     {result.observations['subject_id'].nunique()}")
    print(f"Observation rows:    {len(result.observations)}")
    print(f"High-contrast rows:  {len(result.high_contrast)}")
    print(f"Fit-parameter rows:  {len(result.fit_parameters)}")
    failures = result.observations.attrs.get("read_failures", [])
    if failures:
        print(f"Unreadable files:    {len(failures)}")
    print("\nOutputs:")
    for key, path in sorted(result.paths.items()):
        print(f"  {key}: {path}")


if __name__ == "__main__":
    main()

"""Command-line interface for SSVEP bootstrap analysis."""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path

from .bootstrap import bootstrap_ssveps
from .reader import ExperimentDefaults


def _build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="ssvep-analyse",
        description="Bootstrap SSVEP contrast-response function analysis for fly electrophysiology data.",
    )
    p.add_argument("data_dir", type=Path, help="Root data directory containing genotype sub-folders.")
    p.add_argument("genotypes", nargs="+", help="Genotype sub-folder names to analyse.")
    p.add_argument("-n", "--n-bootstraps", type=int, default=1000, help="Number of bootstrap iterations (default: 1000).")
    p.add_argument("-f", "--freq", type=int, default=12, help="Fundamental stimulus frequency in Hz (default: 12).")
    p.add_argument("-c", "--curve", choices=["reduced_hyper", "full_hyper", "power"], default="reduced_hyper",
                   help="Curve type to fit (default: reduced_hyper).")
    p.add_argument("-l", "--label", default="", help="Label for output file names.")
    p.add_argument("-o", "--output-dir", type=Path, default=None, help="Directory for output files (default: cwd).")
    p.add_argument("--mask", type=int, default=0, help="Mask contrast to analyse (default: 0 = unmasked).")
    p.add_argument("--n-processes", type=int, default=None,
                   help="Number of parallel processes for bootstrapping (default: auto-detect).")
    p.add_argument("--no-save", action="store_true", help="Skip writing CSV/PNG output files.")
    p.add_argument("--show-plot", action="store_true", help="Show matplotlib plot window.")
    p.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging.")
    return p


def main(argv: list[str] | None = None) -> None:
    """Entry point for the ``ssvep-analyse`` CLI command."""
    args = _build_parser().parse_args(argv)

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s: %(message)s",
    )

    bootstrap_ssveps(
        main_directory=args.data_dir,
        genotypes=args.genotypes,
        n_bootstraps=args.n_bootstraps,
        input_freq=args.freq,
        curve_type=args.curve,
        label=args.label,
        save=not args.no_save,
        save_dir=args.output_dir,
        show_plot=args.show_plot,
        n_processes=args.n_processes,
        mask=args.mask,
    )


if __name__ == "__main__":
    main()

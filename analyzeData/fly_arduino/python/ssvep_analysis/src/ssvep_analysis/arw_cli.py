"""Command-line interface for the general ``arw_`` analysis toolbox."""

from __future__ import annotations

import argparse
import logging
from pathlib import Path

from .bootstrap import CURVE_SPECS
from .arw_toolbox import ArwAnalysisConfig, arw_analyze_directory


def _csv_list(value: str | None) -> list[str] | None:
    if value is None:
        return None
    items = [item.strip() for item in value.split(",") if item.strip()]
    return items or None


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="arw-analyse",
        description=(
            "General arw_ SSVEP toolbox: process SVP subdirectories, fit CRFs, "
            "write stats, and plot fitted/derived parameters."
        ),
    )
    parser.add_argument("data_dir", type=Path, help="Root directory containing SVP subdirectories.")
    parser.add_argument("-o", "--output-dir", type=Path, default=Path("output/arw"), help="Output directory.")
    parser.add_argument("-p", "--prefix", default=None, help="Output filename prefix (default: arw_<data-dir>).")
    parser.add_argument("-f", "--freq", type=int, default=12, help="Fundamental frequency in Hz (default: 12).")
    parser.add_argument(
        "--fit-types",
        nargs="+",
        default=["reduced_hyper", "power", "full_hyper", "fixed_c50_hyper"],
        choices=sorted(CURVE_SPECS),
        help="Curve families to fit per fly.",
    )
    parser.add_argument(
        "--high-contrast-n",
        type=int,
        default=2,
        help="Number of highest probe contrasts to average for the derived metric.",
    )
    parser.add_argument(
        "--subdirs",
        default=None,
        help="Comma-separated subdirectory names to include. Defaults to all direct SVP-containing subdirs.",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Search recursively for SVP-containing directories.",
    )
    parser.add_argument(
        "--genotype-order",
        default=None,
        help="Comma-separated genotype order for stats and plots.",
    )
    parser.add_argument(
        "--timepoint-order",
        default=None,
        help="Comma-separated timepoint order for stats and plots.",
    )
    parser.add_argument("--no-plots", action="store_true", help="Write CSV outputs only.")
    parser.add_argument("--no-observations", action="store_true", help="Skip the large observations CSV.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Enable verbose logging.")
    return parser


def main(argv: list[str] | None = None) -> None:
    args = _build_parser().parse_args(argv)
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s: %(message)s",
    )

    config = ArwAnalysisConfig(
        data_dir=args.data_dir,
        output_dir=args.output_dir,
        output_prefix=args.prefix,
        input_freq=args.freq,
        fit_types=args.fit_types,
        high_contrast_n=args.high_contrast_n,
        subdirs=_csv_list(args.subdirs),
        recursive=args.recursive,
        genotype_order=_csv_list(args.genotype_order),
        timepoint_order=_csv_list(args.timepoint_order),
        make_plots=not args.no_plots,
        save_observations=not args.no_observations,
    )
    result = arw_analyze_directory(config=config)

    print(f"Processed {result.observations['subject_id'].nunique()} flies")
    print(f"Observation rows: {len(result.observations)}")
    print(f"High-contrast rows: {len(result.high_contrast)}")
    print(f"Fit-parameter rows: {len(result.fit_parameters)}")
    for key, path in sorted(result.paths.items()):
        print(f"{key}: {path}")


if __name__ == "__main__":
    main()

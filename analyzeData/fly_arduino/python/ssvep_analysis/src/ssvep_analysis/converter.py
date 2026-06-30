"""Convert .SVP files in a directory into a compressed numpy archive (.npz).

This is the ssvep_analysis equivalent of ``flickerPy/convertSVP.py``.
The resulting archive allows much faster repeated reads (no re-parsing text).

Usage from Python::

    from ssvep_analysis.converter import convert_svp_to_npz
    archive_path = convert_svp_to_npz("/path/to/genotype_dir", freq=12)

CLI::

    python -m ssvep_analysis.converter /path/to/genotype_dir --freq 12
"""

from __future__ import annotations

import argparse
import logging
import sys
from pathlib import Path
from typing import Any

import numpy as np

from .reader import ExperimentDefaults, get_svp_files, read_file

log = logging.getLogger(__name__)


def convert_svp_to_npz(
    sourcepath: str | Path,
    *,
    freq: int | list[int] = 12,
    defaults: ExperimentDefaults | None = None,
    verbose: bool = False,
    archive_name: str | None = None,
) -> Path | None:
    """Read every .SVP file in *sourcepath* and save as a single ``.npz``.

    Parameters
    ----------
    sourcepath : directory containing .SVP files.
    freq : frequency (or list of frequencies) to extract FFT amplitudes for.
    defaults : experimental parameter overrides.
    verbose : print progress information.
    archive_name : custom name for the archive file (default: auto-generated).

    Returns
    -------
    Path to the created archive, or *None* if no valid files were found.
    """
    sourcepath = Path(sourcepath)
    if not sourcepath.is_dir():
        log.error("Not a directory: %s", sourcepath)
        return None

    svp_files = get_svp_files(sourcepath)
    if not svp_files:
        log.warning("No .SVP files found in %s", sourcepath)
        return None

    log.info("Found %d .SVP files in %s", len(svp_files), sourcepath)

    all_scd: list[Any] = []
    all_md: list[Any] = []
    skipped_none = 0
    skipped_error = 0

    for fname in svp_files:
        filepath = sourcepath / fname
        try:
            scd, md = read_file(filepath, freq=freq, defaults=defaults, verbose=verbose)
            if scd is None or md is None:
                skipped_none += 1
                continue
            all_scd.append(scd)
            all_md.append(md)
        except Exception as exc:
            skipped_error += 1
            log.warning("Skipping %s: %s", fname, exc)

    log.info(
        "Processed %d files. Skipped: %d (errors), %d (None returns).",
        len(all_scd), skipped_error, skipped_none,
    )

    if not all_scd:
        log.error("No valid files could be processed in %s", sourcepath)
        return None

    # build archive name
    if archive_name is None:
        base = "".join(c for c in sourcepath.name if c.isalnum())
        archive_name = f"{base}_archive.npz"

    archive_path = sourcepath / archive_name
    np.savez_compressed(archive_path, scd=all_scd, md=all_md)
    log.info("Saved archive %s (%d entries)", archive_path, len(all_scd))
    return archive_path


def load_npz_archive(
    archive_path: str | Path,
) -> tuple[list[Any], list[Any]]:
    """Load a previously saved ``.npz`` archive.

    Returns
    -------
    (scd_all, md_all) : lists of per-file DataFrames and metadata dicts.
    """
    archive_path = Path(archive_path)
    data = np.load(archive_path, allow_pickle=True)

    if "scd" not in data or "md" not in data:
        raise ValueError(f"Archive {archive_path} missing required 'scd' and 'md' arrays")

    scd_all = [x for x in data["scd"] if x is not None]
    md_all = [x for x in data["md"] if x is not None]

    if not scd_all:
        raise ValueError(f"No valid data in archive {archive_path}")

    return scd_all, md_all


# ── CLI ───────────────────────────────────────────────────────────────────

def _main() -> None:
    parser = argparse.ArgumentParser(
        prog="ssvep-convert",
        description="Convert .SVP files to a compressed numpy archive (.npz).",
    )
    parser.add_argument("sourcepath", type=Path, help="Directory containing .SVP files")
    parser.add_argument("--freq", type=int, nargs="+", default=[12],
                        help="Frequency(ies) to extract (default: 12)")
    parser.add_argument("--verbose", action="store_true", help="Verbose output")

    args = parser.parse_args()
    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s: %(message)s",
    )

    freqs = args.freq if len(args.freq) > 1 else args.freq[0]
    result = convert_svp_to_npz(args.sourcepath, freq=freqs, verbose=args.verbose)
    if result is None:
        sys.exit(1)


if __name__ == "__main__":
    _main()
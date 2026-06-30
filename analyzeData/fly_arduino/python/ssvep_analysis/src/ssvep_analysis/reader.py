"""Read SVP / text / binary fly-arduino data files and extract FFT amplitudes."""

from __future__ import annotations

import logging
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

import numpy as np
import pandas as pd

log = logging.getLogger(__name__)


@dataclass
class ExperimentDefaults:
    """Defaults matching the JOTS NatSci 2023/24 rig."""
    num_trials: int = 45
    num_samples: int = 1024
    probes: list[int] = field(default_factory=lambda: [5, 10, 30, 70, 100])
    masks: list[int] = field(default_factory=lambda: [0, 30])
    sample_rate: int = 250      # Hz
    sample_interval_ms: int = 4  # ms


def _read_text_file(
    filepath: Path,
    num_trials: int,
    num_samples: int,
) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Read a text/SVP file using numpy (fast).  Raises on failure.

    Tries multiple header-skip values (1, 6, 12) to accommodate different
    Arduino software versions (flickerPy compatibility).
    """
    expected = num_trials * (num_samples + 1)
    last_exc: Exception | None = None
    for skip in (1, 6, 12):
        try:
            data = np.loadtxt(filepath, delimiter=",", skiprows=skip)  # shape (N, 3)
            if data.shape[0] == expected:
                times = data[:, 0].reshape(num_trials, num_samples + 1)
                stimuli = data[:, 1].reshape(num_trials, num_samples + 1)
                responses = data[:, 2].reshape(num_trials, num_samples + 1)
                return times, stimuli, responses
        except Exception as exc:
            last_exc = exc
            continue
    raise ValueError(
        f"Expected {expected} rows but could not read file with any skiprows value "
        f"(tried 1, 6, 12): {last_exc}"
    )


def _extract_metadata_from_file(filepath: Path) -> dict[str, Any]:
    """Extract GET-line metadata from a text file."""
    metadata: dict[str, Any] = {}
    try:
        with open(filepath) as fh:
            for line in fh:
                if "GET" in line:
                    parts = line.strip(" \n").split(",")
                    parts.pop(0)
                    for token in parts:
                        kv = token.split("=")
                        if len(kv) == 2:
                            metadata[kv[0]] = kv[1]
                    break
    except Exception as exc:
        log.warning("Could not parse metadata from %s: %s", filepath, exc)
    return metadata


def _extract_metadata_from_binary(filepath: Path) -> dict[str, Any]:
    """Extract metadata from a binary file header."""
    metadata: dict[str, Any] = {}
    try:
        with open(filepath, mode="rb") as fh:
            raw = str(fh.read(200)).split("&")
            for token in raw:
                parts = token.split("=")
                if len(parts) == 2:
                    key = parts[0].lstrip("'")
                    metadata[key] = parts[1]
    except Exception:
        pass
    return metadata


def read_file(
    filepath: str | Path,
    freq: int | list[int] = 12,
    defaults: ExperimentDefaults | None = None,
    verbose: bool = False,
) -> tuple[pd.DataFrame, dict[str, Any]]:
    """Read a single arduino data file and return FFT amplitudes at *freq* Hz.

    Parameters
    ----------
    filepath : path to a .SVP, .txt, .html, or binary arduino file.
    freq : stimulus frequency (Hz) to extract, or a list of frequencies.
    defaults : experimental parameters (uses JOTS 2023/24 defaults if *None*).
    verbose : print debug information.

    Returns
    -------
    sorted_data : DataFrame with columns [mask, probe, complex_data].
    metadata : dict of file metadata.
    """
    filepath = Path(filepath)
    if defaults is None:
        defaults = ExperimentDefaults()

    num_trials = defaults.num_trials
    num_samples = defaults.num_samples
    probes = defaults.probes
    masks = defaults.masks
    sr = defaults.sample_rate
    si = defaults.sample_interval_ms
    time_points = [si * i for i in range(num_samples)]

    # normalise freq to list
    if isinstance(freq, int):
        freqs = [freq]
    else:
        freqs = list(freq)

    metadata: dict[str, Any] = {}

    # ── try reading as text ───────────────────────────────────────────────
    try:
        times, stimuli, responses = _read_text_file(filepath, num_trials, num_samples)
        metadata = _extract_metadata_from_file(filepath)

        # validate trials
        ix_to_omit: list[int] = []
        omit_reasons: list[str] = []
        for ix in range(num_trials):
            t = times[ix]
            if t[0] != 0:
                ix_to_omit.append(ix); omit_reasons.append("t0"); continue
            if (t[1] - t[0]) != si:
                ix_to_omit.append(ix); omit_reasons.append("si"); continue
            if not np.array_equal(t[:-1], time_points):
                ix_to_omit.append(ix); omit_reasons.append("tp"); continue
            if stimuli[ix][-1] not in probes:
                ix_to_omit.append(ix); omit_reasons.append("pr"); continue
            if responses[ix][-1] not in masks:
                ix_to_omit.append(ix); omit_reasons.append("ma"); continue

        stimuli = np.delete(stimuli, ix_to_omit, axis=0)
        responses = np.delete(responses, ix_to_omit, axis=0)

        if verbose:
            log.info("Read %s — %d trials omitted", filepath, len(ix_to_omit))

        # FFT + build rows for all requested frequencies
        rows: list[dict[str, Any]] = []
        for trial_idx in range(len(responses)):
            sig = responses[trial_idx][:1000]
            amps = np.fft.fft(sig) / 1000
            all_freqs = np.fft.fftfreq(n=len(sig), d=1.0 / sr)

            for f in freqs:
                target_amp = amps[np.where(all_freqs == f)]
                rows.append({
                    "mask": int(responses[trial_idx][-1]),
                    "probe": int(stimuli[trial_idx][-1]),
                    "complex_data": target_amp[0] if len(target_amp) else complex(0),
                    "freq": f,
                })

    except Exception as text_exc:
        # ── fallback: try binary ──────────────────────────────────────────
        if verbose:
            log.info("Text read failed for %s (%s), trying binary", filepath, text_exc)
        try:
            metadata = _extract_metadata_from_binary(filepath)
            data = np.fromfile(filepath, dtype=np.int32, count=-1)
            data = list(data)[33:]
            data = np.reshape(data, (-1, 1025))

            bin_responses: list[list[int]] = []
            conditions: list[list[int | None]] = []
            cond: list[int | None] = [None, None]
            for ix, d in enumerate(data):
                if ix % 2 == 0:
                    cond = [None, None]
                    bin_responses.append(list(d[:1024]))
                    cond[1] = int(d[-1])
                else:
                    cond[0] = int(d[-1])
                    conditions.append(cond)

            rows = []
            for trial_idx in range(len(bin_responses)):
                sig = bin_responses[trial_idx][:1000]
                amps = np.fft.fft(sig) / 1000
                all_freqs = np.fft.fftfreq(n=len(sig), d=1.0 / sr)
                for f in freqs:
                    target_amp = amps[np.where(all_freqs == f)]
                    rows.append({
                        "mask": conditions[trial_idx][1],
                        "probe": conditions[trial_idx][0],
                        "complex_data": target_amp[0] if len(target_amp) else complex(0),
                        "freq": f,
                    })

            ix_to_omit = []
            omit_reasons = []

        except Exception as bin_exc:
            log.error("Cannot read %s: text=%s, binary=%s", filepath, text_exc, bin_exc)
            raise RuntimeError(f"Cannot read {filepath}") from bin_exc

    sorted_data = pd.DataFrame(rows)

    # ── finalise metadata ─────────────────────────────────────────────────
    metadata["n_trials"] = len(sorted_data)
    metadata["omitted"] = (
        list(zip(ix_to_omit, omit_reasons)) if ix_to_omit else None
    )
    metadata["filepath"] = str(filepath)

    # enrich metadata (from original jots_readFile logic)
    try:
        if "GAL4" in metadata and "UAS" in metadata:
            metadata["genotype"] = f'{metadata["GAL4"]}-GAL4/UAS-{metadata["UAS"]}'
        if "filename" in metadata:
            fname_parts = metadata["filename"].split(" ")
            metadata["filename"] = fname_parts[0]
            metadata["ID"] = fname_parts[0].split("_")[-1]
            fn = metadata["filename"]
            metadata["datetime"] = (
                f"2023{fn[3:5]}{fn[0:2]}{fn[6:8]}{fn[9:11]}{fn[12:14]}"
            )  # YYYYMMDDHHMMSS
    except Exception:
        pass

    return sorted_data, metadata


def get_svp_files(directory: str | Path) -> list[str]:
    """Return sorted list of .SVP files in *directory*.

    This is the refactored equivalent of ``jots_getSVPFiles.getSVPFiles``.
    """
    d = Path(directory)
    return sorted(f.name for f in d.iterdir() if "SVP" in f.name)

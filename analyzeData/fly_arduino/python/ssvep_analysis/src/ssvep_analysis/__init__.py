"""SSVEP Bootstrap Analysis for Drosophila electrophysiology data."""

__version__ = "0.2.0"

from .reader import ExperimentDefaults, get_svp_files, read_file
from .bootstrap import bootstrap_ssveps
from .converter import convert_svp_to_npz, load_npz_archive

__all__ = [
    "ExperimentDefaults",
    "bootstrap_ssveps",
    "convert_svp_to_npz",
    "get_svp_files",
    "load_npz_archive",
    "read_file",
]

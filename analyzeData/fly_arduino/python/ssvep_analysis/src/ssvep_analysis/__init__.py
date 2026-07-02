"""SSVEP Bootstrap Analysis for Drosophila electrophysiology data."""

__version__ = "0.2.0"

from .reader import ExperimentDefaults, get_svp_files, read_file
from .bootstrap import bootstrap_ssveps
from .converter import convert_svp_to_npz, load_npz_archive
from .arw_toolbox import (
    ArwAnalysisConfig,
    ArwAnalysisResult,
    arw_analyze_directory,
    arw_derive_high_contrast,
    arw_fit_observations,
    arw_process_directory,
)

__all__ = [
    "ExperimentDefaults",
    "ArwAnalysisConfig",
    "ArwAnalysisResult",
    "arw_analyze_directory",
    "arw_derive_high_contrast",
    "arw_fit_observations",
    "arw_process_directory",
    "bootstrap_ssveps",
    "convert_svp_to_npz",
    "get_svp_files",
    "load_npz_archive",
    "read_file",
]

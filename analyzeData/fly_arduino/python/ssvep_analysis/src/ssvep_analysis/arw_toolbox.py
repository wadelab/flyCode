"""General ``arw_`` SSVEP processing, fitting, statistics, and plotting tools.

The functions in this module deliberately avoid hSNCA-specific assumptions:
they discover SVP-containing subdirectories, infer genotype/timepoint labels
from folder names such as ``GAL80LACZ_7dpe``, and write reusable long/wide
exports plus publication-oriented plots.
"""

from __future__ import annotations

import logging
import re
import warnings
from dataclasses import dataclass, field
from itertools import combinations
from pathlib import Path
from typing import Any, Mapping, Sequence

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
from matplotlib.patches import Patch
from scipy.stats import f as f_dist
from scipy.stats import studentized_range
from scipy.stats import t as t_dist

from .bootstrap import CURVE_SPECS
from .reader import ExperimentDefaults, get_svp_files, read_file

log = logging.getLogger(__name__)


ARW_PALETTE = [
    "#1f1f1f",
    "#0072B2",
    "#009E73",
    "#D55E00",
    "#CC79A7",
    "#E69F00",
    "#56B4E9",
    "#6A51A3",
    "#7F7F7F",
]

_EFFECT_ORDER = ["genotype", "timepoint", "genotype:timepoint"]
_EFFECT_LABELS = {
    "genotype": "Genotype",
    "timepoint": "Timepoint",
    "genotype:timepoint": "Genotype × Timepoint",
}
_EFFECT_SHORT = {"genotype": "G", "timepoint": "T", "genotype:timepoint": "G×T"}

_TIMEPOINT_RE = re.compile(
    r"^(?P<genotype>.+?)[_-](?P<timepoint>(?P<age>\d+(?:\.\d+)?)(?P<unit>dpe|days?|d|hpe|hours?|hrs?|h))$",
    re.IGNORECASE,
)


@dataclass(frozen=True)
class ArwSubdirectory:
    """A discovered data folder and its inferred condition labels."""

    path: Path
    directory: str
    genotype: str
    timepoint: str
    age_days: float | None


@dataclass
class ArwAnalysisConfig:
    """Configuration for the general ``arw_`` analysis pipeline."""

    data_dir: Path | str
    output_dir: Path | str = Path("output/arw")
    output_prefix: str | None = None
    input_freq: int = 12
    harmonics: Mapping[str, int] | None = None
    fit_types: Sequence[str] = ("reduced_hyper", "power", "full_hyper", "fixed_c50_hyper")
    high_contrast_n: int = 2
    genotype_order: Sequence[str] | None = None
    timepoint_order: Sequence[str] | None = None
    subdirs: Sequence[str] | None = None
    recursive: bool = False
    colors: Sequence[str] | None = None
    make_plots: bool = True
    save_observations: bool = True
    crf_bootstrap_n: int = 300
    crf_ci: float = 0.95
    annotate_anova: bool = True
    seed: int = 20240517
    defaults: ExperimentDefaults | None = None

    def __post_init__(self) -> None:
        self.data_dir = Path(self.data_dir)
        self.output_dir = Path(self.output_dir)
        invalid_fit_types = [fit for fit in self.fit_types if fit not in CURVE_SPECS]
        if invalid_fit_types:
            valid = ", ".join(sorted(CURVE_SPECS))
            raise ValueError(f"Unknown fit type(s) {invalid_fit_types}; valid choices: {valid}")


@dataclass
class ArwAnalysisResult:
    """DataFrames and written output paths from an ``arw_`` run."""

    observations: pd.DataFrame
    high_contrast: pd.DataFrame
    fit_parameters: pd.DataFrame
    paths: dict[str, Path] = field(default_factory=dict)


def _natural_key(value: Any) -> list[Any]:
    return [int(part) if part.isdigit() else part.lower() for part in re.split(r"(\d+)", str(value))]


def _slug(value: str) -> str:
    return re.sub(r"[^A-Za-z0-9_.-]+", "_", value).strip("_") or "dataset"


def _frequency_map(config: ArwAnalysisConfig) -> dict[str, int]:
    if config.harmonics:
        return dict(config.harmonics)
    return {"1F1": int(config.input_freq), "2F1": int(config.input_freq) * 2}


def _parse_subdirectory_name(path: Path, root: Path) -> ArwSubdirectory:
    directory = path.relative_to(root).as_posix() if path != root else path.name
    label = path.name
    match = _TIMEPOINT_RE.match(label)
    if not match:
        return ArwSubdirectory(
            path=path,
            directory=directory,
            genotype=label,
            timepoint="all",
            age_days=None,
        )

    genotype = match.group("genotype")
    timepoint = match.group("timepoint")
    age = float(match.group("age"))
    unit = match.group("unit").lower()
    age_days = age / 24.0 if unit.startswith("h") else age
    if age_days.is_integer():
        age_days = int(age_days)
    return ArwSubdirectory(
        path=path,
        directory=directory,
        genotype=genotype,
        timepoint=timepoint,
        age_days=age_days,
    )


def _has_svp_files(path: Path) -> bool:
    try:
        return bool(get_svp_files(path))
    except Exception:
        return False


def _ordered_unique(values: Sequence[Any], preferred: Sequence[Any] | None = None) -> list[Any]:
    seen = []
    for value in values:
        if value not in seen:
            seen.append(value)
    if preferred is None:
        return sorted(seen, key=_natural_key)
    ordered = [value for value in preferred if value in seen]
    ordered.extend(value for value in seen if value not in ordered)
    return ordered


def arw_discover_subdirs(config: ArwAnalysisConfig) -> list[ArwSubdirectory]:
    """Find SVP-containing data directories and infer genotype/timepoint labels."""

    root = Path(config.data_dir)
    if not root.exists():
        raise FileNotFoundError(root)

    if config.subdirs:
        candidates = [
            Path(item) if Path(item).is_absolute() else root / item
            for item in config.subdirs
        ]
    elif config.recursive:
        candidates = [path for path in root.rglob("*") if path.is_dir()]
        if _has_svp_files(root):
            candidates.insert(0, root)
    else:
        candidates = [path for path in root.iterdir() if path.is_dir()]
        if _has_svp_files(root):
            candidates.insert(0, root)

    discovered = [
        _parse_subdirectory_name(path, root)
        for path in candidates
        if path.is_dir() and _has_svp_files(path)
    ]
    discovered.sort(key=lambda item: (_natural_key(item.timepoint), _natural_key(item.genotype)))

    if not discovered:
        raise ValueError(f"No SVP-containing subdirectories found under {root}")
    return discovered


def _analysis_orders(
    observations: pd.DataFrame,
    config: ArwAnalysisConfig,
) -> tuple[list[str], list[str]]:
    genotype_order = _ordered_unique(
        observations["genotype"].dropna().astype(str).tolist(),
        config.genotype_order,
    )
    if config.timepoint_order is not None:
        timepoint_order = _ordered_unique(
            observations["timepoint"].dropna().astype(str).tolist(),
            config.timepoint_order,
        )
    else:
        tp_meta = (
            observations[["timepoint", "age_days"]]
            .drop_duplicates()
            .assign(_age=lambda df: pd.to_numeric(df["age_days"], errors="coerce"))
        )
        if tp_meta["_age"].notna().any():
            tp_meta = tp_meta.sort_values(["_age", "timepoint"], kind="stable")
            timepoint_order = tp_meta["timepoint"].astype(str).tolist()
        else:
            timepoint_order = _ordered_unique(observations["timepoint"].dropna().astype(str).tolist())
    return genotype_order, timepoint_order


def _condition_order(observations: pd.DataFrame, config: ArwAnalysisConfig) -> list[tuple[str, str]]:
    harmonic_order = list(_frequency_map(config))
    rows = observations[["harmonic", "mask"]].drop_duplicates()
    conditions = [(str(row.harmonic), str(row.mask)) for row in rows.itertuples(index=False)]
    conditions.sort(
        key=lambda item: (
            harmonic_order.index(item[0]) if item[0] in harmonic_order else len(harmonic_order),
            _natural_key(item[1]),
        )
    )
    return conditions


def _color_map(genotype_order: Sequence[str], config: ArwAnalysisConfig) -> dict[str, str]:
    palette = list(config.colors) if config.colors else ARW_PALETTE
    return {genotype: palette[idx % len(palette)] for idx, genotype in enumerate(genotype_order)}


def arw_process_directory(config: ArwAnalysisConfig) -> pd.DataFrame:
    """Read every SVP file from discovered subdirectories into fly-level observations."""

    freq_map = _frequency_map(config)
    rows: list[dict[str, Any]] = []
    failures: list[tuple[str, str]] = []

    for subdir in arw_discover_subdirs(config):
        svp_files = get_svp_files(subdir.path)
        log.info("Processing %s (%d files)", subdir.directory, len(svp_files))
        for fly_idx, filename in enumerate(svp_files):
            source_path = subdir.path / filename
            subject_id = f"{_slug(subdir.directory)}_{fly_idx:02d}"
            try:
                scd, _metadata = read_file(
                    source_path,
                    freq=list(freq_map.values()),
                    defaults=config.defaults,
                )
            except Exception as exc:
                failures.append((str(source_path), str(exc)))
                log.warning("Skipping %s: %s", source_path, exc)
                continue

            for harmonic, frequency in freq_map.items():
                subset = scd[scd["freq"] == frequency]
                if subset.empty:
                    continue
                grouped = subset.groupby(["probe", "mask"]).mean(numeric_only=False)["complex_data"]
                for (probe, mask), complex_value in grouped.items():
                    rows.append({
                        "subject_id": subject_id,
                        "directory": subdir.directory,
                        "source_file": filename,
                        "genotype": subdir.genotype,
                        "timepoint": subdir.timepoint,
                        "age_days": subdir.age_days if subdir.age_days is not None else np.nan,
                        "fly_index": fly_idx,
                        "harmonic": harmonic,
                        "frequency_hz": frequency,
                        "mask": str(int(mask)),
                        "probe": int(probe),
                        "amplitude": float(np.abs(complex_value)),
                    })

    if not rows:
        raise ValueError("No readable SVP observations were produced")

    observations = pd.DataFrame(rows)
    observations.attrs["read_failures"] = failures
    return observations


def arw_derive_high_contrast(
    observations: pd.DataFrame,
    *,
    n_contrasts: int = 2,
) -> pd.DataFrame:
    """Compute each fly's mean response at the top N available probe contrasts."""

    base_cols = [
        "subject_id", "directory", "source_file", "genotype", "timepoint",
        "age_days", "fly_index", "harmonic", "frequency_hz", "mask",
    ]
    rows: list[dict[str, Any]] = []
    for keys, group in observations.groupby(base_cols, dropna=False, sort=False):
        top = group.sort_values("probe").tail(n_contrasts)
        if top.empty:
            continue
        row = dict(zip(base_cols, keys))
        row.update({
            "metric": "high_contrast_mean",
            "parameter": "high_contrast_mean",
            "value": float(top["amplitude"].mean()),
            "n_contrasts": int(len(top)),
            "min_probe": int(top["probe"].min()),
            "max_probe": int(top["probe"].max()),
        })
        rows.append(row)
    return pd.DataFrame(rows)


def _fit_curve(probes: np.ndarray, responses: np.ndarray, fit_type: str) -> np.ndarray | None:
    spec = CURVE_SPECS[fit_type]
    min_points = max(2, len(spec.param_names))
    if probes.size < min_points:
        return None
    if not np.all(np.isfinite(probes)) or not np.all(np.isfinite(responses)):
        return None
    if np.nanmax(responses) <= 0:
        return None
    try:
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            params = np.asarray(spec.fit_fn(probes.tolist(), responses.tolist()), dtype=float)
    except Exception:
        return None
    if params.size != len(spec.param_names) or not np.all(np.isfinite(params)):
        return None
    return params


def arw_fit_observations(
    observations: pd.DataFrame,
    *,
    fit_types: Sequence[str] = ("reduced_hyper", "power", "full_hyper", "fixed_c50_hyper"),
) -> pd.DataFrame:
    """Fit configured contrast-response curves to each fly/harmonic/mask."""

    base_cols = [
        "subject_id", "directory", "source_file", "genotype", "timepoint",
        "age_days", "fly_index", "harmonic", "frequency_hz", "mask",
    ]
    rows: list[dict[str, Any]] = []
    for keys, group in observations.groupby(base_cols, dropna=False, sort=False):
        ordered = group.sort_values("probe")
        probes = ordered["probe"].to_numpy(dtype=float)
        responses = ordered["amplitude"].to_numpy(dtype=float)
        base = dict(zip(base_cols, keys))

        for fit_type in fit_types:
            spec = CURVE_SPECS[fit_type]
            params = _fit_curve(probes, responses, fit_type)
            if params is None:
                continue

            for parameter, value in zip(spec.param_names, params):
                row = dict(base)
                row.update({
                    "fit_type": fit_type,
                    "parameter": parameter,
                    "value": float(value),
                    "n_points": int(probes.size),
                    "min_probe": int(np.min(probes)),
                    "max_probe": int(np.max(probes)),
                })
                rows.append(row)
    return pd.DataFrame(rows)


def _summary_table(
    data: pd.DataFrame,
    metric_cols: Sequence[str],
    *,
    value_col: str = "value",
) -> pd.DataFrame:
    group_cols = list(metric_cols) + ["genotype", "timepoint", "age_days"]
    rows: list[dict[str, Any]] = []
    if data.empty:
        return pd.DataFrame()
    for keys, group in data.groupby(group_cols, dropna=False, sort=False):
        values = group[value_col].dropna().to_numpy(dtype=float)
        if values.size == 0:
            continue
        mean = float(np.mean(values))
        sd = float(np.std(values, ddof=1)) if values.size > 1 else 0.0
        sem = float(sd / np.sqrt(values.size)) if values.size > 1 else 0.0
        ci_delta = float(t_dist.ppf(0.975, values.size - 1) * sem) if values.size > 1 else 0.0
        row = dict(zip(group_cols, keys))
        row.update({
            "n": int(values.size),
            "mean": mean,
            "sd": sd,
            "sem": sem,
            "ci95_low": mean - ci_delta,
            "ci95_high": mean + ci_delta,
            "median": float(np.median(values)),
            "q25": float(np.quantile(values, 0.25)),
            "q75": float(np.quantile(values, 0.75)),
            "min": float(np.min(values)),
            "max": float(np.max(values)),
        })
        rows.append(row)
    return pd.DataFrame(rows)


def _design_matrix(
    genotypes: Sequence[str],
    timepoints: Sequence[str],
    genotype_levels: Sequence[str],
    timepoint_levels: Sequence[str],
    *,
    include_genotype: bool,
    include_timepoint: bool,
    include_interaction: bool,
) -> np.ndarray:
    columns = [np.ones(len(genotypes))]
    genotype_cols: list[np.ndarray] = []
    timepoint_cols: list[np.ndarray] = []

    if include_genotype:
        for level in genotype_levels[1:]:
            col = np.asarray([1.0 if value == level else 0.0 for value in genotypes])
            columns.append(col)
            genotype_cols.append(col)

    if include_timepoint:
        for level in timepoint_levels[1:]:
            col = np.asarray([1.0 if value == level else 0.0 for value in timepoints])
            columns.append(col)
            timepoint_cols.append(col)

    if include_interaction:
        for g_col in genotype_cols:
            for t_col in timepoint_cols:
                columns.append(g_col * t_col)

    return np.column_stack(columns)


def _fit_sse(y: np.ndarray, x: np.ndarray) -> tuple[float, int]:
    beta, *_ = np.linalg.lstsq(x, y, rcond=None)
    residuals = y - x @ beta
    return float(np.sum(residuals ** 2)), int(np.linalg.matrix_rank(x))


def _levels_for_metric(
    data: pd.DataFrame,
    genotype_order: Sequence[str],
    timepoint_order: Sequence[str],
) -> tuple[list[str], list[str]]:
    observed_genotypes = data["genotype"].astype(str).tolist()
    observed_timepoints = data["timepoint"].astype(str).tolist()
    genotypes = [value for value in genotype_order if value in observed_genotypes]
    genotypes.extend(value for value in _ordered_unique(observed_genotypes) if value not in genotypes)
    timepoints = [value for value in timepoint_order if value in observed_timepoints]
    timepoints.extend(value for value in _ordered_unique(observed_timepoints) if value not in timepoints)
    return genotypes, timepoints


def _anova_rows_for_metric(
    data: pd.DataFrame,
    metric_values: Mapping[str, Any],
    genotype_order: Sequence[str],
    timepoint_order: Sequence[str],
) -> list[dict[str, Any]]:
    clean = data.dropna(subset=["value"]).copy()
    if clean.empty:
        return []

    y = clean["value"].to_numpy(dtype=float)
    genotypes = clean["genotype"].astype(str).tolist()
    timepoints = clean["timepoint"].astype(str).tolist()
    genotype_levels, timepoint_levels = _levels_for_metric(clean, genotype_order, timepoint_order)
    include_genotype = len(genotype_levels) > 1
    include_timepoint = len(timepoint_levels) > 1
    if not include_genotype and not include_timepoint:
        return []

    rows: list[dict[str, Any]] = []
    if include_genotype and include_timepoint:
        x_genotype = _design_matrix(
            genotypes, timepoints, genotype_levels, timepoint_levels,
            include_genotype=True, include_timepoint=False, include_interaction=False,
        )
        x_time = _design_matrix(
            genotypes, timepoints, genotype_levels, timepoint_levels,
            include_genotype=False, include_timepoint=True, include_interaction=False,
        )
        x_additive = _design_matrix(
            genotypes, timepoints, genotype_levels, timepoint_levels,
            include_genotype=True, include_timepoint=True, include_interaction=False,
        )
        x_full = _design_matrix(
            genotypes, timepoints, genotype_levels, timepoint_levels,
            include_genotype=True, include_timepoint=True, include_interaction=True,
        )
        sse_genotype, rank_genotype = _fit_sse(y, x_genotype)
        sse_time, rank_time = _fit_sse(y, x_time)
        sse_additive, rank_additive = _fit_sse(y, x_additive)
        sse_full, rank_full = _fit_sse(y, x_full)
        df_error = y.size - rank_full
        if df_error <= 0:
            return []
        mse_error = sse_full / df_error
        effects = [
            ("genotype", sse_time - sse_additive, rank_additive - rank_time),
            ("timepoint", sse_genotype - sse_additive, rank_additive - rank_genotype),
            ("genotype:timepoint", sse_additive - sse_full, rank_full - rank_additive),
        ]
    else:
        factor_name = "genotype" if include_genotype else "timepoint"
        x_null = np.ones((y.size, 1))
        x_factor = _design_matrix(
            genotypes, timepoints, genotype_levels, timepoint_levels,
            include_genotype=include_genotype,
            include_timepoint=include_timepoint,
            include_interaction=False,
        )
        sse_null, rank_null = _fit_sse(y, x_null)
        sse_factor, rank_factor = _fit_sse(y, x_factor)
        df_error = y.size - rank_factor
        if df_error <= 0:
            return []
        mse_error = sse_factor / df_error
        effects = [(factor_name, sse_null - sse_factor, rank_factor - rank_null)]

    for effect, ss, df in effects:
        ss = max(float(ss), 0.0)
        ms = ss / df if df > 0 else np.nan
        f_value = ms / mse_error if df > 0 and mse_error > 0 else np.nan
        p_value = f_dist.sf(f_value, df, df_error) if np.isfinite(f_value) else np.nan
        row = dict(metric_values)
        row.update({
            "effect": effect,
            "df": int(df),
            "df_error": int(df_error),
            "ss": ss,
            "ms": ms,
            "f": f_value,
            "p": p_value,
            "stars": arw_p_to_stars(p_value),
            "n": int(y.size),
        })
        rows.append(row)
    return rows


def arw_anova_table(
    data: pd.DataFrame,
    metric_cols: Sequence[str],
    *,
    genotype_order: Sequence[str],
    timepoint_order: Sequence[str],
) -> pd.DataFrame:
    """Run one- or two-way categorical ANOVAs for each metric/condition."""

    rows: list[dict[str, Any]] = []
    if data.empty:
        return pd.DataFrame()
    for metric_keys, group in data.groupby(list(metric_cols), dropna=False, sort=False):
        if not isinstance(metric_keys, tuple):
            metric_keys = (metric_keys,)
        metric_values = dict(zip(metric_cols, metric_keys))
        rows.extend(_anova_rows_for_metric(group, metric_values, genotype_order, timepoint_order))
    return pd.DataFrame(rows)


def arw_p_to_stars(p_value: float | int | None) -> str:
    """Convert a p-value to the common significance-star notation."""

    if p_value is None or not np.isfinite(p_value):
        return ""
    p_value = float(p_value)
    if p_value < 0.0001:
        return "****"
    if p_value < 0.001:
        return "***"
    if p_value < 0.01:
        return "**"
    if p_value < 0.05:
        return "*"
    return "ns"


def _one_way_mse(data: pd.DataFrame, group_col: str = "genotype") -> tuple[float, int]:
    clean = data.dropna(subset=["value"]).copy()
    levels = _ordered_unique(clean[group_col].astype(str).tolist())
    if len(levels) < 2:
        return np.nan, 0
    y = clean["value"].to_numpy(dtype=float)
    groups = clean[group_col].astype(str).tolist()
    columns = [np.ones(y.size)]
    for level in levels[1:]:
        columns.append(np.asarray([1.0 if value == level else 0.0 for value in groups]))
    x = np.column_stack(columns)
    sse, rank = _fit_sse(y, x)
    df_error = y.size - rank
    if df_error <= 0:
        return np.nan, df_error
    return sse / df_error, df_error


def arw_tukey_posthoc(
    data: pd.DataFrame,
    metric_cols: Sequence[str],
    *,
    genotype_order: Sequence[str],
    timepoint_order: Sequence[str],
) -> pd.DataFrame:
    """Compute Tukey-Kramer genotype post-hocs and add star labels."""

    rows: list[dict[str, Any]] = []
    if data.empty:
        return pd.DataFrame()

    for metric_keys, metric_data in data.groupby(list(metric_cols), dropna=False, sort=False):
        if not isinstance(metric_keys, tuple):
            metric_keys = (metric_keys,)
        metric_values = dict(zip(metric_cols, metric_keys))
        observed_timepoints = [
            tp for tp in timepoint_order
            if tp in set(metric_data["timepoint"].astype(str))
        ]
        scopes = [("marginal", "all", metric_data)]
        if len(observed_timepoints) > 1:
            scopes.extend(
                (
                    "simple_timepoint",
                    timepoint,
                    metric_data[metric_data["timepoint"].astype(str) == timepoint],
                )
                for timepoint in observed_timepoints
            )
        else:
            scopes = [("overall", observed_timepoints[0] if observed_timepoints else "all", metric_data)]

        for comparison_scope, timepoint_label, scope_data in scopes:
            grouped_values: dict[str, np.ndarray] = {}
            for genotype in genotype_order:
                vals = scope_data.loc[
                    scope_data["genotype"].astype(str) == genotype,
                    "value",
                ].dropna().to_numpy(dtype=float)
                if vals.size:
                    grouped_values[genotype] = vals

            k = len(grouped_values)
            if k < 2:
                continue
            mse_error, df_error = _one_way_mse(scope_data)
            if not np.isfinite(mse_error) or df_error <= 0:
                continue

            for genotype_a, genotype_b in combinations(genotype_order, 2):
                if genotype_a not in grouped_values or genotype_b not in grouped_values:
                    continue
                vals_a = grouped_values[genotype_a]
                vals_b = grouped_values[genotype_b]
                mean_a = float(np.mean(vals_a))
                mean_b = float(np.mean(vals_b))
                diff = mean_a - mean_b
                se = float(np.sqrt(mse_error * 0.5 * (1 / vals_a.size + 1 / vals_b.size)))
                q_stat = abs(diff) / se if se > 0 else np.nan
                p_adj = studentized_range.sf(q_stat, k, df_error) if np.isfinite(q_stat) else np.nan
                row = dict(metric_values)
                row.update({
                    "comparison_scope": comparison_scope,
                    "timepoint": timepoint_label,
                    "genotype_a": genotype_a,
                    "genotype_b": genotype_b,
                    "mean_a": mean_a,
                    "mean_b": mean_b,
                    "difference_a_minus_b": diff,
                    "n_a": int(vals_a.size),
                    "n_b": int(vals_b.size),
                    "mse_error": float(mse_error),
                    "df_error": int(df_error),
                    "q": q_stat,
                    "p_tukey": p_adj,
                    "stars": arw_p_to_stars(p_adj),
                    "significant_0_05": bool(np.isfinite(p_adj) and p_adj < 0.05),
                })
                rows.append(row)
    return pd.DataFrame(rows)


def _wide_export(
    data: pd.DataFrame,
    *,
    value_col: str,
    column_col: str,
) -> pd.DataFrame:
    if data.empty:
        return pd.DataFrame()
    index_cols = ["subject_id", "genotype", "timepoint", "age_days", "fly_index"]
    wide = (
        data.assign(_column=data[column_col])
        .pivot_table(
            index=index_cols,
            columns="_column",
            values=value_col,
            aggfunc="first",
        )
        .reset_index()
    )
    wide.columns.name = None
    return wide.where(pd.notna(wide), "")


def _write_csv(path: Path, data: pd.DataFrame) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    data.to_csv(path, index=False)
    return path


def _apply_plot_style(ax: plt.Axes) -> None:
    ax.set_axisbelow(True)
    ax.grid(axis="y", color="#E6E8EB", linewidth=0.8)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_color("#A8ADB4")
    ax.spines["bottom"].set_color("#A8ADB4")
    ax.tick_params(colors="#333333", labelsize=8)


def _curve_values(fit_type: str, x_values: np.ndarray, params: Sequence[float]) -> np.ndarray:
    if fit_type not in CURVE_SPECS:
        raise ValueError(f"Unknown fit type {fit_type!r}")
    return CURVE_SPECS[fit_type].curve_fn(x_values, *params)


def _bootstrap_curve_band(
    panel: pd.DataFrame,
    fit_type: str,
    x_fit: np.ndarray,
    *,
    n_boot: int,
    rng: np.random.Generator,
    ci: float = 0.95,
) -> tuple[np.ndarray, np.ndarray] | None:
    """Resample flies to build a percentile CI band around the fitted mean CRF.

    Each iteration draws flies with replacement, averages their responses at
    every probe, refits the mean curve, and evaluates it on ``x_fit``. The
    2.5/97.5 (or ``ci``) percentiles across iterations form the shaded band.
    """

    wide = panel.pivot_table(index="subject_id", columns="probe", values="amplitude", aggfunc="mean")
    if wide.empty:
        return None
    probes = np.asarray(sorted(wide.columns), dtype=float)
    matrix = wide.reindex(columns=sorted(wide.columns)).to_numpy(dtype=float)
    n_subjects = matrix.shape[0]
    min_points = max(2, len(CURVE_SPECS[fit_type].param_names))
    if n_subjects < 3 or probes.size < min_points:
        return None

    curves: list[np.ndarray] = []
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        for _ in range(n_boot):
            idx = rng.integers(0, n_subjects, n_subjects)
            means = np.nanmean(matrix[idx], axis=0)
            params = _fit_curve(probes, means, fit_type)
            if params is None:
                continue
            curves.append(_curve_values(fit_type, x_fit, params))

    if len(curves) < max(20, n_boot // 10):
        return None
    stack = np.asarray(curves, dtype=float)
    alpha = (1.0 - ci) / 2.0
    lower, upper = np.quantile(stack, [alpha, 1.0 - alpha], axis=0)
    return lower, upper


def arw_plot_crfs(
    observations: pd.DataFrame,
    config: ArwAnalysisConfig,
    *,
    output_path: Path,
    overlay_fit_type: str = "reduced_hyper",
) -> Path:
    """Plot mean CRFs by timepoint, harmonic/mask, and genotype."""

    genotype_order, timepoint_order = _analysis_orders(observations, config)
    conditions = _condition_order(observations, config)
    colors = _color_map(genotype_order, config)
    if overlay_fit_type not in CURVE_SPECS:
        overlay_fit_type = "reduced_hyper"
    rng = np.random.default_rng(config.seed)

    fig, axes = plt.subplots(
        len(conditions),
        len(timepoint_order),
        figsize=(3.6 * len(timepoint_order), 2.9 * len(conditions)),
        squeeze=False,
        sharex=True,
        layout="constrained",
    )

    for row_idx, (harmonic, mask) in enumerate(conditions):
        for col_idx, timepoint in enumerate(timepoint_order):
            ax = axes[row_idx, col_idx]
            panel = observations[
                (observations["harmonic"].astype(str) == harmonic)
                & (observations["mask"].astype(str) == str(mask))
                & (observations["timepoint"].astype(str) == str(timepoint))
            ]
            for genotype in genotype_order:
                g_panel = panel[panel["genotype"].astype(str) == genotype]
                if g_panel.empty:
                    continue
                probe_stats = (
                    g_panel.groupby("probe")["amplitude"]
                    .agg(mean="mean", sem="sem", count="count")
                    .reset_index()
                    .sort_values("probe")
                )
                probes = probe_stats["probe"].to_numpy(dtype=float)
                means = probe_stats["mean"].to_numpy(dtype=float)
                sems = np.nan_to_num(probe_stats["sem"].to_numpy(dtype=float))
                color = colors[genotype]
                ax.errorbar(
                    probes,
                    means,
                    yerr=sems,
                    color=color,
                    marker="o",
                    markersize=4,
                    markeredgecolor="white",
                    markeredgewidth=0.6,
                    linestyle="none",
                    capsize=2.5,
                    alpha=0.95,
                    zorder=3,
                    label=genotype if row_idx == 0 and col_idx == 0 else None,
                )

                params = _fit_curve(probes, means, overlay_fit_type)
                if params is not None and np.min(probes) > 0:
                    x_fit = np.geomspace(np.min(probes), np.max(probes), 200)
                    band = _bootstrap_curve_band(
                        g_panel,
                        overlay_fit_type,
                        x_fit,
                        n_boot=config.crf_bootstrap_n,
                        rng=rng,
                        ci=config.crf_ci,
                    )
                    if band is not None:
                        ax.fill_between(
                            x_fit,
                            band[0],
                            band[1],
                            color=color,
                            alpha=0.15,
                            linewidth=0,
                            zorder=1,
                        )
                    ax.plot(
                        x_fit,
                        _curve_values(overlay_fit_type, x_fit, params),
                        color=color,
                        linewidth=1.6,
                        alpha=0.9,
                        zorder=2,
                    )

            if row_idx == 0:
                ax.set_title(str(timepoint), fontsize=10, pad=8)
            if col_idx == 0:
                ax.set_ylabel(f"{harmonic}, mask {mask}\nFFT amplitude", fontsize=9)
            if row_idx == len(conditions) - 1:
                ax.set_xlabel("Probe contrast (%)", fontsize=9)
            if (panel["probe"] > 0).all():
                ax.set_xscale("log")
            _apply_plot_style(ax)

    handles = [
        Patch(facecolor=colors[genotype], edgecolor=colors[genotype], label=genotype)
        for genotype in genotype_order
    ]
    fig.legend(
        handles=handles,
        loc="center left",
        bbox_to_anchor=(1.01, 0.5),
        ncol=1,
        frameon=False,
    )
    fig.suptitle(
        f"Contrast-response functions "
        f"({overlay_fit_type.replace('_', ' ')} fits, shaded {int(round(config.crf_ci * 100))}% bootstrap CI)",
        fontsize=13,
        y=1.02,
    )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=220, bbox_inches="tight")
    plt.close(fig)
    return output_path


def _matches_metric(row: pd.Series, metric_match: Mapping[str, Any]) -> bool:
    return all(str(row.get(key)) == str(value) for key, value in metric_match.items())


def _anova_note(anova: pd.DataFrame | None, metric_match: Mapping[str, Any]) -> str:
    """Build a compact per-panel ANOVA summary such as ``G *   T ***   G×T ns``."""

    if anova is None or anova.empty:
        return ""
    subset = anova[anova.apply(lambda row: _matches_metric(row, metric_match), axis=1)]
    if subset.empty:
        return ""
    parts: list[str] = []
    for effect in _EFFECT_ORDER:
        rows = subset[subset["effect"].astype(str) == effect]
        if rows.empty:
            continue
        stars = str(rows.iloc[0].get("stars") or "")
        parts.append(f"{_EFFECT_SHORT[effect]} {stars or 'ns'}")
    return "   ".join(parts)


def arw_plot_anova_summary(
    anova: pd.DataFrame,
    group_cols: Sequence[str],
    label_fn: Any,
    *,
    output_path: Path,
    title: str,
) -> Path | None:
    """Render an ANOVA table as an effect × condition significance heatmap.

    Cells are shaded by ``-log10(p)`` and annotated with significance stars and
    the F statistic; missing effects show a dash.
    """

    if anova is None or anova.empty:
        return None

    group_tuples = sorted(
        {
            tuple(str(row[col]) for col in group_cols)
            for _, row in anova[list(group_cols)].drop_duplicates().iterrows()
        },
        key=lambda tup: [_natural_key(value) for value in tup],
    )
    effects = [effect for effect in _EFFECT_ORDER if effect in set(anova["effect"].astype(str))]
    if not effects or not group_tuples:
        return None

    n_rows = len(effects)
    n_cols = len(group_tuples)
    p_matrix = np.full((n_rows, n_cols), np.nan)
    f_matrix = np.full((n_rows, n_cols), np.nan)
    star_matrix = [["" for _ in range(n_cols)] for _ in range(n_rows)]

    lookup: dict[tuple[str, tuple[str, ...]], tuple[float, float, str]] = {}
    for row in anova.itertuples(index=False):
        key = (str(getattr(row, "effect")), tuple(str(getattr(row, col)) for col in group_cols))
        lookup[key] = (float(getattr(row, "p")), float(getattr(row, "f")), str(getattr(row, "stars") or ""))

    for i, effect in enumerate(effects):
        for j, group in enumerate(group_tuples):
            entry = lookup.get((effect, group))
            if entry is None:
                continue
            p_value, f_value, stars = entry
            p_matrix[i, j] = p_value
            f_matrix[i, j] = f_value
            star_matrix[i][j] = stars

    with np.errstate(divide="ignore", invalid="ignore"):
        signif = -np.log10(np.clip(p_matrix, 1e-12, 1.0))
    signif = np.where(np.isfinite(signif), signif, np.nan)
    finite = signif[np.isfinite(signif)]
    vmax = float(max(4.0, finite.max())) if finite.size else 4.0

    fig, ax = plt.subplots(
        figsize=(max(6.0, 1.25 * n_cols + 2.4), 1.05 * n_rows + 2.2),
        layout="constrained",
    )
    cmap = plt.get_cmap("BuPu").copy()
    cmap.set_bad("#F2F3F5")
    im = ax.imshow(signif, aspect="auto", cmap=cmap, vmin=0.0, vmax=vmax)

    ax.set_xticks(range(n_cols))
    ax.set_xticklabels([label_fn(group) for group in group_tuples], rotation=35, ha="right", fontsize=8)
    ax.set_yticks(range(n_rows))
    ax.set_yticklabels([_EFFECT_LABELS.get(effect, effect) for effect in effects], fontsize=9)
    ax.set_xticks(np.arange(-0.5, n_cols), minor=True)
    ax.set_yticks(np.arange(-0.5, n_rows), minor=True)
    ax.grid(which="minor", color="white", linewidth=1.5)
    ax.tick_params(which="minor", length=0)
    ax.tick_params(which="major", length=0)

    for i in range(n_rows):
        for j in range(n_cols):
            if not np.isfinite(p_matrix[i, j]):
                ax.text(j, i, "–", ha="center", va="center", color="#9AA0A6", fontsize=10)
                continue
            text_color = "white" if signif[i, j] > 0.55 * vmax else "#222222"
            stars = star_matrix[i][j] or "ns"
            ax.text(j, i - 0.14, stars, ha="center", va="center", fontsize=10, fontweight="bold", color=text_color)
            ax.text(j, i + 0.24, f"F={f_matrix[i, j]:.1f}", ha="center", va="center", fontsize=7, color=text_color)

    for spine in ax.spines.values():
        spine.set_visible(False)
    cbar = fig.colorbar(im, ax=ax, shrink=0.85, pad=0.02)
    cbar.set_label("$-\\log_{10}(p)$", fontsize=8)
    cbar.ax.tick_params(labelsize=7)
    ax.set_title(title, fontsize=12, pad=10)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=220, bbox_inches="tight")
    plt.close(fig)
    return output_path


def _add_sig_bracket(ax: plt.Axes, x1: float, x2: float, y: float, h: float, label: str) -> None:
    ax.plot([x1, x1, x2, x2], [y, y + h, y + h, y], color="#333333", linewidth=0.9, clip_on=False)
    ax.text((x1 + x2) / 2, y + h, label, ha="center", va="bottom", fontsize=8, color="#222222")


def _draw_grouped_boxes(
    ax: plt.Axes,
    panel: pd.DataFrame,
    *,
    genotype_order: Sequence[str],
    timepoint_order: Sequence[str],
    colors: Mapping[str, str],
    posthoc: pd.DataFrame,
    metric_match: Mapping[str, Any],
    ylabel: str | None = None,
    show_xlabel: bool = True,
    max_star_pairs_per_timepoint: int = 3,
    anova_note: str = "",
) -> None:
    n_genotypes = len(genotype_order)
    group_width = n_genotypes + 1
    box_values: list[np.ndarray] = []
    box_positions: list[float] = []
    box_colors: list[str] = []
    pos_lookup: dict[tuple[str, str], float] = {}
    rng = np.random.default_rng(12345)

    for tp_idx, timepoint in enumerate(timepoint_order):
        group_start = tp_idx * group_width
        for gt_idx, genotype in enumerate(genotype_order):
            vals = panel.loc[
                (panel["timepoint"].astype(str) == str(timepoint))
                & (panel["genotype"].astype(str) == str(genotype)),
                "value",
            ].dropna().to_numpy(dtype=float)
            position = group_start + gt_idx
            pos_lookup[(str(timepoint), str(genotype))] = position
            if vals.size:
                box_values.append(vals)
                box_positions.append(position)
                box_colors.append(colors[genotype])

    if box_values:
        bp = ax.boxplot(
            box_values,
            positions=box_positions,
            widths=0.62,
            patch_artist=True,
            showfliers=False,
            whis=(5, 95),
            medianprops={"color": "#111111", "linewidth": 1.25},
        )
        for patch, color in zip(bp["boxes"], box_colors):
            patch.set_facecolor(color)
            patch.set_alpha(0.26)
            patch.set_edgecolor(color)
            patch.set_linewidth(1.15)
        for key in ("whiskers", "caps"):
            for line in bp[key]:
                line.set_color("#656B73")
                line.set_linewidth(0.85)

    for tp_idx, timepoint in enumerate(timepoint_order):
        for gt_idx, genotype in enumerate(genotype_order):
            vals = panel.loc[
                (panel["timepoint"].astype(str) == str(timepoint))
                & (panel["genotype"].astype(str) == str(genotype)),
                "value",
            ].dropna().to_numpy(dtype=float)
            if not vals.size:
                continue
            position = tp_idx * group_width + gt_idx
            jitter = rng.normal(0, 0.055, size=vals.size)
            ax.scatter(
                np.full(vals.size, position) + jitter,
                vals,
                s=11,
                color=colors[genotype],
                alpha=0.48,
                linewidths=0,
                zorder=3,
            )

    for boundary_idx in range(1, len(timepoint_order)):
        ax.axvline(boundary_idx * group_width - 0.5, color="#ECEFF3", linewidth=0.9, zorder=0)

    age_positions = [
        tp_idx * group_width + (n_genotypes - 1) / 2
        for tp_idx in range(len(timepoint_order))
    ]
    ax.set_xticks(age_positions)
    ax.set_xticklabels(timepoint_order, rotation=0)
    ax.set_xlim(-0.8, (len(timepoint_order) - 1) * group_width + n_genotypes - 0.2)
    if ylabel:
        ax.set_ylabel(ylabel, fontsize=9)
    if show_xlabel:
        ax.set_xlabel("Timepoint", fontsize=9)
    _apply_plot_style(ax)

    if anova_note:
        ax.text(
            0.015,
            0.985,
            anova_note,
            transform=ax.transAxes,
            ha="left",
            va="top",
            fontsize=7.5,
            color="#444444",
            bbox={"facecolor": "white", "edgecolor": "#D5D8DC", "boxstyle": "round,pad=0.3", "alpha": 0.85},
        )

    if posthoc.empty or panel.empty:
        return

    y_values = panel["value"].dropna().to_numpy(dtype=float)
    if y_values.size == 0:
        return
    y_min = float(np.min(y_values))
    y_max = float(np.max(y_values))
    y_range = y_max - y_min if y_max > y_min else max(abs(y_max), 1.0)
    h = y_range * 0.035
    step = y_range * 0.095
    current_top = y_max

    matching_posthoc = posthoc[
        posthoc.apply(lambda row: _matches_metric(row, metric_match), axis=1)
    ].copy()
    if matching_posthoc.empty:
        return

    for timepoint in timepoint_order:
        if len(timepoint_order) > 1:
            candidates = matching_posthoc[
                (matching_posthoc["comparison_scope"] == "simple_timepoint")
                & (matching_posthoc["timepoint"].astype(str) == str(timepoint))
                & (matching_posthoc["significant_0_05"] == True)  # noqa: E712
            ]
        else:
            candidates = matching_posthoc[
                (matching_posthoc["comparison_scope"].isin(["overall", "marginal"]))
                & (matching_posthoc["significant_0_05"] == True)  # noqa: E712
            ]
        if candidates.empty:
            continue
        candidates = candidates.sort_values("p_tukey").head(max_star_pairs_per_timepoint)
        local_vals = panel.loc[
            panel["timepoint"].astype(str) == str(timepoint),
            "value",
        ].dropna().to_numpy(dtype=float)
        local_top = float(np.max(local_vals)) if local_vals.size else current_top
        y = max(current_top + step * 0.3, local_top + step * 0.3)
        for row in candidates.itertuples(index=False):
            gt_a = str(row.genotype_a)
            gt_b = str(row.genotype_b)
            stars = str(row.stars)
            if stars == "ns":
                continue
            x1 = pos_lookup.get((str(timepoint), gt_a))
            x2 = pos_lookup.get((str(timepoint), gt_b))
            if x1 is None or x2 is None:
                continue
            _add_sig_bracket(ax, x1, x2, y, h, stars)
            y += step
        current_top = max(current_top, y)

    ax.set_ylim(top=current_top + step)


def arw_plot_high_contrast_boxplots(
    high_contrast: pd.DataFrame,
    posthoc: pd.DataFrame,
    config: ArwAnalysisConfig,
    *,
    output_path: Path,
    anova: pd.DataFrame | None = None,
) -> Path | None:
    """Plot boxplots for the derived high-contrast mean metric."""

    if high_contrast.empty:
        return None
    genotype_order, timepoint_order = _analysis_orders(high_contrast, config)
    colors = _color_map(genotype_order, config)
    conditions = [
        (str(row.harmonic), str(row.mask))
        for row in high_contrast[["harmonic", "mask"]].drop_duplicates().itertuples(index=False)
    ]
    conditions.sort(key=lambda item: (_natural_key(item[0]), _natural_key(item[1])))

    fig, axes = plt.subplots(
        1,
        len(conditions),
        figsize=(4.0 * len(conditions), 4.6),
        squeeze=False,
        layout="constrained",
    )
    for idx, (harmonic, mask) in enumerate(conditions):
        ax = axes[0, idx]
        panel = high_contrast[
            (high_contrast["harmonic"].astype(str) == harmonic)
            & (high_contrast["mask"].astype(str) == str(mask))
        ]
        metric_match = {"metric": "high_contrast_mean", "harmonic": harmonic, "mask": mask}
        _draw_grouped_boxes(
            ax,
            panel,
            genotype_order=genotype_order,
            timepoint_order=timepoint_order,
            colors=colors,
            posthoc=posthoc,
            metric_match=metric_match,
            ylabel="Top-contrast mean" if idx == 0 else None,
            anova_note=_anova_note(anova, metric_match) if config.annotate_anova else "",
        )
        ax.set_title(f"{harmonic}, mask {mask}", fontsize=10)

    handles = [
        Patch(facecolor=colors[genotype], edgecolor=colors[genotype], alpha=0.3, label=genotype)
        for genotype in genotype_order
    ]
    fig.legend(
        handles=handles,
        loc="center left",
        bbox_to_anchor=(1.01, 0.5),
        ncol=1,
        frameon=False,
    )
    fig.suptitle("Derived high-contrast responses", fontsize=13, y=1.03)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=220, bbox_inches="tight")
    plt.close(fig)
    return output_path


def arw_plot_fit_parameter_boxplots(
    fit_parameters: pd.DataFrame,
    posthoc: pd.DataFrame,
    config: ArwAnalysisConfig,
    *,
    fit_type: str,
    output_path: Path,
    anova: pd.DataFrame | None = None,
) -> Path | None:
    """Plot fitted parameter boxplots for one fit family."""

    data = fit_parameters[fit_parameters["fit_type"] == fit_type]
    if data.empty:
        return None
    genotype_order, timepoint_order = _analysis_orders(data, config)
    colors = _color_map(genotype_order, config)
    parameters = [param for param in CURVE_SPECS[fit_type].param_names if param in set(data["parameter"])]
    conditions = [
        (str(row.harmonic), str(row.mask))
        for row in data[["harmonic", "mask"]].drop_duplicates().itertuples(index=False)
    ]
    conditions.sort(key=lambda item: (_natural_key(item[0]), _natural_key(item[1])))

    fig, axes = plt.subplots(
        len(parameters),
        len(conditions),
        figsize=(4.0 * len(conditions), 3.8 * len(parameters)),
        squeeze=False,
        layout="constrained",
    )

    for row_idx, parameter in enumerate(parameters):
        for col_idx, (harmonic, mask) in enumerate(conditions):
            ax = axes[row_idx, col_idx]
            panel = data[
                (data["parameter"].astype(str) == str(parameter))
                & (data["harmonic"].astype(str) == harmonic)
                & (data["mask"].astype(str) == str(mask))
            ]
            metric_match = {
                "fit_type": fit_type,
                "parameter": parameter,
                "harmonic": harmonic,
                "mask": mask,
            }
            _draw_grouped_boxes(
                ax,
                panel,
                genotype_order=genotype_order,
                timepoint_order=timepoint_order,
                colors=colors,
                posthoc=posthoc,
                metric_match=metric_match,
                ylabel=parameter if col_idx == 0 else None,
                show_xlabel=row_idx == len(parameters) - 1,
                anova_note=_anova_note(anova, metric_match) if config.annotate_anova else "",
            )
            if row_idx == 0:
                ax.set_title(f"{harmonic}, mask {mask}", fontsize=10)

    handles = [
        Patch(facecolor=colors[genotype], edgecolor=colors[genotype], alpha=0.3, label=genotype)
        for genotype in genotype_order
    ]
    fig.legend(
        handles=handles,
        loc="center left",
        bbox_to_anchor=(1.01, 0.5),
        ncol=1,
        frameon=False,
    )
    fig.suptitle(f"{fit_type.replace('_', ' ')} fitted parameters", fontsize=13, y=1.03)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    fig.savefig(output_path, dpi=220, bbox_inches="tight")
    plt.close(fig)
    return output_path


def _prepare_high_contrast_wide(high_contrast: pd.DataFrame) -> pd.DataFrame:
    if high_contrast.empty:
        return pd.DataFrame()
    data = high_contrast.copy()
    data["column"] = "HC_" + data["harmonic"].astype(str) + "_mask" + data["mask"].astype(str)
    return _wide_export(data, value_col="value", column_col="column")


def _prepare_fit_wide(fit_parameters: pd.DataFrame) -> pd.DataFrame:
    if fit_parameters.empty:
        return pd.DataFrame()
    data = fit_parameters.copy()
    data["column"] = (
        data["fit_type"].astype(str)
        + "_"
        + data["parameter"].astype(str)
        + "_"
        + data["harmonic"].astype(str)
        + "_mask"
        + data["mask"].astype(str)
    )
    return _wide_export(data, value_col="value", column_col="column")


def _prefix(config: ArwAnalysisConfig) -> str:
    if config.output_prefix:
        return _slug(config.output_prefix)
    return "arw_" + _slug(Path(config.data_dir).name)


def arw_analyze_directory(
    data_dir: Path | str | None = None,
    *,
    config: ArwAnalysisConfig | None = None,
    output_dir: Path | str | None = None,
    output_prefix: str | None = None,
    input_freq: int = 12,
    fit_types: Sequence[str] = ("reduced_hyper", "power", "full_hyper", "fixed_c50_hyper"),
    high_contrast_n: int = 2,
    genotype_order: Sequence[str] | None = None,
    timepoint_order: Sequence[str] | None = None,
    subdirs: Sequence[str] | None = None,
    recursive: bool = False,
    make_plots: bool = True,
    defaults: ExperimentDefaults | None = None,
) -> ArwAnalysisResult:
    """Run the complete ``arw_`` processing, fitting, stats, and plotting pipeline."""

    if config is None:
        if data_dir is None:
            raise ValueError("data_dir is required when config is not supplied")
        config = ArwAnalysisConfig(
            data_dir=data_dir,
            output_dir=Path(output_dir) if output_dir is not None else Path("output/arw"),
            output_prefix=output_prefix,
            input_freq=input_freq,
            fit_types=fit_types,
            high_contrast_n=high_contrast_n,
            genotype_order=genotype_order,
            timepoint_order=timepoint_order,
            subdirs=subdirs,
            recursive=recursive,
            make_plots=make_plots,
            defaults=defaults,
        )

    out_dir = Path(config.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    prefix = _prefix(config)
    paths: dict[str, Path] = {}

    observations = arw_process_directory(config)
    genotype_order_final, timepoint_order_final = _analysis_orders(observations, config)

    if config.save_observations:
        paths["observations"] = _write_csv(out_dir / f"{prefix}_observations.csv", observations)

    high_contrast = arw_derive_high_contrast(
        observations,
        n_contrasts=config.high_contrast_n,
    )
    fit_parameters = arw_fit_observations(observations, fit_types=config.fit_types)

    high_summary = _summary_table(high_contrast, ["metric", "harmonic", "mask"])
    fit_summary = _summary_table(fit_parameters, ["fit_type", "parameter", "harmonic", "mask"])
    high_anova = arw_anova_table(
        high_contrast,
        ["metric", "harmonic", "mask"],
        genotype_order=genotype_order_final,
        timepoint_order=timepoint_order_final,
    )
    fit_anova = arw_anova_table(
        fit_parameters,
        ["fit_type", "parameter", "harmonic", "mask"],
        genotype_order=genotype_order_final,
        timepoint_order=timepoint_order_final,
    )
    high_posthoc = arw_tukey_posthoc(
        high_contrast,
        ["metric", "harmonic", "mask"],
        genotype_order=genotype_order_final,
        timepoint_order=timepoint_order_final,
    )
    fit_posthoc = arw_tukey_posthoc(
        fit_parameters,
        ["fit_type", "parameter", "harmonic", "mask"],
        genotype_order=genotype_order_final,
        timepoint_order=timepoint_order_final,
    )

    paths["high_contrast_long"] = _write_csv(
        out_dir / f"{prefix}_high_contrast_FLY_long.csv",
        high_contrast,
    )
    paths["high_contrast_wide"] = _write_csv(
        out_dir / f"{prefix}_high_contrast_JASP_wide.csv",
        _prepare_high_contrast_wide(high_contrast),
    )
    paths["high_contrast_summary"] = _write_csv(
        out_dir / f"{prefix}_high_contrast_summary.csv",
        high_summary,
    )
    paths["high_contrast_anova"] = _write_csv(
        out_dir / f"{prefix}_high_contrast_anova.csv",
        high_anova,
    )
    paths["high_contrast_posthoc"] = _write_csv(
        out_dir / f"{prefix}_high_contrast_posthoc_tukey.csv",
        high_posthoc,
    )
    paths["fit_parameters_long"] = _write_csv(
        out_dir / f"{prefix}_fit_parameters_FLY_long.csv",
        fit_parameters,
    )
    paths["fit_parameters_wide"] = _write_csv(
        out_dir / f"{prefix}_fit_parameters_JASP_wide.csv",
        _prepare_fit_wide(fit_parameters),
    )
    paths["fit_parameters_summary"] = _write_csv(
        out_dir / f"{prefix}_fit_parameters_summary.csv",
        fit_summary,
    )
    paths["fit_parameters_anova"] = _write_csv(
        out_dir / f"{prefix}_fit_parameters_anova.csv",
        fit_anova,
    )
    paths["fit_parameters_posthoc"] = _write_csv(
        out_dir / f"{prefix}_fit_parameters_posthoc_tukey.csv",
        fit_posthoc,
    )

    if config.make_plots:
        paths["crf_plot"] = arw_plot_crfs(
            observations,
            config,
            output_path=out_dir / f"{prefix}_CRFs.png",
        )
        high_plot = arw_plot_high_contrast_boxplots(
            high_contrast,
            high_posthoc,
            config,
            output_path=out_dir / f"{prefix}_high_contrast_boxplots.png",
            anova=high_anova,
        )
        if high_plot is not None:
            paths["high_contrast_boxplots"] = high_plot

        high_anova_plot = arw_plot_anova_summary(
            high_anova,
            ["harmonic", "mask"],
            lambda group: f"{group[0]} · mask {group[1]}",
            output_path=out_dir / f"{prefix}_high_contrast_anova.png",
            title="High-contrast mean — ANOVA effects",
        )
        if high_anova_plot is not None:
            paths["high_contrast_anova_plot"] = high_anova_plot

        for fit_type in config.fit_types:
            fit_plot = arw_plot_fit_parameter_boxplots(
                fit_parameters,
                fit_posthoc,
                config,
                fit_type=fit_type,
                output_path=out_dir / f"{prefix}_{fit_type}_parameter_boxplots.png",
                anova=fit_anova,
            )
            if fit_plot is not None:
                paths[f"{fit_type}_parameter_boxplots"] = fit_plot

            fit_type_anova = (
                fit_anova[fit_anova["fit_type"].astype(str) == fit_type]
                if not fit_anova.empty
                else fit_anova
            )
            fit_anova_plot = arw_plot_anova_summary(
                fit_type_anova,
                ["parameter", "harmonic", "mask"],
                lambda group: f"{group[0]}\n{group[1]} · m{group[2]}",
                output_path=out_dir / f"{prefix}_{fit_type}_anova.png",
                title=f"{fit_type.replace('_', ' ')} parameters — ANOVA effects",
            )
            if fit_anova_plot is not None:
                paths[f"{fit_type}_anova_plot"] = fit_anova_plot

    return ArwAnalysisResult(
        observations=observations,
        high_contrast=high_contrast,
        fit_parameters=fit_parameters,
        paths=paths,
    )


__all__ = [
    "ARW_PALETTE",
    "ArwAnalysisConfig",
    "ArwAnalysisResult",
    "ArwSubdirectory",
    "arw_analyze_directory",
    "arw_anova_table",
    "arw_derive_high_contrast",
    "arw_discover_subdirs",
    "arw_fit_observations",
    "arw_p_to_stars",
    "arw_plot_anova_summary",
    "arw_plot_crfs",
    "arw_plot_fit_parameter_boxplots",
    "arw_plot_high_contrast_boxplots",
    "arw_process_directory",
    "arw_tukey_posthoc",
]

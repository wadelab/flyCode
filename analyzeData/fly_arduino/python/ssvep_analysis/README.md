# SSVEP Bootstrap Analysis

Bootstrap contrast-response function (CRF) fitting for Drosophila SSVEP electrophysiology data recorded with the fly-arduino rig.

## Setup

Requires [uv](https://docs.astral.sh/uv/).

```bash
cd fly_arduino/python/ssvep_analysis
uv sync
```

## Usage

### General `arw_` toolbox

`arw-analyse` is the reusable pipeline for any root folder containing SVP
subdirectories. It discovers folders such as `GAL80LACZ_7dpe`, infers
`genotype=GAL80LACZ` and `timepoint=7dpe`, then writes fly-level observations,
derived high-contrast means, per-fly fitted parameters, two-way ANOVA tables,
Tukey post-hocs with significance stars, and publication-oriented plots.

```bash
source .venv/bin/activate

arw-analyse /raid/data/SITRAN/GAL80_hSNCA-raw \
    -o ./output/hSNCA \
    -p arw_hSNCA \
    --fit-types reduced_hyper power full_hyper fixed_c50_hyper
```

Useful options:

- `--subdirs A_7dpe,B_7dpe` limits the run to selected subdirectories.
- `--recursive` finds SVP-containing folders below nested roots.
- `--genotype-order` and `--timepoint-order` set plot/stat ordering.
- `--no-plots` writes CSV outputs only.

Plots:

- **CRFs** (`*_CRFs.png`): mean ± SEM markers, a fitted curve per genotype, and
  a shaded 95% bootstrap CI band (flies resampled with replacement) — one panel
  per harmonic/mask × timepoint.
- **Boxplots** (`*_high_contrast_boxplots.png`, `*_<fit>_parameter_boxplots.png`):
  genotypes grouped by timepoint with jittered points, Tukey post-hoc brackets
  with stars, and a per-panel two-way ANOVA note (`G / T / G×T`).
- **ANOVA heatmaps** (`*_high_contrast_anova.png`, `*_<fit>_anova.png`): effect ×
  condition grid shaded by `-log10(p)` and annotated with stars and F.

CSV outputs:

- `*_observations.csv` - one row per fly/probe/mask/harmonic amplitude.
- `*_high_contrast_FLY_long.csv` and `*_high_contrast_JASP_wide.csv`.
- `*_fit_parameters_FLY_long.csv` and `*_fit_parameters_JASP_wide.csv`.
- `*_summary.csv`, `*_anova.csv`, and `*_posthoc_tukey.csv` stats exports.

To reproduce the hSNCA figures with the pinned genotype order and colours, run
`python run_hsnca_arw.py` (writes to `output/hSNCA_arw/`).

### CLI

```bash
# Activate the venv
source .venv/bin/activate

# Run analysis (power curve, 10 bootstraps, 2 genotypes)
ssvep-analyse /raid/data/SITRAN/DJ1_data_15_08_24 \
    DJ1aDJ1b_1dpe DJ1aDJ1b_14dpe \
    -n 10 -c power -o ./output

# Or use uv run
uv run ssvep-analyse /path/to/data Genotype1 Genotype2 -n 100 -c reduced_hyper
```

### Python API

```python
from ssvep_analysis.reader import read_file
from ssvep_analysis.bootstrap import bootstrap_ssveps

# Read a single file
data, meta = read_file("path/to/10H39M25.SVP", freq=12)

# Run bootstrap analysis
results = bootstrap_ssveps(
    main_directory="/path/to/data",
    genotypes=["Genotype1", "Genotype2"],
    n_bootstraps=100,
    curve_type="power",
)
```

## Curve types

| Key | Function | Parameters |
|---|---|---|
| `reduced_hyper` | Rmax·c² / (c50² + c²) | c50, Rmax |
| `fixed_c50_hyper` | Rmax·c² / (50² + c²) | Rmax |
| `full_hyper` | Rmax·cⁿ / (c50ⁿ + cⁿ) + R0 | c50, Rmax, n, R0 |
| `power` | scale · c^exponent | exponent, scale |

## Outputs

When `save=True` (default):

- `*_RAW.csv` — per-bootstrap parameter estimates
- `*_SUM.csv` — summary statistics (min, 2.5th percentile, mean, 97.5th percentile, max)
- `*_HIS.png` — overlaid bootstrap histograms per genotype

## Project structure

```
ssvep_analysis/
├── pyproject.toml
├── README.md
└── src/ssvep_analysis/
    ├── __init__.py
    ├── reader.py      # File I/O and FFT extraction
    ├── bootstrap.py   # Bootstrap CRF fitting engine
    └── cli.py         # Command-line interface

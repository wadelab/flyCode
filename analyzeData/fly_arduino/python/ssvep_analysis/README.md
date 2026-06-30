# SSVEP Bootstrap Analysis

Bootstrap contrast-response function (CRF) fitting for Drosophila SSVEP electrophysiology data recorded with the fly-arduino rig.

## Setup

Requires [uv](https://docs.astral.sh/uv/).

```bash
cd fly_arduino/python/ssvep_analysis
uv sync
```

## Usage

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
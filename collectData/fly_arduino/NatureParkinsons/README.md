# NatureParkinsons — reference acquisition code

Frozen reference copy of `WebServerNoIPNoZapOct24` (Arduino Due sketch used to
record the SSVEP/ERG data for the GAL80 hSNCA Parkinson's paper). Copied on
2026-08-27 from flyCode commit e0740a0; the only change is the sketch rename
(`WebServerNoIPNoZapOct24.ino` -> `NatureParkinsons.ino`, required because the
Arduino IDE needs the `.ino` to match its folder name). Do not edit: treat as
the archival version cited in the manuscript. Live development continues in
`WebServerNoIPNoZapOct24`.

## Stimulus parameters (as compiled)

| Parameter | Value | Source line |
|---|---|---|
| F1 (probe) | 12 Hz sinusoid | `freq1` |
| F2 (mask) | 15 Hz sinusoid | `freq2` |
| Probe contrasts | 5, 10, 30, 70, 100 % (mask 0 %) and 5, 10, 30, 70 % (mask 30 %) | `F1contrast[]`, `F2contrast[]` |
| Conditions | 9, reshuffled (Fisher-Yates) every block | `maxContrasts`, `doShuffle()` |
| Repeats | 5 blocks -> 45 trials per fly | `maxRepeats` |
| Sampling | 250 Hz (4 ms), 1025 samples (~4.1 s) + 102 pre-samples for DC baseline | `startTimer(250)`, `max_data`, `presamples` |
| LED drive | `127 + 1.27*(c1*sin(2*pi*12*t) + c2*sin(2*pi*15*t))`, 8-bit PWM; mean luminance between trials | `Get_br_Now()` |

Matching analysis defaults: `analyzeData/fly_arduino/python/ssvep_analysis`
(`ExperimentDefaults` in `reader.py`).

## Files

- `NatureParkinsons.ino` — the sketch
- `due.h` — per-board `#define dueNN` selecting the MAC address (rig-specific)
- `temperature_calibration_2019.xlsx` — thermistor calibration
- `favicon-32x32.png` — served by the built-in web page

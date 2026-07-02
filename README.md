# Predictable Patterns of Protest: The Impact of Agricultural Cycles on Social Unrest in Kenya — Replication Package

Replication code for the analysis of how the agricultural crop cycle relates to
protest activity across Kenyan wards (2000–2019), using a ward-level panel,
satellite-derived NDVI harvest indicators, and geocoded ACLED protest records.

## Repository layout

```
conflict-replication/
├── code/                  # all do-files
│   ├── master.do          # << run this. Orchestrates the whole pipeline.
│   ├── 00_prepare_data.do # builds the cached analysis sample (run once)
│   ├── _load.do           # helper: loads a dataset only if not already in memory
│   ├── Figure2.do … Figure5.do
│   ├── Table1.do  … Table8.do
│   └── App_Figure9.do, App_Figure10.do, App_Table9.do … App_Table13.do
├── data/                  # input .dta files (NOT tracked in git — see below)
│   └── _cache/            # auto-generated cached analysis dataset
└── Results/               # all exported figures (.png) and tables (.tex)
```

## How to run

1. Place the input data files (see **Data** below) in the `data/` folder.
2. Open `code/master.do`.
3. Set the project root at the top of the file if needed. By default it
   auto-detects the location of `master.do` and uses its parent folder, so if
   you keep the folder structure above you usually do not need to edit anything.
4. Run `master.do`. All output is written to `Results/`.

You can also run any individual do-file on its own: each one has a small
standalone configuration block at the top that sets the paths and loads the data
it needs if the globals are not already defined.

## Efficiency design

- **`00_prepare_data.do`** builds every derived variable once
  (`priots_*` buffer sums, the binary outcome, the per-sqkm outcome including the
  `adm3_area` merge, the FE interaction groups, and the election / warning
  robustness flags) and saves a cached file to
  `data/_cache/_cache_analysis_80percent.dta`.
- Downstream scripts load that cached file via **`_load.do`**, which only re-reads
  the dataset from disk when the file currently in memory is different. Running
  the pipeline through `master.do` therefore reads the main analysis sample from
  disk once and keeps it in memory across all the scripts that use it.
- To skip rebuilding the cache on subsequent runs, set `global RUN_PREP 0` in
  `master.do`.

## Required Stata packages

Installed automatically by `master.do` (comment the install block out if you are
offline or already have them):

`reghdfe`, `ftools`, `did_multiplegt_dyn` (ships `sotable`), `gtools`,
`estout` (`esttab`/`eststo`), `xtevent`, `acreg`.

## Data

The following input files go in `data/` (they are not redistributed here):

| File | Used by |
|------|---------|
| `database_final_80percent.dta` | main analysis (Tables 2–8, Figures 4–5, App Tables 9–12) |
| `adm3_area.dta` | merged in data prep for the per-sqkm outcome |
| `database_final.dta` | Figure 2 |
| `dataset_20240202_copernicus_clean.dta` | Figure 3 |
| `data_figure2.dta` | Appendix Figures 9–10 |

## Notes on the long-running specifications

Two sets of estimates are computationally very expensive in Stata and are left
**commented out** in the do-files, with both the Stata syntax and a faster
Python reference implementation preserved alongside:

- **Conley spatial-HAC standard errors** (`acreg`) in `Table2.do`.
- **Conditional logit and zero-inflated Poisson** (`clogit`, `zip`) in
  `Table4.do`.

These blocks are intentionally not executed by default. Uncomment them (or run
the included Python) if you wish to reproduce those columns.

## Minor fix relative to the original source

In `Table7.do` the `effects(4)` and `effects(5)` runs both exported to
`timewindow5_5.png` in the original, so the first was overwritten. The
`effects(4)` graph is now exported to `timewindow4_4.png`. The estimation
commands themselves are unchanged.

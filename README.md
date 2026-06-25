# Pepperwood LFM: Live Fuel Moisture and Water Potential Relationships

Code and data for analyzing the relationship between live fuel moisture (LFM) and water potential across California study sites (Pepperwood Preserve, Stunt Ranch, Sedgwick Reserve, and Sierra Nevada).

## Repository structure

```
R/                     Analysis scripts (run in numbered order)
data/                  Input datasets
  raw/                 Raw field measurements (Pepperwood Oct 2021, Jun 2022)
  other_studies/       Comparative data from other study sites
output/                Generated figures and tables (gitignored)
```

## How to reproduce

### Requirements

- R (>= 4.0)
- Key packages: `tidyverse`, `here`, `lme4`, `lmerTest`, `brms`, `cowplot`, `patchwork`, `ggridges`, `car`, `Metrics`, `kableExtra`, `fExtremes`, `performance`, `emmeans`, `GGally`, `ggnewscale`, `ggpmisc`, `tidybayes`

### Run the pipeline

Scripts are numbered in execution order. Run from the project root directory:

1. **`R/01_data_prep.R`** — Calculates LFM from raw Pepperwood field measurements
2. **`R/02_combine_data.R`** — Merges Pepperwood data with Stunt Ranch, Sierra, and Sedgwick datasets
3. **`R/03_traits_compile.R`** *(optional)* — Compiles species traits from TRY database. Output (`data/traits_rd_20250327.csv`) is pre-built; only re-run if updating trait data. Requires `data/try_all_20241014.csv` (not included; obtain from [TRY Plant Trait Database](https://www.try-db.org/))
4. **`R/04_Q1_models_and_figures.Rmd`** — Q1: Water potential vs. LFM models (Figs 1-3, S2-S5)
5. **`R/05_Q1_bayesian.Rmd`** — Q1: Bayesian ridgeline visualization (Fig 4). Note: MCMC sampling takes ~10-30 min
6. **`R/06_Q1_cross_study.Rmd`** — Q1: Cross-study slope/intercept comparison (Fig 5, Table S5)
7. **`R/07_Q2_model_params.Rmd`** — Q2: Model parameter relationships and isoclines (Figs 6-7, S9)
8. **`R/08_Q3_trait_correlations.Rmd`** — Q3: Trait-parameter correlations (Figs 8-9, S7, S10-S12, Table S6)
9. **`R/09_Q4_model_prediction.Rmd`** — Q4: Model selection and prediction testing (Fig 10, Table S7)

Scripts 00 (`00_figure_setup.R`, `00_functions.R`) are sourced automatically by the analysis scripts.

## Data sources

- **Pepperwood Preserve**: Field measurements from [PepperwoodVegPlots](https://github.com/dackerly/PepperwoodVegPlots)
- **Stunt Ranch**: Pivovaroff et al. water potential vs. LFM data
- **Sierra Nevada**: Sierra LFM and water potential measurements
- **Sedgwick Reserve**: 2022 LFM and water potential data
- **Species traits**: Compiled from [TRY Plant Trait Database](https://www.try-db.org/) and literature values

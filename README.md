# Multivariate Statistics Course Project 2

2nd Repository for applying multivariate methods from a MVS II course to ZOFE dataset and preparing a scientific poster.

## Contributors
- **Klaus Jarosh** — Agroscope
- **Jelena Čuklina** — NEXUS Personalized Health, ETH Zurich
 
## Project Goal

### Methodological
Apply and interpret the outputs of the following methods on a ZOFE dataset:
- Causality methods
- Regression models
    - Random Forest
    - Linear models
    - Feature selection models

### Research questions

1. Is specific nutrient availability in fertilizer predictive of higher yields?
    - is adding nutrients "artificially" influencing higher yields?
2. Which features are predictive of higher yields?

## Analys plan

1. Exploratory Data Analysis


Final output: **poster**. Draft output: **R Markdown slide deck**.

## Repository Structure
- `data`: data folders + dataset description
  - `data/raw/` — original data files (read-only, not versioned on git)
  - `data/processed/` — cleaned/derived data
- `scripts/` — R scripts for analysis pipeline
- `notebooks/` — exploratory notebooks (Rmd, optional)
- `poster_drafts/` — poster-draft slide deck(s)
- `outputs` (not versioned on git)
  - `outputs/figures/` — generated plots
  - `outputs/tables/` — generated tables
- `docs/` — design docs etc.

## Proposed Project Workflow
1. Add dataset and data description to `data` and `data/raw/` correspondingly.
2. (TBC) Run preprocessing scripts. Create EDA output for the dataset
3. For each method:
   1. Execute method-specific analysis, upload / commit the analysis, including the interpretation.
   2. Review the analysis for the method executed by partner, upload / commit proposed edits.
4. Consolidate key findings into slide deck draft.
5. Convert/refine into final poster.

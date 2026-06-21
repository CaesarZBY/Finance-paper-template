# Empirical Research Workflow Template

This repository is a reusable workflow template for empirical research projects in finance, accounting, economics, management, and international business.

The purpose of this repository is to support a semi-automated, reproducible, and transparent research workflow using:

* R
* Python
* GitHub
* Codex
* Quarto
* Zotero / BibTeX
* reproducible research tools

Codex can assist with coding, debugging, documentation, and workflow organization, but the researcher remains responsible for theoretical judgment, identification strategy, interpretation, and research integrity.

---

## 1. Project Purpose

This repository is designed to support empirical paper development from early-stage research design to manuscript preparation.

The workflow may include:

1. research idea development
2. literature organization
3. data source documentation
4. variable definition
5. data cleaning
6. panel data merging
7. variable construction
8. descriptive statistics
9. baseline regressions
10. mechanism analysis
11. robustness checks
12. endogeneity checks
13. heterogeneity analysis
14. tables and figures
15. manuscript drafting
16. simulated peer review
17. revision planning

The workflow is modular. Each step should be run and checked separately.

---

## 2. Repository Structure

```text
.
├── AGENTS.md
├── README.md
├── .gitignore
│
├── R/
│   ├── 00_config.R
│   ├── 01_clean.R
│   ├── 02_merge_panel.R
│   ├── 03_construct_variables.R
│   ├── 04_descriptive_statistics.R
│   ├── 05_baseline_models.R
│   ├── 06_mechanism_models.R
│   ├── 07_robustness_checks.R
│   ├── 08_endogeneity_checks.R
│   ├── 09_heterogeneity_checks.R
│   └── 10_tables_figures.R
│
├── python/
│   ├── validate_data.py
│   ├── build_dataset.py
│   ├── scrape_or_api.py
│   └── text_processing.py
│
├── data/
│   ├── raw/
│   ├── interim/
│   ├── processed/
│   └── dictionary/
│
├── docs/
│   ├── data_sources.md
│   ├── variable_definitions.md
│   ├── identification_strategy.md
│   ├── literature_reading.md
│   └── research_log.md
│
├── outputs/
│   ├── tables/
│   ├── figures/
│   ├── logs/
│   └── manuscript/
│
├── paper/
│   ├── manuscript.qmd
│   └── references.bib
│
└── review/
    ├── reviewer_1.md
    ├── reviewer_2.md
    ├── reviewer_3.md
    ├── editor_summary.md
    └── response_matrix.md
```

Not every file must exist at the beginning. The repository can be built gradually.

---

## 3. Folder Explanation

### `R/`

This folder contains R scripts for the empirical workflow.

Recommended script order:

| Script                        | Purpose                                                                                     |
| ----------------------------- | ------------------------------------------------------------------------------------------- |
| `00_config.R`                 | Load packages, define paths, create folders                                                 |
| `01_clean.R`                  | Initial cleaning of raw data                                                                |
| `02_merge_panel.R`            | Merge panel datasets                                                                        |
| `03_construct_variables.R`    | Construct key variables, controls, moderators, mediators                                    |
| `04_descriptive_statistics.R` | Generate descriptive statistics and correlation tables                                      |
| `05_baseline_models.R`        | Run baseline regressions                                                                    |
| `06_mechanism_models.R`       | Run mechanism or channel analysis                                                           |
| `07_robustness_checks.R`      | Run robustness checks                                                                       |
| `08_endogeneity_checks.R`     | Run DID, IV, PSM, entropy balancing, Heckman, placebo tests, or other identification checks |
| `09_heterogeneity_checks.R`   | Run heterogeneity analysis                                                                  |
| `10_tables_figures.R`         | Export final tables and figures                                                             |

Each script should be able to run independently when possible.

---

### `python/`

This folder contains Python scripts for tasks that are better handled in Python, such as:

* large-scale data cleaning
* validation
* file conversion
* text processing
* web scraping
* API work

R remains the preferred language for econometric analysis.

---

### `data/`

This folder stores data files.

| Folder             | Purpose                                                     |
| ------------------ | ----------------------------------------------------------- |
| `data/raw/`        | Raw source data. Do not modify. Do not commit private data. |
| `data/interim/`    | Intermediate generated datasets                             |
| `data/processed/`  | Final cleaned datasets used for regressions                 |
| `data/dictionary/` | Data dictionaries, codebooks, variable maps                 |

Important rule:

Raw data in `data/raw/` should never be overwritten by scripts.

---

### `docs/`

This folder stores research documentation.

| File                         | Purpose                                                   |
| ---------------------------- | --------------------------------------------------------- |
| `data_sources.md`            | Documents all data sources                                |
| `variable_definitions.md`    | Defines all key variables                                 |
| `identification_strategy.md` | Documents empirical design and endogeneity strategy       |
| `literature_reading.md`      | Stores literature notes                                   |
| `research_log.md`            | Tracks research decisions, failed attempts, and revisions |

Research decisions should be documented in `docs/research_log.md`.

---

### `outputs/`

This folder stores generated outputs.

| Folder                | Purpose                                                                |
| --------------------- | ---------------------------------------------------------------------- |
| `outputs/tables/`     | Regression tables, descriptive statistics, balance tables              |
| `outputs/figures/`    | Figures and plots                                                      |
| `outputs/logs/`       | Merge logs, missing value reports, sample flow reports, debugging logs |
| `outputs/manuscript/` | Rendered manuscript outputs                                            |

Outputs are generated by code and may be ignored by Git depending on project settings.

---

### `paper/`

This folder stores manuscript files.

Recommended files:

| File                           | Purpose                   |
| ------------------------------ | ------------------------- |
| `manuscript.qmd`               | Main Quarto manuscript    |
| `01_introduction.qmd`          | Introduction              |
| `02_literature_review.qmd`     | Literature review         |
| `03_theory_hypotheses.qmd`     | Theory and hypotheses     |
| `04_data_methodology.qmd`      | Data and methodology      |
| `05_results.qmd`               | Empirical results         |
| `06_robustness.qmd`            | Robustness checks         |
| `07_mechanism.qmd`             | Mechanism analysis        |
| `08_additional_analyses.qmd`   | Additional analyses       |
| `09_discussion_conclusion.qmd` | Discussion and conclusion |
| `references.bib`               | BibTeX references         |

Manuscript writing should use academic English unless otherwise instructed.

---

### `review/`

This folder stores simulated peer review and revision materials.

Recommended files:

| File                 | Purpose                                     |
| -------------------- | ------------------------------------------- |
| `reviewer_1.md`      | Econometrics or finance/accounting reviewer |
| `reviewer_2.md`      | Theory or international business reviewer   |
| `reviewer_3.md`      | Data and reproducibility reviewer           |
| `editor_summary.md`  | Simulated editor decision                   |
| `response_matrix.md` | Response plan for revision                  |

---

## 4. Data Protection Rules

Do not commit private or paid database files to GitHub.

Files that should usually not be committed include:

* raw CSMAR files
* raw Wind files
* raw WRDS files
* raw Compustat files
* private firm-level data
* confidential coauthor comments
* confidential reviewer comments
* large raw Excel files
* Stata `.dta` files
* R `.rds` or `.RData` files
* generated intermediate datasets

Raw data should remain in:

```text
data/raw/
```

Cleaned data should be generated into:

```text
data/interim/
data/processed/
```

---

## 5. Standard R Workflow

The preferred workflow is modular.

Run one step at a time.

### 5.1 Load project configuration

```bash
Rscript R/00_config.R
```

### 5.2 Clean raw data

```bash
Rscript R/01_clean.R
```

### 5.3 Merge panel data

```bash
Rscript R/02_merge_panel.R
```

### 5.4 Construct variables

```bash
Rscript R/03_construct_variables.R
```

### 5.5 Generate descriptive statistics

```bash
Rscript R/04_descriptive_statistics.R
```

### 5.6 Run baseline models

```bash
Rscript R/05_baseline_models.R
```

### 5.7 Run mechanism analysis

```bash
Rscript R/06_mechanism_models.R
```

### 5.8 Run robustness checks

```bash
Rscript R/07_robustness_checks.R
```

### 5.9 Run endogeneity checks

```bash
Rscript R/08_endogeneity_checks.R
```

### 5.10 Run heterogeneity checks

```bash
Rscript R/09_heterogeneity_checks.R
```

### 5.11 Export final tables and figures

```bash
Rscript R/10_tables_figures.R
```

Do not run all scripts unless the researcher explicitly requests a full pipeline run.

---

## 6. Recommended R Packages

Common R packages include:

```r
library(data.table)
library(dplyr)
library(tidyr)
library(stringr)
library(readr)
library(readxl)
library(writexl)
library(haven)
library(fixest)
library(modelsummary)
library(broom)
library(ggplot2)
library(MatchIt)
library(WeightIt)
library(cobalt)
library(sampleSelection)
library(AER)
library(ivreg)
library(did)
library(clubSandwich)
```

Do not load unnecessary packages.

If a package is missing, install it or provide a minimal alternative.

---

## 7. Recommended Python Packages

Common Python packages include:

```python
import pandas as pd
import numpy as np
import polars as pl
import duckdb
import pyarrow
import statsmodels.api as sm
```

Python should mainly be used for data cleaning, validation, file conversion, text processing, scraping, or API work.

R should remain the main language for econometric analysis.

---

## 8. Codex Usage Rules

Codex should work as an empirical research assistant.

Codex should:

* inspect relevant files before editing
* work module by module
* avoid changing unrelated files
* protect raw data
* run the smallest relevant script first
* debug using the smallest failing step
* document important changes
* report errors honestly
* avoid fabricating results
* avoid p-hacking

Codex should not:

* modify `data/raw/`
* invent results
* invent citations
* run the full workflow unless explicitly asked
* change model specifications only to obtain significance
* hide failed results
* overclaim causality

---

## 9. Example Codex Tasks

### 9.1 Inspect repository

```text
Please inspect the repository structure and summarize what each folder and key file does. Do not modify any files.
```

### 9.2 Improve repository scaffolding

```text
Please inspect the repository and improve only the scaffolding. Do not run regressions. Do not modify raw data. Create missing folders or placeholder files if needed, and summarize all changes.
```

### 9.3 Merge panel data

```text
Please update and run R/02_merge_panel.R to merge the panel datasets using stock and year as keys. Do not modify files in data/raw/. Save intermediate or processed outputs to data/interim/ or data/processed/. Generate merge diagnostics in outputs/logs/. If the script fails, debug the smallest failing step and rerun it.
```

### 9.4 Check data quality

```text
Please inspect the processed dataset and create a data quality report. Check missing values, duplicate firm-year observations, sample size, panel balance, and key variable distributions. Save logs to outputs/logs/. Do not run regressions.
```

### 9.5 Run baseline regression

```text
Please update and run R/05_baseline_models.R using the processed panel dataset. Use fixest for panel fixed effects regressions. Report the dependent variable, independent variable, controls, fixed effects, clustering level, observations, adjusted R-squared, and whether the hypothesis is supported. Save tables to outputs/tables/.
```

### 9.6 Debug a script

```text
Please run R/05_baseline_models.R. If it fails, identify the exact error, modify only the relevant file, rerun the smallest relevant command, and summarize the fix.
```

### 9.7 Simulate peer review

```text
Please read the manuscript and main empirical results, then simulate three reviewers: an econometrics reviewer, a theory reviewer, and a data/reproducibility reviewer. Save the reviews in the review/ folder.
```

---

## 10. Research Log

Use:

```text
docs/research_log.md
```

to record major project decisions.

Each log entry should include:

```text
Date:
Change made:
Reason:
Files changed:
Result changed:
Theoretical justification:
Exploratory or confirmatory:
Notes:
```

Failed attempts should also be documented.

---

## 11. Current Project Status

Current status:

```text
Repository scaffolding stage.
```

The current goal is to build a reusable, modular, and Codex-compatible empirical workflow.

The project is not yet assumed to have a finalized dataset, finalized variables, finalized baseline model, or finalized identification strategy.

---

## 12. Next Steps

Suggested next steps:

1. Confirm folder structure.
2. Confirm `.gitignore`.
3. Complete `R/00_config.R`.
4. Create templates for documentation files.
5. Create `R/02_merge_panel.R`.
6. Test the merge workflow with local data.
7. Create data quality logs.
8. Build baseline regression script.
9. Add robustness and endogeneity modules.
10. Add manuscript and review workflow.

---

## 13. Research Integrity Reminder

This repository is designed to make empirical research more transparent, reproducible, and efficient.

It should not be used to hide failed results, fabricate significance, or overstate causal claims.

When evidence is weak, report it honestly and improve the research design.


# R/00_config.R
# Project configuration file
# This file loads common packages and creates required folders.

# -----------------------------
# 1. Required packages
# -----------------------------

required_packages <- c(
  "data.table",
  "dplyr",
  "tidyr",
  "stringr",
  "readr",
  "readxl",
  "writexl",
  "haven",
  "fixest",
  "modelsummary",
  "broom",
  "ggplot2"
)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(required_packages, install_if_missing))

# -----------------------------
# 2. Load packages
# -----------------------------

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

# -----------------------------
# 3. Define project paths
# -----------------------------

path_data_raw <- "data/raw"
path_data_interim <- "data/interim"
path_data_processed <- "data/processed"
path_data_dictionary <- "data/dictionary"

path_outputs <- "outputs"
path_tables <- "outputs/tables"
path_figures <- "outputs/figures"
path_logs <- "outputs/logs"
path_manuscript_outputs <- "outputs/manuscript"

path_docs <- "docs"
path_paper <- "paper"

# -----------------------------
# 4. Create required folders
# -----------------------------

required_dirs <- c(
  path_data_raw,
  path_data_interim,
  path_data_processed,
  path_data_dictionary,
  path_outputs,
  path_tables,
  path_figures,
  path_logs,
  path_manuscript_outputs,
  path_docs,
  path_paper
)

invisible(lapply(required_dirs, dir.create, recursive = TRUE, showWarnings = FALSE))

# -----------------------------
# 5. Helper function
# -----------------------------

write_log <- function(text, file = file.path(path_logs, "run_log.md"), append = TRUE) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- paste0("\n## ", timestamp, "\n\n", text, "\n")
  cat(line, file = file, append = append)
}

message("Project configuration loaded successfully.")

# R/02_merge_panel.R
# Reusable firm-year panel merge script
#
# Purpose:
#   Merge a main firm-year panel dataset with an additional firm-year dataset
#   using stock and year as the default merge keys.
#
# Important safety rules:
#   - This script reads from data/raw/ but never writes to data/raw/.
#   - This script does not create fake example data.
#   - This script performs only the panel merge module; it does not run
#     regressions or any downstream empirical workflow.

source("R/00_config.R")

# -----------------------------------------------------------------------------
# 1. Configurable paths and merge keys
# -----------------------------------------------------------------------------
# Place the real source files in data/raw/ using these names, or edit these paths
# before running the script. Raw files are treated as protected inputs.

main_file <- "data/raw/main_data.xlsx"
add_file <- "data/raw/additional_data.xlsx"
output_file <- "data/processed/merged_panel.xlsx"

# Default firm-year merge keys. Edit here if your project uses different names.
merge_keys <- c("stock", "year")
stock_key <- "stock"
year_key <- "year"

# Diagnostics and log outputs. These are generated files, not raw data.
duplicate_main_file <- "outputs/logs/duplicate_keys_main.csv"
duplicate_add_file <- "outputs/logs/duplicate_keys_additional.csv"
merge_quality_file <- "outputs/logs/merge_quality.csv"
sample_flow_file <- "outputs/logs/sample_flow.md"

# -----------------------------------------------------------------------------
# 2. Helper functions
# -----------------------------------------------------------------------------

# Stop early with a clear message if an expected input file is missing.
check_input_file <- function(file_path) {
  if (!file.exists(file_path)) {
    stop(
      paste0(
        "Input file not found: ", file_path, "\n",
        "Please place the real Excel file at this path, or update the path ",
        "configuration near the top of R/02_merge_panel.R.\n",
        "Do not create fake data; this merge script is designed to run once ",
        "real source files are available in data/raw/."
      ),
      call. = FALSE
    )
  }
}

# Trim whitespace from column names while leaving the data values unchanged.
trim_column_names <- function(data) {
  names(data) <- stringr::str_trim(names(data))
  data
}

# Read an Excel file while forcing the stock-code column to text when possible.
# This helps protect leading zeros in stock codes such as "000001".
read_panel_excel <- function(file_path, stock_column = stock_key) {
  header_only <- readxl::read_excel(file_path, n_max = 0)
  header_names <- stringr::str_trim(names(header_only))

  stock_position <- match(stock_column, header_names)

  if (is.na(stock_position)) {
    # The formal missing-column check below will report all missing keys.
    data <- readxl::read_excel(file_path)
  } else {
    col_types <- rep("guess", length(header_names))
    col_types[stock_position] <- "text"
    data <- readxl::read_excel(file_path, col_types = col_types)
  }

  trim_column_names(data)
}

# Confirm that all required merge keys exist in a dataset.
check_required_columns <- function(data, required_columns, dataset_label) {
  missing_columns <- setdiff(required_columns, names(data))

  if (length(missing_columns) > 0) {
    stop(
      paste0(
        "Required merge column(s) missing in ", dataset_label, ": ",
        paste(missing_columns, collapse = ", "), ".\n",
        "Available columns are: ", paste(names(data), collapse = ", "), ".\n",
        "Please rename the columns in the source file or edit merge_keys near ",
        "the top of R/02_merge_panel.R."
      ),
      call. = FALSE
    )
  }
}

# Standardize merge keys without changing non-key variables.
standardize_merge_keys <- function(data, dataset_label) {
  data %>%
    dplyr::mutate(
      # Preserve stock codes as character strings and trim accidental spaces.
      dplyr::across(
        dplyr::all_of(stock_key),
        ~ stringr::str_trim(as.character(.x))
      ),
      # Convert year to integer where possible. Non-convertible values become NA,
      # and the warning is handled explicitly below with a clear message.
      dplyr::across(
        dplyr::all_of(year_key),
        ~ suppressWarnings(as.integer(.x))
      )
    ) %>%
    {
      if (any(is.na(.[[year_key]]) & !is.na(data[[year_key]]))) {
        warning(
          paste0(
            "Some year values in ", dataset_label,
            " could not be converted to integer and were set to NA. ",
            "Please inspect the source file."
          ),
          call. = FALSE
        )
      }
      .
    }
}

# Save duplicate key diagnostics for a dataset. Empty reports are still saved so
# the researcher can verify that the check was performed.
save_duplicate_report <- function(data, dataset_label, output_path) {
  duplicate_report <- data %>%
    dplyr::count(dplyr::across(dplyr::all_of(merge_keys)), name = "n") %>%
    dplyr::filter(.data$n > 1) %>%
    dplyr::arrange(dplyr::desc(.data$n)) %>%
    dplyr::mutate(dataset = dataset_label, .before = 1)

  readr::write_csv(duplicate_report, output_path)
  duplicate_report
}

# -----------------------------------------------------------------------------
# 3. Read and validate input files
# -----------------------------------------------------------------------------

check_input_file(main_file)
check_input_file(add_file)

main_data <- read_panel_excel(main_file)
add_data <- read_panel_excel(add_file)

check_required_columns(main_data, merge_keys, "main dataset")
check_required_columns(add_data, merge_keys, "additional dataset")

main_data <- standardize_merge_keys(main_data, "main dataset")
add_data <- standardize_merge_keys(add_data, "additional dataset")

# -----------------------------------------------------------------------------
# 4. Duplicate-key checks
# -----------------------------------------------------------------------------

main_duplicates <- save_duplicate_report(
  main_data,
  dataset_label = "main",
  output_path = duplicate_main_file
)

add_duplicates <- save_duplicate_report(
  add_data,
  dataset_label = "additional",
  output_path = duplicate_add_file
)

# -----------------------------------------------------------------------------
# 5. Merge and diagnostics
# -----------------------------------------------------------------------------

main_rows <- nrow(main_data)
add_rows <- nrow(add_data)

# Count unmatched observations from the main dataset before the merge. Distinct
# additional keys are used because duplicate additional keys should not affect
# whether a main observation has at least one match.
add_keys <- add_data %>%
  dplyr::distinct(dplyr::across(dplyr::all_of(merge_keys)))

unmatched_main_rows <- main_data %>%
  dplyr::anti_join(add_keys, by = merge_keys) %>%
  nrow()

merged_panel <- main_data %>%
  dplyr::left_join(add_data, by = merge_keys)

merged_rows <- nrow(merged_panel)
row_count_increased <- merged_rows > main_rows

merge_quality <- tibble::tibble(
  diagnostic = c(
    "main_rows",
    "additional_rows",
    "merged_rows",
    "unmatched_main_rows",
    "main_duplicate_key_count",
    "additional_duplicate_key_count",
    "row_count_increased_unexpectedly"
  ),
  value = c(
    as.character(main_rows),
    as.character(add_rows),
    as.character(merged_rows),
    as.character(unmatched_main_rows),
    as.character(nrow(main_duplicates)),
    as.character(nrow(add_duplicates)),
    as.character(row_count_increased)
  )
)

readr::write_csv(merge_quality, merge_quality_file)

sample_flow <- c(
  "# Sample Flow: Panel Merge",
  "",
  paste0("- Main input file: `", main_file, "`"),
  paste0("- Additional input file: `", add_file, "`"),
  paste0("- Merge keys: `", paste(merge_keys, collapse = "`, `"), "`"),
  paste0("- Main dataset rows before merge: ", main_rows),
  paste0("- Additional dataset rows before merge: ", add_rows),
  paste0("- Rows after left join: ", merged_rows),
  paste0("- Unmatched observations from main dataset: ", unmatched_main_rows),
  paste0("- Duplicate stock-year keys in main dataset: ", nrow(main_duplicates)),
  paste0("- Duplicate stock-year keys in additional dataset: ", nrow(add_duplicates)),
  paste0("- Row count increased unexpectedly: ", row_count_increased),
  "",
  "Notes:",
  "- The main dataset is used as the left table in `dplyr::left_join()`.",
  "- A row-count increase usually indicates duplicate keys in the additional dataset and should be reviewed before regression analysis.",
  "- This script does not modify files in `data/raw/`."
)

writeLines(sample_flow, sample_flow_file)

# -----------------------------------------------------------------------------
# 6. Save merged dataset
# -----------------------------------------------------------------------------

writexl::write_xlsx(merged_panel, output_file)

message("Panel merge completed.")
message("Merged dataset saved to: ", output_file)
message("Merge diagnostics saved to: ", merge_quality_file)
message("Sample flow saved to: ", sample_flow_file)

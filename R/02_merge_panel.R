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
year_cleaning_examples_file <- "outputs/logs/year_cleaning_examples.csv"

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

# Read an Excel file while forcing the stock-code and year columns to text when
# possible. This helps protect leading zeros in stock codes and prevents Excel
# year/date values from being converted unpredictably before key normalization.
read_panel_excel <- function(file_path, stock_column = stock_key, year_column = year_key) {
  header_only <- readxl::read_excel(file_path, n_max = 0)
  header_names <- stringr::str_trim(names(header_only))

  stock_position <- match(stock_column, header_names)
  year_position <- match(year_column, header_names)

  text_positions <- stats::na.omit(c(stock_position, year_position))

  if (length(text_positions) == 0) {
    # The formal missing-column check below will report all missing keys.
    data <- readxl::read_excel(file_path)
  } else {
    col_types <- rep("guess", length(header_names))
    col_types[text_positions] <- "text"
    data <- readxl::read_excel(file_path, col_types = col_types)
  }

  trim_column_names(data)
}

# Normalize mixed year/date keys to integer calendar years. The function first
# extracts explicit 1900-2100 years from text-like values, then treats remaining
# numeric values as possible Excel serial dates.
normalize_year_key <- function(year_values) {
  valid_year <- function(year) {
    !is.na(year) & year >= 1900L & year <= 2100L
  }

  if (inherits(year_values, "Date")) {
    date_years <- as.integer(format(year_values, "%Y"))
    date_years[!valid_year(date_years)] <- NA_integer_
    return(date_years)
  }

  if (inherits(year_values, "POSIXt")) {
    datetime_years <- as.integer(format(as.Date(year_values), "%Y"))
    datetime_years[!valid_year(datetime_years)] <- NA_integer_
    return(datetime_years)
  }

  year_text <- stringr::str_trim(as.character(year_values))
  year_text[year_text %in% c("", "NA", "NaN")] <- NA_character_

  explicit_year <- stringr::str_extract(year_text, "19\\d{2}|20\\d{2}|2100")
  cleaned_year <- suppressWarnings(as.integer(explicit_year))

  unresolved <- is.na(cleaned_year) & !is.na(year_text)
  numeric_values <- suppressWarnings(as.numeric(year_text[unresolved]))
  max_excel_serial <- as.numeric(as.Date("2100-12-31") - as.Date("1899-12-30"))
  possible_serial <- !is.na(numeric_values) &
    numeric_values >= 1 &
    numeric_values <= max_excel_serial

  serial_years <- rep(NA_integer_, length(numeric_values))
  serial_dates <- as.Date(rep(NA_real_, length(numeric_values)), origin = "1899-12-30")
  serial_dates[possible_serial] <- as.Date(
    numeric_values[possible_serial],
    origin = "1899-12-30"
  )
  serial_years[possible_serial] <- as.integer(format(serial_dates[possible_serial], "%Y"))
  serial_years[!valid_year(serial_years)] <- NA_integer_
  cleaned_year[unresolved] <- serial_years

  cleaned_year[!valid_year(cleaned_year)] <- NA_integer_
  cleaned_year
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
      # Convert mixed year/date formats to integer years where possible.
      # Non-convertible values become NA, and the warning is handled below.
      dplyr::across(
        dplyr::all_of(year_key),
        ~ normalize_year_key(.x)
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

# Save examples of raw and cleaned year keys so date-like or mixed formats can
# be audited without opening the raw Excel files.
save_year_cleaning_examples <- function(main_raw, main_clean, add_raw, add_clean, output_path) {
  build_examples <- function(raw_data, clean_data, dataset_label) {
    tibble::tibble(
      dataset = dataset_label,
      raw_year_value = as.character(raw_data[[year_key]]),
      cleaned_year_value = clean_data[[year_key]]
    ) %>%
      dplyr::distinct(.data$dataset, .data$raw_year_value, .data$cleaned_year_value) %>%
      dplyr::slice_head(n = 25)
  }

  year_examples <- dplyr::bind_rows(
    build_examples(main_raw, main_clean, "main"),
    build_examples(add_raw, add_clean, "additional")
  )

  readr::write_csv(year_examples, output_path)
  year_examples
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

main_data_raw <- read_panel_excel(main_file)
add_data_raw <- read_panel_excel(add_file)

check_required_columns(main_data_raw, merge_keys, "main dataset")
check_required_columns(add_data_raw, merge_keys, "additional dataset")

main_data <- standardize_merge_keys(main_data_raw, "main dataset")
add_data <- standardize_merge_keys(add_data_raw, "additional dataset")

year_cleaning_examples <- save_year_cleaning_examples(
  main_data_raw,
  main_data,
  add_data_raw,
  add_data,
  year_cleaning_examples_file
)

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

main_keys <- main_data %>%
  dplyr::distinct(dplyr::across(dplyr::all_of(merge_keys)))

unmatched_main_keys <- main_keys %>%
  dplyr::anti_join(add_keys, by = merge_keys) %>%
  nrow()

unmatched_additional_keys <- add_keys %>%
  dplyr::anti_join(main_keys, by = merge_keys) %>%
  nrow()

merged_panel <- main_data %>%
  dplyr::left_join(add_data, by = merge_keys)

merged_rows <- nrow(merged_panel)
row_count_increased <- merged_rows > main_rows
matching_rate <- if (main_rows == 0) {
  NA_real_
} else {
  (main_rows - unmatched_main_rows) / main_rows
}

merge_quality <- tibble::tibble(
  diagnostic = c(
    "main_rows",
    "additional_rows",
    "merged_rows",
    "matching_rate",
    "unmatched_main_rows",
    "unmatched_main_keys",
    "unmatched_additional_keys",
    "main_duplicate_key_count",
    "additional_duplicate_key_count",
    "row_count_increased_unexpectedly"
  ),
  value = c(
    as.character(main_rows),
    as.character(add_rows),
    as.character(merged_rows),
    as.character(matching_rate),
    as.character(unmatched_main_rows),
    as.character(unmatched_main_keys),
    as.character(unmatched_additional_keys),
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
  paste0("- Matching rate for main observations: ", round(matching_rate * 100, 2), "%"),
  paste0("- Unmatched observations from main dataset: ", unmatched_main_rows),
  paste0("- Unmatched distinct keys from main dataset: ", unmatched_main_keys),
  paste0("- Unmatched distinct keys from additional dataset: ", unmatched_additional_keys),
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
message("Year cleaning examples saved to: ", year_cleaning_examples_file)
message("Sample flow saved to: ", sample_flow_file)

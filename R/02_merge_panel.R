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
unmatched_main_keys_file <- "outputs/logs/unmatched_main_keys.csv"
unmatched_additional_keys_file <- "outputs/logs/unmatched_additional_keys.csv"
unconvertible_year_values_file <- "outputs/logs/unconvertible_year_values.csv"

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

# Normalize stock codes before merging.
normalize_stock_key <- function(stock_values) {
  stock_chr <- stringr::str_trim(as.character(stock_values))
  stock_chr <- stringr::str_replace(stock_chr, "\\.0$", "")

  should_pad <- !is.na(stock_chr) &
    stringr::str_detect(stock_chr, "^[0-9]+$") &
    stringr::str_length(stock_chr) > 0 &
    stringr::str_length(stock_chr) < 6

  stock_chr[should_pad] <- stringr::str_pad(
    stock_chr[should_pad],
    width = 6,
    side = "left",
    pad = "0"
  )

  stock_chr
}

# Convert Excel serial dates to calendar years when the raw value looks like an
# Excel date rather than a year. Excel's common Windows date origin is used.
excel_serial_to_year <- function(raw_values) {
  numeric_values <- suppressWarnings(as.numeric(raw_values))
  possible_excel_date <- !is.na(numeric_values) &
    numeric_values >= 1 &
    numeric_values <= 80000 &
    !(numeric_values >= 1900 & numeric_values <= 2100)

  excel_year <- rep(NA_integer_, length(raw_values))
  converted_dates <- as.Date(numeric_values[possible_excel_date], origin = "1899-12-30")
  converted_years <- suppressWarnings(as.integer(format(converted_dates, "%Y")))
  valid_converted_years <- converted_years >= 1900 & converted_years <= 2100

  excel_indices <- which(possible_excel_date)
  excel_year[excel_indices[valid_converted_years]] <- converted_years[valid_converted_years]
  excel_year
}

# Extract the first valid 4-digit year between 1900 and 2100. This handles raw
# values such as 2010, "2010", "2010.0", "2010年", "FY2010", "2010-12-31",
# and "2010/12/31". If no embedded year exists, Excel serial-date conversion is
# attempted for numeric-looking values.
normalize_year_key <- function(year_values) {
  year_chr <- stringr::str_trim(as.character(year_values))
  extracted_year_chr <- stringr::str_extract(year_chr, "(?<![0-9])(?:19[0-9]{2}|20[0-9]{2}|2100)(?![0-9])")
  extracted_year <- suppressWarnings(as.integer(extracted_year_chr))
  valid_extracted_year <- !is.na(extracted_year) & extracted_year >= 1900 & extracted_year <= 2100

  normalized_year <- rep(NA_integer_, length(year_values))
  normalized_year[valid_extracted_year] <- extracted_year[valid_extracted_year]

  needs_excel_conversion <- is.na(normalized_year) & !is.na(year_values) & year_chr != ""
  excel_year <- excel_serial_to_year(year_chr)
  normalized_year[needs_excel_conversion & !is.na(excel_year)] <- excel_year[needs_excel_conversion & !is.na(excel_year)]

  normalized_year
}

# Build a report of raw year values that still cannot be converted after the
# enhanced year normalization. Empty or missing raw years are excluded so the
# report focuses on problematic nonmissing source values.
get_unconvertible_year_values <- function(original_data, cleaned_data, dataset_label) {
  original_year_chr <- stringr::str_trim(as.character(original_data[[year_key]]))

  tibble::tibble(
    dataset = dataset_label,
    raw_year_value = original_year_chr
  ) %>%
    dplyr::filter(
      !is.na(.data$raw_year_value),
      .data$raw_year_value != "",
      is.na(cleaned_data[[year_key]])
    ) %>%
    dplyr::distinct() %>%
    dplyr::arrange(.data$raw_year_value)
}

# Standardize merge keys without changing non-key variables.
standardize_merge_keys <- function(data, dataset_label) {
  cleaned_data <- data %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(stock_key),
        normalize_stock_key
      ),
      dplyr::across(
        dplyr::all_of(year_key),
        normalize_year_key
      )
    )

  unconvertible_years <- get_unconvertible_year_values(data, cleaned_data, dataset_label)

  if (nrow(unconvertible_years) > 0) {
    warning(
      paste0(
        "Some year values in ", dataset_label,
        " could not be converted after extracting valid 4-digit years and ",
        "checking Excel serial dates. They will be reported in ",
        unconvertible_year_values_file, "."
      ),
      call. = FALSE
    )
  }

  attr(cleaned_data, "unconvertible_years") <- unconvertible_years
  cleaned_data
}

format_matching_rate <- function(rate) {
  if (is.na(rate)) {
    return(NA_character_)
  }

  paste0(format(round(rate * 100, 2), nsmall = 2), "%")
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

unconvertible_year_values <- dplyr::bind_rows(
  attr(main_data, "unconvertible_years"),
  attr(add_data, "unconvertible_years")
)
readr::write_csv(unconvertible_year_values, unconvertible_year_values_file)

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

unmatched_main_keys <- main_data %>%
  dplyr::distinct(dplyr::across(dplyr::all_of(merge_keys))) %>%
  dplyr::anti_join(add_keys, by = merge_keys) %>%
  dplyr::arrange(dplyr::across(dplyr::all_of(merge_keys)))

main_keys <- main_data %>%
  dplyr::distinct(dplyr::across(dplyr::all_of(merge_keys)))

unmatched_additional_keys <- add_keys %>%
  dplyr::anti_join(main_keys, by = merge_keys) %>%
  dplyr::arrange(dplyr::across(dplyr::all_of(merge_keys)))

matched_keys <- main_keys %>%
  dplyr::inner_join(add_keys, by = merge_keys)

unmatched_main_rows <- main_data %>%
  dplyr::anti_join(add_keys, by = merge_keys) %>%
  nrow()

matched_key_count <- nrow(matched_keys)
main_key_count <- nrow(main_keys)
matching_rate <- if (main_key_count == 0) NA_real_ else matched_key_count / main_key_count

readr::write_csv(unmatched_main_keys, unmatched_main_keys_file)
readr::write_csv(unmatched_additional_keys, unmatched_additional_keys_file)

message("Matched stock-year keys after cleaning: ", matched_key_count)
message("Matching rate after cleaning: ", format_matching_rate(matching_rate))

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
    "unmatched_main_key_count",
    "unmatched_additional_key_count",
    "matched_stock_year_key_count",
    "matching_rate",
    "unconvertible_year_value_count",
    "main_duplicate_key_count",
    "additional_duplicate_key_count",
    "row_count_increased_unexpectedly"
  ),
  value = c(
    as.character(main_rows),
    as.character(add_rows),
    as.character(merged_rows),
    as.character(unmatched_main_rows),
    as.character(nrow(unmatched_main_keys)),
    as.character(nrow(unmatched_additional_keys)),
    as.character(matched_key_count),
    as.character(matching_rate),
    as.character(nrow(unconvertible_year_values)),
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
  paste0("- Unmatched distinct stock-year keys from main dataset: ", nrow(unmatched_main_keys)),
  paste0("- Unmatched distinct stock-year keys from additional dataset: ", nrow(unmatched_additional_keys)),
  paste0("- Matched distinct stock-year keys after cleaning: ", matched_key_count),
  paste0("- Matching rate after cleaning: ", format_matching_rate(matching_rate)),
  paste0("- Unconvertible raw year values: ", nrow(unconvertible_year_values)),
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
message("Unmatched main keys saved to: ", unmatched_main_keys_file)
message("Unmatched additional keys saved to: ", unmatched_additional_keys_file)
message("Unconvertible year values saved to: ", unconvertible_year_values_file)
message("Sample flow saved to: ", sample_flow_file)

source("R/00_config.R")

# -----------------------------------------------------------------------------
# User configuration
# -----------------------------------------------------------------------------
# Replace placeholder variable names such as Y, X, control1, and control2 with
# real variables documented in docs/variable_definitions.md before running.

input_file <- "data/processed/merged_panel.xlsx"
output_file <- "outputs/tables/descriptive_statistics_and_correlation.xlsx"
vars_for_summary <- c("internationalization_scope", "CSR_Decoupling(LM)", "FirmAge", "board_size","asset_intensity","Growth","Indep","firm_size")
correlation_method <- "pearson"

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

stop_with_clear_message <- function(message_text) {
  stop(message_text, call. = FALSE)
}

check_required_columns <- function(data, required_columns) {
  required_columns <- unique(required_columns[!is.na(required_columns) & nzchar(required_columns)])
  missing_columns <- setdiff(required_columns, names(data))

  if (length(missing_columns) > 0) {
    stop_with_clear_message(
      paste0(
        "Required variable(s) are missing from ", input_file, ": ",
        paste(missing_columns, collapse = ", "), ". ",
        "Please edit vars_for_summary in the user configuration section with real variable names."
      )
    )
  }
}

as_numeric_strict <- function(x, variable_name) {
  if (is.numeric(x)) {
    return(x)
  }

  x_chr <- trimws(as.character(x))
  x_chr[x_chr == ""] <- NA_character_
  x_num <- suppressWarnings(as.numeric(x_chr))

  nonmissing_input <- !is.na(x_chr)
  failed_conversion <- nonmissing_input & is.na(x_num)

  if (any(failed_conversion)) {
    stop_with_clear_message(
      paste0(
        "Variable ", variable_name, " is not numeric and cannot be safely converted to numeric. ",
        "Please edit vars_for_summary or clean this variable before generating descriptive statistics."
      )
    )
  }

  x_num
}

summary_one_variable <- function(data, variable_name) {
  x <- data[[variable_name]]
  x <- x[!is.na(x)]

  data.frame(
    variable = variable_name,
    N = length(x),
    mean = if (length(x) == 0) NA_real_ else mean(x),
    sd = if (length(x) <= 1) NA_real_ else stats::sd(x),
    minimum = if (length(x) == 0) NA_real_ else min(x),
    p25 = if (length(x) == 0) NA_real_ else stats::quantile(x, 0.25, names = FALSE, type = 7),
    median = if (length(x) == 0) NA_real_ else stats::median(x),
    p75 = if (length(x) == 0) NA_real_ else stats::quantile(x, 0.75, names = FALSE, type = 7),
    maximum = if (length(x) == 0) NA_real_ else max(x),
    stringsAsFactors = FALSE
  )
}

# -----------------------------------------------------------------------------
# Main script
# -----------------------------------------------------------------------------

if (!file.exists(input_file)) {
  stop_with_clear_message(
    paste0(
      "Input file does not exist: ", input_file, ". ",
      "Please create the processed panel dataset or edit input_file in the user configuration section."
    )
  )
}

if (!correlation_method %in% c("pearson", "spearman", "kendall")) {
  stop_with_clear_message(
    "correlation_method must be one of: pearson, spearman, kendall."
  )
}

panel_data <- readxl::read_excel(input_file)
names(panel_data) <- stringr::str_trim(names(panel_data))

check_required_columns(panel_data, vars_for_summary)

analysis_data <- panel_data[, vars_for_summary, drop = FALSE]

for (variable_name in vars_for_summary) {
  analysis_data[[variable_name]] <- as_numeric_strict(
    analysis_data[[variable_name]],
    variable_name
  )
}

descriptive_statistics <- do.call(
  rbind,
  lapply(vars_for_summary, function(variable_name) {
    summary_one_variable(analysis_data, variable_name)
  })
)

correlation_matrix <- stats::cor(
  analysis_data,
  use = "pairwise.complete.obs",
  method = correlation_method
)

correlation_table <- data.frame(
  variable = rownames(correlation_matrix),
  correlation_matrix,
  row.names = NULL,
  check.names = FALSE
)

writexl::write_xlsx(
  list(
    descriptive_statistics = descriptive_statistics,
    correlation_matrix = correlation_table
  ),
  path = output_file
)

message("Descriptive statistics and correlation matrix written to: ", output_file)

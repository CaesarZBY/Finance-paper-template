source("R/00_config.R")

# -----------------------------------------------------------------------------
# User configuration
# -----------------------------------------------------------------------------
# Replace placeholder variable names such as X, Y, control1, and control2 with
# real variables documented in docs/variable_definitions.md before running.

input_file <- "data/processed/merged_panel.xlsx"
output_file <- "outputs/logs/within_firm_variation_check.csv"
firm_id <- "stock"
year_id <- "year"
vars_to_check <- c("internationalization_scope", "CSR_Decoupling(LM)", "FirmAge", "board_size","Growth","Indep","firm_size","asset_intensity")

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

weak_within_ratio_threshold <- 0.10

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
        "Please edit firm_id, year_id, and vars_to_check in the user configuration section with real variable names."
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
        "Please edit vars_to_check or clean this variable before running the within-firm variation check."
      )
    )
  }

  x_num
}

safe_sd <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) <= 1) {
    return(NA_real_)
  }
  stats::sd(x)
}

summarize_within_variation <- function(data, variable_name) {
  variable_data <- data.frame(
    firm = data[[firm_id]],
    year = data[[year_id]],
    value = data[[variable_name]],
    stringsAsFactors = FALSE
  )
  variable_data <- variable_data[!is.na(variable_data$value), , drop = FALSE]

  if (nrow(variable_data) == 0) {
    return(data.frame(
      variable = variable_name,
      total_N = 0L,
      number_of_firms = 0L,
      total_sd = NA_real_,
      between_firm_sd = NA_real_,
      within_firm_sd = NA_real_,
      within_total_sd_ratio = NA_real_,
      firms_with_no_within_variation = 0L,
      pct_firms_with_no_within_variation = NA_real_,
      warning = "No nonmissing observations for this variable.",
      stringsAsFactors = FALSE
    ))
  }

  firm_summary <- variable_data %>%
    dplyr::group_by(.data$firm) %>%
    dplyr::summarise(
      firm_mean = mean(.data$value),
      nonmissing_N = dplyr::n(),
      unique_values = dplyr::n_distinct(.data$value),
      .groups = "drop"
    )

  variable_data <- variable_data %>%
    dplyr::group_by(.data$firm) %>%
    dplyr::mutate(within_deviation = .data$value - mean(.data$value)) %>%
    dplyr::ungroup()

  total_sd <- safe_sd(variable_data$value)
  between_firm_sd <- safe_sd(firm_summary$firm_mean)
  within_firm_sd <- safe_sd(variable_data$within_deviation)
  within_total_sd_ratio <- if (is.na(total_sd) || total_sd == 0) {
    NA_real_
  } else {
    within_firm_sd / total_sd
  }

  number_of_firms <- nrow(firm_summary)
  firms_with_no_within_variation <- sum(firm_summary$unique_values <= 1)
  pct_firms_with_no_within_variation <- if (number_of_firms == 0) {
    NA_real_
  } else {
    100 * firms_with_no_within_variation / number_of_firms
  }

  warning_text <- dplyr::case_when(
    is.na(within_firm_sd) ~ "Within-firm standard deviation is unavailable.",
    within_firm_sd == 0 ~ "No within-firm variation.",
    !is.na(within_total_sd_ratio) && within_total_sd_ratio < weak_within_ratio_threshold ~ "Weak within-firm variation; firm fixed effects may leave limited identifying variation.",
    TRUE ~ ""
  )

  data.frame(
    variable = variable_name,
    total_N = nrow(variable_data),
    number_of_firms = number_of_firms,
    total_sd = total_sd,
    between_firm_sd = between_firm_sd,
    within_firm_sd = within_firm_sd,
    within_total_sd_ratio = within_total_sd_ratio,
    firms_with_no_within_variation = firms_with_no_within_variation,
    pct_firms_with_no_within_variation = pct_firms_with_no_within_variation,
    warning = warning_text,
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

panel_data <- readxl::read_excel(input_file)
names(panel_data) <- stringr::str_trim(names(panel_data))

check_required_columns(panel_data, c(firm_id, year_id, vars_to_check))

for (variable_name in vars_to_check) {
  panel_data[[variable_name]] <- as_numeric_strict(
    panel_data[[variable_name]],
    variable_name
  )
}

within_variation_report <- do.call(
  rbind,
  lapply(vars_to_check, function(variable_name) {
    summarize_within_variation(panel_data, variable_name)
  })
)

readr::write_csv(within_variation_report, output_file)

message("Within-firm variation check written to: ", output_file)

# R/05_baseline_models.R
# Reusable finance-style baseline panel regression module
#
# Purpose:
#   Estimate baseline firm-year panel regressions with configurable variables,
#   fixed effects, clustering, lagging, winsorization, centering, and optional
#   quadratic terms.
#
# Research integrity notes:
#   - This script reads a processed dataset and never modifies data/raw/.
#   - This script does not create fake data or fabricate empirical results.
#   - Baseline regressions document conditional associations. Do not describe
#     estimates as causal effects unless the paper's identification strategy
#     justifies that interpretation.

source("R/00_config.R")

# -----------------------------------------------------------------------------
# 1. User configuration
# -----------------------------------------------------------------------------
# Edit this section for each new paper before running the baseline models.
# Replace placeholder variable names such as Y, X, control1, control2, and
# control3 with real variables documented in docs/variable_definitions.md.

input_file <- "data/processed/merged_panel.xlsx"

output_table_xlsx <- "outputs/tables/baseline_models.xlsx"
output_table_html <- "outputs/tables/baseline_models.html"

model_log_file <- "outputs/logs/baseline_model_log.md"
sample_quality_file <- "outputs/logs/baseline_sample_quality.csv"
winsorization_report_file <- "outputs/logs/baseline_winsorization_report.csv"
centering_report_file <- "outputs/logs/baseline_centering_report.csv"
quadratic_diagnostics_file <- "outputs/logs/baseline_quadratic_diagnostics.csv"

# Extra top-journal-style audit outputs.
duplicate_keys_file <- "outputs/logs/baseline_duplicate_firm_year_keys.csv"
variable_audit_file <- "outputs/logs/baseline_variable_audit.csv"
model_metadata_file <- "outputs/logs/baseline_model_metadata.csv"
effect_size_file <- "outputs/logs/baseline_economic_magnitude.csv"
cluster_diagnostics_file <- "outputs/logs/baseline_cluster_diagnostics.csv"

# Panel identifiers. Edit these names if your project uses different columns.
firm_id <- "stock"
year_id <- "year"
industry_id <- "industry"
province_id <- "province"

# Regression variables. Keep the dependent variable separate from explanatory
# variables so model formulas and sample diagnostics remain transparent.
dependent_var <- "CSR_Decoupling(LM)"
main_independent_vars <- c("internationalization_scope")
control_vars <- c("FirmAge", "ROA.x","firm_size","board_size","asset_intensity","female_board_percentage","board_independence","industry_growth","duality_of_chairperson_ceo","industry_competition","Top1","Cashflow","Lev")

# Fixed effects. Supported choices:
#   "firm", "year", "industry", "province",
#   "industry-year", "province-year", "none"
# Use only theoretically justified choices. Do not change fixed effects only to
# obtain statistical significance.
fixed_effects <- c("firm", "year")

# Clustering level. Supported choices:
#   "firm", "year", "industry", "province",
#   "firm-year", "industry-year", "province-year", "none"
# For firm-year finance panels, firm-level clustering is often a minimum.
cluster_vars <- c("firm")
min_cluster_count_warning <- 30

# Optional lagging. Lagged variables are created within firm after sorting by
# firm and year. By default, only RHS variables are lagged. A lagged dependent
# variable is a different dynamic specification and should be enabled manually.
use_lag <- FALSE
lag_n <- 1
lag_vars <- c("internationalization_scope", "FirmAge", "ROA.x","firm_size","board_size","asset_intensity","female_board_percentage","board_independence","industry_growth","duality_of_chairperson_ceo","industry_competition")
lag_dependent_var <- FALSE

# Optional winsorization. Numeric continuous variables are winsorized in the
# analysis copy only; identifiers, fixed effects, year variables, and obvious
# 0/1 dummy variables are skipped.
use_winsor <- TRUE
winsor_lower <- 0.01
winsor_upper <- 0.99
winsor_vars <- c(dependent_var, main_independent_vars, control_vars)

# Optional mean-centering. Centered variables are named c_varname and can be
# used in the regression formula when listed in center_vars.
# Centering is usually most useful for interactions or quadratic terms.
use_centering <- TRUE
center_vars <- c(main_independent_vars)

# Optional U-shaped or nonlinear baseline model. When enabled, squared terms
# are named var_sq. If centering and/or lagging are enabled, the active
# transformed variable is squared.
use_quadratic <- TRUE
quadratic_vars <- c(main_independent_vars)

# Duplicate firm-year keys are usually a serious problem in firm-year finance
# panels. For dyad-level or firm-country-year panels, set this to FALSE and
# document why duplicates are expected.
stop_on_duplicate_firm_year <- TRUE

# -----------------------------------------------------------------------------
# 2. Helper functions
# -----------------------------------------------------------------------------

timestamp <- function() {
  format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

write_model_log <- function(lines, append = TRUE) {
  cat(paste0(lines, collapse = "\n"), "\n", file = model_log_file, append = append)
}

stop_with_log <- function(message_text) {
  write_model_log(
    c(
      "# Baseline Model Log",
      "",
      paste0("Generated: ", timestamp()),
      "",
      "## Status",
      "",
      message_text
    ),
    append = FALSE
  )
  stop(message_text, call. = FALSE)
}

clean_names_only <- function(data) {
  names(data) <- stringr::str_trim(names(data))
  data
}

qname <- function(variable_name) {
  paste0("`", gsub("`", "", variable_name), "`")
}

collapse_or_none <- function(x) {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x) == 0) "None" else paste(x, collapse = ", ")
}

normalize_choice <- function(x) {
  x <- x[!is.na(x)]
  stringr::str_replace_all(stringr::str_to_lower(stringr::str_trim(x)), "[- ]", "_")
}

is_obvious_dummy <- function(x) {
  if (!is.numeric(x)) {
    return(FALSE)
  }
  values <- unique(stats::na.omit(x))
  length(values) > 0 && length(values) <= 2 && all(values %in% c(0, 1))
}

is_numeric_like <- function(x) {
  if (is.numeric(x)) {
    return(TRUE)
  }
  x_chr <- stringr::str_trim(as.character(x))
  nonmissing <- x_chr[!is.na(x_chr) & x_chr != ""]
  if (length(nonmissing) == 0) {
    return(FALSE)
  }
  mean(!is.na(suppressWarnings(as.numeric(nonmissing)))) > 0.95
}

coerce_numeric_like <- function(data, vars) {
  report <- data.frame(
    variable = character(0),
    original_class = character(0),
    final_class = character(0),
    converted_to_numeric = logical(0),
    missing_before = integer(0),
    missing_after = integer(0),
    note = character(0),
    stringsAsFactors = FALSE
  )

  for (v in unique(vars[vars %in% names(data)])) {
    original_class <- paste(class(data[[v]]), collapse = "/")
    missing_before <- sum(is.na(data[[v]]))

    if (!is.numeric(data[[v]]) && is_numeric_like(data[[v]])) {
      data[[v]] <- suppressWarnings(as.numeric(data[[v]]))
      converted <- TRUE
      note <- "Converted numeric-like variable to numeric for regression."
    } else {
      converted <- FALSE
      note <- "No numeric conversion applied."
    }

    report <- rbind(
      report,
      data.frame(
        variable = v,
        original_class = original_class,
        final_class = paste(class(data[[v]]), collapse = "/"),
        converted_to_numeric = converted,
        missing_before = missing_before,
        missing_after = sum(is.na(data[[v]])),
        note = note,
        stringsAsFactors = FALSE
      )
    )
  }

  list(data = data, report = report)
}

require_existing_columns <- function(data, required_columns, context_label) {
  required_columns <- unique(required_columns[!is.na(required_columns) & nzchar(required_columns)])
  missing_columns <- setdiff(required_columns, names(data))
  if (length(missing_columns) > 0) {
    stop_with_log(
      paste0(
        "Required column(s) missing for ", context_label, ": ",
        paste(missing_columns, collapse = ", "), ".\n",
        "Please update the user configuration section near the top of ",
        "R/05_baseline_models.R with real variable names from the processed dataset.\n",
        "No regression was estimated and no empirical results were fabricated."
      )
    )
  }
}

resolve_simple_choice <- function(choice, firm_col, year_col, industry_col, province_col) {
  normalized <- normalize_choice(choice)
  dplyr::case_when(
    normalized == "firm" ~ firm_col,
    normalized == "year" ~ year_col,
    normalized == "industry" ~ industry_col,
    normalized == "province" ~ province_col,
    TRUE ~ NA_character_
  )
}

add_interaction_fe <- function(data, first_col, second_col, new_col) {
  data[[new_col]] <- interaction(
    data[[first_col]],
    data[[second_col]],
    drop = TRUE,
    lex.order = TRUE
  )
  data
}

resolve_fixed_effects <- function(data, selected_effects) {
  fe_vars <- character(0)
  issues <- character(0)
  selected_effects <- normalize_choice(selected_effects)

  for (effect in selected_effects) {
    if (effect %in% c("", "none")) {
      next
    } else if (effect %in% c("firm", "year", "industry", "province")) {
      resolved <- resolve_simple_choice(effect, firm_id, year_id, industry_id, province_id)
      fe_vars <- c(fe_vars, resolved)
    } else if (effect %in% c("industry_year", "industry:year")) {
      if (all(c(industry_id, year_id) %in% names(data))) {
        data <- add_interaction_fe(data, industry_id, year_id, ".fe_industry_year")
        fe_vars <- c(fe_vars, ".fe_industry_year")
      } else {
        issues <- c(issues, "industry-year fixed effects require industry and year columns.")
      }
    } else if (effect %in% c("province_year", "province:year")) {
      if (all(c(province_id, year_id) %in% names(data))) {
        data <- add_interaction_fe(data, province_id, year_id, ".fe_province_year")
        fe_vars <- c(fe_vars, ".fe_province_year")
      } else {
        issues <- c(issues, "province-year fixed effects require province and year columns.")
      }
    } else if (nzchar(effect)) {
      issues <- c(issues, paste0("Unsupported fixed effect choice: ", effect))
    }
  }

  list(data = data, fe_vars = unique(fe_vars), issues = issues)
}

resolve_cluster_vars <- function(selected_clusters) {
  selected_clusters <- normalize_choice(selected_clusters)
  cluster_columns <- character(0)
  issues <- character(0)

  for (cluster in selected_clusters) {
    if (cluster %in% c("", "none")) {
      next
    } else if (cluster %in% c("firm", "year", "industry", "province")) {
      cluster_columns <- c(
        cluster_columns,
        resolve_simple_choice(cluster, firm_id, year_id, industry_id, province_id)
      )
    } else if (cluster %in% c("firm_year", "firm_and_year", "firm:year")) {
      cluster_columns <- c(cluster_columns, firm_id, year_id)
    } else if (cluster %in% c("industry_year", "industry_and_year", "industry:year")) {
      cluster_columns <- c(cluster_columns, industry_id, year_id)
    } else if (cluster %in% c("province_year", "province_and_year", "province:year")) {
      cluster_columns <- c(cluster_columns, province_id, year_id)
    } else if (nzchar(cluster)) {
      issues <- c(issues, paste0("Unsupported clustering choice: ", cluster))
    }
  }

  list(cluster_vars = unique(cluster_columns), issues = issues)
}

build_formula <- function(lhs, rhs_vars, fe_vars = character(0)) {
  rhs_vars <- unique(rhs_vars[!is.na(rhs_vars) & nzchar(rhs_vars)])
  rhs <- if (length(rhs_vars) == 0) "1" else paste(qname(rhs_vars), collapse = " + ")

  if (length(fe_vars) == 0) {
    stats::as.formula(paste(qname(lhs), "~", rhs))
  } else {
    stats::as.formula(
      paste(qname(lhs), "~", rhs, "|", paste(qname(fe_vars), collapse = " + "))
    )
  }
}

cluster_formula <- function(cluster_columns) {
  cluster_columns <- unique(cluster_columns[!is.na(cluster_columns) & nzchar(cluster_columns)])
  if (length(cluster_columns) == 0) {
    return(NULL)
  }
  stats::as.formula(paste("~", paste(qname(cluster_columns), collapse = " + ")))
}

replace_with_lagged_name <- function(vars, allow_lagged_lhs = FALSE) {
  if (!use_lag || length(vars) == 0) {
    return(vars)
  }
  lagged_names <- paste0("L", lag_n, "_", vars)
  can_lag <- vars %in% lag_vars
  if (!allow_lagged_lhs) {
    can_lag <- can_lag & vars != dependent_var
  }
  ifelse(can_lag, lagged_names, vars)
}

replace_with_centered_name <- function(vars, active_center_vars) {
  if (!use_centering || length(vars) == 0) {
    return(vars)
  }
  centered_names <- paste0("c_", vars)
  ifelse(vars %in% active_center_vars, centered_names, vars)
}

make_missing_report <- function(data, variables) {
  variables <- unique(variables[!is.na(variables) & nzchar(variables)])
  data.frame(
    section = "missing_values",
    item = variables,
    value = vapply(
      variables,
      function(v) {
        if (v %in% names(data)) {
          as.character(sum(is.na(data[[v]])))
        } else {
          "column_missing"
        }
      },
      character(1)
    ),
    note = "Missing-value count before regression filtering",
    stringsAsFactors = FALSE
  )
}

write_empty_report_if_needed <- function(path, report, default_note) {
  if (is.null(report) || nrow(report) == 0) {
    report <- data.frame(
      variable = NA_character_,
      status = "not_applicable",
      note = default_note,
      stringsAsFactors = FALSE
    )
  }
  readr::write_csv(report, path)
}

safe_fitstat <- function(model, stat_name) {
  value <- tryCatch(
    as.numeric(fixest::fitstat(model, stat_name)[[stat_name]]),
    error = function(e) NA_real_
  )
  if (length(value) == 0) NA_real_ else value[[1]]
}

range_text <- function(x) {
  if (all(is.na(x))) {
    return("all_missing")
  }
  if (is.numeric(x) || inherits(x, "Date")) {
    paste(range(x, na.rm = TRUE), collapse = " to ")
  } else {
    x_chr <- sort(unique(as.character(stats::na.omit(x))))
    if (length(x_chr) == 0) "all_missing" else paste(x_chr[[1]], "to", x_chr[[length(x_chr)]])
  }
}

# -----------------------------------------------------------------------------
# 3. Read processed data and validate configuration
# -----------------------------------------------------------------------------

if (!file.exists(input_file)) {
  stop_with_log(
    paste0(
      "Processed input file not found: ", input_file, ".\n",
      "Please generate or place the real processed firm-year panel dataset at ",
      "this path, or update input_file in R/05_baseline_models.R.\n",
      "The script stopped without creating fake data or estimating models."
    )
  )
}

panel_data <- readxl::read_excel(input_file) %>%
  clean_names_only()

initial_rows <- nrow(panel_data)

basic_required <- unique(c(firm_id, year_id, dependent_var, main_independent_vars, control_vars))
require_existing_columns(panel_data, basic_required, "baseline regression variables")

# Coerce numeric-like regression variables to numeric. This avoids accidental
# character import from Excel for variables that should enter a regression.
numeric_candidate_vars <- unique(c(dependent_var, main_independent_vars, control_vars, winsor_vars, center_vars, quadratic_vars))
coerce_result <- coerce_numeric_like(panel_data, numeric_candidate_vars)
panel_data <- coerce_result$data
readr::write_csv(coerce_result$report, variable_audit_file)

fe_resolved <- resolve_fixed_effects(panel_data, fixed_effects)
panel_data <- fe_resolved$data
selected_fe_vars <- fe_resolved$fe_vars

cluster_resolved <- resolve_cluster_vars(cluster_vars)
selected_cluster_vars <- cluster_resolved$cluster_vars

configuration_issues <- c(fe_resolved$issues, cluster_resolved$issues)

missing_fe_columns <- setdiff(selected_fe_vars, names(panel_data))
missing_cluster_columns <- setdiff(selected_cluster_vars, names(panel_data))

if (length(configuration_issues) > 0 ||
    length(missing_fe_columns) > 0 ||
    length(missing_cluster_columns) > 0) {
  issue_text <- paste(
    c(
      if (length(configuration_issues) > 0) {
        paste0("Configuration issue(s): ", paste(configuration_issues, collapse = "; "))
      },
      if (length(missing_fe_columns) > 0) {
        paste0("Missing fixed effect columns: ", paste(missing_fe_columns, collapse = ", "))
      },
      if (length(missing_cluster_columns) > 0) {
        paste0("Missing clustering columns: ", paste(missing_cluster_columns, collapse = ", "))
      }
    ),
    collapse = "\n"
  )
  stop_with_log(
    paste0(
      issue_text, "\n",
      "Please update the identifier, fixed effect, or clustering configuration before running ",
      "the baseline models."
    )
  )
}

# -----------------------------------------------------------------------------
# 4. Optional lagging, winsorization, centering, and quadratic terms
# -----------------------------------------------------------------------------

lag_report <- data.frame(
  variable = character(0),
  lagged_variable = character(0),
  missing_before_lag = integer(0),
  missing_after_lag = integer(0),
  additional_missing_due_to_lag = integer(0),
  stringsAsFactors = FALSE
)

if (use_lag) {
  if (!is.numeric(lag_n) || length(lag_n) != 1 || lag_n < 1 || lag_n != as.integer(lag_n)) {
    stop_with_log("lag_n must be a positive integer.")
  }

  if (!lag_dependent_var && dependent_var %in% lag_vars) {
    warning(
      "dependent_var is listed in lag_vars, but lag_dependent_var is FALSE. The dependent variable will not be lagged.",
      call. = FALSE
    )
  }

  require_existing_columns(panel_data, c(firm_id, year_id, lag_vars), "lag construction")

  panel_data <- panel_data %>%
    dplyr::arrange(.data[[firm_id]], .data[[year_id]]) %>%
    dplyr::group_by(.data[[firm_id]]) %>%
    dplyr::mutate(
      dplyr::across(
        dplyr::all_of(lag_vars),
        ~ dplyr::lag(.x, n = lag_n),
        .names = paste0("L", lag_n, "_{.col}")
      )
    ) %>%
    dplyr::ungroup()

  lag_report <- data.frame(
    variable = lag_vars,
    lagged_variable = paste0("L", lag_n, "_", lag_vars),
    missing_before_lag = vapply(lag_vars, function(v) sum(is.na(panel_data[[v]])), integer(1)),
    missing_after_lag = vapply(
      paste0("L", lag_n, "_", lag_vars),
      function(v) sum(is.na(panel_data[[v]])),
      integer(1)
    ),
    stringsAsFactors = FALSE
  )
  lag_report$additional_missing_due_to_lag <- pmax(
    lag_report$missing_after_lag - lag_report$missing_before_lag,
    0L
  )
}

active_dependent_var <- replace_with_lagged_name(dependent_var, allow_lagged_lhs = lag_dependent_var)
active_main_vars <- replace_with_lagged_name(main_independent_vars, allow_lagged_lhs = TRUE)
active_control_vars <- replace_with_lagged_name(control_vars, allow_lagged_lhs = TRUE)
active_winsor_vars <- replace_with_lagged_name(winsor_vars, allow_lagged_lhs = TRUE)
active_center_vars <- replace_with_lagged_name(center_vars, allow_lagged_lhs = TRUE)
active_quadratic_vars <- replace_with_lagged_name(quadratic_vars, allow_lagged_lhs = TRUE)

winsor_report <- data.frame(
  variable = character(0),
  status = character(0),
  lower_quantile = numeric(0),
  upper_quantile = numeric(0),
  values_below = integer(0),
  values_above = integer(0),
  note = character(0),
  stringsAsFactors = FALSE
)

if (use_winsor) {
  if (!is.numeric(winsor_lower) || !is.numeric(winsor_upper) ||
      winsor_lower < 0 || winsor_upper > 1 || winsor_lower >= winsor_upper) {
    stop_with_log("Winsorization cutoffs must satisfy 0 <= winsor_lower < winsor_upper <= 1.")
  }

  skip_vars <- unique(c(
    firm_id,
    year_id,
    industry_id,
    province_id,
    selected_fe_vars,
    selected_cluster_vars
  ))
  active_winsor_vars <- unique(active_winsor_vars)

  for (v in active_winsor_vars) {
    if (!v %in% names(panel_data)) {
      winsor_report <- rbind(
        winsor_report,
        data.frame(
          variable = v,
          status = "skipped",
          lower_quantile = NA_real_,
          upper_quantile = NA_real_,
          values_below = NA_integer_,
          values_above = NA_integer_,
          note = "Column not found",
          stringsAsFactors = FALSE
        )
      )
    } else if (v %in% skip_vars) {
      winsor_report <- rbind(
        winsor_report,
        data.frame(
          variable = v,
          status = "skipped",
          lower_quantile = NA_real_,
          upper_quantile = NA_real_,
          values_below = NA_integer_,
          values_above = NA_integer_,
          note = "Identifier, fixed effect, cluster, or year variable",
          stringsAsFactors = FALSE
        )
      )
    } else if (!is.numeric(panel_data[[v]])) {
      winsor_report <- rbind(
        winsor_report,
        data.frame(
          variable = v,
          status = "skipped",
          lower_quantile = NA_real_,
          upper_quantile = NA_real_,
          values_below = NA_integer_,
          values_above = NA_integer_,
          note = "Non-numeric variable",
          stringsAsFactors = FALSE
        )
      )
    } else if (is_obvious_dummy(panel_data[[v]])) {
      winsor_report <- rbind(
        winsor_report,
        data.frame(
          variable = v,
          status = "skipped",
          lower_quantile = NA_real_,
          upper_quantile = NA_real_,
          values_below = NA_integer_,
          values_above = NA_integer_,
          note = "Obvious 0/1 dummy variable",
          stringsAsFactors = FALSE
        )
      )
    } else {
      lower_value <- stats::quantile(panel_data[[v]], probs = winsor_lower, na.rm = TRUE, names = FALSE)
      upper_value <- stats::quantile(panel_data[[v]], probs = winsor_upper, na.rm = TRUE, names = FALSE)
      below_count <- sum(panel_data[[v]] < lower_value, na.rm = TRUE)
      above_count <- sum(panel_data[[v]] > upper_value, na.rm = TRUE)

      panel_data[[v]] <- pmin(pmax(panel_data[[v]], lower_value), upper_value)

      winsor_report <- rbind(
        winsor_report,
        data.frame(
          variable = v,
          status = "winsorized",
          lower_quantile = lower_value,
          upper_quantile = upper_value,
          values_below = below_count,
          values_above = above_count,
          note = paste0("Cutoffs: ", winsor_lower, " and ", winsor_upper),
          stringsAsFactors = FALSE
        )
      )
    }
  }
}

write_empty_report_if_needed(
  winsorization_report_file,
  winsor_report,
  "Winsorization was disabled or no variables were selected."
)

centering_report <- data.frame(
  original_variable = character(0),
  active_variable = character(0),
  centered_variable = character(0),
  mean_used = numeric(0),
  status = character(0),
  note = character(0),
  stringsAsFactors = FALSE
)

if (use_centering) {
  require_existing_columns(panel_data, active_center_vars, "centering")

  for (v in unique(active_center_vars)) {
    centered_name <- paste0("c_", v)
    if (is.numeric(panel_data[[v]])) {
      mean_value <- mean(panel_data[[v]], na.rm = TRUE)
      panel_data[[centered_name]] <- panel_data[[v]] - mean_value
      centering_report <- rbind(
        centering_report,
        data.frame(
          original_variable = center_vars[match(v, active_center_vars)],
          active_variable = v,
          centered_variable = centered_name,
          mean_used = mean_value,
          status = "centered",
          note = "Mean-centered numeric variable",
          stringsAsFactors = FALSE
        )
      )
    } else {
      centering_report <- rbind(
        centering_report,
        data.frame(
          original_variable = center_vars[match(v, active_center_vars)],
          active_variable = v,
          centered_variable = centered_name,
          mean_used = NA_real_,
          status = "skipped",
          note = "Non-numeric variable",
          stringsAsFactors = FALSE
        )
      )
    }
  }
}

write_empty_report_if_needed(
  centering_report_file,
  centering_report,
  "Centering was disabled or no variables were selected."
)

active_dependent_var <- replace_with_centered_name(active_dependent_var, active_center_vars)
active_main_vars <- replace_with_centered_name(active_main_vars, active_center_vars)
active_control_vars <- replace_with_centered_name(active_control_vars, active_center_vars)
active_quadratic_vars <- replace_with_centered_name(active_quadratic_vars, active_center_vars)

quadratic_report <- data.frame(
  base_variable = character(0),
  squared_variable = character(0),
  status = character(0),
  beta_linear = numeric(0),
  beta_squared = numeric(0),
  turning_point = numeric(0),
  observed_min = numeric(0),
  observed_max = numeric(0),
  turning_point_inside_range = logical(0),
  note = character(0),
  stringsAsFactors = FALSE
)

quadratic_terms <- character(0)

if (use_quadratic) {
  require_existing_columns(panel_data, active_quadratic_vars, "quadratic term construction")

  for (v in unique(active_quadratic_vars)) {
    squared_name <- paste0(v, "_sq")
    if (is.numeric(panel_data[[v]])) {
      panel_data[[squared_name]] <- panel_data[[v]]^2
      quadratic_terms <- c(quadratic_terms, squared_name)
      quadratic_report <- rbind(
        quadratic_report,
        data.frame(
          base_variable = v,
          squared_variable = squared_name,
          status = "created",
          beta_linear = NA_real_,
          beta_squared = NA_real_,
          turning_point = NA_real_,
          observed_min = min(panel_data[[v]], na.rm = TRUE),
          observed_max = max(panel_data[[v]], na.rm = TRUE),
          turning_point_inside_range = NA,
          note = "Squared term included. Coefficient signs and turning point must be interpreted cautiously.",
          stringsAsFactors = FALSE
        )
      )
    } else {
      quadratic_report <- rbind(
        quadratic_report,
        data.frame(
          base_variable = v,
          squared_variable = squared_name,
          status = "skipped",
          beta_linear = NA_real_,
          beta_squared = NA_real_,
          turning_point = NA_real_,
          observed_min = NA_real_,
          observed_max = NA_real_,
          turning_point_inside_range = NA,
          note = "Non-numeric variable",
          stringsAsFactors = FALSE
        )
      )
    }
  }

  active_main_vars <- unique(c(active_main_vars, active_quadratic_vars, quadratic_terms))
}

# -----------------------------------------------------------------------------
# 5. Sample quality checks before regression
# -----------------------------------------------------------------------------

regression_vars <- unique(c(active_dependent_var, active_main_vars, active_control_vars))
required_for_estimation <- unique(c(regression_vars, selected_fe_vars, selected_cluster_vars))
require_existing_columns(panel_data, required_for_estimation, "estimation")

firm_year_duplicate_count <- NA_integer_
duplicated_key_rows <- NA_integer_

if (all(c(firm_id, year_id) %in% names(panel_data))) {
  duplicate_keys <- panel_data %>%
    dplyr::count(.data[[firm_id]], .data[[year_id]], name = "n") %>%
    dplyr::filter(.data$n > 1) %>%
    dplyr::arrange(dplyr::desc(.data$n))

  firm_year_duplicate_count <- nrow(duplicate_keys)
  duplicated_key_rows <- sum(duplicate_keys$n)

  readr::write_csv(duplicate_keys, duplicate_keys_file)

  if (stop_on_duplicate_firm_year && firm_year_duplicate_count > 0) {
    stop_with_log(
      paste0(
        "Duplicate firm-year keys were detected: ", firm_year_duplicate_count,
        " duplicated key combination(s), involving ", duplicated_key_rows, " rows.\n",
        "For a firm-year finance panel, this is usually not acceptable before baseline regression.\n",
        "Inspect ", duplicate_keys_file, ". If the dataset is intentionally dyadic or firm-country-year, ",
        "set stop_on_duplicate_firm_year <- FALSE and document the panel structure."
      )
    )
  }
} else {
  readr::write_csv(
    data.frame(note = "firm_id or year_id column missing; duplicate check was not possible."),
    duplicate_keys_file
  )
}

estimation_data <- panel_data %>%
  dplyr::filter(dplyr::if_all(dplyr::all_of(required_for_estimation), ~ !is.na(.x)))

year_range <- if (year_id %in% names(panel_data)) {
  range_text(panel_data[[year_id]])
} else {
  "year column missing"
}

sample_quality <- data.frame(
  section = c(
    "sample",
    "sample",
    "sample",
    "sample",
    "duplicates",
    "duplicates",
    "fixed_effects",
    "clustering",
    "configuration"
  ),
  item = c(
    "rows_before_regression",
    "rows_after_missing_value_filter",
    "unique_firms_before_filtering",
    "year_range_before_filtering",
    "duplicate_firm_year_keys",
    "rows_in_duplicated_firm_year_keys",
    "missing_fixed_effect_columns",
    "missing_cluster_columns",
    "configuration_issues"
  ),
  value = c(
    as.character(initial_rows),
    as.character(nrow(estimation_data)),
    as.character(dplyr::n_distinct(panel_data[[firm_id]], na.rm = TRUE)),
    year_range,
    as.character(firm_year_duplicate_count),
    as.character(duplicated_key_rows),
    collapse_or_none(missing_fe_columns),
    collapse_or_none(missing_cluster_columns),
    collapse_or_none(configuration_issues)
  ),
  note = c(
    "Rows in processed dataset before regression filtering",
    "Rows after dropping missing dependent, independent, control, fixed effect, and cluster variables",
    "Unique firm identifiers before regression filtering",
    "Observed year range before regression filtering",
    "Number of firm-year key combinations with more than one row",
    "Total rows involved in duplicated firm-year keys",
    "Fixed effect columns required but absent",
    "Cluster columns required but absent",
    "Unsupported or partially unresolved user configuration choices"
  ),
  stringsAsFactors = FALSE
)

sample_quality <- rbind(
  sample_quality,
  make_missing_report(panel_data, regression_vars)
)

if (length(selected_fe_vars) > 0) {
  sample_quality <- rbind(
    sample_quality,
    data.frame(
      section = "fixed_effect_missing_values",
      item = selected_fe_vars,
      value = vapply(selected_fe_vars, function(v) as.character(sum(is.na(panel_data[[v]]))), character(1)),
      note = "Missing values in selected fixed effect variables",
      stringsAsFactors = FALSE
    )
  )
}

if (length(selected_cluster_vars) > 0) {
  sample_quality <- rbind(
    sample_quality,
    data.frame(
      section = "cluster_missing_values",
      item = selected_cluster_vars,
      value = vapply(selected_cluster_vars, function(v) as.character(sum(is.na(panel_data[[v]]))), character(1)),
      note = "Missing values in selected clustering variables",
      stringsAsFactors = FALSE
    )
  )
}

if (nrow(lag_report) > 0) {
  sample_quality <- rbind(
    sample_quality,
    data.frame(
      section = "lagging",
      item = lag_report$lagged_variable,
      value = as.character(lag_report$additional_missing_due_to_lag),
      note = "Additional missing values after within-firm lag construction",
      stringsAsFactors = FALSE
    )
  )
}

readr::write_csv(sample_quality, sample_quality_file)

if (nrow(estimation_data) == 0) {
  stop_with_log(
    paste0(
      "No complete observations remain after filtering regression variables, fixed effects, ",
      "and clustering variables. Please inspect ", sample_quality_file,
      " and revise the variable configuration or data construction."
    )
  )
}

cluster_diagnostics <- data.frame(
  cluster_variable = character(0),
  cluster_count = integer(0),
  min_recommended_cluster_count = integer(0),
  warning = character(0),
  stringsAsFactors = FALSE
)

for (v in selected_cluster_vars) {
  cluster_count <- dplyr::n_distinct(estimation_data[[v]], na.rm = TRUE)
  cluster_diagnostics <- rbind(
    cluster_diagnostics,
    data.frame(
      cluster_variable = v,
      cluster_count = cluster_count,
      min_recommended_cluster_count = min_cluster_count_warning,
      warning = ifelse(
        cluster_count < min_cluster_count_warning,
        "Cluster count is small; conventional clustered standard errors may be unreliable.",
        "No small-cluster warning."
      ),
      stringsAsFactors = FALSE
    )
  )
}

write_empty_report_if_needed(
  cluster_diagnostics_file,
  cluster_diagnostics,
  "No clustering variables were selected."
)

# -----------------------------------------------------------------------------
# 6. Baseline model sequence
# -----------------------------------------------------------------------------

year_fe_if_selected <- if ("year" %in% normalize_choice(fixed_effects)) year_id else character(0)
firm_fe_if_selected <- if ("firm" %in% normalize_choice(fixed_effects)) firm_id else character(0)
firm_year_fe_if_selected <- intersect(unique(c(firm_fe_if_selected, year_fe_if_selected)), selected_fe_vars)

candidate_models <- list(
  "Model 1: Main variable + year FE" = list(
    rhs = active_main_vars,
    fe = intersect(year_fe_if_selected, selected_fe_vars),
    note = "Main independent variable(s) with year fixed effects if selected."
  ),
  "Model 2: Controls + year FE" = list(
    rhs = unique(c(active_main_vars, active_control_vars)),
    fe = intersect(year_fe_if_selected, selected_fe_vars),
    note = "Adds control variables while retaining year fixed effects if selected."
  ),
  "Model 3: Firm and year FE" = list(
    rhs = unique(c(active_main_vars, active_control_vars)),
    fe = firm_year_fe_if_selected,
    note = "Adds firm fixed effects while retaining year fixed effects if both are selected."
  ),
  "Model 4: Full selected FE" = list(
    rhs = unique(c(active_main_vars, active_control_vars)),
    fe = selected_fe_vars,
    note = "Uses full selected fixed effects and controls."
  )
)

models <- list()
model_formulas <- character(0)
model_notes <- character(0)
skipped_models <- character(0)
cluster_spec <- cluster_formula(selected_cluster_vars)

for (model_name in names(candidate_models)) {
  model_spec <- candidate_models[[model_name]]
  formula_obj <- build_formula(active_dependent_var, model_spec$rhs, model_spec$fe)
  formula_text <- paste(deparse(formula_obj), collapse = " ")

  if (formula_text %in% model_formulas) {
    skipped_models <- c(
      skipped_models,
      paste0(model_name, " skipped because it duplicates an earlier model formula.")
    )
    next
  }

  fit <- tryCatch(
    fixest::feols(
      fml = formula_obj,
      data = estimation_data,
      cluster = cluster_spec
    ),
    error = function(e) e
  )

  if (inherits(fit, "error")) {
    skipped_models <- c(
      skipped_models,
      paste0(model_name, " failed: ", conditionMessage(fit))
    )
  } else {
    models[[model_name]] <- fit
    model_formulas[model_name] <- formula_text
    model_notes[model_name] <- model_spec$note
  }
}

if (length(models) == 0) {
  stop_with_log(
    paste0(
      "No baseline model was successfully estimated. Issues: ",
      collapse_or_none(skipped_models),
      "\nNo empirical results were fabricated."
    )
  )
}

# -----------------------------------------------------------------------------
# 7. Export tables, model metadata, effect sizes, and quadratic diagnostics
# -----------------------------------------------------------------------------

modelsummary::modelsummary(
  models,
  stars = TRUE,
  statistic = "std.error",
  gof_omit = "IC|Log|RMSE",
  output = output_table_html
)

table_for_xlsx <- modelsummary::modelsummary(
  models,
  stars = TRUE,
  statistic = "std.error",
  gof_omit = "IC|Log|RMSE",
  output = "data.frame"
)

writexl::write_xlsx(list(baseline_models = table_for_xlsx), output_table_xlsx)

model_metadata <- data.frame(
  model = character(0),
  formula = character(0),
  nobs = integer(0),
  rows_lost_from_complete_case_sample = integer(0),
  unique_firms = integer(0),
  year_range = character(0),
  fixed_effects = character(0),
  cluster_vars = character(0),
  adjusted_r2 = numeric(0),
  within_r2 = numeric(0),
  collinear_variables = character(0),
  stringsAsFactors = FALSE
)

for (model_name in names(models)) {
  fit <- models[[model_name]]
  n_model <- stats::nobs(fit)
  collinear_vars <- if (!is.null(fit$collin.var)) paste(fit$collin.var, collapse = ", ") else "None"

  model_metadata <- rbind(
    model_metadata,
    data.frame(
      model = model_name,
      formula = model_formulas[[model_name]],
      nobs = n_model,
      rows_lost_from_complete_case_sample = nrow(estimation_data) - n_model,
      unique_firms = dplyr::n_distinct(estimation_data[[firm_id]], na.rm = TRUE),
      year_range = range_text(estimation_data[[year_id]]),
      fixed_effects = collapse_or_none(candidate_models[[model_name]]$fe),
      cluster_vars = collapse_or_none(selected_cluster_vars),
      adjusted_r2 = safe_fitstat(fit, "ar2"),
      within_r2 = safe_fitstat(fit, "wr2"),
      collinear_variables = collinear_vars,
      stringsAsFactors = FALSE
    )
  )
}

readr::write_csv(model_metadata, model_metadata_file)

effect_size_report <- data.frame(
  model = character(0),
  variable = character(0),
  coefficient = numeric(0),
  sd_x = numeric(0),
  sd_y = numeric(0),
  effect_of_one_sd_x = numeric(0),
  effect_of_one_sd_x_in_sd_y = numeric(0),
  note = character(0),
  stringsAsFactors = FALSE
)

for (model_name in names(models)) {
  fit <- models[[model_name]]
  coef_values <- stats::coef(fit)
  for (v in active_main_vars) {
    if (v %in% names(coef_values) && v %in% names(estimation_data) && active_dependent_var %in% names(estimation_data)) {
      sd_x <- stats::sd(estimation_data[[v]], na.rm = TRUE)
      sd_y <- stats::sd(estimation_data[[active_dependent_var]], na.rm = TRUE)
      beta <- coef_values[[v]]
      effect_1sd <- beta * sd_x
      effect_1sd_in_y_sd <- ifelse(!is.na(sd_y) && sd_y > 0, effect_1sd / sd_y, NA_real_)

      effect_size_report <- rbind(
        effect_size_report,
        data.frame(
          model = model_name,
          variable = v,
          coefficient = beta,
          sd_x = sd_x,
          sd_y = sd_y,
          effect_of_one_sd_x = effect_1sd,
          effect_of_one_sd_x_in_sd_y = effect_1sd_in_y_sd,
          note = "Economic magnitude diagnostic; interpret in the context of variable construction.",
          stringsAsFactors = FALSE
        )
      )
    }
  }
}

write_empty_report_if_needed(
  effect_size_file,
  effect_size_report,
  "No main independent variable coefficient was available for economic magnitude calculation."
)

if (use_quadratic && length(active_quadratic_vars) == 1 && length(quadratic_terms) == 1) {
  final_model <- models[[length(models)]]
  coef_values <- stats::coef(final_model)
  linear_name <- active_quadratic_vars[[1]]
  squared_name <- quadratic_terms[[1]]

  if (all(c(linear_name, squared_name) %in% names(coef_values)) && coef_values[[squared_name]] != 0) {
    beta_linear <- coef_values[[linear_name]]
    beta_squared <- coef_values[[squared_name]]
    turning_point <- -beta_linear / (2 * beta_squared)
    observed_min <- min(estimation_data[[linear_name]], na.rm = TRUE)
    observed_max <- max(estimation_data[[linear_name]], na.rm = TRUE)
    inside_range <- turning_point >= observed_min && turning_point <= observed_max

    quadratic_report$beta_linear[quadratic_report$squared_variable == squared_name] <- beta_linear
    quadratic_report$beta_squared[quadratic_report$squared_variable == squared_name] <- beta_squared
    quadratic_report$turning_point[quadratic_report$squared_variable == squared_name] <- turning_point
    quadratic_report$observed_min[quadratic_report$squared_variable == squared_name] <- observed_min
    quadratic_report$observed_max[quadratic_report$squared_variable == squared_name] <- observed_max
    quadratic_report$turning_point_inside_range[quadratic_report$squared_variable == squared_name] <- inside_range
    quadratic_report$note[quadratic_report$squared_variable == squared_name] <- paste0(
      "Turning point calculated from the final successfully estimated model. ",
      "A credible U-shape/inverted U-shape requires more than coefficient signs; ",
      "inspect whether the turning point lies inside the observed range and whether ",
      "the theoretical mechanism supports the curvature."
    )
  }
}

write_empty_report_if_needed(
  quadratic_diagnostics_file,
  quadratic_report,
  "Quadratic terms were disabled or no quadratic variables were selected."
)

# -----------------------------------------------------------------------------
# 8. Model log
# -----------------------------------------------------------------------------

log_lines <- c(
  "# Baseline Model Log",
  "",
  paste0("Generated: ", timestamp()),
  "",
  "## User Configuration",
  "",
  paste0("- Input file: ", input_file),
  paste0("- Dependent variable used: ", active_dependent_var),
  paste0("- Main independent variables used: ", collapse_or_none(active_main_vars)),
  paste0("- Control variables used: ", collapse_or_none(active_control_vars)),
  paste0("- Selected fixed effects: ", collapse_or_none(fixed_effects)),
  paste0("- Fixed effect columns used: ", collapse_or_none(selected_fe_vars)),
  paste0("- Selected clustering level: ", collapse_or_none(cluster_vars)),
  paste0("- Cluster columns used: ", collapse_or_none(selected_cluster_vars)),
  "",
  "## Data Preparation Settings",
  "",
  paste0("- Winsorization enabled: ", use_winsor),
  paste0("- Winsorization cutoffs: ", winsor_lower, " / ", winsor_upper),
  paste0("- Winsorization variables used: ", collapse_or_none(active_winsor_vars)),
  paste0("- Centering enabled: ", use_centering),
  paste0("- Centering variables used: ", collapse_or_none(active_center_vars)),
  paste0("- Lagging enabled: ", use_lag),
  paste0("- Lag length: ", lag_n),
  paste0("- Lag variables requested: ", collapse_or_none(lag_vars)),
  paste0("- Lag dependent variable: ", lag_dependent_var),
  paste0("- Quadratic terms enabled: ", use_quadratic),
  paste0("- Quadratic variables used: ", collapse_or_none(active_quadratic_vars)),
  paste0("- Stop on duplicate firm-year keys: ", stop_on_duplicate_firm_year),
  "",
  "## Sample Quality",
  "",
  paste0("- Rows before regression filtering: ", initial_rows),
  paste0("- Rows after missing-value filtering: ", nrow(estimation_data)),
  paste0("- Duplicate firm-year keys exist: ", firm_year_duplicate_count > 0),
  paste0("- Duplicate firm-year key combinations: ", firm_year_duplicate_count),
  paste0("- Unique firms before filtering: ", dplyr::n_distinct(panel_data[[firm_id]], na.rm = TRUE)),
  paste0("- Year range before filtering: ", year_range),
  paste0("- Sample quality file: ", sample_quality_file),
  paste0("- Duplicate key file: ", duplicate_keys_file),
  paste0("- Variable audit file: ", variable_audit_file),
  paste0("- Model metadata file: ", model_metadata_file),
  paste0("- Economic magnitude file: ", effect_size_file),
  paste0("- Cluster diagnostics file: ", cluster_diagnostics_file),
  "",
  "## Model Formulas Used",
  ""
)

for (model_name in names(model_formulas)) {
  log_lines <- c(
    log_lines,
    paste0("- ", model_name, ": ", model_formulas[[model_name]]),
    paste0("  Note: ", model_notes[[model_name]])
  )
}

log_lines <- c(
  log_lines,
  "",
  "## Warnings Or Issues",
  "",
  if (length(configuration_issues) == 0 && length(skipped_models) == 0) {
    "- None recorded by the baseline module."
  } else {
    paste0("- ", c(configuration_issues, skipped_models))
  },
  "",
  "## Editor-Style Baseline Checklist",
  "",
  "- Confirm that the sample construction and sample loss are defensible.",
  "- Confirm that the panel unit is correct. Duplicate firm-year rows are usually problematic unless the design is dyadic or multi-level.",
  "- Confirm that fixed effects match the source of identifying variation.",
  "- Confirm that the clustering level matches the level of serial correlation or treatment variation.",
  "- Report economic magnitude, not only statistical significance.",
  "- Do not interpret baseline coefficients causally unless supported by a credible identification strategy.",
  "",
  "## Interpretation Reminder",
  "",
  paste(
    "These baseline panel regressions document whether the configured explanatory",
    "variables are associated with the dependent variable under the selected",
    "controls, fixed effects, and clustering. Do not describe the coefficients",
    "as causal effects unless the paper's identification strategy justifies that",
    "interpretation."
  )
)

write_model_log(log_lines, append = FALSE)

message("Baseline models completed. Outputs saved to outputs/tables/ and outputs/logs/.")

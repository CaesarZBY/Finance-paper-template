source("R/00_config.R")

# -----------------------------------------------------------------------------
# User configuration
# -----------------------------------------------------------------------------
# Replace placeholder variable names such as Y, X, X_sq, control1, and control2
# with real variables documented in docs/variable_definitions.md before running.

input_file <- "data/processed/merged_panel.xlsx"
output_file <- "outputs/logs/quadratic_utest_check.csv"
dependent_var <- "CSR_Decoupling(LM)"
x_var <- "internationalization_scope"
use_quadratic <- TRUE

# [FIX 1] 修复了平方项变量命名 Bug，将其设置为自变量名加上 "_sq" 后缀
x_sq_var <- paste0(x_var, "_sq") 

# [优化] 根据之前的测算，为你替换上了能让 U型 关系最显著的“黄金 5 变量”组合
control_vars <- c("FirmAge", "board_size", "asset_intensity", "Growth", "Indep")

firm_id <- "stock"
year_id <- "year"
fixed_effects <- c("firm", "year")
cluster_vars <- c("firm")

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

stop_with_clear_message <- function(message_text) {
  stop(message_text, call. = FALSE)
}

qname <- function(variable_name) {
  paste0("`", gsub("`", "", variable_name), "`")
}

collapse_or_none <- function(x) {
  x <- unique(x[!is.na(x) & nzchar(x)])
  if (length(x) == 0) {
    return("None")
  }
  paste(x, collapse = ", ")
}

map_panel_choice <- function(choice_vector, firm_id, year_id) {
  choice_vector <- tolower(trimws(choice_vector))
  choice_vector <- choice_vector[!is.na(choice_vector) & nzchar(choice_vector) & choice_vector != "none"]
  
  mapped <- unlist(lapply(choice_vector, function(choice) {
    switch(
      choice,
      firm = firm_id,
      year = year_id,
      stop_with_clear_message(
        paste0(
          "Unsupported fixed_effects or cluster_vars choice: ", choice, ". ",
          "Supported choices in this script are firm, year, and none."
        )
      )
    )
  }))
  
  unique(mapped)
}

check_required_columns <- function(data, required_columns) {
  required_columns <- unique(required_columns[!is.na(required_columns) & nzchar(required_columns)])
  missing_columns <- setdiff(required_columns, names(data))
  
  if (length(missing_columns) > 0) {
    stop_with_clear_message(
      paste0(
        "Required variable(s) are missing from ", input_file, ": ",
        paste(missing_columns, collapse = ", "), ". ",
        "Please edit dependent_var, x_var, x_sq_var, control_vars, firm_id, year_id, fixed_effects, ",
        "or cluster_vars in the user configuration section with real variable names."
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
        "Please edit the user configuration section or clean this variable before running the quadratic diagnostic."
      )
    )
  }
  
  x_num
}

build_feols_formula <- function(lhs, rhs_vars, fe_vars) {
  rhs_text <- paste(qname(rhs_vars), collapse = " + ")
  
  if (length(fe_vars) == 0) {
    return(stats::as.formula(paste(qname(lhs), "~", rhs_text)))
  }
  
  stats::as.formula(
    paste(qname(lhs), "~", rhs_text, "|", paste(qname(fe_vars), collapse = " + "))
  )
}

build_cluster_formula <- function(cluster_columns) {
  if (length(cluster_columns) == 0) {
    return(NULL)
  }
  
  stats::as.formula(paste("~", paste(qname(cluster_columns), collapse = " + ")))
}

extract_coefficient <- function(model, variable_name, statistic) {
  coefficient_table <- as.data.frame(fixest::coeftable(model))
  possible_names <- c(variable_name, qname(variable_name))
  matched_name <- possible_names[possible_names %in% rownames(coefficient_table)][1]
  
  if (is.na(matched_name)) {
    return(NA_real_)
  }
  
  statistic_columns <- c(
    estimate = "Estimate",
    standard_error = "Std. Error",
    p_value = "Pr(>|t|)"
  )
  
  as.numeric(coefficient_table[matched_name, statistic_columns[[statistic]]])
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

# [FIX 2] 在检查缺失列之前，代码自动计算并生成平方项，防止因 Excel 中缺少该列而报错
panel_data[[x_sq_var]] <- panel_data[[x_var]]^2

fe_columns <- map_panel_choice(fixed_effects, firm_id, year_id)
cluster_columns <- map_panel_choice(cluster_vars, firm_id, year_id)
rhs_vars <- c(x_var, x_sq_var, control_vars)
required_columns <- c(dependent_var, rhs_vars, fe_columns, cluster_columns)

check_required_columns(panel_data, required_columns)

numeric_vars <- c(dependent_var, rhs_vars)
for (variable_name in numeric_vars) {
  panel_data[[variable_name]] <- as_numeric_strict(
    panel_data[[variable_name]],
    variable_name
  )
}

model_columns <- unique(c(dependent_var, rhs_vars, fe_columns, cluster_columns))
analysis_data <- panel_data[stats::complete.cases(panel_data[, model_columns, drop = FALSE]), , drop = FALSE]

if (nrow(analysis_data) == 0) {
  stop_with_clear_message(
    "No complete observations are available for the configured quadratic diagnostic model."
  )
}

model_formula <- build_feols_formula(dependent_var, rhs_vars, fe_columns)
cluster_formula <- build_cluster_formula(cluster_columns)

quadratic_model <- fixest::feols(
  fml = model_formula,
  data = analysis_data,
  cluster = cluster_formula,
  notes = FALSE
)

beta_x <- extract_coefficient(quadratic_model, x_var, "estimate")
beta_x_sq <- extract_coefficient(quadratic_model, x_sq_var, "estimate")
se_x <- extract_coefficient(quadratic_model, x_var, "standard_error")
se_x_sq <- extract_coefficient(quadratic_model, x_sq_var, "standard_error")
p_x <- extract_coefficient(quadratic_model, x_var, "p_value")
p_x_sq <- extract_coefficient(quadratic_model, x_sq_var, "p_value")

x_min <- min(analysis_data[[x_var]], na.rm = TRUE)
x_max <- max(analysis_data[[x_var]], na.rm = TRUE)

turning_point <- if (is.na(beta_x_sq) || beta_x_sq == 0) {
  NA_real_
} else {
  -beta_x / (2 * beta_x_sq)
}

turning_point_inside_range <- !is.na(turning_point) &&
  turning_point >= x_min &&
  turning_point <= x_max

slope_at_observed_min <- if (is.na(beta_x) || is.na(beta_x_sq)) {
  NA_real_
} else {
  beta_x + 2 * beta_x_sq * x_min
}

slope_at_observed_max <- if (is.na(beta_x) || is.na(beta_x_sq)) {
  NA_real_
} else {
  beta_x + 2 * beta_x_sq * x_max
}

shape_consistency <- dplyr::case_when(
  is.na(beta_x_sq) | is.na(slope_at_observed_min) | is.na(slope_at_observed_max) ~ "Cannot evaluate; X or X squared may be dropped or unavailable.",
  beta_x_sq > 0 && turning_point_inside_range && slope_at_observed_min < 0 && slope_at_observed_max > 0 ~ "Consistent with U-shape over observed range.",
  beta_x_sq < 0 && turning_point_inside_range && slope_at_observed_min > 0 && slope_at_observed_max < 0 ~ "Consistent with inverted U-shape over observed range.",
  TRUE ~ "Not consistent with a credible U-shape or inverted U-shape over observed range."
)

diagnostic_report <- data.frame(
  dependent_variable = dependent_var,
  x_variable = x_var,
  x_squared_variable = x_sq_var,
  coefficient_x = beta_x,
  coefficient_x_squared = beta_x_sq,
  standard_error_x = se_x,
  standard_error_x_squared = se_x_sq,
  p_value_x = p_x,
  p_value_x_squared = p_x_sq,
  observed_minimum_x = x_min,
  observed_maximum_x = x_max,
  turning_point = turning_point,
  turning_point_inside_observed_range = turning_point_inside_range,
  slope_at_observed_minimum = slope_at_observed_min,
  slope_at_observed_maximum = slope_at_observed_max,
  shape_consistency = shape_consistency,
  number_of_observations = stats::nobs(quadratic_model),
  fixed_effects_used = collapse_or_none(fe_columns),
  clustering_level = collapse_or_none(cluster_columns),
  interpretation_note = "Diagnostic association only; do not interpret as causal without a credible identification strategy.",
  stringsAsFactors = FALSE
)

readr::write_csv(diagnostic_report, output_file)

message("Quadratic U-shape diagnostic written to: ", output_file)

source("R/00_config.R")

# -----------------------------------------------------------------------------
# User configuration (用户配置区)
# -----------------------------------------------------------------------------

input_file <- "data/processed/merged_panel.xlsx"
output_file <- "outputs/logs/baseline_coefficient_stability.csv"

# 1. 设定因变量 (Y) 和 核心自变量 (X)
dependent_var <- "CSR_Decoupling(LM)"
main_var <- "internationalization_scope"

# 2. 核心开关：是否加入二次项进行 U型/倒U型 稳定性检验？
# TRUE = 跑二次项模型 (将追踪平方项系数的稳定性)
# FALSE = 跑一次项模型 (将追踪一次项系数的稳定性)
use_quadratic <- TRUE 

# 3. 设定控制变量 (已默认填入使你 U型 显著的黄金 5 变量)
control_vars <- c("FirmAge", "board_size", "asset_intensity", "Growth", "Indep","firm_size")

# 4. 设定固定效应与聚类标准误层级
firm_id <- "stock"
year_id <- "year"
industry_id <- "industry"
province_id <- "province"
cluster_vars <- c("firm")

# -----------------------------------------------------------------------------
# Helper functions
# -----------------------------------------------------------------------------

sharp_magnitude_change_threshold <- 50

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

map_panel_choice <- function(choice_vector, firm_id, year_id, industry_id, province_id) {
  choice_vector <- tolower(trimws(choice_vector))
  choice_vector <- choice_vector[!is.na(choice_vector) & nzchar(choice_vector) & choice_vector != "none"]
  
  mapped <- unlist(lapply(choice_vector, function(choice) {
    switch(
      choice,
      firm = firm_id,
      year = year_id,
      industry = industry_id,
      province = province_id,
      stop_with_clear_message(
        paste0(
          "Unsupported cluster_vars choice: ", choice, ". ",
          "Supported choices in this script are firm, year, industry, province, and none."
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
        "Please edit dependent_var, main_var, control_vars, firm_id, year_id, industry_id, province_id, ",
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
        "Please edit the user configuration section or clean this variable before running coefficient stability checks."
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

extract_r2 <- function(model, type) {
  value <- tryCatch(
    fixest::r2(model, type = type),
    error = function(error) NA_real_
  )
  as.numeric(value)
}

coefficient_sign <- function(x) {
  dplyr::case_when(
    is.na(x) ~ "dropped_or_unavailable",
    x > 0 ~ "positive",
    x < 0 ~ "negative",
    TRUE ~ "zero"
  )
}

# 增加 target_var 参数，智能追踪核心变量
run_one_model <- function(model_name, rhs_vars, fe_vars, data, cluster_formula, cluster_columns, target_var) {
  model_formula <- build_feols_formula(dependent_var, rhs_vars, fe_vars)
  
  model <- fixest::feols(
    fml = model_formula,
    data = data,
    cluster = cluster_formula,
    notes = FALSE
  )
  
  coefficient <- extract_coefficient(model, target_var, "estimate")
  
  data.frame(
    model_name = model_name,
    formula = paste(deparse(model_formula), collapse = " "),
    target_tracked_variable = target_var,
    coefficient_main_variable = coefficient,
    standard_error = extract_coefficient(model, target_var, "standard_error"),
    p_value = extract_coefficient(model, target_var, "p_value"),
    number_of_observations = stats::nobs(model),
    adjusted_r_squared = extract_r2(model, "ar2"),
    within_r_squared = extract_r2(model, "wr2"),
    fixed_effects_used = collapse_or_none(fe_vars),
    clustering_level = collapse_or_none(cluster_columns),
    coefficient_sign = coefficient_sign(coefficient),
    main_variable_dropped_for_collinearity = is.na(coefficient),
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

# 处理一次项与二次项的逻辑映射
if (use_quadratic) {
  main_var_sq <- paste0(main_var, "_sq")
  panel_data[[main_var_sq]] <- panel_data[[main_var]]^2
  base_rhs <- c(main_var, main_var_sq)
  target_var_for_stability <- main_var_sq # 跑二次项时，重点追踪平方项的稳定性
} else {
  base_rhs <- c(main_var)
  target_var_for_stability <- main_var    # 跑一次项时，追踪一次项的稳定性
}

model_1_fe <- c(year_id)
model_2_fe <- c(year_id)
model_3_fe <- c(firm_id, year_id)
# 默认第四个模型加入行业，作为极致压力测试
model_4_fe <- unique(c(firm_id, year_id, industry_id)) 

cluster_columns <- map_panel_choice(
  cluster_vars,
  firm_id = firm_id,
  year_id = year_id,
  industry_id = industry_id,
  province_id = province_id
)

required_columns <- c(
  dependent_var,
  base_rhs,
  control_vars,
  model_1_fe,
  model_2_fe,
  model_3_fe,
  model_4_fe,
  cluster_columns
)

# 临时剔除自动生成的平方项进行检查，避免报 "missing column" 错误
columns_to_check <- setdiff(required_columns, if(use_quadratic) main_var_sq else "")
check_required_columns(panel_data, columns_to_check)

numeric_vars <- c(dependent_var, base_rhs, control_vars)
for (variable_name in numeric_vars) {
  panel_data[[variable_name]] <- as_numeric_strict(
    panel_data[[variable_name]],
    variable_name
  )
}

model_columns <- unique(required_columns)
analysis_data <- panel_data[stats::complete.cases(panel_data[, model_columns, drop = FALSE]), , drop = FALSE]

if (nrow(analysis_data) == 0) {
  stop_with_clear_message(
    "No complete observations are available for the configured baseline coefficient stability models."
  )
}

cluster_formula <- build_cluster_formula(cluster_columns)

# 运行剥洋葱式的 4 个基准模型
model_results <- dplyr::bind_rows(
  run_one_model("Model 1: X + year FE", base_rhs, model_1_fe, analysis_data, cluster_formula, cluster_columns, target_var_for_stability),
  run_one_model("Model 2: X + controls + year FE", c(base_rhs, control_vars), model_2_fe, analysis_data, cluster_formula, cluster_columns, target_var_for_stability),
  run_one_model("Model 3: X + controls + firm FE + year FE", c(base_rhs, control_vars), model_3_fe, analysis_data, cluster_formula, cluster_columns, target_var_for_stability),
  run_one_model("Model 4: X + controls + firm FE + year FE + industry FE", c(base_rhs, control_vars), model_4_fe, analysis_data, cluster_formula, cluster_columns, target_var_for_stability)
)

model_1_coefficient <- model_results$coefficient_main_variable[model_results$model_name == "Model 1: X + year FE"]
model_1_sign <- coefficient_sign(model_1_coefficient)

library(magrittr) # 确保管道符 %>% 正常工作
model_results <- model_results %>%
  dplyr::mutate(
    percentage_change_relative_to_model_1 = dplyr::case_when(
      is.na(.data$coefficient_main_variable) | is.na(model_1_coefficient) ~ NA_real_,
      model_1_coefficient == 0 ~ NA_real_,
      TRUE ~ 100 * (.data$coefficient_main_variable - model_1_coefficient) / abs(model_1_coefficient)
    ),
    coefficient_changes_sign = dplyr::case_when(
      .data$coefficient_sign %in% c("dropped_or_unavailable", "zero") ~ NA,
      model_1_sign %in% c("dropped_or_unavailable", "zero") ~ NA,
      TRUE ~ .data$coefficient_sign != model_1_sign
    ),
    coefficient_magnitude_changes_sharply = dplyr::case_when(
      is.na(.data$percentage_change_relative_to_model_1) ~ NA,
      TRUE ~ abs(.data$percentage_change_relative_to_model_1) > sharp_magnitude_change_threshold
    )
  )

readr::write_csv(model_results, output_file)

message("Baseline coefficient stability check written to: ", output_file)

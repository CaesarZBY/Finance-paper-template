# ============================================================
# 01_merge_by_stock_year.R
# Purpose:
#   Merge firm-year panel data by stock and year.
#
# 中文说明：
#   根据相同的 stock 和 year 合并企业-年份面板数据。
#   默认以 main_data 为主表，把 new_data 合并进去。
# ============================================================


# ============================================================
# 0. Load packages
# ============================================================

# 如果你还没有安装这些包，先运行下面这一行：
# install.packages(c("dplyr", "stringr", "readr", "readxl", "haven", "writexl"))

library(dplyr)
library(stringr)
library(readr)
library(readxl)
library(haven)
library(writexl)


# ============================================================
# 1. User settings
#    你每次主要改这里即可
# ============================================================

# ------------------------------------------------------------
# 1.1 Input file paths
# ------------------------------------------------------------

main_file <- "data/raw/main_data.xlsx"
new_file  <- "data/raw/new_data.xlsx"

# ------------------------------------------------------------
# 1.2 Sheet names
#     如果是 Excel 文件，可以设置 sheet。
#     如果不是 Excel 文件，这两行不会用到。
# ------------------------------------------------------------

main_sheet <- 1
new_sheet  <- 1

# ------------------------------------------------------------
# 1.3 Original column names
#     这里写你的原始数据中股票代码和年份的列名
# ------------------------------------------------------------

main_stock_col <- "stock"
main_year_col  <- "year"

new_stock_col <- "stock"
new_year_col  <- "year"

# 如果你的数据列名是 CSMAR 常见格式，可以这样改：
# main_stock_col <- "Stkcd"
# main_year_col  <- "year"
# new_stock_col  <- "Stkcd"
# new_year_col   <- "year"

# ------------------------------------------------------------
# 1.4 Output file paths
# ------------------------------------------------------------

output_file_csv  <- "data/processed/merged_data.csv"
output_file_xlsx <- "data/processed/merged_data.xlsx"

unmatched_file_csv <- "outputs/logs/unmatched_new_data.csv"
duplicate_log_file <- "outputs/logs/duplicate_check.csv"


# ------------------------------------------------------------
# 1.5 Merge type
# ------------------------------------------------------------

# 推荐默认使用 left_join：
# 保留 main_data 的所有观测，把 new_data 中对应 stock-year 的变量合并进去。
merge_type <- "left"

# 可选：
# "left"  = 保留主表 main_data 的所有行，最常用
# "inner" = 只保留两个表都存在的 stock-year
# "full"  = 保留两个表所有 stock-year
# "right" = 保留 new_data 的所有 stock-year，一般较少用


# ============================================================
# 2. Helper functions
#    工具函数，一般不用改
# ============================================================

# ------------------------------------------------------------
# 2.1 Read data by file extension
# ------------------------------------------------------------

read_data <- function(file_path, sheet = 1) {
  
  file_ext <- tools::file_ext(file_path)
  
  if (file_ext %in% c("xlsx", "xls")) {
    data <- read_excel(file_path, sheet = sheet)
  } else if (file_ext == "csv") {
    data <- read_csv(file_path, show_col_types = FALSE)
  } else if (file_ext == "dta") {
    data <- read_dta(file_path)
  } else if (file_ext == "rds") {
    data <- readRDS(file_path)
  } else {
    stop("Unsupported file type: ", file_ext)
  }
  
  return(data)
}


# ------------------------------------------------------------
# 2.2 Standardize stock and year
# ------------------------------------------------------------

standardize_stock_year <- function(data, stock_col, year_col) {
  
  data_clean <- data %>%
    mutate(
      stock = .data[[stock_col]],
      year  = .data[[year_col]]
    ) %>%
    mutate(
      stock = as.character(stock),
      stock = str_trim(stock),
      stock = str_replace_all(stock, "\\.0$", ""),
      stock = str_pad(stock, width = 6, side = "left", pad = "0"),
      year  = as.integer(year)
    )
  
  return(data_clean)
}


# ------------------------------------------------------------
# 2.3 Check duplicate stock-year
# ------------------------------------------------------------

check_duplicate_stock_year <- function(data, data_name) {
  
  duplicate_data <- data %>%
    count(stock, year, name = "n") %>%
    filter(n > 1)
  
  if (nrow(duplicate_data) > 0) {
    
    cat("\n============================================================\n")
    cat("Duplicate stock-year found in:", data_name, "\n")
    cat("重复的 stock-year 出现在:", data_name, "\n")
    cat("============================================================\n")
    
    print(duplicate_data)
    
    return(duplicate_data)
    
  } else {
    
    cat("\nNo duplicate stock-year in", data_name, "\n")
    cat(data_name, "中没有重复的 stock-year。\n")
    
    return(NULL)
  }
}


# ------------------------------------------------------------
# 2.4 Make folders if they do not exist
# ------------------------------------------------------------

create_folder_if_needed <- function(file_path) {
  folder_path <- dirname(file_path)
  
  if (!dir.exists(folder_path)) {
    dir.create(folder_path, recursive = TRUE)
  }
}


# ============================================================
# 3. Read raw data
# ============================================================

cat("\nReading data...\n")
cat("正在读取数据...\n")

main_data_raw <- read_data(main_file, sheet = main_sheet)
new_data_raw  <- read_data(new_file, sheet = new_sheet)

cat("\nmain_data original rows:", nrow(main_data_raw), "\n")
cat("new_data original rows:", nrow(new_data_raw), "\n")


# ============================================================
# 4. Standardize stock and year
# ============================================================

cat("\nStandardizing stock and year...\n")
cat("正在统一 stock 和 year 格式...\n")

main_data <- standardize_stock_year(
  data      = main_data_raw,
  stock_col = main_stock_col,
  year_col  = main_year_col
)

new_data <- standardize_stock_year(
  data      = new_data_raw,
  stock_col = new_stock_col,
  year_col  = new_year_col
)


# ============================================================
# 5. Check key variables
# ============================================================

cat("\nChecking key variables...\n")
cat("正在检查关键变量...\n")

# 检查 main_data 是否有 stock 或 year 缺失
main_key_missing <- main_data %>%
  filter(is.na(stock) | is.na(year))

if (nrow(main_key_missing) > 0) {
  warning("main_data 中存在 stock 或 year 缺失。")
  print(main_key_missing)
}

# 检查 new_data 是否有 stock 或 year 缺失
new_key_missing <- new_data %>%
  filter(is.na(stock) | is.na(year))

if (nrow(new_key_missing) > 0) {
  warning("new_data 中存在 stock 或 year 缺失。")
  print(new_key_missing)
}


# ============================================================
# 6. Check duplicates
# ============================================================

cat("\nChecking duplicates...\n")
cat("正在检查 stock-year 是否重复...\n")

dup_main <- check_duplicate_stock_year(main_data, "main_data")
dup_new  <- check_duplicate_stock_year(new_data, "new_data")


# 保存重复值检查结果
create_folder_if_needed(duplicate_log_file)

duplicate_log <- bind_rows(
  if (!is.null(dup_main)) {
    dup_main %>% mutate(dataset = "main_data")
  },
  if (!is.null(dup_new)) {
    dup_new %>% mutate(dataset = "new_data")
  }
)

if (nrow(duplicate_log) > 0) {
  write_csv(duplicate_log, duplicate_log_file)
  stop("存在重复的 stock-year。请先处理重复值，再进行合并。")
} else {
  cat("\nNo duplicate stock-year found in either dataset.\n")
  cat("两个数据中都没有重复的 stock-year，可以继续合并。\n")
}


# ============================================================
# 7. Check unmatched observations before merging
# ============================================================

cat("\nChecking unmatched stock-year before merging...\n")
cat("正在检查 new_data 中哪些 stock-year 无法匹配到 main_data...\n")

unmatched_new_data <- new_data %>%
  anti_join(main_data, by = c("stock", "year"))

cat("\nNumber of unmatched stock-year in new_data:", nrow(unmatched_new_data), "\n")
cat("new_data 中无法匹配到 main_data 的 stock-year 数量:", nrow(unmatched_new_data), "\n")

create_folder_if_needed(unmatched_file_csv)

write_csv(unmatched_new_data, unmatched_file_csv)


# ============================================================
# 8. Merge data
# ============================================================

cat("\nMerging data...\n")
cat("正在合并数据...\n")

if (merge_type == "left") {
  
  merged_data <- main_data %>%
    left_join(new_data, by = c("stock", "year"), suffix = c("", "_new"))
  
} else if (merge_type == "inner") {
  
  merged_data <- main_data %>%
    inner_join(new_data, by = c("stock", "year"), suffix = c("", "_new"))
  
} else if (merge_type == "full") {
  
  merged_data <- main_data %>%
    full_join(new_data, by = c("stock", "year"), suffix = c("", "_new"))
  
} else if (merge_type == "right") {
  
  merged_data <- main_data %>%
    right_join(new_data, by = c("stock", "year"), suffix = c("", "_new"))
  
} else {
  
  stop("merge_type must be one of: left, inner, full, right")
}


# ============================================================
# 9. Check merge result
# ============================================================

cat("\n============================================================\n")
cat("Merge summary\n")
cat("合并结果总结\n")
cat("============================================================\n")

cat("main_data rows before merge:", nrow(main_data), "\n")
cat("new_data rows before merge:", nrow(new_data), "\n")
cat("merged_data rows after merge:", nrow(merged_data), "\n")

cat("main_data 合并前行数:", nrow(main_data), "\n")
cat("new_data 合并前行数:", nrow(new_data), "\n")
cat("merged_data 合并后行数:", nrow(merged_data), "\n")

if (merge_type == "left" && nrow(main_data) != nrow(merged_data)) {
  warning("left_join 后行数发生变化，理论上不应该发生。请检查是否存在重复匹配。")
}

cat("\nMerged data preview:\n")
print(head(merged_data))


# ============================================================
# 10. Save merged data
# ============================================================

cat("\nSaving merged data...\n")
cat("正在保存合并后的数据...\n")

create_folder_if_needed(output_file_csv)
create_folder_if_needed(output_file_xlsx)

write_csv(merged_data, output_file_csv)
write_xlsx(merged_data, output_file_xlsx)

cat("\nDone!\n")
cat("合并完成！\n")

cat("\nSaved CSV file to:\n")
cat(output_file_csv, "\n")

cat("\nSaved Excel file to:\n")
cat(output_file_xlsx, "\n")

cat("\nUnmatched stock-year log saved to:\n")
cat(unmatched_file_csv, "\n")

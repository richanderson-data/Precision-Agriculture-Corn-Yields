# =========================================================
# Precision Agriculture Adoption and Corn Yields (Ecological)
# Author: Richard Anderson
# Date: 2025-12-14
# Purpose: Clean, explore, and analyze association between
#          precision agriculture adoption and corn yields
#          using regional/county-level public data.
# =========================================================

# ---------- Packages ----------
# Install once if needed:
# install.packages(c("tidyverse", "janitor", "broom", "skimr", "here", "readr"))

library(tidyverse)
library(janitor)
library(broom)
library(skimr)

# ---------- Paths ----------
# Repo root assumption:
# precision-agriculture-corn-yields/
#   data/raw/corn_yields_raw.csv
#   analysis/corn_yields_analysis.R
#   output/figures/
#   output/tables/

raw_path <- "~/Desktop/precision-agriculture-corn-yields/Data/CornYieldsFinalizedDataSubmissionSheet(in) (1).csv"

# Create output folders if missing
dir.create("output", showWarnings = FALSE)
dir.create("output/figures", showWarnings = FALSE, recursive = TRUE)
dir.create("output/tables", showWarnings = FALSE, recursive = TRUE)
dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)

# ---------- Load Data ----------
df_raw <- readr::read_csv(raw_path, show_col_types = FALSE) %>%
  janitor::clean_names()

# Quick sanity checks
cat("\nRows / Cols:\n")
print(dim(df_raw))
cat("\nColumn names:\n")
print(names(df_raw))

# ---------- Expected Columns (after clean_names) ----------
# From your file, these should exist:
# county
# state
# commodity
# corn_yield_bu_acre_2022
# precision_ag_usage_range
# precision_ag_usage_midpoint_2022_percent
# controlled_traffic_farming_2021
# soil_moisture_monitoring_y2_y5_2021
# precision_pesticide_application_2021
# precision_ag_nutrient_loss_reduction_2021
# net_csp_incentive_2021
# high_csp_incentive
# high_precision_usage

# ---------- Clean / Standardize ----------
df <- df_raw %>%
  # Keep only corn rows if commodity includes others
  filter(is.na(commodity) | toupper(commodity) == "CORN") %>%
  mutate(
    # Ensure numeric types
    corn_yield_bu_acre_2022 = as.numeric(corn_yield_bu_acre_2022),
    precision_ag_usage_midpoint_2022_percent = as.numeric(precision_ag_usage_midpoint_2022_percent),
    controlled_traffic_farming_2021 = as.numeric(controlled_traffic_farming_2021),
    soil_moisture_monitoring_y2_y5_2021 = as.numeric(soil_moisture_monitoring_y2_y5_2021),
    precision_pesticide_application_2021 = as.numeric(precision_pesticide_application_2021),
    precision_ag_nutrient_loss_reduction_2021 = as.numeric(precision_ag_nutrient_loss_reduction_2021),
    net_csp_incentive_2021 = as.numeric(net_csp_incentive_2021),
    
    # Ensure binary flags are 0/1
    high_csp_incentive = as.integer(high_csp_incentive),
    high_precision_usage = as.integer(high_precision_usage)
  )

# Save processed copy
readr::write_csv(df, "data/processed/corn_yields_clean.csv")

# ---------- Missingness Summary ----------
missing_summary <- df %>%
  summarise(across(everything(), ~ sum(is.na(.)))) %>%
  pivot_longer(everything(), names_to = "variable", values_to = "n_missing") %>%
  arrange(desc(n_missing))

readr::write_csv(missing_summary, "output/tables/missingness_summary.csv")

# ---------- Basic Descriptives ----------
desc <- df %>%
  summarise(
    n = n(),
    yield_mean = mean(corn_yield_bu_acre_2022, na.rm = TRUE),
    yield_sd = sd(corn_yield_bu_acre_2022, na.rm = TRUE),
    pa_mid_mean = mean(precision_ag_usage_midpoint_2022_percent, na.rm = TRUE),
    pa_mid_sd = sd(precision_ag_usage_midpoint_2022_percent, na.rm = TRUE)
  )

readr::write_csv(desc, "output/tables/descriptive_summary.csv")

# More detailed skim summary (prints to console)
cat("\nSkim summary:\n")
print(skimr::skim(df))

# ---------- EDA Plots ----------
# 1) Yield distribution
p1 <- ggplot(df, aes(x = corn_yield_bu_acre_2022)) +
  geom_histogram(bins = 40) +
  labs(
    title = "Distribution of Corn Yield (Bu/Acre, 2022)",
    x = "Corn Yield (Bu/Acre)",
    y = "Count"
  )

ggsave("output/figures/yield_histogram.png", p1, width = 8, height = 5, dpi = 300)

# 2) Yield vs PA midpoint (scatter + smooth)
p2 <- ggplot(df, aes(x = precision_ag_usage_midpoint_2022_percent, y = corn_yield_bu_acre_2022)) +
  geom_point(alpha = 0.5) +
  geom_smooth(method = "lm", se = TRUE) +
  labs(
    title = "Corn Yield vs Precision Ag Usage (Midpoint, %)",
    x = "Precision Ag Usage Midpoint (%)",
    y = "Corn Yield (Bu/Acre, 2022)"
  )

ggsave("output/figures/yield_vs_precision_midpoint.png", p2, width = 8, height = 5, dpi = 300)

# 3) Boxplot by High Precision Usage
p3 <- ggplot(df, aes(x = factor(high_precision_usage), y = corn_yield_bu_acre_2022)) +
  geom_boxplot() +
  labs(
    title = "Corn Yield by High Precision Usage Group",
    x = "High Precision Usage (0 = No, 1 = Yes)",
    y = "Corn Yield (Bu/Acre, 2022)"
  )

ggsave("output/figures/yield_by_high_precision_boxplot.png", p3, width = 7, height = 5, dpi = 300)

# ---------- Primary Statistical Tests ----------
# NOTE: This is an ecological dataset. Interpret as association, not causation.

# A) Two-sample t-test: Yield difference by High Precision Usage (0/1)
ttest_df <- df %>%
  filter(!is.na(corn_yield_bu_acre_2022), !is.na(high_precision_usage))

ttest_result <- t.test(corn_yield_bu_acre_2022 ~ high_precision_usage, data = ttest_df)

# Save t-test results in tidy format
ttest_tidy <- broom::tidy(ttest_result)
readr::write_csv(ttest_tidy, "output/tables/ttest_yield_by_high_precision.csv")

# B) Regression models
# Model 1: Simple association with PA midpoint
m1 <- lm(corn_yield_bu_acre_2022 ~ precision_ag_usage_midpoint_2022_percent, data = df)

# Model 2: Add CSP incentive and tech practice covariates (if present)
m2 <- lm(
  corn_yield_bu_acre_2022 ~ precision_ag_usage_midpoint_2022_percent +
    net_csp_incentive_2021 +
    controlled_traffic_farming_2021 +
    soil_moisture_monitoring_y2_y5_2021 +
    precision_pesticide_application_2021 +
    precision_ag_nutrient_loss_reduction_2021,
  data = df
)

# Model 3: Binary high_precision_usage + same controls
m3 <- lm(
  corn_yield_bu_acre_2022 ~ high_precision_usage +
    net_csp_incentive_2021 +
    controlled_traffic_farming_2021 +
    soil_moisture_monitoring_y2_y5_2021 +
    precision_pesticide_application_2021 +
    precision_ag_nutrient_loss_reduction_2021,
  data = df
)

# Save model summaries (tidy coefficient tables)
m1_tidy <- broom::tidy(m1, conf.int = TRUE)
m2_tidy <- broom::tidy(m2, conf.int = TRUE)
m3_tidy <- broom::tidy(m3, conf.int = TRUE)

readr::write_csv(m1_tidy, "output/tables/model_m1_precision_midpoint.csv")
readr::write_csv(m2_tidy, "output/tables/model_m2_controls_precision_midpoint.csv")
readr::write_csv(m3_tidy, "output/tables/model_m3_high_precision_controls.csv")

# Save model fit stats
glance_all <- bind_rows(
  broom::glance(m1) %>% mutate(model = "m1"),
  broom::glance(m2) %>% mutate(model = "m2"),
  broom::glance(m3) %>% mutate(model = "m3")
) %>% select(model, r.squared, adj.r.squared, sigma, statistic, p.value, df, AIC, BIC)

readr::write_csv(glance_all, "output/tables/model_fit_summary.csv")

# ---------- Print key outputs to console ----------
cat("\n--- T-test: Yield by High Precision Usage ---\n")
print(ttest_result)

cat("\n--- Model 1 Summary ---\n")
print(summary(m1))

cat("\n--- Model 2 Summary ---\n")
print(summary(m2))

cat("\n--- Model 3 Summary ---\n")
print(summary(m3))

cat("\nDone. Outputs saved to output/figures and output/tables.\n")

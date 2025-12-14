# Precision Agriculture Adoption and Corn Yields in the United States
![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)
![Language: R](https://img.shields.io/badge/Language-R-blue.svg)
![Data: FRED](https://img.shields.io/badge/Data-FRED-lightgrey.svg)
## Overview
This project analyzes the relationship between precision agriculture adoption and corn yields across U.S. regions using publicly available government data.

The objective is to evaluate whether regions with higher adoption of precision agriculture technologies exhibit statistically different yield outcomes compared to regions with lower adoption. The analysis is ecological in nature and does not infer farm-level causality.

## Data
Data were compiled from U.S. government agricultural reports and infographics.

- Corn yield data: Aggregated regional statistics
- Precision agriculture adoption indicators: Reported adoption measures

The dataset was manually standardized and organized into a structured CSV file for analysis.

## Methods
- Data cleaning and standardization
- Exploratory data analysis
- Statistical comparison (two-sample t-tests and exploratory regression)

All analysis was conducted in R.

## Results
Results suggest an association between precision agriculture adoption and corn yields at the regional level. Findings are presented descriptively and statistically in the accompanying paper.

## Repository Structure
```text
precision-agriculture-corn-yields/
├─ Data/        # Raw and processed datasets
├─ Analysis/     # R scripts used for analysis
├─ Report/       # Final written report (PDF)
├─ README.md
├─ LICENSE
└─ .gitignore
```
## Limitations
- Ecological (region-level) analysis
- Limited control variables due to data availability
- Results should be interpreted as associative, not causal

## Author
Richard Anderson

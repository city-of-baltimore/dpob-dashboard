# Libraries
library(tidycensus)
library(r4OPI)
library(tidyverse)
library(blsR)
library(jsonlite)
library(blsAPI) 
library(httr)
library(sf)
library(fastmap)
library(odbc)
library(DBI)
library(hms)
library(readxl)
library(stringr)
library(dplyr)
library(lubridate)
library(rmarkdown)
library(kableExtra)
library(Microsoft365R)
library(AzureGraph)
library(ggplot2)
library(here)


# Load ACS 5-Year Estimates for employment
# Variables:
# B23025_001 = Total population 16 years and over
# B23025_002 = In labor force

# Define available 5-year ACS years: 2009 to most recent available
years <- 2009:2024  # or update dynamically with `as.numeric(format(Sys.Date(), "%Y")) - 1`

# Function to get county-level labor data for Baltimore City
get_labor_data_year <- function(year) {
  message("Getting ACS data for ", year)
  
  df <- get_acs(
    geography = "county",
    variables = c(
      total_16plus = "B23025_001",
      in_labor_force = "B23025_002"
    ),
    state = "MD",
    county = "Baltimore City",
    year = year,
    survey = "acs5",
    output = "wide"
  ) %>%
    mutate(
      LFPR = round(100 * in_labor_forceE / total_16plusE, 1),
      Year = year
    ) %>%
    select(Year, GEOID, NAME, total_16plusE, in_labor_forceE, LFPR)
  
  return(df)
}

# Run for all years using purrr::map safely to avoid interruption
safe_get_labor_data_year <- safely(get_labor_data_year)

results <- map(years, safe_get_labor_data_year)

# Keep only successful results
labor_data_all_years <- results %>%
  keep(~ is.null(.x$error)) %>%
  map("result") %>%
  bind_rows()


## CHANGE THE YEAR AS NEEDED WHEN NEW DATA COMES OUT

# one year only 
labor_data <- get_acs(
  geography = "county",
  variables = c(
    total_16plus = "B23025_001",
    in_labor_force = "B23025_002"
  ),
  state = "MD",
  county = "Baltimore City",
  year = 2023,
  survey = "acs5",
  output = "wide"
)

# calculation
labor_data <- labor_data |> 
  mutate(
    LFPR = round(100 * in_labor_forceE / total_16plusE, 1),
    Year = 2024
  ) |> 
  select(Year, GEOID, NAME, total_16plusE, in_labor_forceE, LFPR)


# write the dataset out
# make sure to change your path    

write.csv(labor_data_all_years, ("C:/Users/selenea.gibson/OneDrive - City Of Baltimore/Projects/Downtown Rise/results/baltimore_labor_force.csv"), row.names = F)
write.csv(labor_data, ("C:/Users/selenea.gibson/OneDrive - City Of Baltimore/Projects/Downtown Rise/results/balt_labor_force_1year.csv"), row.names = F)













































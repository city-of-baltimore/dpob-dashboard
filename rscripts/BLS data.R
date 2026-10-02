

# Gathering data from the Bureau of Labor Statistics' (BLS) site. 
# You will need your own API key which can be found here (BLS)[https://www.bls.gov/developers/home.htm].
# The blsAPI package can be installed from Github (link)[https://github.com/mikeasilva/blsAPI] or library(devtools), install_github('mikeasilva/blsAPI')

## API KEY JUST IN CASE> e7a00f69248d41e9b919cafdeca12a0f


# Libraries
library(r4OPI)
library(tidyverse)
library(blsR)
library(jsonlite)
library(blsAPI) 
library(dplyr)
library(httr)
library(here)

####
### Setting up for the Employment data

# Example series ID: Quarterly employment for all employees, total nonfarm, seasonally adjusted
# Series IDs for BLS vary by sector/area. Here's an example: CES0000000001 (Total Nonfarm)
series_id <- "LNS12300000"

# read the url
url <- "https://api.bls.gov/publicAPI/v2/timeseries/data/"

# Get current year from system date
current_year <- format(Sys.Date(), "%Y")

# Create the request body (no API key needed for light use)
body <- list(
  seriesid = list(series_id),
  startyear = "2020",
  endyear = current_year
)

# make the post request to the BLS API
response <- POST(url, body = body, encode = "json")
json_text <- content(response, as = "text")
parsed <- fromJSON(json_text)

# Extract the data directly into a data frame
employment_data <- as.data.frame(parsed$Results$series$data)

####
### Filter for the monthly data 

# filtering for monthly data and setting the criteria for it
monthly_data <- employment_data %>%
  mutate(
    value = as.numeric(value),
    month = as.numeric(sub("M", "", period)),
    date = as.Date(paste(year, month, "01", sep = "-"))
  ) %>%
  arrange(date)

# remove unwanted columns
monthly_data <- monthly_data |> 
  select(-c(footnotes, latest))

# write out the data to a xlsx file
writexl::write_xlsx(monthly_data, here("results", "monthly_data.xlsx"))

#####
### Unemployment rate by month

# BLS series ID for Unemployment Rate (seasonally adjusted)
un_series_id <- "LNS14000000"

# API endpoint
un_url <- "https://api.bls.gov/publicAPI/v2/timeseries/data/"

# Get current year dynamically
current_year <- format(Sys.Date(), "%Y")

# Create request body
un_body <- list(
  seriesid = list(un_series_id),
  startyear = "2020",
  endyear = current_year
)

# Make API request
un_response <- POST(url, body = un_body, encode = "json")
un_json_text <- content(un_response, as = "text")
un_parsed <- fromJSON(un_json_text)

# Extract and clean data
unemployment_data <- as.data.frame(un_parsed$Results$series$data)
monthly_unemployment <- unemployment_data |> 
  mutate(
    value = as.numeric(value),
    month = as.numeric(sub("M", "", period)),
    date = as.Date(paste(year, month, "01", sep = "-"))
  ) |> 
  arrange(date)

# write out the data to a xlsx file
writexl::write_xlsx(monthly_unemployment, here("results", "monthly_unemployment.xlsx"))


#####
### US Employment Rate

# BLS series ID for Employment-Population Ratio (seasonally adjusted)
em_series_id <- "LNS12300000"

# API endpoint
un_url <- "https://api.bls.gov/publicAPI/v2/timeseries/data/"

# Get current year dynamically
current_year <- format(Sys.Date(), "%Y")

# Create request body
un_body <- list(
  seriesid = list(em_series_id),
  startyear = "2020",
  endyear = current_year
)

# Make API request
un_response <- POST(un_url, body = un_body, encode = "json")
un_json_text <- content(un_response, as = "text")
un_parsed <- fromJSON(un_json_text)

# Extract and clean data
pop_employment_data <- as.data.frame(un_parsed$Results$series$data)

monthly_pop_employment <- pop_employment_data %>%
  mutate(
    value = as.numeric(value),
    month = as.numeric(sub("M", "", period)),
    date = as.Date(paste(year, month, "01", sep = "-"))
  ) %>%
  arrange(date)

# Grab the latest employment-population ratio
latest_ratio <- tail(monthly_pop_employment, 1)

print(latest_ratio)

# Write out the data to Excel
writexl::write_xlsx(monthly_pop_employment, here("results", "monthly_employment_ratio.xlsx"))
writexl::write_xlsx(latest_ratio, here("results", "latest_monthly_employment_ratio.xlsx"))
































































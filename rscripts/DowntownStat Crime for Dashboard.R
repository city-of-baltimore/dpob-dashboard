

# Load libraries
library(tidyverse)
library(sf)
library(fastmap)
library(tidycensus)
library(odbc)
library(DBI)
library(hms)
library(readxl)
library(stringr)
library(here)

# Read Downtown shapefile
dntw <- read_sf(here("Canvassing", "shapefiles","downtown_boundary.shp"))

# Connect to CitiStat SQL Server
balt_ctistat <- dbConnect(odbc(), 
                          Driver = "SQL Server", 
                          Server = "balt-sql-fc", 
                          Database = "CitiStat", 
                          trusted_connection = "Yes")

# Query crime data
crime_df <- dbGetQuery(balt_ctistat, 
                       "SELECT [Crime Date], [Crime Time], [Street Address], [Latitude], [Longitude],
                               [Neighborhood], [Reported Date], Description
                        FROM [CitiStat].[dbo].[GroupA_Crime]")

# Remove rows with any NAs
crime_df <- na.omit(crime_df)

# Convert to sf object
crime_sf <- st_as_sf(crime_df, coords = c("Longitude", "Latitude"), crs = 4326)

# Transform downtown boundary to same CRS
dntw <- st_transform(dntw, 4326)

# Spatial join: filter crimes within downtown boundary
dntw_crime <- st_intersection(crime_sf, dntw)

# Convert date/time columns - not needed 
#dntw_crime$`Crime Date` <- as.Date(dntw_crime$`Crime Date`)
#dntw_crime$`Crime Time` <- as_hms(dntw_crime$`Crime Time`)

# Filter for crimes between Jan 2024 - present
dntw_crime <- dntw_crime %>%
  filter(
    Crime.Date >= as.Date("2024-01-01") &
      Crime.Date <= Sys.Date()
  )

# Filter for specific crime types
dntw_crime <- dntw_crime %>%
  filter(Description %in% c(
    "HOMICIDE", "RAPE", "ROBBERY - CARJACKING", "ROBBERY - COMMERCIAL", "ROBBERY",
    "AGG. ASSAULT", "AUTO THEFT", "POCKET-PICKING", "PURSE-SNATCHING", "SHOPLIFTING",
    "THEFT FROM BUILDING", "THEFT FROM COIN-OPERATED MACHINE OR DEVICE", "THEFT FROM MOTOR VEHICLE",
    "THEFT OF MOTOR VEHICLE PARTS OR ACCESSORIES", "ALL OTHER LARCENY"
  ))

# Categorize crime descriptions into broader groups
dntw_crime <- dntw_crime %>%
  mutate(crime_groups = case_when(
    Description %in% c("POCKET-PICKING", "PURSE-SNATCHING", "SHOPLIFTING",
                       "THEFT FROM BUILDING", "THEFT FROM COIN-OPERATED MACHINE OR DEVICE",
                       "THEFT FROM MOTOR VEHICLE", "THEFT OF MOTOR VEHICLE PARTS OR ACCESSORIES") ~ "Theft Offenses",
    Description == "ALL OTHER LARCENY" ~ "Property Larceny",
    Description == "HOMICIDE" ~ "Homicide",
    Description == "RAPE" ~ "Rape",
    Description %in% c("ROBBERY - CARJACKING", "AUTO THEFT") ~ "Auto Theft",
    Description %in% c("ROBBERY - COMMERCIAL", "ROBBERY") ~ "Robbery",
    Description == "AGG. ASSAULT" ~ "Aggravated Assault"
  ))

# Create exportable dataframe with WKT and lat/lon
dntw_crime_wkt <- dntw_crime %>%
  mutate(wkt = st_as_text(geometry)) %>%
  st_drop_geometry() %>%
  mutate(
    geometry_clean = str_remove_all(wkt, "POINT \\(|\\)"),
    longitude = as.numeric(str_extract(geometry_clean, "^-?\\d+\\.\\d+")),
    latitude = as.numeric(str_extract(geometry_clean, "(?<= )-?\\d+\\.\\d+$"))
  )

# define the data as an sf
dntw_crime_wkt <- st_as_sf(dntw_crime_wkt, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)


# Write to CSV
st_write(dntw_crime_wkt, here("geojson", "crime_dma.geojson"), delete_dsn = TRUE)
write.csv(dntw_crime_wkt, here("results", "Downtown Crime.csv"), row.names = F)


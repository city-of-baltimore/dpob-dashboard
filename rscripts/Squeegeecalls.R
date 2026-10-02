#Load libraries
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

# Get today's date
today <- format(Sys.Date(), "%Y-%m-%d")

# Query squeegee data
# Build the query string correctly - we want this to be present day as well.
query <- paste0("
SELECT [Call Number], [Call Date], [Call Time], [Day of Week], [Week Number], [Priority],
       [Call Type], [Description], [Call Type Final], [Incident Street Address], [Latitude],
       [Longitude], [Neighborhood], [Police District], [Council District]
FROM [CitiStat].[dbo].[Police911CallsForService]
WHERE [Call Type] = '55Q'
  AND [Call Date] BETWEEN '2024-01-01' AND '", today, "'")

# Run the query
squeegee_crime_df <- dbGetQuery(balt_ctistat, query)
 
# Convert to sf object
squeegee_crime_sf <- st_as_sf(squeegee_crime_df, coords = c("Longitude", "Latitude"), crs = 4326)

# Transform downtown boundary to same CRS
dntw <- st_transform(dntw, 4326)

# Spatial join: filter crimes within downtown boundary
dntw_squeegee <- st_intersection(squeegee_crime_sf, dntw)

# remove unwanted columns
dntw_squeegee <- dntw_squeegee |> 
  select(-(13:31))


# Create exportable dataframe with WKT and lat/lon
dntw_squeegee_wkt <- dntw_squeegee |> 
  mutate(wkt = st_as_text(geometry)) |> 
  st_drop_geometry() |> 
  mutate(
    geometry_clean = str_remove_all(wkt, "POINT \\(|\\)"),
    longitude = as.numeric(str_extract(geometry_clean, "^-?\\d+\\.\\d+")),
    latitude = as.numeric(str_extract(geometry_clean, "(?<= )-?\\d+\\.\\d+$"))
  )

# rename the wkt column to be geomerty
dntw_squeegee_wkt <- dplyr::rename(dntw_squeegee_wkt, geometry = wkt)

# Write to CSV
write.csv(dntw_squeegee_wkt, here("results", "dntw_squeegee.csv"))

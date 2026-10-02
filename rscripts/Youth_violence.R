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
# 24 is the number that BPD uses
query <- paste0("SELECT [Call Number], [Week Number], [Day Of Week], [Crime Date], [Crime Time], [Weapon Used],
                [Victim Sex], [Victim Race], [Victim Age], [Premise], [Domestic Violence], [Commercial], 
                [Hate Crime], [Street Address],[Shooting], [Latitude], [Longitude],[Neighborhood], Description
                        FROM [CitiStat].[dbo].[GroupA_Crime]
                        WHERE [Victim Age] <= '24'
                        AND [Crime Date] BETWEEN '2024-01-01' AND '", today, "'")

# Run the query
# Query crime data
youth_crime_df <- dbGetQuery(balt_ctistat, query)

# remove any coords that are invalid, I cannot properly join the data with invalid coords
youth_crime_df <- youth_crime_df |> 
  drop_na(Latitude, Longitude)

# Convert to sf object
youth_crime_sf <- st_as_sf(youth_crime_df, coords = c("Longitude", "Latitude"), crs = 4326)

# Transform downtown boundary to same CRS
dntw <- st_transform(dntw, 4326)

# Spatial join: filter crimes within downtown boundary
dntw_youth <- st_intersection(youth_crime_sf, dntw)

# remove unwanted columns
dntw_youth <- dntw_youth |> 
  select(-(18:39))

# Categorize crime descriptions into broader groups
# All of the cases are listed below
# "AGG. ASSAULT", "AUTO THEFT", "BURGLARY","COMMON ASSAULT", "EXTORTION","FRAUD",
#"HOMICIDE", "HUMAN TRAFFICKING", "INTIMIDATION",
#"KIDNAPPING", "LARCENY", "LARCENY FROM AUTO", "LARCENY OF MOTOR VEHICLE PARTS OR ACCESSORIES",
#"RAPE", "ROBBERY", "ROBBERY - CARJACKING", "SEX OFFENSES", "STOLEN PROPERTY", "VANDALISM"
dntw_youth <- dntw_youth |> 
  mutate("Crime Groups" = case_when(
    Description %in% c("FRAUD", "STOLEN PROPERTY", "VANDALISM", "BURGLARY") ~ "Theft/Destruction of Property Offenses",
    Description == "LARCENY" ~ "Larceny",
    Description == "HOMICIDE" ~ "Homicide",
    Description == "RAPE" ~ "Rape",
    Description %in% c("ROBBERY - CARJACKING", "AUTO THEFT", "LARCENY FROM AUTO", "LARCENY OF MOTOR VEHICLE PARTS OR ACCESSORIES") ~ "Auto Theft",
    Description %in% c("ROBBERY - COMMERCIAL", "ROBBERY") ~ "Robbery",
    Description %in% c("AGG. ASSAULT", "COMMON ASSAULT", "INTIMIDATION") ~ "Assault Offenses",
    Description == "SEX OFFENSES" ~ "Sex Offenses",
    Description %in% c("KIDNAPPING", "HUMAN TRAFFICKING", "EXTORTION") ~ "All Other Offenses"
  ))

# Create exportable dataframe with WKT and lat/lon
dntw_youth_wkt <- dntw_youth |> 
  mutate(wkt = st_as_text(geometry)) |> 
  st_drop_geometry() |> 
  mutate(
    geometry_clean = str_remove_all(wkt, "POINT \\(|\\)"),
    longitude = as.numeric(str_extract(geometry_clean, "^-?\\d+\\.\\d+")),
    latitude = as.numeric(str_extract(geometry_clean, "(?<= )-?\\d+\\.\\d+$"))
  )

# rename the wkt column to be geomerty
dntw_youth_wkt <- dplyr::rename(dntw_youth_wkt, geometry = wkt)

# Write to CSV
write.csv(dntw_youth_wkt, here("results", "dntw_youth.csv"))

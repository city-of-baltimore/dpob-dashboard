## Project Overview
#This project looks at the block lots that are within the downtown area. Using a shapefile of the downtown area, I will use st_intersect to intersect the blocks within the downtown area.

## Libraries
#Loading the libraries that are needed.

library(tidyverse)
library(r4OPI)
library(sf)
library(here)
library(fastmap)
library(tidycensus)
library(lubridate)
library(Microsoft365R)
library(AzureGraph)
library(DBI)
library(tibble)
library(janitor)
library(odbc)
library(stringr)

## Reading in the datasets
#Reading in the shapefiles that are needed to complete the analysis.

# datasets
dntw <- st_read(here("shapefiles", "downtown.shp"))
trees <- st_read(here("shapefiles", "DowntownRISE_TreeInventory.shp"))

# tracts <- st_transform(tracts, 2248)
# dntw <- st_transform(dntw, 2248)
trees <- st_transform(trees, 4326)

# Extract coordinates (assuming POINT geometries)
coords <- st_coordinates(trees)
trees$Longitude <- coords[, "X"]
trees$Latitude <- coords[, "Y"]

# Drop geometry and convert to a plain dataframe
trees_wkt <- st_drop_geometry(trees)

## Write out the file
st_write(trees, here("geojson", "trees_dma.geojson"), delete_dsn = TRUE)
writexl::write_xlsx(trees_wkt, here("bin", "trees.xlsx")) # data will need to be cleaned up



































































































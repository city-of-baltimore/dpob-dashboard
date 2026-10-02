# Load the packages
library(lubridate)
library(dplyr)
library(tidyverse)
library(lubridate)
library(rmarkdown)
library(DBI)
library(kableExtra)
library(Microsoft365R)
library(AzureGraph)
library(sf)
library(jsonlite)
library(ggplot2)
library(here)

#connect to the sql database, make sure you are connected to the VPN for
#this to work
sql_conn <- dbConnect(
  odbc::odbc(),
  Driver = "SQL Server",
  Server = "BALT-SQL-FC",
  Database = "CitiStat",  
  Port = 1433
)

#SQL query
data <- dbGetQuery(sql_conn, "SELECT 

[SR Type], 
[Service Request Number],
[SR Status],
[Created Date],
[Due Date],
[Close Date],
[Outcome],
[Agency],
[Contact Name],
[Contact Email],
[Neighborhood],
[Street Address],
[geo_census_tract],
[Block_Number_c],
[Zip Code],
[Latitude],
[Longitude],
[geo_street_light_service_area],
[case_details]

FROM [CitiStat].[dbo].[CSR]

WHERE
[SR Status] NOT LIKE '%DUP%' 
AND [SR Status] NOT LIKE '%TRANS%'
 AND [LONGITUDE] IS NOT NULL
  AND [Created Date] >= '2024-01-01 00:00:00.000'
  AND [SR Type] in ('TEC-Footways Complaint', 
'TEC-Footways Contract/Reconstruction', 
'TRM-Potholes', 
'TR-Street Cut Issues', 
'TRM-Street Repairs', 
'TRM-Footways Repair', 
'TRM-Street and Crosswalk Markings', 
'TRM-Street Cut Notification', 
'TRM-(ADA) Sidewalk Ramp Concern (Repair)', 
'TRM-Snow/Icy Conditions', 
'TEC-Alley Reconstruction Complaint', 
'TRM-Slow Street', 
'TRM-WO Street and Crosswalk Markings', 
'TRT-Crosswalks', 
'TEC-Street Repair (Misc)', 
'TRM-Alleys', 
'TRT-Street and Crosswalk Markings', 
'WW-Storm Damaged Inlet', 
'TEC-Alley Contract/Reconstruction', 
'TEC-WO Street Markings', 
'TRM-Curb Repair', 
'TRM-Pickup Pothole', 
'TRM-Street Cut Issues', 
'TR-Sign Issue', 
'TRM-StLight Pole Missing', 
'PABC-ADA Signage Request on PABC Lot', 
'TRM-Sign Damaged', 
'TRT-New Stop Sign', 
'BGE-StLight(s) Out', 
'TRM-StLight Pole Access Cover/Plate Missing', 
'TRM-StLighting Inadequate/Too Bright', 
'TRT-New Traffic Sign', 
'TRM-Illegal Sign Removal', 
'TRM-StLight Pole Pickup', 
'TRT-Sign New', 
'ECC-ARTEST', 
'TRM-StLight Damaged/Knocked Down/Rusted', 
'TRM-Street Light Out', 
'TRM-WO Sign Removal', 
'TRT-Signal Timing', 
'TRT-Traffic Sign Request', 
'TRT-Traffic Signal Repairs', 
'HCD-Illegal Campaign Signs on Private Property', 
'TRM-Sign Damaged/Sign Structure', 
'TRT-Traffic Calming', 
'RP-Street Lighting Repairs', 
'TRT-Sign Damaged/Sign Structure', 
'TRM-WO Sign Installation', 
'TRT-New Traffic Signal', 
'FOR-Broken Branch in Tree', 
'FOR-Down Tree', 
'SW-Leaf Collection Scheduling', 
'TRM-Grass Mowing', 
'FOR-Stump Removal', 
'HCD-Trees and Shrubs', 
'HCD-Weatherization', 
'SW-Leaf Removal', 
'FOR-Tree Inspection', 
'FOR-Fallen Limb', 
'RP-Grass Cutting', 
'ECC-Grass Mowing', 
'SW-City Trash Can or Recycling Cart Concern', 
'SW-Municipal Trash Can Concern', 
'SW-Residential Recycling Carts', 
'HCD-Illegal Dumping', 
'SW-Inappropriate use of Recycling Bins', 
'SW-Mixed Refuse', 
'SW-Bulk Special', 
'SW-City Trash Can or Recycling Cart Lost or Stolen', 
'SW-Dumpster Collection', 
'SW-Municipal Trash Can Stolen/Lost', 
'SW-Trash Can/Recycling Container Complaint', 
'TRM-Debris Hanging From Wires or Poles', 
'SW-Public (Corner) Trash Can Issue', 
'SW-Recycling', 
'SW-School Recycling', 
'SW-City Trash Can or Recycling Cart Concern', 
'SW-Park Cans', 
'SW-Graffiti Removal-Rec and Parks', 
'SW-Graffiti Removal Proactive', 
'TRM-Graffiti Referral', 
'HCD-Graffiti', 
'SW-Graffiti Removal', 
'SW-Graffiti Removal - Rec and Parks', 
'SW-Fire Debris Removal', 
'SW-Rat Rubout Alley Concern', 
'HCD-Rodents', 
'HCD-Sanitation Property', 
'SW-Mechanical Alley Sweeping', 
'SW-Rat Rubout Proactive', 
'SW-Dirty Street', 
'WW-Sediment or Erosion Problem', 
'HCD-Snow and Ice on Sidewalks', 
'SW-Dirty Alley Proactive', 
'SW-Dirty Street Proactive', 
'SW-Mechanical Street Sweeping', 
'SW-Clean Up', 
'SW-SIU Clean Up', 
'SW-Cleaning', 
'SW-Dirty Alley', 
'HCD-Emergency Sewer Investigation', 
'WW-Water Low Pressure', 
'WW-Storm Misc Investigation', 
'WW-Storm Water In Basement', 
'WW-Water Meter Cover Missing or Damaged', 
'WW-Sewer Misc Investigation', 
'WW-Water Leak (Exterior)', 
'WW-Water Meter Leak', 
'WW-Water No Water', 
'WW-HCD Acquisition/Remove Meter', 
'WW-Storm Flooded Street', 
'WW-Water Noise In Pipe', 
'WW-Hydrant Damaged', 
'WW-Hydrant Open', 
'WW-Water Odor/Bad Taste', 
'WW-Water Water In Basement', 
'FCCS-Metered Water', 
'WW-Hydrant Leaking', 
'WW-Sewer Water In Basement', 
'WW-Waterway Pollution Investigation', 
'SW-Water Way Cleaning', 
'WW-Sewer Overflow', 
'WW-Water Discolored'
)

ORDER BY [Created Date] DESC;
                ")

#parsing the data by the DMA shapefile so it only shows SRs in the DMA
data_sf <- 
  st_as_sf( data,
            coords = c("Longitude", "Latitude"), 
            crs = 4326,
            remove = T) 

rise_sf <- read_sf(here("Canvassing", "shapefiles", "downtown_boundary.shp"))
rise_sf <- st_transform(rise_sf, crs = 4326) 
#rise_sf <- st_cast(rise_sf, "MULTIPOLYGON")
df1 <- st_join(data_sf, rise_sf)
df1 <- df1 %>%
  filter(!is.na(AREA_NAME))%>%
  distinct(`Service Request Number`, .keep_all = TRUE)%>%
  mutate(longitude = st_coordinates(geometry)[,1],
         latitude = st_coordinates(geometry)[,2])

df1$geometry <- NULL

#make sure to change this to your own computer path
df2 <- read_csv (here("Canvassing", "data", "SLA for downtown.csv"))

#make the values the same
df1$`SR Type`<- trimws(tolower(as.character(df1$`SR Type`)))
df2$`SR Type` <- trimws(tolower(as.character(df2$`SR Type`)))

#colnames(df1)[colnames(df1) == "SR Type"] <- "SR.Type"

#merge the two dataframes
dfmerged <- merge(df1, df2[, c("SR Type", "SLA")], by = "SR Type", all.x = TRUE)

# Use lubridate to parse the dates, which is more flexible
dfmerged$`Created Date` <- ymd_hms(dfmerged$`Created Date`)  # Month-Day-Year Hour:Minute
dfmerged$`Close Date` <- ymd_hms(dfmerged$`Close Date`)
dfmerged$`Due Date` <- ymd_hms(dfmerged$`Due Date`)

# Calculate the difference in days
dfmerged$Days_Difference <- as.numeric(difftime(dfmerged$`Close Date`, dfmerged$`Created Date`, units = "days"))

current_date <- Sys.Date()

#were they closed on time or late?
dfmerged$ontime <- ifelse(dfmerged$Days_Difference <= dfmerged$SLA, "on time", "late")
dfmerged$ontime[is.na(dfmerged$ontime) & dfmerged$`Due Date` < current_date] <- "overdue"

#ADD SR GROUPS
dfmerged_groups <- dfmerged %>%
  mutate(SR_groups = case_when(
    `SR Type` %in% c('tec-footways complaint', 
                   'tec-footways contract/reconstruction', 
                   'trm-potholes', 
                   'tr-street cut issues', 
                   'trm-street repairs', 
                   'trm-footways repair', 
                 
                  
                   'trm-(ada) sidewalk ramp concern (repair)', 
                   'trm-snow/icy conditions', 
                   'tec-alley reconstruction complaint', 
                  
                
                   'trt-crosswalks', 
                   'tec-street repair (misc)', 
                   'trm-alleys', 
                   'trt-street and crosswalk markings', 
                   'ww-storm damaged inlet', 
                   'tec-alley contract/reconstruction', 
                   'tec-wo street markings', 
                   'trm-curb repair', 
                   'trm-pickup pothole', 
                   'trm-street cut issues'
    ) ~ 'Street & Curb Repairs',
    `SR Type` %in% c( 
                   'trm-stlight pole missing', 
                   'pabc-ada signage request on pabc lot', 
                   'trm-sign damaged', 
                   'trt-new stop sign', 
                   'bge-stlight(s) out', 
                   'trm-stlight pole access cover/plate missing', 
                   'trm-stlighting inadequate/too bright', 
                   'trt-new traffic sign', 
                   'trm-illegal sign removal', 
                   'trm-stlight pole pickup', 
                    'trt-sign damaged/sign structure',
                   'ecc-artest', 
                   'trm-stlight damaged/knocked down/rusted', 
                   'trm-street light out', 
                   'trm-wo sign removal', 
                   'trt-signal timing', 
                   'trt-traffic sign request', 
                   'trt-traffic signal repairs',
                 'trt-sign damaged/sign structure',
                   'trt-traffic calming', 
                   'rp-street lighting repairs', 
                
                   'trm-wo sign installation', 
                   'trt-new traffic signal'
    ) ~ 'Traffic Signals, Lights, Signs',
    `SR Type` %in% c('for-broken branch in tree', 
                   'for-down tree', 
                   'sw-leaf collection scheduling', 
                   'trm-grass mowing', 
                   'for-stump removal', 
                   'hcd-trees and shrubs', 
                   'hcd-weatherization', 
                   'sw-leaf removal', 
                   'for-tree inspection', 
                   'for-fallen limb', 
                   'rp-grass cutting', 
                   'ecc-grass mowing'
    ) ~ 'Trees & Grass',
    `SR Type` %in% c('sw-city trash can or recycling cart concern', 
                   'sw-municipal trash can concern', 
                   'sw-residential recycling carts', 
                   'hcd-illegal dumping', 
                   'sw-inappropriate use of recycling bins', 
                   'sw-mixed refuse', 
                   'sw-bulk special', 
                   'sw-city trash can or recycling cart lost or stolen', 
                   'sw-dumpster collection', 
                   'sw-municipal trash can stolen/lost', 
                   'sw-trash can/recycling container complaint', 
                   'trm-debris hanging from wires or poles', 
                   'sw-public (corner) trash can issue', 
                   'sw-recycling', 
                   'sw-school recycling', 
                   'sw- city trash can or recycling cart concern', 
                   'sw-park cans'
    ) ~ 'Trash & Recycling',
    `SR Type` %in% c('sw-graffiti removal-rec and parks', 
                   'sw-graffiti removal proactive', 
                   'trm-graffiti referral', 
                   'hcd-graffiti',
                   'hcd-illegal campaign signs on private property', 
                   'sw-graffiti removal', 
                   'sw-graffiti removal - rec and parks', 
                   'sw-graffiti removal-owner\'s request'
    ) ~ 'Graffiti',
    `SR Type` %in% c('sw-fire debris removal', 
                   'sw-rat rubout alley concern', 
                   'hcd-rodents', 
                   'hcd-sanitation property', 
                   'sw-mechanical alley sweeping', 
                   'sw-rat rubout proactive', 
                   'sw-dirty street', 
                   'ww-sediment or erosion problem', 
                   'hcd-snow and ice on sidewalks', 
                   'sw-dirty alley proactive', 
                   'sw-dirty street proactive', 
                   'sw-mechanical street sweeping', 
                   'sw-clean up', 
                   'sw-siu clean up', 
                   'sw-cleaning', 
                   'sw-dirty alley'
    ) ~ 'Dirty Streets',
    `SR Type` %in% c('hcd-emergency sewer investigation', 
                   'ww-water low pressure', 
                   'ww-storm misc investigation', 
                   'ww-storm water in basement', 
                   'ww-water meter cover missing or damaged', 
                   'ww-sewer misc investigation', 
                   'ww-water leak (exterior)', 
                   'ww-water meter leak', 
                   'ww-water no water', 
                   'ww-hcd acquisition/ remove meter', 
                   'ww-storm flooded street', 
                   'ww-water noise in pipe', 
                   'ww-hydrant damaged', 
                   'ww-hydrant open', 
                   'ww-water odor/bad taste', 
                   'ww-water water in basement', 
                   'fccs-metered water', 
                   'ww-hydrant leaking', 
                   'ww-sewer water in basement', 
                   'ww-waterway pollution investigation', 
                   'sw-water way cleaning', 
                   'ww-sewer overflow', 
                   'ww-water discolored'
    ) ~ 'Water',
    TRUE ~ 'Other'  # Default case for any other categories
  ))

#add a column for if an SR is internal or external
dfmerged_groups2 <- dfmerged_groups %>%
  mutate(internal = case_when(
    'SR Type' %in% c('tec-footways contract/reconstruction',
                   'tr-street cut issues',
                   'trm-footways repair',
                   'trm-wo street and crosswalk markings',
                   'tec-street repair (misc)',
                   'tec-alley contract/reconstruction',
                   'tec-wo st fccs-metered waterreet markings',
                   'trm-pickup pothole',
                   'trm-street cut issues',
                   'trm-stlight pole pickup',
                   'ecc-artest',
                   'trm-wo sign removal',
                   'trm-wo sign installation',
                   'sw-leaf collection scheduling',
                   'for-stump removal',
                   'sw-residential recycling carts',
                   'sw-municipal trash can stolen/lost',
                   'sw- city trash can or recycling cart concern',
                   'sw-graffiti removal-rec and parks',
                   'sw-graffiti removal proactive',
                   'sw-graffiti removal - rec and parks',
                   'sw-fire debris removal',
                   'sw-rat rubout alley concern',
                   'sw-mechanical alley sweeping',
                   'sw-rat rubout proactive',
                   'sw-dirty alley proactive',
                   'sw-dirty street proactive',
                   'sw-clean up',
                   'sw-siu clean up',
                   'sw-cleaning',
                   'ww-hcd acquisition/ remove meter',
                   'fccs-metered water') ~ 'Internal'
    ,TRUE ~ 'Non-Internal'  # Default case for any other categories
  ))
    
dfmerged_groups2 <- st_as_sf(dfmerged_groups2, coords = c("longitude", "latitude"), crs = 4326, remove = FALSE)

#export the csv file with data, make sure to change your path  
st_write(dfmerged_groups2, here("geojson", "sr_dma.geojson"), delete_dsn = TRUE)
writexl::write_xlsx(dfmerged_groups2, here("data" , "downtownstatdata.xlsx"))

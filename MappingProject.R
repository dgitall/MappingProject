library(rgdal)
library(leaflet)
library(RColorBrewer)

# From https://opendata.minneapolismn.gov/. Search for 'Communities' and
# 'stormwater catch basins' to find the files. Download them and unzip into the
# local directories. NOTE: You have to unzip all of the files into the directory
# because the *.shp file has dependencies on all of the other files. If you don't,
# the call to readOGR() will fail. 
communities <- readOGR("./Communities-shp/Minneapolis_Communities.shp",
                       layer="Minneapolis_Communities", GDAL1_integer64_policy = TRUE)
stormbasins <- readOGR("./Stormwater_Catch_Basins-shp/Stormwater_Catch_Basins.shp",
                       layer="Stormwater_Catch_Basins", GDAL1_integer64_policy = TRUE)
# Make sure the projections match
communities <- spTransform(communities, CRS("+proj=longlat +ellps=GRS80"))
stormbasins <- spTransform(stormbasins, CRS("+proj=longlat +ellps=GRS80"))

# Create a palette to show different colors for the stormwater feature types
stormbasins$FEATURE_TY <- as.factor(stormbasins$FEATURE_TY)
palFeatureType <- colorFactor(
    palette = "Paired",
    domain = stormbasins$FEATURE_TY
)

## Create a map showing the Minneapolis community boundaries on top of 
# the base leaflet tile
my_map <- leaflet(communities) %>% 
    addTiles() %>% 
    # Set the view to center on downtown with an initial zoom
    setView(lng = -93.270013, lat=44.965964, zoom = 11) %>%
    # Add the polygons for the communities
    addPolygons(color = "#666666", weight = 1, smoothFactor = 0.5,
                opacity = 1.0, fillOpacity = 0.5,
                fillColor = "LightBlue"
                ) %>%  
    # Add circle markers at the stormbasin locations. There are a lot so do
    # clustering. Disable clustering at tighter zooms so we can see the individual
    # locations. The fill color is based on the feature type. Create a popup
    # with the feature type
    addCircleMarkers(stormbasins$coords.x1, 
                     stormbasins$coords.x2, 
                     weight=2, 
                     radius=5,
                     color="#222222",
                     fillColor = ~palFeatureType(stormbasins$FEATURE_TY),
                     fillOpacity = 0.6,
                     clusterOptions = 
                         markerClusterOptions(showCoverageOnHover = FALSE,
                                                           disableClusteringAtZoom = 16),
                     popup = paste("Feature Type",'<br>',stormbasins$FEATURE_TY)
                     ) %>%
    # Add a legend of the colors matched to the feature types 
    addLegend("bottomright", pal = palFeatureType, values = ~stormbasins$FEATURE_TY,
              title = "Stormwater Catchment Facilities",
              opacity = 1
    )


print(my_map)
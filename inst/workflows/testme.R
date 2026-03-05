# testme.R

library(devtools)
library(dplyr)
library(sf)
setwd("C:/Users/tmf77/scorecard/socialinfrascorer")
devtools::load_all()

devtools::document()

readRenviron("../secret/.env")
# Search OSM for Ithaca, NY at admin level 6 (neighborhood)
shapes = socialinfrascorer::get_bounds_osm(place = "Ithaca, NY", iso_id = "USA", admin_level = "4")
shapes

socialinfrascorer::si_get_polygon_by_osm_id()

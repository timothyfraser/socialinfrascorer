# DEPRECATED -------------------
# STILL IN DEVELOPMENT ---------


#' Get administrative OSM polygons from a place bounding box
#'
#' Queries OpenStreetMap via Overpass using the place bounding box from
#' [osmdata::getbb()], then returns administrative multipolygons for the
#' requested `admin_level`.
#'
#' @param place Place search term used by [osmdata::getbb()].
#' @param iso_id ISO country identifier to append in the output.
#' @param admin_level Administrative level as text (e.g. `"5"` or `"6"`).
#' @param timeout Overpass timeout in seconds.
#' @param memsize Overpass memory size in bytes.
#'
#' @return An `sf` object of multipolygons, or `NULL` when no polygons are found.
#' @export
get_bounds_osm = function(place = "London UK",
                          iso_id = "GBR",
                          admin_level = "5",
                          timeout = 15,
                          memsize = 536870912) {
  # Testing IDs
  # place = "Ithaca, NY"; iso_id = "USA"; admin_level = "4"; timeout = 5
  
  if (!is.character(place) || length(place) != 1 || nchar(trimws(place)) == 0) {
    stop("`place` must be a non-empty string.")
  }
  if (!is.character(iso_id) || length(iso_id) != 1 || nchar(trimws(iso_id)) == 0) {
    stop("`iso_id` must be a non-empty string.")
  }
  if (!is.character(admin_level) || length(admin_level) != 1 || nchar(trimws(admin_level)) == 0) {
    stop("`admin_level` must be a non-empty string.")
  }

library(osmextract)
library(sf)
library(dplyr)
# oe_providers(quiet = TRUE) %>%
# as_tibble()
# class(geofabrik_zones)
# class(bbbike_zones)

# oe_match("us/new-york")

# oe_match("Ithaca", provider = "geofabrik", level = 6, max_string_dist = 2)

# oe_match_pattern("US", match_by = "iso3166_2")
# x = oe_get("us/new-york", layer = "polygons", quiet = FALSE)


place = "Ithaca, NY"
bb = osmdata::getbb(place) 
bbox = st_bbox(c(xmin = bb[1,1], xmax = bb[1,2], ymin = bb[2,1], ymax = bb[2,2]), crs = 4326)

# https://docs.ropensci.org/osmextract/reference/oe_get.html
x = oe_get(
  place = bbox,
  quiet = FALSE,
  provider = "geofabrik",
  layer = "multipolygons",
  query = "SELECT * FROM 'multipolygons' WHERE 'admin_level' IN (4,5,6) AND 'boundary' = 'administrative'",
  force_download = TRUE
)
x %>% nrow()
x %>% glimpse()

x %>% glimpse()

  query = osmdata::getbb(place) |>
    osmdata::opq(
      osm_types = "relation"
      #timeout = as.integer(timeout)
    ) |>
    osmdata::add_osm_feature(key = "boundary", value = "administrative") |>
    osmdata::add_osm_feature(key = "admin_level", value = trimws(admin_level))

  shapes = osmdata::osmdata_sf(query)
  shapes
  multipolygons = shapes$osm_multipolygons

  if (is.null(multipolygons) || nrow(multipolygons) == 0) {
    return(NULL)
  }

  if (!("name:en" %in% names(multipolygons))) {
    multipolygons[["name:en"]] = NA_character_
  }

  result = multipolygons |>
    dplyr::mutate(iso_id = trimws(iso_id)) |>
    dplyr::select(dplyr::any_of(c("osm_id", "name", "name:en", "iso_id", "admin_level", "geometry"))) |>
    sf::st_as_sf() |>
    sf::st_make_valid()

  result
}

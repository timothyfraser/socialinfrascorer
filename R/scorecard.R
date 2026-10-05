#' Get scorecard results for a location or OSM area
#'
#' @param client A client from `client()` authenticated with `sign_in()`.
#' @param osm_id Optional OSM ID used to resolve one bounds area.
#' @param location_id Optional location_id used for direct scorecard lookup.
#' @param limit Maximum rows to return (hard capped to 100).
#' @param offset Pagination offset.
#'
#' @return A tibble of scorecard_result rows.
#' @keywords internal
#' @noRd
si_get_scorecard_results = function(client,
                                    osm_id = NULL,
                                    location_id = NULL,
                                    limit = 100L,
                                    offset = 0L) {
  si_require_auth(client)

  limit = si_clamp_limit(limit, max_limit = 100L)
  offset = as.integer(offset)
  if (is.na(offset) || offset < 0L) {
    stop("`offset` must be a non-negative integer.")
  }

  has_osm = !is.null(osm_id)
  has_location = !is.null(location_id)
  if ((has_osm && has_location) || (!has_osm && !has_location)) {
    stop("Provide exactly one of `osm_id` or `location_id`.")
  }

  if (has_location) {
    data = si_perform(
      client,
      "/rest/v1/rpc/fn_scorecard_result_by_location_id",
      body = list(
        p_location_id = as.character(location_id),
        p_limit = limit,
        p_offset = offset
      ),
      auth = TRUE
    )
    return(si_as_tibble(data))
  }

  bounds_row = si_get_polygon_by_osm_id(client, osm_id)
  if (nrow(bounds_row) == 0) {
    return(dplyr::tibble())
  }

  bounds_id = as.character(bounds_row$id[[1]])
  data = si_perform(
    client,
    "/rest/v1/scorecard_result",
    method = "GET",
    query = list(
      area_type = "eq.bounds",
      area_id = paste0("eq.", bounds_id),
      order = "computed_at.desc,id.desc",
      limit = limit,
      offset = offset
    ),
    auth = TRUE
  )
  si_as_tibble(data)
}

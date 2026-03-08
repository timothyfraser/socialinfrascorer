#' Get one bounds polygon by OSM ID
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param osm_id Numeric OSM identifier in `public.bounds.osm_id`.
#'
#' @return A tibble with up to one row.
#' @keywords internal
#' @noRd
si_get_polygon_by_osm_id = function(client, osm_id) {
  si_require_auth(client)

  osm_id_num = suppressWarnings(as.numeric(osm_id))
  if (is.na(osm_id_num)) {
    stop("`osm_id` must be numeric.")
  }

  req = httr2::request(paste0(client$supabase_url, "/rest/v1/bounds")) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_url_query(
      select = "id,name,display_name,osm_id,geometry",
      osm_id = paste0("eq.", format(osm_id_num, scientific = FALSE, trim = TRUE)),
      limit = 1
    )

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Get one bounds polygon by location ID (via secure RPC)
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param location_id Text location identifier from `public.location.location_id`.
#'
#' @return A tibble with up to one row.
#' @keywords internal
#' @noRd
si_get_polygon_by_location_id = function(client, location_id) {
  si_require_auth(client)

  if (!is.character(location_id) || length(location_id) != 1 || nchar(trimws(location_id)) == 0) {
    stop("`location_id` must be a non-empty string.")
  }

  req = httr2::request(paste0(client$supabase_url, "/rest/v1/rpc/fn_bounds_by_location_id")) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(list(p_location_id = trimws(location_id)))

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Get one bounds polygon by area ID (via secure RPC)
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param area_id UUID area identifier from `public.location.area_id`.
#'
#' @return A tibble with up to one row.
#' @keywords internal
#' @noRd
si_get_polygon_by_area_id = function(client, area_id) {
  si_require_auth(client)

  area_id = trimws(as.character(area_id))
  if (length(area_id) != 1 || nchar(area_id) == 0) {
    stop("`area_id` must be a non-empty UUID string.")
  }

  uuid_pattern = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$"
  if (!grepl(uuid_pattern, area_id)) {
    stop("`area_id` must be a valid UUID string.")
  }

  req = httr2::request(paste0(client$supabase_url, "/rest/v1/rpc/fn_bounds_by_area_id")) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(list(p_area_id = area_id))

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Lookup location rows by place name (via secure RPC)
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param place_name Required place text to search in `public.location.place_name`.
#' @param country Optional country filter.
#' @param state Optional state/province filter.
#' @param limit Maximum rows to return. Hard capped at 5.
#'
#' @return A tibble of up to 5 matching location rows.
#' @keywords internal
#' @noRd
si_get_polygon_lookup_by_place_name = function(client,
                                               place_name,
                                               country = NULL,
                                               state = NULL,
                                               limit = 5L) {
  si_require_auth(client)

  place_name = trimws(as.character(place_name))
  if (length(place_name) != 1 || nchar(place_name) == 0) {
    stop("`place_name` must be a non-empty string.")
  }

  normalize_opt_text = function(x) {
    if (is.null(x)) {
      return(NULL)
    }
    x = trimws(as.character(x))
    if (length(x) != 1 || nchar(x) == 0) {
      return(NULL)
    }
    x
  }

  country = normalize_opt_text(country)
  state = normalize_opt_text(state)
  limit = si_clamp_limit(limit, max_limit = 5L)

  req = httr2::request(paste0(client$supabase_url, "/rest/v1/rpc/fn_location_lookup_by_place_name")) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(
      list(
        p_place_name = place_name,
        p_country = country,
        p_state = state,
        p_limit = limit
      )
    )

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Get one bounds polygon by place name (via secure RPC)
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param place_name Required place text to search in `public.location.place_name`.
#' @param country Optional country filter.
#' @param state Optional state/province filter.
#'
#' @return A tibble with up to one row.
#' @keywords internal
#' @noRd
si_get_polygon_by_place_name = function(client,
                                        place_name,
                                        country = NULL,
                                        state = NULL) {
  si_require_auth(client)

  place_name = trimws(as.character(place_name))
  if (length(place_name) != 1 || nchar(place_name) == 0) {
    stop("`place_name` must be a non-empty string.")
  }

  normalize_opt_text = function(x) {
    if (is.null(x)) {
      return(NULL)
    }
    x = trimws(as.character(x))
    if (length(x) != 1 || nchar(x) == 0) {
      return(NULL)
    }
    x
  }

  country = normalize_opt_text(country)
  state = normalize_opt_text(state)

  req = httr2::request(paste0(client$supabase_url, "/rest/v1/rpc/fn_bounds_by_place_name")) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(
      list(
        p_place_name = place_name,
        p_country = country,
        p_state = state
      )
    )

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

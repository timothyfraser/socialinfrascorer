#' Submit a new polygon request via Supabase RPC
#'
#' Validates geometry, checks quota, inserts bounds + location + request row,
#' and triggers asynchronous processing -- all server-side via
#' \code{fn_submit_request} in PostgreSQL.
#'
#' @param client A client from \code{si_client()} authenticated with
#'   \code{si_auth_signin()}.
#' @param geometry GeoJSON geometry list, or a JSON string.
#' @param n_keywords Number of ingestion keywords. When \code{NULL} and
#'   \code{theme_ids} is provided, the server derives the count from
#'   the matching theme keywords.
#' @param name Optional short identifier for the polygon.
#' @param display_name Optional user-facing polygon label.
#' @param place_name Optional place name metadata.
#' @param country Country code or name (default \code{"US"}).
#' @param state Optional state/region metadata.
#' @param theme_ids Integer vector or comma-separated string of theme IDs
#'   to use for keyword selection.
#' @param sites_grid_sqkm Query-grid cell size in sqkm for Google Places
#'   ingestion (default 2).
#'
#' @return A list with \code{request}, \code{bounds_id}, \code{location_id},
#'   \code{required_queries}, and \code{usage} fields.
#' @keywords internal
#' @noRd
si_submit_request = function(client,
                             geometry,
                             n_keywords = NULL,
                             name = NULL,
                             display_name = NULL,
                             place_name = NULL,
                             country = "US",
                             state = NULL,
                             theme_ids = NULL,
                             sites_grid_sqkm = 2) {
  si_require_auth(client)

  # Coerce geometry to a JSON string for the RPC
  if (is.character(geometry) && length(geometry) == 1) {
    geometry_json = geometry
  } else {
    geometry_json = jsonlite::toJSON(geometry, auto_unbox = TRUE, null = "null")
  }

  # Coerce theme_ids to CSV string
  theme_ids_csv = NULL
  if (!is.null(theme_ids)) {
    if (is.numeric(theme_ids) || is.integer(theme_ids)) {
      theme_ids_csv = paste(as.integer(theme_ids), collapse = ",")
    } else if (is.character(theme_ids) && length(theme_ids) == 1) {
      theme_ids_csv = trimws(theme_ids)
    } else {
      stop("`theme_ids` must be an integer vector or a comma-separated string.")
    }
  }

  payload = list(
    p_geometry_geojson = jsonlite::fromJSON(as.character(geometry_json), simplifyVector = FALSE),
    p_name = name,
    p_display_name = display_name,
    p_country = if (!is.null(country) && nchar(trimws(as.character(country))) > 0) {
      trimws(as.character(country))
    } else {
      "US"
    },
    p_state = if (!is.null(state)) trimws(as.character(state)) else NULL,
    p_place_name = if (!is.null(place_name)) trimws(as.character(place_name)) else NULL,
    p_theme_ids = theme_ids_csv,
    p_n_keywords = if (!is.null(n_keywords)) as.integer(n_keywords) else NULL,
    p_sites_grid_sqkm = as.numeric(sites_grid_sqkm)
  )

  req = httr2::request(
    paste0(client$supabase_url, "/rest/v1/rpc/fn_submit_request")
  ) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(payload, auto_unbox = TRUE)

  data = si_parse_response(httr2::req_perform(req))

  # fn_submit_request returns a jsonb scalar; PostgREST wraps it.
  if (is.character(data) && length(data) == 1) {
    data = jsonlite::fromJSON(data, simplifyVector = FALSE)
  }
  data
}

#' Get one request status
#'
#' Reads directly from \code{public.requests} via Supabase PostgREST.
#' Row-level security restricts results to the authenticated user's
#' own requests.
#'
#' @param client A client from \code{si_client()} authenticated with
#'   \code{si_auth_signin()}.
#' @param request_id Request UUID string.
#'
#' @return A tibble with one row, or an empty tibble if not found.
#' @keywords internal
si_get_request_status = function(client, request_id) {
  si_require_auth(client)
  if (!is.character(request_id) || length(request_id) != 1 || nchar(trimws(request_id)) == 0) {
    stop("`request_id` must be a non-empty UUID string.")
  }

  req = httr2::request(
    paste0(client$supabase_url, "/rest/v1/requests")
  ) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_url_query(
      id = paste0("eq.", trimws(request_id)),
      select = "*",
      limit = 1
    )

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Get request history for current user
#'
#' @param client A client from \code{si_client()} authenticated with
#'   \code{si_auth_signin()}.
#' @param limit Maximum rows (default 100).
#' @param offset Pagination offset (default 0).
#'
#' @return A tibble of requests rows.
#' @keywords internal
#' @noRd
si_get_requests = function(client, limit = 100L, offset = 0L) {
  si_require_auth(client)
  limit = si_clamp_limit(limit, max_limit = 500L)
  offset = as.integer(offset)
  if (is.na(offset) || offset < 0L) {
    stop("`offset` must be a non-negative integer.")
  }

  req = httr2::request(
    paste0(client$supabase_url, "/rest/v1/rpc/fn_get_user_requests")
  ) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(
      list(
        p_limit = limit,
        p_offset = offset
      )
    )

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

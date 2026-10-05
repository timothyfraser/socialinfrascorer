#' Submit a new polygon request via Supabase RPC
#'
#' Validates geometry, checks quota, inserts bounds + location + request row,
#' and triggers asynchronous processing -- all server-side via
#' \code{fn_submit_request} in PostgreSQL. Sites are drawn from Overture
#' Maps (open data).
#'
#' @param client A client from \code{client()} authenticated with
#'   \code{sign_in()}.
#' @param geometry GeoJSON geometry list, or a JSON string.
#' @param name Optional short identifier for the polygon.
#' @param display_name Optional user-facing polygon label.
#' @param place_name Optional place name metadata.
#' @param country Country code or name (default \code{"US"}).
#' @param state Optional state/region metadata.
#' @param theme_ids Optional integer vector or comma-separated string of
#'   theme IDs. \code{NULL} uses the server default.
#' @param ... Retired arguments (\code{sites_grid_sqkm}, \code{n_keywords})
#'   are accepted and ignored with a warning.
#'
#' @return A list with \code{request}, \code{bounds_id}, \code{location_id},
#'   \code{required_queries}, and \code{usage} fields.
#' @keywords internal
#' @noRd
si_submit_request = function(client,
                             geometry,
                             name = NULL,
                             display_name = NULL,
                             place_name = NULL,
                             country = "US",
                             state = NULL,
                             theme_ids = NULL,
                             ...) {
  si_retired_args(..., .retired = c("sites_grid_sqkm", "n_keywords"))
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
    p_theme_ids = theme_ids_csv
  )

  data = si_perform(client, "/rest/v1/rpc/fn_submit_request", body = payload, auth = TRUE)

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
#' @param client A client from \code{client()} authenticated with
#'   \code{sign_in()}.
#' @param request_id Request UUID string.
#'
#' @return A tibble with one row, or an empty tibble if not found.
#' @keywords internal
si_get_request_status = function(client, request_id) {
  si_require_auth(client)
  if (!is.character(request_id) || length(request_id) != 1 || nchar(trimws(request_id)) == 0) {
    stop("`request_id` must be a non-empty UUID string.")
  }

  data = si_perform(
    client,
    "/rest/v1/requests",
    method = "GET",
    query = list(
      id = paste0("eq.", trimws(request_id)),
      select = "*",
      limit = 1
    ),
    auth = TRUE
  )
  si_as_tibble(data)
}

#' Get request history for current user
#'
#' @param client A client from \code{client()} authenticated with
#'   \code{sign_in()}.
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

  data = si_perform(
    client,
    "/rest/v1/rpc/fn_get_user_requests",
    body = list(
      p_limit = limit,
      p_offset = offset
    ),
    auth = TRUE
  )
  si_as_tibble(data)
}

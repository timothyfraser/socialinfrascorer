#' Submit a new polygon request
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param geometry GeoJSON geometry object/list, an `sf` object, or JSON string.
#' @param n_keywords Number of ingestion keywords (default 10).
#' @param name Optional short identifier for the polygon.
#' @param display_name Optional user-facing polygon label.
#' @param place_name Optional place name metadata.
#' @param country Optional country code/name.
#' @param state Optional state/region metadata.
#' @param auto_process If TRUE, trigger processing automatically.
#' @param async_process If TRUE and server supports it, processing runs in background.
#' @param api_base_url Base URL of the private API.
#'
#' @return Parsed response list with request metadata.
#' @export
si_submit_request = function(client,
                             geometry,
                             n_keywords = 10L,
                             name = NULL,
                             display_name = NULL,
                             place_name = NULL,
                             country = "US",
                             state = NULL,
                             auto_process = TRUE,
                             async_process = TRUE,
                             api_base_url = Sys.getenv("SCORECARD_API_URL", "")) {
  si_require_auth(client)

  if (!is.character(api_base_url) || length(api_base_url) != 1 || nchar(trimws(api_base_url)) == 0) {
    stop("`api_base_url` must be provided (or set SCORECARD_API_URL).")
  }

  geometry_payload = geometry
  if (inherits(geometry, "sf")) {
    stop("`geometry` as `sf` is not yet auto-converted; pass a GeoJSON geometry list or string.")
  } else if (is.character(geometry) && length(geometry) == 1) {
    geometry_payload = jsonlite::fromJSON(geometry, simplifyVector = FALSE)
  }

  payload = list(
    geometry = geometry_payload,
    n_keywords = as.integer(n_keywords),
    name = name,
    display_name = display_name,
    place_name = place_name,
    country = country,
    state = state,
    auto_process = isTRUE(auto_process),
    async_process = isTRUE(async_process)
  )

  req = httr2::request(paste0(sub("/+$", "", trimws(api_base_url)), "/request/new")) |>
    httr2::req_headers(
      Authorization = paste("Bearer", client$access_token),
      `Content-Type` = "application/json"
    ) |>
    httr2::req_body_json(payload, auto_unbox = TRUE)

  si_parse_response(httr2::req_perform(req))
}

#' Get one request status
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param request_id Request UUID.
#' @param api_base_url Base URL of the private API.
#'
#' @return Parsed response payload.
#' @export
si_get_request_status = function(client,
                                 request_id,
                                 api_base_url = Sys.getenv("SCORECARD_API_URL", "")) {
  si_require_auth(client)
  if (!is.character(request_id) || length(request_id) != 1 || nchar(trimws(request_id)) == 0) {
    stop("`request_id` must be a non-empty UUID string.")
  }
  if (!is.character(api_base_url) || length(api_base_url) != 1 || nchar(trimws(api_base_url)) == 0) {
    stop("`api_base_url` must be provided (or set SCORECARD_API_URL).")
  }

  req = httr2::request(
    paste0(sub("/+$", "", trimws(api_base_url)), "/request/", trimws(request_id), "/status")
  ) |>
    httr2::req_headers(
      Authorization = paste("Bearer", client$access_token),
      `Content-Type` = "application/json"
    )

  si_parse_response(httr2::req_perform(req))
}

#' Get request history for current user
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param limit Maximum rows (default 100).
#' @param offset Pagination offset (default 0).
#'
#' @return A tibble of requests rows.
#' @export
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


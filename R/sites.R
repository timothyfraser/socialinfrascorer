#' Get sites by location_id with capped sampling
#'
#' @param client A client from `client()` authenticated with `sign_in()`.
#' @param location_id Text location identifier from `public.location.location_id`.
#' @param limit Maximum rows to return. Hard capped at 1000.
#'
#' @return A tibble of sites rows.
#' @keywords internal
#' @noRd
si_get_sites_by_location_id = function(client, location_id, limit = 1000L) {
  si_require_auth(client)

  if (!is.character(location_id) || length(location_id) != 1 || nchar(trimws(location_id)) == 0) {
    stop("`location_id` must be a non-empty string.")
  }

  limit = si_clamp_limit(limit, max_limit = 1000L)

  data = si_perform(
    client,
    "/rest/v1/rpc/fn_get_sites_by_location_id",
    body = list(
      p_location_id = trimws(location_id),
      p_limit = limit
    ),
    auth = TRUE
  )
  si_as_tibble(data)
}


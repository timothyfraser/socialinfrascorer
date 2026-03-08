#' Create a socialinfrascorer API client
#'
#' @param supabase_url Supabase project URL (e.g. \code{https://project.supabase.co}).
#' @param anon_key Supabase anon/publishable API key.
#' @param access_token Optional authenticated access token.
#' @param refresh_token Optional refresh token.
#'
#' @return A client object used by package functions.
#' @export
client = si_client

#' Sign up a new user
#'
#' @param client A client from \code{client()}.
#' @param email User email.
#' @param password User password.
#' @param name Optional display name stored in user metadata.
#'
#' @return A list with \code{client}, \code{session}, \code{user}, and raw \code{data}.
#' @export
sign_up = function(client, email, password, name = NULL) {
  si_auth_signup(client, email, password, display_name = name)
}

#' Sign in with email and password
#'
#' @param client A client from \code{client()}.
#' @param email User email.
#' @param password User password.
#'
#' @return A list with authenticated \code{client}, \code{session}, and raw \code{data}.
#' @export
sign_in = si_auth_signin

#' Request a password reset email
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#'
#' @return Parsed response payload from Supabase auth.
#' @export
send_password_reset = si_auth_reset_password

#' Delete the currently authenticated account
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#'
#' @return A list with \code{status}, \code{user_id}, and \code{message}.
#' @export
delete_account = si_auth_delete_account

#' List available social-infrastructure themes
#'
#' @param client A client from \code{client()}.
#'
#' @return A tibble with theme IDs and types.
#' @export
get_themes = si_get_themes

#' List keywords for given theme IDs
#'
#' @param client A client from \code{client()}.
#' @param theme_ids Integer vector or comma-separated string of theme IDs. Pass \code{NULL} for all.
#'
#' @return A tibble with theme, type, and term columns.
#' @export
get_theme_keywords = si_get_theme_keywords

#' Search for locations by place name
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param query Place name to search.
#' @param country Optional country filter.
#' @param state Optional state/region filter.
#' @param limit Maximum rows to return (default 5).
#'
#' @return A tibble of matching location rows.
#' @export
search_locations = function(client, query, country = NULL, state = NULL, limit = 5L) {
  si_get_polygon_lookup_by_place_name(client, place_name = query, country = country, state = state, limit = limit)
}

#' Get boundary by OpenStreetMap ID
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param osm_id Numeric OSM identifier.
#'
#' @return A tibble with boundary geometry.
#' @export
get_boundary_by_osm_id = si_get_polygon_by_osm_id

#' Get boundary by location ID
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param location_id Location identifier.
#'
#' @return A tibble with boundary geometry.
#' @export
get_boundary_by_location_id = si_get_polygon_by_location_id

#' Get boundary by area ID
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param area_id UUID area identifier.
#'
#' @return A tibble with boundary geometry.
#' @export
get_boundary_by_area_id = si_get_polygon_by_area_id

#' Get boundary by place name
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param query Place name to resolve.
#' @param country Optional country filter.
#' @param state Optional state/region filter.
#'
#' @return A tibble with boundary geometry.
#' @export
get_boundary_by_place_name = function(client, query, country = NULL, state = NULL) {
  si_get_polygon_by_place_name(client, place_name = query, country = country, state = state)
}

#' Get scorecard results for a location
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param osm_id Optional OSM ID.
#' @param location_id Optional location ID.
#' @param limit Maximum rows (default 100).
#' @param offset Pagination offset.
#'
#' @return A tibble of scorecard results.
#' @export
get_scorecard = si_get_scorecard_results

#' Get social-infrastructure sites for a location
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param location_id Location identifier.
#' @param limit Maximum rows (default 1000).
#'
#' @return A tibble of site rows.
#' @export
get_sites = si_get_sites_by_location_id

#' Submit a scorecard request for a new area
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param geometry GeoJSON geometry (Polygon or MultiPolygon, CRS 4326).
#' @param n_keywords Number of keywords (optional; derived from themes when \code{NULL}).
#' @param name Optional short identifier.
#' @param display_name Optional user-facing label.
#' @param place_name Optional place name metadata.
#' @param country Country code (default \code{"US"}).
#' @param state Optional state/region.
#' @param theme_ids Integer vector or CSV string of theme IDs.
#' @param sites_grid_sqkm Query grid cell size in sq km (default 2).
#'
#' @return A list with \code{request}, \code{location_id}, and related fields.
#' @export
submit_request = si_submit_request

#' Get status of a submitted request
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param request_id Request UUID.
#'
#' @return A tibble with one row.
#' @export
get_request_status = si_get_request_status

#' Get request history for the current user
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param limit Maximum rows (default 100).
#' @param offset Pagination offset.
#'
#' @return A tibble of request rows.
#' @export
get_requests = si_get_requests

#' Get current subscription profile
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#'
#' @return A tibble with profile row.
#' @export
get_subscription = si_get_subscription

#' Get usage summary for a date range
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#' @param start_date Optional start date (YYYY-MM-DD).
#' @param end_date Optional end date (YYYY-MM-DD).
#'
#' @return A tibble with usage metrics.
#' @export
get_usage = si_get_usage

#' Get remaining monthly query quota
#'
#' @param client A client from \code{client()} authenticated with \code{sign_in()}.
#'
#' @return A tibble with remaining quota.
#' @export
get_remaining_queries = si_get_remaining_queries

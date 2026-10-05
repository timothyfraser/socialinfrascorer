#' Get current subscription profile
#'
#' @param client A client from `client()` authenticated with `sign_in()`.
#' @return A tibble for the authenticated user's profile row.
#' @keywords internal
#' @noRd
si_get_subscription = function(client) {
  si_require_auth(client)
  data = si_perform(
    client,
    "/rest/v1/profiles",
    method = "GET",
    query = list(
      select = "id,display_name,role,subscription_tier,created_at,updated_at",
      limit = 1
    ),
    auth = TRUE
  )
  si_as_tibble(data)
}

#' Get usage summary for date range
#'
#' @param client A client from `client()` authenticated with `sign_in()`.
#' @param start_date Optional start date (`YYYY-MM-DD`).
#' @param end_date Optional end date (`YYYY-MM-DD`).
#' @return A tibble from `fn_get_user_usage`.
#' @keywords internal
#' @noRd
si_get_usage = function(client,
                        start_date = NULL,
                        end_date = NULL) {
  si_require_auth(client)

  start_val = if (!is.null(start_date) && nchar(trimws(as.character(start_date))) > 0) {
    trimws(as.character(start_date))
  } else {
    NULL
  }
  end_val = if (!is.null(end_date) && nchar(trimws(as.character(end_date))) > 0) {
    trimws(as.character(end_date))
  } else {
    NULL
  }

  data = si_perform(
    client,
    "/rest/v1/rpc/fn_get_user_usage",
    body = list(
      p_start_date = start_val,
      p_end_date = end_val
    ),
    auth = TRUE
  )
  si_as_tibble(data)
}

#' Get remaining monthly queries
#'
#' @param client A client from `client()` authenticated with `sign_in()`.
#'
#' @return A tibble with subscription tier and remaining query metrics.
#' @keywords internal
#' @noRd
si_get_remaining_queries = function(client) {
  si_require_auth(client)
  data = si_perform(client, "/rest/v1/rpc/fn_get_user_remaining_queries", body = list(), auth = TRUE)
  si_as_tibble(data)
}

#' Change a user's subscription tier (admin/service role operation)
#'
#' @param client A client from `client()` authenticated with `sign_in()`.
#' @param user_id UUID user identifier.
#' @param tier Target tier id (`free`, `developer`, etc.).
#'
#' @return A tibble with updated profile row.
#' @keywords internal
si_change_subscription = function(client, user_id, tier) {
  si_require_auth(client)
  if (!is.character(user_id) || length(user_id) != 1 || nchar(trimws(user_id)) == 0) {
    stop("`user_id` must be a non-empty UUID string.")
  }
  if (!is.character(tier) || length(tier) != 1 || nchar(trimws(tier)) == 0) {
    stop("`tier` must be a non-empty string.")
  }

  data = si_perform(
    client,
    "/rest/v1/rpc/fn_change_subscription_tier",
    body = list(
      p_user_id = trimws(user_id),
      p_tier = trimws(tier)
    ),
    auth = TRUE
  )
  si_as_tibble(data)
}


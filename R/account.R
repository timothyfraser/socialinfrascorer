#' Get current subscription profile
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @return A tibble for the authenticated user's profile row.
#' @keywords internal
#' @noRd
si_get_subscription = function(client) {
  si_require_auth(client)
  req = httr2::request(paste0(client$supabase_url, "/rest/v1/profiles")) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_url_query(
      select = "id,display_name,role,subscription_tier,created_at,updated_at",
      limit = 1
    )
  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Get usage summary for date range
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
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

  req = httr2::request(paste0(client$supabase_url, "/rest/v1/rpc/fn_get_user_usage")) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(
      list(
        p_start_date = start_val,
        p_end_date = end_val
      )
    )
  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Get remaining fair-use allowance
#'
#' Calls the PostgREST RPC `fn_fair_use_status` (which reports on the caller's
#' own account via `auth.uid()`) and flattens its nested JSON into one row.
#' A limit of `-1` from the server means unlimited and is returned as `NA`.
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#'
#' @return A one-row tibble; see `get_remaining_queries()` for the columns.
#' @keywords internal
#' @noRd
si_get_remaining_queries = function(client) {
  si_require_auth(client)
  req = httr2::request(
    paste0(client$supabase_url, "/rest/v1/rpc/fn_fair_use_status")
  ) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(structure(list(), names = character(0)))

  data = si_parse_response(httr2::req_perform(req))
  si_fair_use_tibble(data)
}

#' Flatten an `fn_fair_use_status` response into a one-row tibble
#'
#' @param data Parsed JSON (a named list) from `fn_fair_use_status`.
#' @return A one-row tibble.
#' @keywords internal
#' @noRd
si_fair_use_tibble = function(data) {
  # PostgREST may wrap a scalar jsonb result in a length-1 array.
  if (is.list(data) && is.null(names(data)) && length(data) == 1) {
    data = data[[1]]
  }
  if (is.data.frame(data) && nrow(data) >= 1) {
    data = as.list(data[1, , drop = FALSE])
  }
  if (!is.list(data)) data = list()

  limits = data$limits %||% list()
  usage = data$usage %||% list()
  resets = data$resets %||% list()

  # First element as a number, NA when missing.
  num = function(x) {
    v = suppressWarnings(as.numeric(unlist(x)))
    if (length(v) == 0) NA_real_ else v[[1]]
  }
  # Limits: -1 (or any negative) means unlimited -> NA.
  lim = function(x) {
    v = num(x)
    if (!is.na(v) && v < 0) NA_real_ else v
  }
  # Remaining = limit - used, never below 0; NA when unlimited/unknown.
  remaining = function(limit, used) {
    if (is.na(limit)) return(NA_real_)
    max(limit - ifelse(is.na(used), 0, used), 0)
  }
  chr = function(x) {
    v = unlist(x)
    if (length(v) == 0 || is.na(v[[1]])) NA_character_ else as.character(v[[1]])
  }

  per_day = lim(limits$per_day)
  per_hour = lim(limits$per_hour)
  day_requests = num(usage$day_requests)
  hour_requests = num(usage$hour_requests)

  dplyr::tibble(
    tier = chr(data$tier),
    display_name = chr(data$display_name),
    per_day = per_day,
    day_requests = day_requests,
    remaining_today = remaining(per_day, day_requests),
    per_hour = per_hour,
    hour_requests = hour_requests,
    remaining_this_hour = remaining(per_hour, hour_requests),
    km2_per_day = lim(limits$km2_per_day),
    day_km2 = num(usage$day_km2),
    km2_per_hour = lim(limits$km2_per_hour),
    hour_km2 = num(usage$hour_km2),
    concurrent = lim(limits$concurrent),
    running = num(usage$running),
    waiting_limit = lim(limits$waiting),
    waiting = num(usage$waiting),
    hour_resets_at = si_parse_timestamp(resets$hour_at),
    day_resets_at = si_parse_timestamp(resets$day_at)
  )
}

#' Parse an ISO-8601 timestamp (with optional UTC offset) to POSIXct UTC
#'
#' @param x A character timestamp such as `2026-10-11T15:00:00+00:00`.
#' @return A length-1 POSIXct in UTC, or `NA`.
#' @keywords internal
#' @noRd
si_parse_timestamp = function(x) {
  na_time = as.POSIXct(NA_real_, origin = "1970-01-01", tz = "UTC")
  v = unlist(x)
  if (length(v) == 0 || is.na(v[[1]]) || !nzchar(as.character(v[[1]]))) {
    return(na_time)
  }
  s = trimws(as.character(v[[1]]))

  # Pull off a trailing "Z" or "+HH:MM" / "-HHMM" / "+HH" offset.
  offset_secs = 0
  m = regmatches(s, regexec("([+-])(\\d{2}):?(\\d{2})?$", s))[[1]]
  if (length(m) == 4 && grepl("T|\\s", s)) {
    sign = if (m[[2]] == "-") -1 else 1
    mins = if (nzchar(m[[4]])) as.numeric(m[[4]]) else 0
    offset_secs = sign * (as.numeric(m[[3]]) * 3600 + mins * 60)
    s = substr(s, 1, nchar(s) - nchar(m[[1]]))
  } else {
    s = sub("Z$", "", s)
  }
  s = sub(" ", "T", s, fixed = TRUE)

  out = as.POSIXct(s, format = "%Y-%m-%dT%H:%M:%OS", tz = "UTC")
  if (is.na(out)) return(na_time)
  out - offset_secs
}


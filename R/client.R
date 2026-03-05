#' Create a Social Infrastructure API client
#'
#' @param supabase_url Supabase project URL.
#' @param anon_key Supabase anon key.
#'
#' @return A client list used by package functions.
#' @export
si_client = function(supabase_url, anon_key) {
  if (!is.character(supabase_url) || length(supabase_url) != 1 || nchar(trimws(supabase_url)) == 0) {
    stop("`supabase_url` must be a non-empty string.")
  }
  if (!is.character(anon_key) || length(anon_key) != 1 || nchar(trimws(anon_key)) == 0) {
    stop("`anon_key` must be a non-empty string.")
  }

  structure(
    list(
      supabase_url = sub("/+$", "", trimws(supabase_url)),
      anon_key = trimws(anon_key),
      access_token = NULL,
      refresh_token = NULL
    ),
    class = "si_client"
  )
}

#' Get scorecard results by location_id
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param location_id Text location identifier from `public.location.location_id`.
#' @param limit Maximum rows (default 100).
#' @param offset Pagination offset (default 0).
#'
#' @return A tibble of scorecard rows.
#' @export
si_get_scorecard_results = function(client, location_id, limit = 100L, offset = 0L) {
  si_require_auth(client)

  if (!is.character(location_id) || length(location_id) != 1 || nchar(trimws(location_id)) == 0) {
    stop("`location_id` must be a non-empty string.")
  }

  limit = si_clamp_limit(limit, max_limit = 500L)
  offset = as.integer(offset)
  if (is.na(offset) || offset < 0L) {
    stop("`offset` must be a non-negative integer.")
  }

  req = httr2::request(
    paste0(client$supabase_url, "/rest/v1/rpc/fn_scorecard_result_by_location_id")
  ) |>
    si_add_common_headers(client = client, use_auth = TRUE) |>
    httr2::req_body_json(
      list(
        p_location_id = trimws(location_id),
        p_limit = limit,
        p_offset = offset
      )
    )

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' @keywords internal
si_add_common_headers = function(req, client, use_auth = TRUE) {
  headers = list(
    apikey = client$anon_key,
    `Content-Type` = "application/json"
  )

  if (isTRUE(use_auth) && !is.null(client$access_token) && nchar(client$access_token) > 0) {
    headers$Authorization = paste("Bearer", client$access_token)
  }

  do.call(httr2::req_headers, c(list(req), headers))
}

#' @keywords internal
si_parse_response = function(resp) {
  status = httr2::resp_status(resp)
  body_text = httr2::resp_body_string(resp)
  content_type = tolower(httr2::resp_header(resp, "content-type") %||% "")

  parsed = tryCatch(
    {
      if (grepl("application/json", content_type, fixed = TRUE) && nzchar(body_text)) {
        jsonlite::fromJSON(body_text, simplifyVector = FALSE)
      } else if (nzchar(body_text)) {
        body_text
      } else {
        list()
      }
    },
    error = function(e) {
      list(error = body_text)
    }
  )

  if (status >= 400) {
    err_msg = if (is.list(parsed) && !is.null(parsed$error)) {
      as.character(parsed$error)
    } else if (is.character(parsed) && length(parsed) == 1) {
      parsed
    } else {
      paste("HTTP", status)
    }
    stop(err_msg, call. = FALSE)
  }

  parsed
}

#' @keywords internal
si_require_auth = function(client) {
  token = client$access_token %||% ""
  if (!is.character(token) || length(token) != 1 || nchar(trimws(token)) == 0) {
    stop("Client is not authenticated. Run `si_auth_signin()` first.")
  }
  invisible(TRUE)
}

#' @keywords internal
si_clamp_limit = function(limit, max_limit = 1000L) {
  lim = as.integer(limit)
  max_lim = as.integer(max_limit)
  if (is.na(max_lim) || max_lim < 1L) {
    stop("`max_limit` must be a positive integer.")
  }
  if (is.na(lim) || lim < 1L) {
    lim = 1L
  }
  min(lim, max_lim)
}

#' @keywords internal
si_as_tibble = function(data) {
  if (is.null(data)) return(dplyr::tibble())

  if (is.data.frame(data)) {
    return(dplyr::as_tibble(data))
  }

  if (is.list(data) && length(data) == 0) {
    return(dplyr::tibble())
  }

  if (is.list(data)) {
    all_named_scalars = all(vapply(data, function(x) length(x) <= 1 && !is.list(x), logical(1)))
    if (all_named_scalars && !is.null(names(data))) {
      return(dplyr::as_tibble(data))
    }

    maybe_df = tryCatch(as.data.frame(data, stringsAsFactors = FALSE), error = function(e) NULL)
    if (!is.null(maybe_df)) return(dplyr::as_tibble(maybe_df))
  }

  dplyr::tibble(value = data)
}

#' @keywords internal
si_with_session = function(client, access_token = NULL, refresh_token = NULL) {
  out = client
  out$access_token = access_token %||% NULL
  out$refresh_token = refresh_token %||% NULL
  out
}
#' Create a socialinfrascorer API client
#'
#' @param supabase_url Supabase project URL (e.g. https://project.supabase.co).
#' @param anon_key Supabase anon/publishable API key.
#' @param access_token Optional authenticated access token.
#' @param refresh_token Optional refresh token.
#'
#' @return A client object used by package functions.
#' @export
si_client = function(supabase_url,
                     anon_key,
                     access_token = NULL,
                     refresh_token = NULL) {
  if (!is.character(supabase_url) || length(supabase_url) != 1 || nchar(trimws(supabase_url)) == 0) {
    stop("`supabase_url` must be a non-empty string.")
  }
  if (!is.character(anon_key) || length(anon_key) != 1 || nchar(trimws(anon_key)) == 0) {
    stop("`anon_key` must be a non-empty string.")
  }

  obj = list(
    supabase_url = sub("/+$", "", trimws(supabase_url)),
    anon_key = trimws(anon_key),
    access_token = if (is.null(access_token)) NULL else as.character(access_token),
    refresh_token = if (is.null(refresh_token)) NULL else as.character(refresh_token)
  )

  class(obj) = c("si_client", "list")
  obj
}

#' @keywords internal
si_require_auth = function(client) {
  if (is.null(client$access_token) || nchar(client$access_token) == 0) {
    stop(
      "This function requires an authenticated user. Call `si_auth_signin()` first.",
      call. = FALSE
    )
  }
}

#' @keywords internal
si_with_session = function(client, access_token = NULL, refresh_token = NULL) {
  si_client(
    supabase_url = client$supabase_url,
    anon_key = client$anon_key,
    access_token = access_token,
    refresh_token = refresh_token
  )
}

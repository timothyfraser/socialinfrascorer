#' @keywords internal
`%||%` = function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
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
si_parse_response = function(resp) {
  status = httr2::resp_status(resp)
  body_text = tryCatch(httr2::resp_body_string(resp), error = function(e) "")

  if (status >= 400) {
    parsed_err = tryCatch(
      jsonlite::fromJSON(body_text, simplifyVector = FALSE),
      error = function(e) NULL
    )
    err_msg = if (is.list(parsed_err) && !is.null(parsed_err$message)) {
      as.character(parsed_err$message)
    } else if (is.list(parsed_err) && !is.null(parsed_err$error)) {
      as.character(parsed_err$error)
    } else if (nzchar(body_text)) {
      body_text
    } else {
      paste("HTTP", status)
    }
    stop(err_msg, call. = FALSE)
  }

  parsed = tryCatch(
    httr2::resp_body_json(resp, simplifyVector = TRUE),
    error = function(e) NULL
  )
  if (is.null(parsed)) {
    return(data.frame())
  }
  parsed
}

#' @keywords internal
si_add_common_headers = function(req, client, use_auth = FALSE) {
  req = req |>
    httr2::req_headers(
      apikey = client$anon_key,
      `Content-Type` = "application/json"
    )

  if (isTRUE(use_auth) && !is.null(client$access_token) && nchar(client$access_token) > 0) {
    req = req |> httr2::req_headers(Authorization = paste("Bearer", client$access_token))
  } else {
    req = req |> httr2::req_headers(Authorization = paste("Bearer", client$anon_key))
  }

  req
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
    all_named_scalars = all(vapply(
      data,
      function(x) length(x) <= 1 && !is.list(x),
      logical(1)
    ))
    if (all_named_scalars && !is.null(names(data))) {
      return(dplyr::as_tibble(data))
    }

    maybe_df = tryCatch(
      as.data.frame(data, stringsAsFactors = FALSE),
      error = function(e) NULL
    )
    if (!is.null(maybe_df)) return(dplyr::as_tibble(maybe_df))
  }

  dplyr::tibble(value = data)
}

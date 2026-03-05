#' @keywords internal
si_clamp_limit = function(limit, max_limit = 100L) {
  limit_int = as.integer(limit)
  if (is.na(limit_int) || limit_int < 1L) {
    stop("`limit` must be a positive integer.")
  }
  as.integer(min(limit_int, max_limit))
}

#' @keywords internal
si_parse_response = function(resp) {
  status = httr2::resp_status(resp)
  if (status >= 400) {
    body_text = tryCatch(httr2::resp_body_string(resp), error = function(e) "")
    stop(
      sprintf("Supabase request failed with HTTP %s: %s", status, body_text),
      call. = FALSE
    )
  }

  parsed = tryCatch(httr2::resp_body_json(resp, simplifyVector = TRUE), error = function(e) NULL)
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

  if (use_auth) {
    req = req |> httr2::req_headers(Authorization = paste("Bearer", client$access_token))
  } else {
    req = req |> httr2::req_headers(Authorization = paste("Bearer", client$anon_key))
  }

  req
}

#' @keywords internal
si_as_tibble = function(x) {
  if (is.null(x)) {
    return(dplyr::tibble())
  }
  if (is.data.frame(x)) {
    return(dplyr::as_tibble(x))
  }
  if (is.list(x) && length(x) == 0) {
    return(dplyr::tibble())
  }
  dplyr::as_tibble(x)
}

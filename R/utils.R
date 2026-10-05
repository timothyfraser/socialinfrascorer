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


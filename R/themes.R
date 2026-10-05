#' List available themes
#'
#' Returns the reference table of theme categories used for
#' keyword-based Google Places ingestion.
#'
#' @param client A client from \code{client()}.
#'   Authentication is optional; the endpoint is public.
#'
#' @return A tibble with columns \code{theme} (integer) and \code{type} (text).
#' @keywords internal
#' @noRd
si_get_themes = function(client) {
  data = si_perform(client, "/rest/v1/rpc/fn_get_themes", body = list())
  si_as_tibble(data)
}

#' List keywords for given theme IDs
#'
#' @param client A client from \code{client()}.
#'   Authentication is optional; the endpoint is public.
#' @param theme_ids Integer vector or comma-separated string of theme IDs.
#'   Pass \code{NULL} to retrieve all keywords.
#'
#' @return A tibble with columns \code{theme}, \code{type}, and \code{term}.
#' @keywords internal
#' @noRd
si_get_theme_keywords = function(client, theme_ids = NULL) {
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

  data = si_perform(
    client,
    "/rest/v1/rpc/fn_get_theme_keywords",
    body = list(p_theme_ids = theme_ids_csv)
  )
  si_as_tibble(data)
}

#' List available themes
#'
#' Returns the reference table of theme categories used for
#' keyword-based Google Places ingestion.
#'
#' @param client A client from \code{si_client()}.
#'   Authentication is optional; the endpoint is public.
#'
#' @return A tibble with columns \code{theme} (integer) and \code{type} (text).
#' @keywords internal
#' @noRd
si_get_themes = function(client) {
  req = httr2::request(
    paste0(client$supabase_url, "/rest/v1/rpc/fn_get_themes")
  ) |>
    si_add_common_headers(client = client, use_auth = FALSE) |>
    httr2::req_body_json(list())

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' List keywords for given theme IDs
#'
#' @param client A client from \code{si_client()}.
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

  req = httr2::request(
    paste0(client$supabase_url, "/rest/v1/rpc/fn_get_theme_keywords")
  ) |>
    si_add_common_headers(client = client, use_auth = FALSE) |>
    httr2::req_body_json(
      list(p_theme_ids = theme_ids_csv),
      auto_unbox = TRUE
    )

  data = si_parse_response(httr2::req_perform(req))
  si_as_tibble(data)
}

#' Create a socialinfrascorer API client
#'
#' @param supabase_url Supabase project URL (e.g. \code{https://project.supabase.co}).
#' @param anon_key Supabase anon/publishable API key.
#' @param access_token Optional authenticated access token.
#' @param refresh_token Optional refresh token.
#'
#' @return A client object used by package functions.
#' @keywords internal
#' @noRd
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

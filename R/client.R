# Public by design: the URL and the publishable (anon) key are already shipped
# in the scorecard web bundle, and row level security protects the data. The
# environment variables below only override them (testing, self-hosting).
si_public_url = "https://annuvayiqynyksnzkpoy.supabase.co"
si_public_key = "sb_publishable_SS0DtvFh990Zcj-6q7t4nw_VRdCF_Vb"

#' @keywords internal
#' @noRd
si_default_url = function() {
  value = Sys.getenv("SI_SUPABASE_URL", si_public_url)
  if (nzchar(trimws(value))) value else si_public_url
}

#' @keywords internal
#' @noRd
si_default_key = function() {
  value = Sys.getenv("SI_SUPABASE_ANON_KEY", si_public_key)
  if (nzchar(trimws(value))) value else si_public_key
}

#' Create a socialinfrascorer API client
#'
#' @param supabase_url Supabase project URL (e.g. \code{https://project.supabase.co}).
#'   Defaults to the scorecard's public project.
#' @param anon_key Supabase anon/publishable API key. Defaults to the
#'   scorecard's public key.
#' @param access_token Optional authenticated access token.
#' @param refresh_token Optional refresh token.
#'
#' @return A client object used by package functions.
#' @keywords internal
#' @noRd
si_client = function(supabase_url = si_default_url(),
                     anon_key = si_default_key(),
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
      "This function requires an authenticated user. Call `sign_in()` first.",
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

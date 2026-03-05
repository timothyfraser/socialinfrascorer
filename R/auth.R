#' Sign up a new Supabase user
#'
#' @param client A client from `si_client()`.
#' @param email User email.
#' @param password User password.
#' @param display_name Optional display name stored in user metadata.
#'
#' @return A list with `client`, `session`, `user`, and raw `data`.
#' @export
si_auth_signup = function(client, email, password, display_name = NULL) {
  payload = list(
    email = as.character(email),
    password = as.character(password)
  )

  if (!is.null(display_name) && nchar(trimws(display_name)) > 0) {
    payload$options = list(data = list(display_name = as.character(display_name)))
  }

  req = httr2::request(paste0(client$supabase_url, "/auth/v1/signup")) |>
    si_add_common_headers(client = client, use_auth = FALSE) |>
    httr2::req_body_json(payload)

  resp = httr2::req_perform(req)
  data = si_parse_response(resp)

  session = data$session
  user = data$user

  list(
    client = if (!is.null(session$access_token)) {
      si_with_session(
        client,
        access_token = session$access_token,
        refresh_token = session$refresh_token %||% NULL
      )
    } else {
      client
    },
    session = session,
    user = user,
    data = data
  )
}

#' Sign in to Supabase with email/password
#'
#' @param client A client from `si_client()`.
#' @param email User email.
#' @param password User password.
#'
#' @return A list with authenticated `client`, `session`, and raw `data`.
#' @export
si_auth_signin = function(client, email, password) {
  req = httr2::request(
    paste0(client$supabase_url, "/auth/v1/token?grant_type=password")
  ) |>
    si_add_common_headers(client = client, use_auth = FALSE) |>
    httr2::req_body_json(
      list(
        email = as.character(email),
        password = as.character(password)
      )
    )

  resp = httr2::req_perform(req)
  data = si_parse_response(resp)

  new_client = si_with_session(
    client,
    access_token = data$access_token %||% NULL,
    refresh_token = data$refresh_token %||% NULL
  )

  list(
    client = new_client,
    session = list(
      access_token = data$access_token %||% NULL,
      refresh_token = data$refresh_token %||% NULL,
      expires_in = data$expires_in %||% NULL,
      token_type = data$token_type %||% NULL
    ),
    data = data
  )
}

#' Request a password reset email
#'
#' @param client A client from `si_client()`.
#' @param email User email.
#'
#' @return Parsed response payload from Supabase auth.
#' @export
si_auth_reset_password = function(client, email) {
  if (!is.character(email) || length(email) != 1 || nchar(trimws(email)) == 0) {
    stop("`email` must be a non-empty string.")
  }

  req = httr2::request(paste0(client$supabase_url, "/auth/v1/recover")) |>
    si_add_common_headers(client = client, use_auth = FALSE) |>
    httr2::req_body_json(list(email = trimws(email)))

  si_parse_response(httr2::req_perform(req))
}

#' Delete the currently authenticated account via private API
#'
#' @param client A client from `si_client()` authenticated with `si_auth_signin()`.
#' @param api_base_url API base URL for the private account endpoint.
#'
#' @return Parsed response payload.
#' @export
si_auth_delete_account = function(client, api_base_url = Sys.getenv("SCORECARD_API_URL", "")) {
  si_require_auth(client)

  if (!is.character(api_base_url) || length(api_base_url) != 1 || nchar(trimws(api_base_url)) == 0) {
    stop("`api_base_url` must be a non-empty string. Set SCORECARD_API_URL or provide it explicitly.")
  }

  req = httr2::request(paste0(sub("/+$", "", trimws(api_base_url)), "/account")) |>
    httr2::req_method("DELETE") |>
    httr2::req_headers(
      Authorization = paste("Bearer", client$access_token),
      `Content-Type` = "application/json"
    )

  si_parse_response(httr2::req_perform(req))
}

#' @keywords internal
`%||%` = function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
}

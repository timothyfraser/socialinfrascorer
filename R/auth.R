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

#' @keywords internal
`%||%` = function(lhs, rhs) {
  if (is.null(lhs)) rhs else lhs
}

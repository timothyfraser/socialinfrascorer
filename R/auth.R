#' Sign up a new Supabase user
#'
#' @param client A client from \code{client()}.
#' @param email User email.
#' @param password User password.
#' @param display_name Optional display name stored in user metadata.
#'
#' @return A list with \code{client}, \code{session}, \code{user}, and
#'   raw \code{data}.
#' @keywords internal
#' @noRd
si_auth_signup = function(client, email, password, display_name = NULL) {
  payload = list(
    email = as.character(email),
    password = as.character(password)
  )

  if (!is.null(display_name) && nchar(trimws(display_name)) > 0) {
    payload$options = list(data = list(display_name = as.character(display_name)))
  }

  data = si_perform(client, "/auth/v1/signup", body = payload)

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
#' @param client A client from \code{client()}.
#' @param email User email.
#' @param password User password.
#'
#' @return A list with authenticated \code{client}, \code{session}, and
#'   raw \code{data}.
#' @keywords internal
#' @noRd
si_auth_signin = function(client, email, password) {
  data = si_perform(
    client,
    "/auth/v1/token",
    query = list(grant_type = "password"),
    body = list(
      email = as.character(email),
      password = as.character(password)
    )
  )

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

#' Request a password reset email for the signed-in user
#'
#' @param client A client from \code{client()} authenticated with
#'   \code{sign_in()}.
#'
#' @return Parsed response payload from Supabase auth.
#' @keywords internal
#' @noRd
si_auth_reset_password = function(client) {
  si_require_auth(client)

  # Fetch the authenticated user's email from Supabase Auth.
  user = si_perform(client, "/auth/v1/user", method = "GET", auth = TRUE)

  email = user$email %||% NULL
  if (is.null(email) || !is.character(email) || nchar(trimws(email)) == 0) {
    stop("Could not resolve authenticated user email for password reset.", call. = FALSE)
  }

  si_perform(client, "/auth/v1/recover", body = list(email = trimws(email)))
}

#' Delete the currently authenticated account
#'
#' Calls the \code{fn_delete_account} Supabase RPC which initiates
#' account deletion via the Auth Admin API server-side.
#' No private API URL is required.
#'
#' @param client A client from \code{client()} authenticated with
#'   \code{sign_in()}.
#'
#' @return A list with \code{status}, \code{user_id}, and \code{message}.
#' @keywords internal
#' @noRd
si_auth_delete_account = function(client) {
  si_require_auth(client)

  data = si_perform(client, "/rest/v1/rpc/fn_delete_account", body = list(), auth = TRUE)

  if (is.character(data) && length(data) == 1) {
    data = jsonlite::fromJSON(data, simplifyVector = FALSE)
  }
  data
}

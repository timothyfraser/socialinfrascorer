# The one HTTP choke point.
#
# Every exported function reaches Supabase through `si_perform()`. It builds
# a backend-neutral request (method, url, headers, JSON body), hands it to a
# backend, and parses the reply. A backend is a function that takes that
# request list and returns `list(status = <int>, body = <chr>)`:
#
# * "httr2" (default on desktop R) performs it with httr2, a Suggests.
# * "webr"  (inside webR, or when `options(socialinfrascorer.backend = "webr")`)
#   performs it with a synchronous XMLHttpRequest through `webr::eval_js()`.
#   webR runs R in a Web Worker, where synchronous XHR is allowed, and
#   Supabase answers CORS for any origin, so no httr2/libcurl is needed.
# * a function set in `options(socialinfrascorer.backend = )` is used as is
#   (tests inject a fake backend this way).

#' Perform one Supabase request
#'
#' @param client A client from `client()`.
#' @param path Path below the Supabase URL, e.g. `"/rest/v1/rpc/fn_get_themes"`.
#' @param method HTTP method.
#' @param body Optional R object sent as a JSON body.
#' @param query Optional named list of query parameters.
#' @param auth Use the signed-in user's access token (when present) instead
#'   of the anon key as the bearer token.
#'
#' @return The parsed JSON reply (simplified), or an empty data frame when
#'   the reply has no JSON body.
#' @keywords internal
#' @noRd
si_perform = function(client,
                      path,
                      method = "POST",
                      body = NULL,
                      query = NULL,
                      auth = FALSE) {
  req = si_build_request(
    client = client,
    path = path,
    method = method,
    body = body,
    query = query,
    auth = auth
  )
  resp = si_backend_fn()(req)
  si_parse_body(status = resp$status, body_text = resp$body)
}

#' Which HTTP backend is in use
#'
#' @return `"httr2"`, `"webr"`, or `"custom"` (a function set in
#'   `options(socialinfrascorer.backend = )`).
#' @keywords internal
#' @noRd
si_backend = function() {
  opt = getOption("socialinfrascorer.backend")
  if (is.function(opt)) {
    return("custom")
  }
  if (!is.null(opt)) {
    if (!is.character(opt) || length(opt) != 1 || !opt %in% c("httr2", "webr")) {
      stop(
        "`options(socialinfrascorer.backend = )` must be \"httr2\", \"webr\", or a function.",
        call. = FALSE
      )
    }
    if (identical(opt, "httr2") && !si_has_httr2()) {
      stop(si_no_backend_message(), call. = FALSE)
    }
    return(opt)
  }
  if (identical(R.version$os, "emscripten")) {
    return("webr")
  }
  if (si_has_httr2()) {
    return("httr2")
  }
  stop(si_no_backend_message(), call. = FALSE)
}

#' @keywords internal
#' @noRd
si_backend_fn = function() {
  switch(
    si_backend(),
    custom = getOption("socialinfrascorer.backend"),
    httr2 = si_backend_httr2,
    webr = si_backend_webr
  )
}

#' @keywords internal
#' @noRd
si_has_httr2 = function() {
  requireNamespace("httr2", quietly = TRUE)
}

#' @keywords internal
#' @noRd
si_no_backend_message = function() {
  paste0(
    "socialinfrascorer needs an HTTP backend and none is available.\n",
    "Install httr2 with `install.packages(\"httr2\")`, ",
    "or run the package inside webR."
  )
}

#' Build a backend-neutral request
#'
#' @return A list with `method`, `url`, `headers` (named character) and
#'   `body` (a JSON string, or `NULL`).
#' @keywords internal
#' @noRd
si_build_request = function(client,
                            path,
                            method = "POST",
                            body = NULL,
                            query = NULL,
                            auth = FALSE) {
  method = toupper(method)
  url = paste0(client$supabase_url, path)
  query_string = si_format_query(query)
  if (nzchar(query_string)) {
    url = paste0(url, "?", query_string)
  }

  list(
    method = method,
    url = url,
    headers = si_common_headers(client, use_auth = auth),
    body = if (is.null(body)) NULL else si_to_json(body)
  )
}

#' @keywords internal
#' @noRd
si_common_headers = function(client, use_auth = FALSE) {
  token = client$anon_key
  if (isTRUE(use_auth) && !is.null(client$access_token) && nchar(client$access_token) > 0) {
    token = client$access_token
  }
  c(
    apikey = client$anon_key,
    `Content-Type` = "application/json",
    Authorization = paste("Bearer", token)
  )
}

# Same serialisation httr2::req_body_json() uses, so requests are unchanged.
#' @keywords internal
#' @noRd
si_to_json = function(body) {
  as.character(jsonlite::toJSON(body, auto_unbox = TRUE, digits = 22, null = "null"))
}

# Same encoding httr2::req_url_query() uses (RFC 3986 escaping, no
# scientific notation), without needing curl.
#' @keywords internal
#' @noRd
si_format_query = function(query) {
  if (is.null(query)) {
    return("")
  }
  query = query[!vapply(query, is.null, logical(1))]
  if (length(query) == 0) {
    return("")
  }
  values = vapply(
    query,
    function(x) {
      if (!is.character(x)) {
        x = format(x, scientific = FALSE, trim = TRUE, justify = "none")
      }
      utils::URLencode(as.character(x), reserved = TRUE)
    },
    character(1)
  )
  paste0(names(query), "=", values, collapse = "&")
}

#' Parse a Supabase reply, raising its error message on HTTP >= 400
#'
#' @keywords internal
#' @noRd
si_parse_body = function(status, body_text) {
  status = as.integer(status)
  if (is.null(body_text) || length(body_text) == 0 || is.na(body_text)) {
    body_text = ""
  }

  if (is.na(status) || status >= 400 || status == 0L) {
    parsed_err = tryCatch(
      jsonlite::fromJSON(body_text, simplifyVector = FALSE),
      error = function(e) NULL
    )
    err_msg = if (is.list(parsed_err) && !is.null(parsed_err$message)) {
      as.character(parsed_err$message)
    } else if (is.list(parsed_err) && !is.null(parsed_err$msg)) {
      as.character(parsed_err$msg)
    } else if (is.list(parsed_err) && !is.null(parsed_err$error_description)) {
      as.character(parsed_err$error_description)
    } else if (is.list(parsed_err) && !is.null(parsed_err$error)) {
      as.character(parsed_err$error)
    } else if (nzchar(body_text)) {
      body_text
    } else {
      paste("HTTP", status)
    }
    cnd = structure(
      class = c("si_http_error", "error", "condition"),
      list(message = err_msg, call = NULL, status = status, body = body_text)
    )
    stop(cnd)
  }

  if (!nzchar(body_text)) {
    return(data.frame())
  }
  parsed = tryCatch(
    jsonlite::fromJSON(body_text, simplifyVector = TRUE),
    error = function(e) NULL
  )
  if (is.null(parsed)) {
    return(data.frame())
  }
  parsed
}

#' httr2 backend
#'
#' @keywords internal
#' @noRd
si_backend_httr2 = function(req) {
  r = httr2::request(req$url)
  r = httr2::req_method(r, req$method)
  r = do.call(httr2::req_headers, c(list(r), as.list(req$headers)))
  if (!is.null(req$body)) {
    r = httr2::req_body_raw(r, req$body, type = "application/json")
  }
  # Let si_parse_body() turn HTTP errors into Supabase's own message.
  r = httr2::req_error(r, is_error = function(resp) FALSE)
  resp = httr2::req_perform(r)
  body = if (httr2::resp_has_body(resp)) {
    tryCatch(httr2::resp_body_string(resp), error = function(e) "")
  } else {
    ""
  }
  list(status = httr2::resp_status(resp), body = body)
}

#' webR backend: synchronous XHR through webr::eval_js()
#'
#' @keywords internal
#' @noRd
si_backend_webr = function(req) {
  eval_js = tryCatch(
    getExportedValue("webr", "eval_js"),
    error = function(e) NULL
  )
  if (is.null(eval_js)) {
    stop(
      "The \"webr\" backend only works inside webR (it needs `webr::eval_js()`).",
      call. = FALSE
    )
  }
  out = eval_js(si_xhr_js(req))
  res = jsonlite::fromJSON(as.character(out), simplifyVector = TRUE)
  if (!is.null(res$error)) {
    stop("Network error: ", res$error, call. = FALSE)
  }
  list(status = as.integer(res$status), body = as.character(res$body %||% ""))
}

#' JavaScript for one synchronous XMLHttpRequest
#'
#' @keywords internal
#' @noRd
si_xhr_js = function(req) {
  js_string = function(x) as.character(jsonlite::toJSON(x, auto_unbox = TRUE))
  headers = if (length(req$headers)) as.list(req$headers) else structure(list(), names = character())
  paste0(
    "(function(){",
    "try {",
    "var x = new XMLHttpRequest();",
    "x.open(", js_string(req$method), ", ", js_string(req$url), ", false);",
    "var h = ", js_string(headers), ";",
    "for (var k in h) { x.setRequestHeader(k, h[k]); }",
    "x.send(", if (is.null(req$body)) "null" else js_string(req$body), ");",
    "return JSON.stringify({status: x.status, body: x.responseText});",
    "} catch (e) { return JSON.stringify({status: 0, error: String(e)}); }",
    "})()"
  )
}

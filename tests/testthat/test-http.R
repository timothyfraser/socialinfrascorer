test_that("si_perform sends method, url, headers and JSON body", {
  fake = fake_backend(body = '[{"theme":1,"type":"Park"}]')
  withr::local_options(socialinfrascorer.backend = fake$fn)

  out = si_perform(fake_client(), "/rest/v1/rpc/fn_get_themes", body = list())

  req = fake$calls()[[1]]
  expect_equal(req$method, "POST")
  expect_equal(req$url, "https://example.supabase.co/rest/v1/rpc/fn_get_themes")
  expect_equal(req$body, "[]")
  expect_equal(unname(req$headers[["apikey"]]), "anon-key")
  expect_equal(unname(req$headers[["Content-Type"]]), "application/json")
  expect_equal(unname(req$headers[["Authorization"]]), "Bearer anon-key")
  expect_equal(out, data.frame(theme = 1L, type = "Park"))
})

test_that("auth = TRUE uses the access token, auth = FALSE the anon key", {
  fake = fake_backend()
  withr::local_options(socialinfrascorer.backend = fake$fn)
  cl = fake_client(access_token = "user-jwt")

  si_perform(cl, "/a", auth = TRUE)
  si_perform(cl, "/b", auth = FALSE)
  si_perform(fake_client(), "/c", auth = TRUE)

  auths = vapply(fake$calls(), function(r) unname(r$headers[["Authorization"]]), character(1))
  expect_equal(auths, c("Bearer user-jwt", "Bearer anon-key", "Bearer anon-key"))
})

test_that("GET with query is encoded like httr2 and has no body", {
  fake = fake_backend(body = "[]")
  withr::local_options(socialinfrascorer.backend = fake$fn)

  si_perform(
    fake_client(),
    "/rest/v1/scorecard_result",
    method = "get",
    query = list(order = "computed_at.desc,id.desc", limit = 100L, skip = NULL, id = "eq.a b"),
    auth = TRUE
  )

  req = fake$calls()[[1]]
  expect_equal(req$method, "GET")
  expect_null(req$body)
  expect_equal(
    req$url,
    "https://example.supabase.co/rest/v1/scorecard_result?order=computed_at.desc%2Cid.desc&limit=100&id=eq.a%20b"
  )
})

test_that("NULL fields serialise as JSON null", {
  fake = fake_backend()
  withr::local_options(socialinfrascorer.backend = fake$fn)

  si_perform(fake_client(), "/x", body = list(p_state = NULL, p_limit = 5L))

  expect_equal(fake$calls()[[1]]$body, '{"p_state":null,"p_limit":5}')
})

test_that("errors carry Supabase's message and status", {
  withr::local_options(
    socialinfrascorer.backend = fake_backend(400L, '{"code":400,"msg":"Invalid login credentials"}')$fn
  )
  err = expect_error(si_perform(fake_client(), "/auth/v1/token"), "Invalid login credentials")
  expect_s3_class(err, "si_http_error")
  expect_equal(err$status, 400L)

  withr::local_options(socialinfrascorer.backend = fake_backend(404L, '{"message":"not found"}')$fn)
  expect_error(si_perform(fake_client(), "/x"), "not found", class = "si_http_error")

  withr::local_options(socialinfrascorer.backend = fake_backend(500L, "")$fn)
  expect_error(si_perform(fake_client(), "/x"), "HTTP 500", class = "si_http_error")
})

test_that("empty or non-JSON success bodies give an empty data frame", {
  withr::local_options(socialinfrascorer.backend = fake_backend(204L, "")$fn)
  expect_equal(si_perform(fake_client(), "/x"), data.frame())
})

test_that("si_backend picks custom, explicit, webR and httr2 in that order", {
  withr::local_options(socialinfrascorer.backend = function(req) NULL)
  expect_equal(si_backend(), "custom")

  withr::local_options(socialinfrascorer.backend = "webr")
  expect_equal(si_backend(), "webr")

  withr::local_options(socialinfrascorer.backend = "curl")
  expect_error(si_backend(), "must be")

  withr::local_options(socialinfrascorer.backend = NULL)
  local_mocked_bindings(si_has_httr2 = function() TRUE)
  expect_equal(si_backend(), "httr2")
})

test_that("a clear error when no backend is available", {
  withr::local_options(socialinfrascorer.backend = NULL)
  local_mocked_bindings(si_has_httr2 = function() FALSE)
  expect_error(si_backend(), "install.packages\\(\"httr2\"\\)")
})

test_that("the webR backend runs a synchronous XHR through eval_js", {
  req = si_build_request(fake_client("jwt"), "/rest/v1/rpc/fn_x", body = list(a = 1), auth = TRUE)
  js = si_xhr_js(req)
  expect_match(js, "x.open(\"POST\", \"https://example.supabase.co/rest/v1/rpc/fn_x\", false)", fixed = TRUE)
  expect_match(js, "\"Authorization\":\"Bearer jwt\"", fixed = TRUE)
  expect_match(js, "x.send(\"{\\\"a\\\":1}\")", fixed = TRUE)

  get_js = si_xhr_js(si_build_request(fake_client(), "/x", method = "GET"))
  expect_match(get_js, "x.send(null)", fixed = TRUE)
})

test_that("the webR backend fails clearly outside webR", {
  skip_if(nzchar(system.file(package = "webr")))
  expect_error(si_backend_webr(list()), "only works inside webR")
})

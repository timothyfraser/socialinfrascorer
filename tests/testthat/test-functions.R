test_that("reads that need a session point to sign_in()", {
  expect_error(get_sites(fake_client(), "1"), "Call `sign_in()` first", fixed = TRUE)
})

test_that("sign_in posts credentials to the token endpoint and keeps the token", {
  fake = fake_backend(body = '{"access_token":"jwt","refresh_token":"r","expires_in":3600,"token_type":"bearer"}')
  withr::local_options(socialinfrascorer.backend = fake$fn)

  auth = sign_in(fake_client(), "a@b.c", "pw")

  req = fake$calls()[[1]]
  expect_equal(req$url, "https://example.supabase.co/auth/v1/token?grant_type=password")
  expect_equal(req$body, '{"email":"a@b.c","password":"pw"}')
  expect_equal(auth$client$access_token, "jwt")
})

test_that("get_sites calls the RPC with the user's token", {
  fake = fake_backend(body = '[{"id":1,"source":"overture"}]')
  withr::local_options(socialinfrascorer.backend = fake$fn)

  sites = get_sites(fake_client("jwt"), " loc-1 ", limit = 5000)

  req = fake$calls()[[1]]
  expect_equal(req$url, "https://example.supabase.co/rest/v1/rpc/fn_get_sites_by_location_id")
  expect_equal(req$body, '{"p_location_id":"loc-1","p_limit":1000}')
  expect_equal(unname(req$headers[["Authorization"]]), "Bearer jwt")
  expect_s3_class(sites, "tbl_df")
  expect_equal(sites$source, "overture")
})

test_that("get_request_status is a GET with PostgREST filters", {
  fake = fake_backend(body = '[{"id":"abc","status":"success"}]')
  withr::local_options(socialinfrascorer.backend = fake$fn)

  get_request_status(fake_client("jwt"), "abc")

  req = fake$calls()[[1]]
  expect_equal(req$method, "GET")
  expect_equal(req$url, "https://example.supabase.co/rest/v1/requests?id=eq.abc&select=%2A&limit=1")
})

test_that("submit_request ignores retired arguments with a warning", {
  fake = fake_backend(body = '{"request":{"id":"r1"}}')
  withr::local_options(socialinfrascorer.backend = fake$fn)
  geom = list(type = "Polygon", coordinates = list(list(c(0, 0), c(0, 1), c(1, 1), c(0, 0))))

  expect_warning(
    submit_request(fake_client("jwt"), geom, sites_grid_sqkm = 2, n_keywords = 10),
    "ignored: sites now come from Overture Maps"
  )
  body = jsonlite::fromJSON(fake$calls()[[1]]$body, simplifyVector = FALSE)
  expect_false(any(c("p_sites_grid_sqkm", "p_n_keywords") %in% names(body)))
  expect_equal(body$p_country, "US")

  expect_error(submit_request(fake_client("jwt"), geom, bogus = 1), "Unused argument")
  expect_no_warning(submit_request(fake_client("jwt"), geom, name = "x"))
})

test_that("the theme helpers are internal", {
  exports = getNamespaceExports("socialinfrascorer")
  expect_false(any(c("get_themes", "get_theme_keywords") %in% exports))
  expect_true(is.function(get_themes))
})

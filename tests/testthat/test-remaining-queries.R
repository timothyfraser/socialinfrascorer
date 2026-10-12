# Tests for get_remaining_queries() against the fn_fair_use_status RPC.
# HTTP is mocked with httr2::local_mocked_responses(); nothing hits the network.

fake_url = "https://example.supabase.co"

authed_client = function() {
  si_client(fake_url, anon_key = "anon-key", access_token = "user-token")
}

# Build a mocked JSON response from a literal JSON string.
json_response = function(json, status = 200L, url = fake_url) {
  httr2::response(
    status_code = status,
    url = url,
    method = "POST",
    headers = list(`Content-Type` = "application/json"),
    body = charToRaw(json)
  )
}

free_tier_json = '{
  "tier": "free",
  "display_name": "Free",
  "limits": {"concurrent": 3, "per_hour": 30, "per_day": 200,
             "km2_per_hour": 15000, "km2_per_day": 50000, "waiting": 10},
  "usage": {"running": 1, "waiting": 2, "hour_requests": 4,
            "hour_km2": 120.5, "day_requests": 37, "day_km2": 980.25},
  "resets": {"hour_at": "2026-10-11T15:30:00+00:00",
             "day_at": "2026-10-12T09:00:00.123456+00:00"}
}'

unlimited_json = '{
  "tier": "developer",
  "display_name": "Developer",
  "limits": {"concurrent": -1, "per_hour": -1, "per_day": -1,
             "km2_per_hour": -1, "km2_per_day": -1, "waiting": -1},
  "usage": {"running": 0, "waiting": 0, "hour_requests": 12,
            "hour_km2": 0, "day_requests": 450, "day_km2": 0},
  "resets": {"hour_at": null, "day_at": null}
}'

test_that("calls fn_fair_use_status with an empty JSON object body", {
  seen = new.env()
  httr2::local_mocked_responses(function(req) {
    seen$url = req$url
    seen$body = as.character(jsonlite::toJSON(req$body$data, auto_unbox = TRUE))
    json_response(free_tier_json)
  })

  get_remaining_queries(authed_client())

  expect_equal(seen$url, paste0(fake_url, "/rest/v1/rpc/fn_fair_use_status"))
  expect_equal(seen$body, "{}")
})

test_that("flattens the free-tier response and computes remaining counts", {
  httr2::local_mocked_responses(function(req) json_response(free_tier_json))

  out = get_remaining_queries(authed_client())

  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 1L)
  expect_named(out, c(
    "tier", "display_name",
    "per_day", "day_requests", "remaining_today",
    "per_hour", "hour_requests", "remaining_this_hour",
    "km2_per_day", "day_km2", "km2_per_hour", "hour_km2",
    "concurrent", "running", "waiting_limit", "waiting",
    "hour_resets_at", "day_resets_at"
  ))

  expect_equal(out$tier, "free")
  expect_equal(out$display_name, "Free")
  expect_equal(out$per_day, 200)
  expect_equal(out$day_requests, 37)
  expect_equal(out$remaining_today, 163)
  expect_equal(out$per_hour, 30)
  expect_equal(out$hour_requests, 4)
  expect_equal(out$remaining_this_hour, 26)
  expect_equal(out$km2_per_day, 50000)
  expect_equal(out$day_km2, 980.25)
  expect_equal(out$km2_per_hour, 15000)
  expect_equal(out$hour_km2, 120.5)
  expect_equal(out$concurrent, 3)
  expect_equal(out$running, 1)
  expect_equal(out$waiting_limit, 10)
  expect_equal(out$waiting, 2)

  expect_s3_class(out$hour_resets_at, "POSIXct")
  expect_equal(
    out$hour_resets_at,
    as.POSIXct("2026-10-11 15:30:00", tz = "UTC")
  )
  expect_equal(
    as.numeric(out$day_resets_at),
    as.numeric(as.POSIXct("2026-10-12 09:00:00", tz = "UTC")) + 0.123456,
    tolerance = 1e-6
  )
})

test_that("unlimited limits (-1) become NA, and so do their remaining counts", {
  httr2::local_mocked_responses(function(req) json_response(unlimited_json))

  out = get_remaining_queries(authed_client())

  expect_equal(out$tier, "developer")
  for (col in c("per_day", "per_hour", "km2_per_day", "km2_per_hour",
                "concurrent", "waiting_limit", "remaining_today",
                "remaining_this_hour")) {
    expect_true(is.na(out[[col]]), info = col)
  }
  # Usage is still reported for unlimited accounts.
  expect_equal(out$day_requests, 450)
  expect_equal(out$hour_requests, 12)
  # Null reset times come back as NA POSIXct.
  expect_s3_class(out$hour_resets_at, "POSIXct")
  expect_true(is.na(out$hour_resets_at))
  expect_true(is.na(out$day_resets_at))
})

test_that("remaining counts never go below zero", {
  over_json = sub('"day_requests": 37', '"day_requests": 250', free_tier_json)
  over_json = sub('"hour_requests": 4', '"hour_requests": 31', over_json)
  httr2::local_mocked_responses(function(req) json_response(over_json))

  out = get_remaining_queries(authed_client())

  expect_equal(out$remaining_today, 0)
  expect_equal(out$remaining_this_hour, 0)
})

test_that("requires a signed-in client", {
  anon = si_client(fake_url, anon_key = "anon-key")
  expect_error(get_remaining_queries(anon), "authenticated user")
})

test_that("server errors are surfaced", {
  httr2::local_mocked_responses(function(req) {
    json_response('{"message": "JWT expired"}', status = 401L)
  })
  expect_error(get_remaining_queries(authed_client()), "401")
})

test_that("timestamps with non-UTC offsets are converted to UTC", {
  expect_equal(
    si_parse_timestamp("2026-10-11T11:30:00-04:00"),
    as.POSIXct("2026-10-11 15:30:00", tz = "UTC")
  )
  expect_equal(
    si_parse_timestamp("2026-10-11T15:30:00Z"),
    as.POSIXct("2026-10-11 15:30:00", tz = "UTC")
  )
  expect_true(is.na(si_parse_timestamp(NULL)))
  expect_true(is.na(si_parse_timestamp("not a time")))
})

test_that("si_change_subscription() has been removed", {
  ns = asNamespace("socialinfrascorer")
  expect_false(exists("si_change_subscription", envir = ns, inherits = FALSE))
  expect_false(exists("change_subscription", envir = ns, inherits = FALSE))
})

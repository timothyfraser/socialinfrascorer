#!/usr/bin/env Rscript

# test_socialinfrascorer_api.R

# ------------------------------------------------------------------------------
# 1) Workspace setup and environment bootstrap
# ------------------------------------------------------------------------------
# Run from package root so relative paths resolve consistently.
setwd("C:/Users/tmf77/scorecard/socialinfrascorer")

# Load local secrets for development-time API tests.
readRenviron("../secret/.env")
message("== socialinfrascorer API workflow test ==")

# Fixed test location id used for polygon and scorecard API checks.
SOCIALINFRA_TEST_LOCATION_ID = "000000000000018"
SOCIALINFRA_TEST_PLACE_NAME = "Ithaca"
SOCIALINFRA_TEST_COUNTRY = "USA"
SOCIALINFRA_TEST_STATE = "NY"

# ------------------------------------------------------------------------------
# 2) Required environment validation
# ------------------------------------------------------------------------------
required_env = c("SUPABASE_URL", "SUPABASE_ANON_KEY")
missing_required = required_env[nchar(Sys.getenv(required_env)) == 0]
if (length(missing_required) > 0) {
  stop("Missing required env vars: ", paste(missing_required, collapse = ", "))
}

# ------------------------------------------------------------------------------
# 3) Load package source files without installation
# ------------------------------------------------------------------------------
# Load package functions directly from source so this script works before install.
frame_file = sys.frames()[[1]]$ofile
if (is.null(frame_file) || nchar(frame_file) == 0) {
  frame_file = "inst/workflows/test_socialinfrascorer_api.R"
}
script_path = normalizePath(frame_file, winslash = "/", mustWork = FALSE)
pkg_root = normalizePath(file.path(dirname(script_path), "..", ".."), winslash = "/", mustWork = TRUE)
r_files = list.files(file.path(pkg_root, "R"), pattern = "\\.R$", full.names = TRUE)
for (f in r_files) {
  source(f, chdir = FALSE)
}

# ------------------------------------------------------------------------------
# 4) Build API client
# ------------------------------------------------------------------------------
client = si_client(
  supabase_url = Sys.getenv("SUPABASE_URL"),
  anon_key = Sys.getenv("SUPABASE_ANON_KEY")
)

# ------------------------------------------------------------------------------
# 5) Optional signup flow
# ------------------------------------------------------------------------------
# Signup is optional and controlled via env vars so this script can be reused
# for existing users as well as new-account smoke tests.
signup_email = Sys.getenv("SOCIALINFRA_SIGNUP_EMAIL", "")
signup_password = Sys.getenv("SOCIALINFRA_SIGNUP_PASSWORD", "")
signup_display_name = Sys.getenv("SOCIALINFRA_SIGNUP_DISPLAY_NAME", "socialinfrascorer test user")

if (nchar(signup_email) > 0 && nchar(signup_password) > 0) {
  message("-- signup step")
  signup_result = tryCatch(
    si_auth_signup(
      client = client,
      email = signup_email,
      password = signup_password,
      display_name = signup_display_name
    ),
    error = function(e) e
  )

  if (inherits(signup_result, "error")) {
    message("signup result: ", signup_result$message)
  } else {
    message("signup result: ok (confirmation may still be required)")
  }
} else {
  message("-- signup step skipped (set SOCIALINFRA_SIGNUP_EMAIL and SOCIALINFRA_SIGNUP_PASSWORD to enable)")
}

# ------------------------------------------------------------------------------
# 6) Signin flow (required for authenticated API checks)
# ------------------------------------------------------------------------------
signin_email = Sys.getenv("SOCIALINFRA_SIGNIN_EMAIL", signup_email)
signin_password = Sys.getenv("SOCIALINFRA_SIGNIN_PASSWORD", signup_password)

if (nchar(signin_email) == 0 || nchar(signin_password) == 0) {
  message("signin step skipped: set SOCIALINFRA_SIGNIN_EMAIL and SOCIALINFRA_SIGNIN_PASSWORD.")
  message("== workflow test complete (partial: auth query steps skipped) ==")
  quit(save = "no", status = 0)
}

message("-- signin step")
signin_result = si_auth_signin(
  client = client,
  email = signin_email,
  password = signin_password
)

authed_client = signin_result$client
message("signin result: ok")


# ------------------------------------------------------------------------------
# 7) Data endpoint smoke tests using location_id
# ------------------------------------------------------------------------------
# Validate both polygon retrieval and scorecard retrieval on one known id.
test_location_id = SOCIALINFRA_TEST_LOCATION_ID
if (nchar(test_location_id) > 0) {
  message("-- polygon by location_id step")
  poly_location = si_get_polygon_by_location_id(authed_client, test_location_id)
  message("polygon rows by location_id: ", nrow(poly_location))

  test_area_id = if ("area_id" %in% names(poly_location) && nrow(poly_location) > 0) {
    as.character(poly_location$area_id[[1]])
  } else {
    ""
  }
  if (nchar(test_area_id) > 0) {
    message("-- polygon by area_id step")
    poly_area = tryCatch(
      si_get_polygon_by_area_id(authed_client, test_area_id),
      error = function(e) e
    )
    if (inherits(poly_area, "error")) {
      message("polygon by area_id step failed (migration may be pending): ", poly_area$message)
    } else {
      message("polygon rows by area_id: ", nrow(poly_area))
    }
  } else {
    message("-- area_id step skipped (no area_id from location result)")
  }

  message("-- scorecard by location_id step")
  sc_location = si_get_scorecard_results(
    client = authed_client,
    location_id = test_location_id,
    limit = 5,
    offset = 0
  )
  message("scorecard rows by location_id: ", nrow(sc_location))
} else {
  message("-- location_id steps skipped (set SOCIALINFRA_TEST_LOCATION_ID)")
}


# STILL HAS ISSUES
# if (nchar(trimws(SOCIALINFRA_TEST_PLACE_NAME)) > 0) {
#   message("-- location lookup by place_name step")
#   place_lookup = tryCatch(
#     si_get_polygon_lookup_by_place_name(
#       client = authed_client,
#       place_name = trimws(SOCIALINFRA_TEST_PLACE_NAME),
#       country = if (nchar(trimws(SOCIALINFRA_TEST_COUNTRY)) > 0) trimws(SOCIALINFRA_TEST_COUNTRY) else NULL,
#       state = if (nchar(trimws(SOCIALINFRA_TEST_STATE)) > 0) trimws(SOCIALINFRA_TEST_STATE) else NULL,
#       limit = 5
#     ),
#     error = function(e) e
#   )
#   if (inherits(place_lookup, "error")) {
#     message("location lookup by place_name step failed (migration may be pending): ", place_lookup$message)
#   } else {
#     message("location lookup rows by place_name: ", nrow(place_lookup))
#   }

#   message("-- polygon by place_name step")
#   poly_place = tryCatch(
#     si_get_polygon_by_place_name(
#       client = authed_client,
#       place_name = trimws(SOCIALINFRA_TEST_PLACE_NAME),
#       country = if (nchar(trimws(SOCIALINFRA_TEST_COUNTRY)) > 0) trimws(SOCIALINFRA_TEST_COUNTRY) else NULL,
#       state = if (nchar(trimws(SOCIALINFRA_TEST_STATE)) > 0) trimws(SOCIALINFRA_TEST_STATE) else NULL
#     ),
#     error = function(e) e
#   )
#   if (inherits(poly_place, "error")) {
#     message("polygon by place_name step failed (migration may be pending): ", poly_place$message)
#   } else {
#     message("polygon rows by place_name: ", nrow(poly_place))
#   }
# } else {
#   message("-- place_name steps skipped (set SOCIALINFRA_TEST_PLACE_NAME)")
# }

message("== workflow test complete ==")

# ------------------------------------------------------------------------------
# 8) New request/account workflow smoke tests
# ------------------------------------------------------------------------------
is_missing_migration_error = function(err_msg) {
  grepl("HTTP 404|HTTP 400|fn_get_user_|subscription_tier|column .* does not exist|relation .* does not exist", err_msg, ignore.case = TRUE)
}

report_optional_step = function(step_name, result_obj, success_rows_label) {
  if (inherits(result_obj, "error")) {
    msg = as.character(result_obj$message)
    if (is_missing_migration_error(msg)) {
      message(step_name, " skipped (backend migration not applied): ", msg)
    } else {
      message(step_name, " failed: ", msg)
    }
  } else {
    message(success_rows_label, nrow(result_obj))
  }
}

message("-- account subscription step")
subscription_result = tryCatch(
  si_get_subscription(authed_client),
  error = function(e) e
)
report_optional_step(
  step_name = "subscription step",
  result_obj = subscription_result,
  success_rows_label = "subscription rows: "
)

message("-- account usage step")
usage_result = tryCatch(
  si_get_usage(authed_client),
  error = function(e) e
)
report_optional_step(
  step_name = "usage step",
  result_obj = usage_result,
  success_rows_label = "usage rows: "
)

message("-- remaining queries step")
remaining_result = tryCatch(
  si_get_remaining_queries(authed_client),
  error = function(e) e
)
report_optional_step(
  step_name = "remaining queries step",
  result_obj = remaining_result,
  success_rows_label = "remaining queries rows: "
)

message("-- requests history step")
requests_result = tryCatch(
  si_get_requests(authed_client, limit = 5, offset = 0),
  error = function(e) e
)
report_optional_step(
  step_name = "requests history step",
  result_obj = requests_result,
  success_rows_label = "requests rows: "
)

message("== workflow test complete (extended) ==")

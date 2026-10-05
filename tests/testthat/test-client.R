test_that("client() with no arguments uses the built-in public defaults", {
  withr::local_envvar(SI_SUPABASE_URL = NA, SI_SUPABASE_ANON_KEY = NA)
  cl = client()
  expect_equal(cl$supabase_url, "https://annuvayiqynyksnzkpoy.supabase.co")
  expect_equal(cl$anon_key, "sb_publishable_SS0DtvFh990Zcj-6q7t4nw_VRdCF_Vb")
  expect_null(cl$access_token)
  expect_s3_class(cl, "si_client")
})

test_that("SI_SUPABASE_* environment variables override the defaults", {
  withr::local_envvar(
    SI_SUPABASE_URL = "https://self-hosted.example.com/",
    SI_SUPABASE_ANON_KEY = "env-key"
  )
  cl = client()
  expect_equal(cl$supabase_url, "https://self-hosted.example.com")
  expect_equal(cl$anon_key, "env-key")
})

test_that("empty environment variables fall back to the defaults", {
  withr::local_envvar(SI_SUPABASE_URL = "", SI_SUPABASE_ANON_KEY = "")
  expect_equal(client()$supabase_url, "https://annuvayiqynyksnzkpoy.supabase.co")
})

test_that("explicit arguments beat the environment, and positional calls still work", {
  withr::local_envvar(SI_SUPABASE_URL = "https://env.example.com", SI_SUPABASE_ANON_KEY = "env-key")
  cl = client("https://arg.example.com", "arg-key")
  expect_equal(cl$supabase_url, "https://arg.example.com")
  expect_equal(cl$anon_key, "arg-key")
})

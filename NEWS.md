# socialinfrascorer 0.2.0

## Breaking changes

* `get_remaining_queries()` now reports the platform's fair-use limits instead
  of a monthly quota. It calls the `fn_fair_use_status` RPC (replacing
  `fn_get_user_remaining_queries`) and returns a one-row tibble with `tier`,
  `display_name`, request limits and usage per day and per hour
  (`remaining_today`, `remaining_this_hour`), area limits and usage in square
  kilometers, running and waiting counts, and when the hourly and daily windows
  reset (`hour_resets_at`, `day_resets_at`, POSIXct UTC). Free-tier limits are
  200 requests per day, 30 per hour, 50,000 sq km per day, 15,000 sq km per
  hour, and 3 running at once. A server limit of `-1` (unlimited) is returned
  as `NA`.
* Removed the internal `si_change_subscription()`. Tiers are assigned
  server-side and cannot be changed from the client.

## Other changes

* Added a testthat suite with mocked HTTP responses (`httr2 >= 1.0.0`).
* Documentation and vignettes no longer describe monthly quotas.

# socialinfrascorer 0.1.0

* Initial release.

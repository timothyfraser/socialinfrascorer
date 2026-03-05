# socialinfrascorer

Small R client package for read-only access to selected SCORECARD Supabase data.

## What it does

- Creates and authenticates users via Supabase Auth.
- Downloads one bounds polygon by `osm_id`.
- Downloads one bounds polygon by `location_id` using a secure RPC.
- Downloads `scorecard_result` records for an area with a hard max of 100 rows per request.

## Dependencies

- `httr2` for HTTP requests
- `curl` for HTTP runtime compatibility
- `dplyr` for tidy tabular returns

## Quick start

```r
library(socialinfrascorer)

client = si_client(
  supabase_url = Sys.getenv("SUPABASE_URL"),
  anon_key = Sys.getenv("SUPABASE_ANON_KEY")
)

# Sign in first (required for download queries)
auth = si_auth_signin(
  client = client,
  email = Sys.getenv("SOCIALINFRA_EMAIL"),
  password = Sys.getenv("SOCIALINFRA_PASSWORD")
)
authed_client = auth$client

poly = si_get_polygon_by_osm_id(authed_client, osm_id = 5128581)
scores = si_get_scorecard_results(authed_client, osm_id = 5128581, limit = 100)
```

## Test workflow script

Run:

```r
source("inst/workflows/test_socialinfrascorer_api.R")
```

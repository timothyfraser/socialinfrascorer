README workflows

Our system needs to support the following operations


### User Read-Only Workflow

- User searches location by place name
- User searches location by osm_id
- User searches location by location_id
- User searches location by area_id
- User queries polygon by location_id
- User queries social infrastructure sites located within location_id, up to a limited number of sites (eg. 1000) - if more than 1000, take a random sample of 1000 sites within that polygon location_id and return that.
- User queries social infrastructure scorecard for location_id

### User Request Workflow

- User places request for scorecard for new polygon not yet supported.
   - User must supply a valid sf polygon/multi-polygon of less than a specific area size limit, formatted with crs 4326.
   - If polygon was valid, then we upload the polygon to bounds and automatically get it a location entry in the public.location table. (Check and see if there is an existing trigger or something first).
   - We log the request in our database, including user id, request timestamp, request id, and location_id of request polygon. Add also logical fields for 'grid', 'sites', and 'scorecard'. These start as FALSE but will be flipped to TRUE, one by one, as sites get added to the sites table for that location_id, as grid cells get added to the neighborhood_grid_cache for that location_id, and as a scorecard row gets added to the scorecard_result table for that location id. These values will be used as triggers later on for several of those processes. Also add a 'status' and 'update_time'. Also add an 'area' entry (area in square kilometers of the polygon) and a 'n_keywords' entry (default 10). This will help us keep track of how much geospatial data we are being asked to process.
   - We get the population density grid for that neighborhood polygon, by doing the following steps:
      - Using bounding box of that neighborhood polygon, we extract the regional population raster for the current year, cropped to extent of the neighborhood polygon (linked to location_id).
         - If this is really fast, then we can just use public.neighborhood_raster_cache as a staging ground.
      - We convert that raster into a grid of 1 square kilometer cells (linked to location_id).
         - We can save this to public.neighborhood_grid_cache
      - When this is complete, set the 'grid' field value for that request entry to TRUE. This will trigger the sites ingestion process. Database should ping our REST API via HTTP GET request (edge function?) to go query Google Places API via api/routes_ingest.R and jobs/ingest_places.R. This will take a while.
         - note: api/routes_ingest.R and jobs/ingest_places.R are currently configured to use a local file of grid cells, but in the future, they should use public.neighborhood_grid_cache.
      - When this data ingest process is complete (could take a few minutes), set the entry in the request table for field 'sites' to TRUE. This will trigger the scorecard calculation process. Database should ping our REST API via HTTP GET request (edge function?) to go calculate the scorecard. This will take a few seconds. In this API endpoint job,
         - for the given location associated with that request,
            - return bounds for that location_id
            - return sites for that location_id
            - return grid with population for that location_id
            - calculate density
            - calculate diversity
            - calculate dispersion
            - calculate scorecard
            - upload scorecard entry to database
            - set 'scorecard' field in requests table entry to TRUE, indicating that the request is now complete. Set 'status' to 'success' with the current time as 'update_time'.
      - This whole process probably takes a few minutes, so it would be good for there to be some kind of callback system in place so that the user can keep on coding 


### Account Management

- User signs up
- User logs in
- User resets password
- User deletes account
- User checks their requests history via 'requests' table, where they only see rows pertaining to their userid.
   - The 'area' and 'n_keywords' fields in the 'requests' table can be multiplied to describe how many total square kilometer queries we have run with Google Places API. This essentially is our cost metric.
- User checks total number of requests and 'n_queries' (total square kilometer queries), aggregated per month, within a user provided time frame - defaults to last six months.
- Check user's subscription tier.
   - Note: every user has a subscription tier. For now, just use 'free' and 'developer', where 'free' gets to query, let's say, a max of n_queries = 100 per month. 'developer' (describes the team currently developing the API and package) gets to query and unlimited amount. Default user subscription is 'free'
- Change user's subscription tier (protected action, only the private api can do this)
- Check how many n_queries are **remaining** this month for user X. Requires there to be a subscriptions metadata table that records how many queries are allowed per month, with a unique subscription id matching the one assigned to each user on signup.

## Implemented client functions

- Auth:
  - `si_auth_signup()`
  - `si_auth_signin()`
  - `si_auth_reset_password()`
  - `si_auth_delete_account()`
- Polygon lookup:
  - `si_get_polygon_by_osm_id()`
  - `si_get_polygon_by_location_id()`
  - `si_get_polygon_by_area_id()`
  - `si_get_polygon_lookup_by_place_name()`
  - `si_get_polygon_by_place_name()`
- Sites and scorecard:
  - `si_get_sites_by_location_id()`
  - `si_get_scorecard_results()`
- Request workflow:
  - `si_submit_request()`
  - `si_get_request_status()`
  - `si_get_requests()`
- Usage and subscription:
  - `si_get_subscription()`
  - `si_get_usage()`
  - `si_get_remaining_queries()`
  - `si_change_subscription()`

## Testing note

- `si_get_subscription()`, `si_get_usage()`, `si_get_remaining_queries()`, and `si_get_requests()` are Supabase-native reads.
- They do not require `SCORECARD_API_URL`.
- They do require database migrations `00016`, `00017`, and `00018` to be applied.

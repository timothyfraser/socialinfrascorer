# `socialinfrascorer`
<h3><b>Map Social Infrastructure in Your Neighborhood</b></h3>

---

<!-- badges: start -->
<!-- badges: end -->

<img src="man/figures/logo.png" align="right" height="500" alt="socialinfrascorer logo" class="si-home-logo" />

**`socialinfrascorer`** lets you use the [Social Infrastructure Scorecard](articles/dashboard.html) from R.
View social infrastructure sites (parks, community spaces, places of worship, and more),
request scorecards for new areas, and download results for analysis.

> Looking for Python? A companion package,
> **`socialinfrascorepy`**, is coming soon.

## Installation

```r
# Install from GitHub (requires devtools or remotes)
devtools::install_github("timothyfraser/socialinfrascorer")
```

## Quick start

```r
library(socialinfrascorer)

# 1. Create a client
cli = client(
  Sys.getenv("SUPABASE_URL"),
  Sys.getenv("SUPABASE_ANON_KEY")
)

# 2. Sign in
auth = sign_in(cli, Sys.getenv("EMAIL"), Sys.getenv("PASSWORD"))
authed = auth$client

# 3. Look up a neighborhood boundary
poly = get_boundary_by_osm_id(authed, osm_id = 5128581)

# 4. Get the scorecard
scores = get_scorecard(authed, osm_id = 5128581)
```

See `vignette("get-started")` for a more detailed walkthrough.

## Example query and output

```r
# Example: retrieve a boundary by place name
boundary = get_boundary_by_place_name(
  authed,
  query = "Ithaca",
  state = "NY"
)
```

Expected output (sample):

```text
# A tibble: 1 x 8
  location_id osm_id  place_name county state country area_km2 geom_type
        84217 5128581 Ithaca     Tompkins NY    US       15.41 Polygon
```

## Example Site Types

<div class="si-gallery" aria-label="Example social infrastructure site types">
  <figure>
    <img src="https://images.unsplash.com/photo-1570205498164-9beb7461ed17?q=80&w=1978&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
         alt="Tree-lined urban area"
         title="Photo from Unsplash: https://images.unsplash.com/photo-1570205498164-9beb7461ed17" />
    <figcaption><a href="https://unsplash.com/photos/basketball-court-JdztKZQ-Prs">Sports Courts</a></figcaption>
  </figure>

  <figure>
    <img src="https://images.unsplash.com/photo-1716582873749-f4fb77fe9957?q=80&w=2340&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
         alt="Community-centered public environment"
         title="Photo from Unsplash: https://images.unsplash.com/photo-1716582873749-f4fb77fe9957" />
    <figcaption><a href="https://unsplash.com/photos/a-group-of-people-sitting-on-top-of-a-park-bench-oTepYAkRp_c">Park</a></figcaption>
  </figure>

  <figure>
    <img src="https://images.unsplash.com/photo-1764173039117-e1ef87b26ec4?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
         alt="Neighborhood activity space"
         title="Photo from Unsplash: https://images.unsplash.com/photo-1716654716581-3c92ba53de10" />
    <figcaption><a href="https://unsplash.com/photos/two-women-looking-at-a-book-in-library-xlG0HM4RG6I">Library</a></figcaption>
  </figure>

  <figure>
    <img src="https://images.unsplash.com/photo-1716654716581-3c92ba53de10?q=80&w=1478&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
         alt="Neighborhood activity space"
         title="Photo from Unsplash: https://images.unsplash.com/photo-1716654716581-3c92ba53de10" />
    <figcaption><a href="https://unsplash.com/photos/a-couple-of-people-that-are-looking-at-a-laptop-KBPP21-bg3o">Community Center</a></figcaption>
  </figure>

  <figure>
    <img src="https://images.unsplash.com/photo-1649451898726-1ed602692cec?q=80&w=1470&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
        alt="Place of Worship" 
        title = "Photo from Unspalsh: https://images.unsplash.com/photo-1649451898726-1ed602692cec"/>
    <figcaption><a href="https://unsplash.com/photos/a-couple-of-little-girls-standing-next-to-each-other-zCdwnXypWnY">Place of Worship</a></figcaption>
  </figure>

  <figure>
    <img src="https://images.unsplash.com/photo-1485182708500-e8f1f318ba72?q=80&w=2410&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
         alt="Public gathering location"
         title="Photo from Unsplash: https://images.unsplash.com/photo-1485182708500-e8f1f318ba72" />
    <figcaption><a href="https://unsplash.com/photos/people-eating-inside-of-cafeteria-during-daytime-6bKpHAun4d8">Cafe</a></figcaption>
  </figure>


  <figure>
    <img src="https://images.unsplash.com/photo-1524247108137-732e0f642303?q=80&w=2071&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
         alt="Public Gardening"
         title="Photo from Unsplash: https://images.unsplash.com/photo-1524247108137-732e0f642303" />
    <figcaption><a href="https://unsplash.com/photos/three-people-planting-flowers-qo6_mo9dsYg">Gardens</a></figcaption>
  </figure>

  <figure>
    <img src="https://images.unsplash.com/photo-1568971316801-980eea553e6e?q=80&w=2070&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D"
         alt="Public Fountain"
         title="Photo from Unsplash: https://images.unsplash.com/photo-1568971316801-980eea553e6e" />
    <figcaption><a href="https://unsplash.com/photos/mens-black-and-white-crew-neck-t-shirt-JwGUm8yQLUA">Fountains</a></figcaption>
  </figure>



</div>

## Key capabilities

| Area | Functions |
|------|-----------|
| **Auth** | `sign_up()`, `sign_in()`, `send_password_reset()`, `delete_account()` |
| **Boundaries** | `search_locations()`, `get_boundary_by_osm_id()`, `get_boundary_by_place_name()`, ... |
| **Themes** | `get_themes()`, `get_theme_keywords()` |
| **Requests** | `submit_request()`, `get_request_status()`, `get_requests()` |
| **Scorecard** | `get_scorecard()`, `get_sites()` |
| **Account** | `get_subscription()`, `get_usage()`, `get_remaining_queries()` |

---

## Environment variables

To use the package and query our database, you will need to set two environmental variables.
Get your keys from the Social Infrastructure Dashboard!

| Variable | Required | Purpose |
|----------|----------|---------|
| `SUPABASE_URL` | Always | Supabase project URL |
| `SUPABASE_ANON_KEY` | Always | Supabase anon/publishable key |

---

## Methodology

The querying strategy behind Mapping Social Infrastructure is based on
the methodology described in:

> Fraser, T., Cherdchaiyapong, N., Tekle, W., Thomas, E., Zayas, J., Page-Tan, C., & Aldrich, D. P. (2022). Trust but verify: Validating new measures for mapping social infrastructure in cities. Urban Climate, 46, 101287.
> <https://doi.org/10.1016/j.uclim.2022.101287>

The scorecard design strategy behind the Social Infrastructure Scorecard is based on the methods described in:

> Fraser, T., Chen, S., Yin, C., Zhang, X., & Aldrich, D. P. (2025). Urban Anchors, Climate Shocks: Measuring Social Infrastructure and their Exposure to Natural Hazards in U.S. Cities. Cornell Systems Studio.
> DOI forthcoming.


The scorecard measures three dimensions of social infrastructure in a
neighborhood: **density** (how many facilities exist), **diversity** (the
variety of facility types), and **dispersion** (how evenly facilities are
spread across the area). These are combined into a composite letter-grade
score.

---

## Credits

**`socialinfrascorer`** is developed by
**Tim Fraser** and **Nabira Ahmad**.

> For questions, please contact package maintainer **Tim Fraser** at <tmf77@cornell.edu>.

---

## License

> **`socialinfrascorer` Source-Available License v1.0**. 
> You may use unmodified copies,
> but modification and distribution of modified versions are not permitted.
> See [`LICENSE`](LICENSE).

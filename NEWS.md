# socialinfrascorer (development version)

* Every request now goes through one internal HTTP choke point. httr2 moves from Imports to Suggests: desktop R still uses it (install it with `install.packages("httr2")`), and inside webR the package switches to a browser backend that sends a synchronous `XMLHttpRequest` through `webr::eval_js()`. Choose one explicitly with `options(socialinfrascorer.backend = "httr2")` or `"webr"`.
* HTTP errors now report Supabase's own message (for example "Invalid login credentials") as an `si_http_error` condition, instead of httr2's generic "HTTP 400 Bad Request".
* Sites come from Overture Maps (open data); the documentation no longer describes keyword search.
* The authentication error now tells you to call `sign_in()` (it named a function that does not exist).
* `get_themes()` and `get_theme_keywords()` are no longer exported. They remain available as `socialinfrascorer:::get_themes()` and `socialinfrascorer:::get_theme_keywords()`.
* `submit_request()` no longer documents `sites_grid_sqkm` or `n_keywords`. Both are still accepted by name and ignored with a warning; pass the remaining arguments by name, since `n_keywords` was the third positional argument.

# socialinfrascorer 0.1.0

* Initial release: Supabase Auth and PostgREST client (sign-up/sign-in, polygon lookup, request submission, scorecard and sites, account and usage).

#!/usr/bin/env Rscript

if (!requireNamespace("pkgdown", quietly = TRUE)) {
  stop("Please install pkgdown first: install.packages('pkgdown')", call. = FALSE)
}

pkg <- if (basename(getwd()) == "socialinfrascorer") "." else "socialinfrascorer"
#pkgdown::preview_site(pkg)

# -------------------------------------------------------------------
# buildme (quick recompiles) -- keep commented until needed
# -------------------------------------------------------------------
# if (!requireNamespace("devtools", quietly = TRUE)) {
#   stop("Please install devtools first: install.packages('devtools')", call. = FALSE)
# }
# if (!requireNamespace("pkgdown", quietly = TRUE)) {
#   stop("Please install pkgdown first: install.packages('pkgdown')", call. = FALSE)
# }

# pkg <- if (basename(getwd()) == "socialinfrascorer") "." else "socialinfrascorer"

# # 1) Regenerate Rd/NAMESPACE from roxygen comments
# devtools::document(pkg)

# # 2) Fast docs refresh (reference pages only)
# pkgdown::build_reference(pkg)

# # 3) Full docs rebuild (home + articles + reference)
# pkgdown::build_site(pkg)

# pkgdown::build_home_index(pkg)

# # 4) Preview rebuilt site locally
# pkgdown::preview_site(pkg)

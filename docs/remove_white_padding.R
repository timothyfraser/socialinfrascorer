#!/usr/bin/env Rscript

suppressPackageStartupMessages(library(magick))

trim_white_padding = function(infile, outfile, fuzz = 12) {
  img = image_read(infile)
  info = image_info(img)
  w = info$width[[1]]
  h = info$height[[1]]

  # Remove near-white area connected to the edges/corners.
  corner_points = c(
    "+1+1",
    sprintf("+%d+1", w - 2),
    sprintf("+1+%d", h - 2),
    sprintf("+%d+%d", w - 2, h - 2)
  )

  for (pt in corner_points) {
    img = image_fill(img, color = "none", point = pt, fuzz = fuzz)
  }

  img = image_trim(img)
  image_write(img, path = outfile, format = "png")
  invisible(outfile)
}

main = function() {
  args = commandArgs(trailingOnly = TRUE)
  infile = if (length(args) >= 1) args[[1]] else "socialinfrascorer/docs/icon_r.png"
  outfile = if (length(args) >= 2) args[[2]] else "socialinfrascorer/docs/icon_r_trimmed.png"
  fuzz = if (length(args) >= 3) as.numeric(args[[3]]) else 12

  trim_white_padding(infile, outfile, fuzz)
  message("Wrote: ", outfile)
}

if (sys.nframe() == 0) {
  main()
}

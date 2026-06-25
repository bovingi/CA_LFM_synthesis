solveForX <- function(cs, yval = 0.7) {
  # y = m*x + b  =>  x = (y - b) / m
  return((yval - cs[1]) / cs[2])
}

inversePlotData <- function(mm, cfit, pts = 100) {
  xy <- data.frame(
    x = seq(mm[1], mm[2], length.out = pts),
    y = NA,
    iy = NA)
  xy$y  <- cfit[1] + cfit[2] * xy$x
  xy$iy <- 1 / xy$y
  names(xy) <- c('MWP', 'iLFM', 'LFM')
  return(xy)
}

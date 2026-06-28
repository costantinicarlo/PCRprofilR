#' Test whether each element of x is inside a closed interval
#' @param x a numeric vector
#' @param r a numeric vector with two ordered elements
#' @noRd
inside.range <- function (x, r)
{
  stopifnot(length(r) == 2 && r[1L] <= r[2L])
  return(x >= r[1L] & x <= r[2L])
}

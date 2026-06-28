# Shared validation helpers for exported functions.

.fail <- function(message) {
    stop(message, call. = FALSE)
}

.assert_dat <- function(dat) {
    if (!inherits(dat, "data.frame")) {
        .fail("the dat argument must be a data frame")
    }
}

.assert_required_cols <- function(dat, cols, message) {
    missing_cols <- setdiff(cols, names(dat))
    if (length(missing_cols) > 0) {
        .fail(message)
    }
}

.assert_positive_numeric_scalar <- function(x, arg_name) {
    ok <- is.numeric(x) && length(x) == 1 && !is.na(x) && x > 0
    if (!ok) {
        .fail(sprintf("the %s argument must be a positive numeric scalar", arg_name))
    }
}

.assert_nonnegative_numeric_scalar <- function(x, arg_name) {
    ok <- is.numeric(x) && length(x) == 1 && !is.na(x) && x >= 0
    if (!ok) {
        .fail(sprintf("the %s argument must be a numeric scalar greater or equal to zero", arg_name))
    }
}

.assert_tolerance <- function(tolerance, message) {
    ok <- is.numeric(tolerance) &&
        length(tolerance) == 2 &&
        !any(is.na(tolerance)) &&
        tolerance[1L] >= 0 &&
        tolerance[2L] >= 0
    if (!ok) {
        .fail(message)
    }
}

.assert_targets <- function(targets) {
    ok <- is.numeric(targets) &&
        length(targets) > 0 &&
        !any(is.na(targets)) &&
        all(targets > 0) &&
        !is.null(names(targets)) &&
        all(nzchar(names(targets)))
    if (!ok) {
        .fail("the targets argument must be a named numeric vector of positive values")
    }
}

# Shared validation helpers for exported functions.

.assert_dat <- function(dat) {
    stopifnot(
        "the dat argument must be a data frame" =
            class(dat) %in% c("data.frame", "tbl", "tbl_df", "spec_tbl_df")
    )
}

.assert_required_cols <- function(dat, cols, message) {
    do.call(stopifnot, stats::setNames(list(cols %in% names(dat)), message))
}

.assert_positive_numeric_scalar <- function(x, arg_name) {
    do.call(
        stopifnot,
        stats::setNames(
            list(is.numeric(x) & length(x) == 1 & x > 0),
            sprintf("the %s argument must be a positive numeric scalar", arg_name)
        )
    )
}

.assert_nonnegative_numeric_scalar <- function(x, arg_name) {
    do.call(
        stopifnot,
        stats::setNames(
            list(is.numeric(x) & length(x) == 1 & x >= 0),
            sprintf("the %s argument must be a numeric scalar greater or equal to zero", arg_name)
        )
    )
}

.assert_tolerance <- function(tolerance, message) {
    do.call(
        stopifnot,
        stats::setNames(
            list(
                is.numeric(tolerance) &
                    length(tolerance) == 2 &
                    tolerance[1L] >= 0 &
                    tolerance[2L] >= 0
            ),
            message
        )
    )
}

.assert_targets <- function(targets) {
    stopifnot(
        "the targets argument must be a named numeric vector of positive values" =
            is.numeric(targets) & !is.null(attributes(targets)) & targets > 0
    )
}

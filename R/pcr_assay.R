pcr_assay_required_cols <- c(
    "assay_id",
    "target_id",
    "expected_size_bp",
    "lower_size_bp",
    "upper_size_bp",
    "min_concentration",
    "biological_label",
    "rule_group"
)

validate_pcr_assay <- function(x) {
    if (!inherits(x, "data.frame")) {
        stop("pcr_assay input must be a data frame", call. = FALSE)
    }

    missing_cols <- setdiff(pcr_assay_required_cols, names(x))
    if (length(missing_cols) > 0) {
        stop(
            sprintf(
                "pcr_assay is missing required columns: %s",
                paste(missing_cols, collapse = ", ")
            ),
            call. = FALSE
        )
    }

    if (!"confirm_concentration" %in% names(x)) {
        x$confirm_concentration <- x$min_concentration
    }

    numeric_cols <- c("expected_size_bp", "lower_size_bp", "upper_size_bp", "min_concentration", "confirm_concentration")
    for (col in numeric_cols) {
        if (!is.numeric(x[[col]]) || any(is.na(x[[col]]))) {
            stop(sprintf("pcr_assay column '%s' must be numeric and non-missing", col), call. = FALSE)
        }
    }

    if (any(x$expected_size_bp <= 0) || any(x$lower_size_bp <= 0) || any(x$upper_size_bp <= 0)) {
        stop("pcr_assay size columns must be strictly positive", call. = FALSE)
    }

    if (any(x$min_concentration < 0)) {
        stop("pcr_assay column 'min_concentration' must be non-negative", call. = FALSE)
    }

    if (any(x$confirm_concentration < x$min_concentration)) {
        stop("pcr_assay requires confirm_concentration >= min_concentration", call. = FALSE)
    }

    if (any(x$lower_size_bp > x$upper_size_bp)) {
        stop("pcr_assay requires lower_size_bp <= upper_size_bp", call. = FALSE)
    }

    if (any(x$expected_size_bp < x$lower_size_bp | x$expected_size_bp > x$upper_size_bp)) {
        stop("pcr_assay requires expected_size_bp to be within [lower_size_bp, upper_size_bp]", call. = FALSE)
    }

    id_cols <- c("assay_id", "target_id", "biological_label", "rule_group")
    for (col in id_cols) {
        if (!is.character(x[[col]]) || any(is.na(x[[col]])) || any(!nzchar(x[[col]]))) {
            stop(
                sprintf("pcr_assay column '%s' must be non-missing, non-empty character values", col),
                call. = FALSE
            )
        }
    }

    invisible(x)
}

pcr_assay <- function(dat) {
    x <- tibble::as_tibble(dat)

    id_cols <- c("assay_id", "target_id", "biological_label", "rule_group")
    for (col in intersect(id_cols, names(x))) {
        x[[col]] <- as.character(x[[col]])
    }

    validate_pcr_assay(x)

    if (!"confirm_concentration" %in% names(x)) {
        x$confirm_concentration <- x$min_concentration
    }

    class(x) <- c("pcr_assay", class(x))
    x
}

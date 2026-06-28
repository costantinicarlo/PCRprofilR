pcr_peaks_required_cols <- c(
    "run_id",
    "plate_id",
    "well_id",
    "sample_id",
    "peak_id",
    "size_bp",
    "concentration",
    "raw_file",
    "instrument"
)

validate_pcr_peaks <- function(x) {
    if (!inherits(x, "data.frame")) {
        stop("pcr_peaks input must be a data frame", call. = FALSE)
    }

    missing_cols <- setdiff(pcr_peaks_required_cols, names(x))
    if (length(missing_cols) > 0) {
        stop(
            sprintf(
                "pcr_peaks is missing required columns: %s",
                paste(missing_cols, collapse = ", ")
            ),
            call. = FALSE
        )
    }

    if (!is.numeric(x$size_bp) || any(is.na(x$size_bp)) || any(x$size_bp <= 0)) {
        stop("pcr_peaks column 'size_bp' must be numeric and strictly positive", call. = FALSE)
    }

    if (!is.numeric(x$concentration) || any(is.na(x$concentration)) || any(x$concentration < 0)) {
        stop("pcr_peaks column 'concentration' must be numeric and non-negative", call. = FALSE)
    }

    id_cols <- c("run_id", "plate_id", "well_id", "sample_id", "peak_id", "raw_file", "instrument")
    for (col in id_cols) {
        if (!is.character(x[[col]]) || any(is.na(x[[col]])) || any(!nzchar(x[[col]]))) {
            stop(
                sprintf("pcr_peaks column '%s' must be non-missing, non-empty character values", col),
                call. = FALSE
            )
        }
    }

    invisible(x)
}

pcr_peaks <- function(dat) {
    x <- tibble::as_tibble(dat)

    id_cols <- c("run_id", "plate_id", "well_id", "sample_id", "peak_id", "raw_file", "instrument")
    for (col in intersect(id_cols, names(x))) {
        x[[col]] <- as.character(x[[col]])
    }

    validate_pcr_peaks(x)
    class(x) <- c("pcr_peaks", class(x))
    x
}

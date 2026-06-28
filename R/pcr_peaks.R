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

#' Validate a canonical PCR peak table
#'
#' `validate_pcr_peaks()` checks that an object satisfies the canonical
#' `pcr_peaks` schema used by PCRprofilR's deterministic interpretation
#' workflow.
#'
#' Peak size must be numeric, finite, non-missing, and strictly positive.
#' Concentration must be numeric, finite, non-missing, and non-negative. Required
#' identifier columns must be non-empty character values. Remove ladder,
#' calibration, blank, or other non-peak instrument rows before strict
#' validation.
#'
#' @param x Candidate canonical peak table.
#' @param allow_qc_issues Logical scalar. If `FALSE`, validation is strict. If
#'   `TRUE`, selected QC-able issues, currently missing or malformed well
#'   identifiers, are allowed through for later QC review.
#'
#' @return The validated input, invisibly.
#'
#' @seealso [as_pcr_peaks()], [qc_pcr_run()]
#' @export
validate_pcr_peaks <- function(x, allow_qc_issues = FALSE) {
    if (!inherits(x, "data.frame")) {
        stop("pcr_peaks input must be a data frame", call. = FALSE)
    }

    if (!is.logical(allow_qc_issues) || length(allow_qc_issues) != 1L || is.na(allow_qc_issues)) {
        stop("allow_qc_issues must be a logical scalar", call. = FALSE)
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

    if (!is.numeric(x$size_bp) || any(is.na(x$size_bp)) || any(!is.finite(x$size_bp)) || any(x$size_bp <= 0)) {
        stop(
            "pcr_peaks column 'size_bp' must be numeric, non-missing, finite, and strictly positive; remove ladder/calibration/non-peak rows before calling as_pcr_peaks()",
            call. = FALSE
        )
    }

    if (!is.numeric(x$concentration) || any(is.na(x$concentration)) || any(!is.finite(x$concentration)) || any(x$concentration < 0)) {
        stop(
            "pcr_peaks column 'concentration' must be numeric, non-missing, finite, and non-negative; remove ladder/calibration/non-peak rows before calling as_pcr_peaks()",
            call. = FALSE
        )
    }

    id_cols <- c("run_id", "plate_id", "sample_id", "peak_id", "raw_file", "instrument")
    for (col in id_cols) {
        if (!is.character(x[[col]]) || any(is.na(x[[col]])) || any(!nzchar(x[[col]]))) {
            stop(
                sprintf("pcr_peaks column '%s' must be non-missing, non-empty character values", col),
                call. = FALSE
            )
        }
    }

    if (!is.character(x$well_id) || (!allow_qc_issues && (any(is.na(x$well_id)) || any(!nzchar(x$well_id))))) {
        stop("pcr_peaks column 'well_id' must be non-missing, non-empty character values", call. = FALSE)
    }

    invisible(x)
}

pcr_peaks <- function(dat, allow_qc_issues = FALSE) {
    x <- tibble::as_tibble(dat)

    id_cols <- c("run_id", "plate_id", "well_id", "sample_id", "peak_id", "raw_file", "instrument")
    for (col in intersect(id_cols, names(x))) {
        x[[col]] <- as.character(x[[col]])
    }

    validate_pcr_peaks(x, allow_qc_issues = allow_qc_issues)
    class(x) <- c("pcr_peaks", class(x))
    x
}

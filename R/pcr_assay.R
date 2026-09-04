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

#' Validate a canonical PCR assay specification
#'
#' `validate_pcr_assay()` checks that an assay specification satisfies the
#' canonical `pcr_assay` schema used to compare observed PCR peaks with expected
#' targets.
#'
#' Required assay fields describe target identity, expected size, accepted size
#' window, minimum analytical concentration, biological label, and deterministic
#' rule group. If `confirm_concentration` is absent, it is treated as equal to
#' `min_concentration` for validation. If `target_role` is present, values must
#' be `required`, `optional`, or `forbidden`.
#'
#' A canonical `pcr_assay` object represents exactly one assay: it must
#' contain exactly one unique `assay_id`, and `(assay_id, target_id)` pairs
#' must be unique. [detect_pcr_peaks()] has no way to know which of several
#' candidate assays produced an observed peak, so a multi-assay table would
#' let targets from different assays combine or collapse silently.
#' Multi-assay support requires assay identity in the observed-peak schema and
#' is out of scope for this contract.
#'
#' @param x Candidate canonical assay table.
#'
#' @return The validated input, invisibly.
#'
#' @seealso [as_pcr_assay()], [detect_pcr_peaks()]
#' @export
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

    if ("target_role" %in% names(x)) {
        allowed_roles <- c("required", "optional", "forbidden")
        if (!is.character(x$target_role) || any(is.na(x$target_role)) || any(!x$target_role %in% allowed_roles)) {
            stop(
                sprintf("pcr_assay column 'target_role' must contain only: %s", paste(allowed_roles, collapse = ", ")),
                call. = FALSE
            )
        }
    }

    if (dplyr::n_distinct(x$assay_id) != 1L) {
        stop(
            sprintf(
                "pcr_assay must represent exactly one assay_id; found %d distinct values: %s",
                dplyr::n_distinct(x$assay_id), paste(sort(unique(x$assay_id)), collapse = ", ")
            ),
            call. = FALSE
        )
    }

    if (anyDuplicated(x$target_id) > 0) {
        stop(
            sprintf(
                "pcr_assay must not define duplicate target_id values within an assay: %s",
                paste(unique(x$target_id[duplicated(x$target_id)]), collapse = ", ")
            ),
            call. = FALSE
        )
    }

    invisible(x)
}

pcr_assay <- function(dat) {
    x <- tibble::as_tibble(dat)

    if (!"target_role" %in% names(x)) {
        x$target_role <- "optional"
    }

    id_cols <- c("assay_id", "target_id", "biological_label", "rule_group", "target_role")
    for (col in intersect(id_cols, names(x))) {
        x[[col]] <- as.character(x[[col]])
    }

    x$target_role <- tolower(x$target_role)

    validate_pcr_assay(x)

    if (!"confirm_concentration" %in% names(x)) {
        x$confirm_concentration <- x$min_concentration
    }

    class(x) <- c("pcr_assay", class(x))
    x
}

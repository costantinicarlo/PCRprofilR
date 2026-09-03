pcr_profile_rules_required_cols <- c(
    "assay_id",
    "profile_id",
    "target_a",
    "target_b",
    "profile_type"
)

pcr_profile_rules_profile_types <- c("hybrid", "mixed", "forbidden")
pcr_profile_rules_calibration_statuses <- c("pending", "validated", "not_applicable")
pcr_profile_rules_evidence_zones <- c("below_analytical", "analytical_to_confirmatory", "above_confirmatory")

#' Validate a canonical pairwise PCR profile-rule specification
#'
#' `validate_pcr_profile_rules()` checks that a candidate table satisfies the
#' canonical `pcr_profile_rules` schema. Each row describes the expected
#' quantitative relationship between two assay targets (`target_a`,
#' `target_b`) for a named biological profile (for example a hybrid, mixed, or
#' forbidden target-pair combination). Profile rules are consumed by
#' [evaluate_pcr_profiles()] and are the only mechanism by which
#' [classify_pcr_samples()] may produce a `hybrid_candidate` call.
#'
#' Required columns are `assay_id`, `profile_id`, `target_a`, `target_b`, and
#' `profile_type`. Optional columns are `calibration_status` (default
#' `"pending"`), `expected_log2_ratio`, `max_abs_log2_deviation`,
#' `min_evidence_zone_a`, `min_evidence_zone_b` (default
#' `"above_confirmatory"`), and `rule_version` (default `"1"`).
#'
#' `profile_type` must be one of `"hybrid"`, `"mixed"`, or `"forbidden"`.
#' `calibration_status` must be one of `"pending"`, `"validated"`, or
#' `"not_applicable"`. A row with `profile_type == "hybrid"` and
#' `calibration_status == "validated"` must supply a finite
#' `expected_log2_ratio` and a finite, non-negative `max_abs_log2_deviation`.
#' `target_a` and `target_b` must differ, and the same unordered target pair
#' must not appear more than once within the same `assay_id`.
#'
#' @param x Candidate canonical profile-rule table.
#'
#' @return The validated input, invisibly.
#'
#' @seealso [as_pcr_profile_rules()], [evaluate_pcr_profiles()]
#' @export
validate_pcr_profile_rules <- function(x) {
    if (!inherits(x, "data.frame")) {
        stop("pcr_profile_rules input must be a data frame", call. = FALSE)
    }

    missing_cols <- setdiff(pcr_profile_rules_required_cols, names(x))
    if (length(missing_cols) > 0) {
        stop(
            sprintf(
                "pcr_profile_rules is missing required columns: %s",
                paste(missing_cols, collapse = ", ")
            ),
            call. = FALSE
        )
    }

    id_cols <- c("assay_id", "profile_id", "target_a", "target_b")
    for (col in id_cols) {
        if (!is.character(x[[col]]) || any(is.na(x[[col]])) || any(!nzchar(x[[col]]))) {
            stop(
                sprintf("pcr_profile_rules column '%s' must be non-missing, non-empty character values", col),
                call. = FALSE
            )
        }
    }

    if (any(x$target_a == x$target_b)) {
        stop("pcr_profile_rules requires target_a != target_b in every row", call. = FALSE)
    }

    if (!is.character(x$profile_type) || any(is.na(x$profile_type)) || any(!x$profile_type %in% pcr_profile_rules_profile_types)) {
        stop(
            sprintf("pcr_profile_rules column 'profile_type' must contain only: %s", paste(pcr_profile_rules_profile_types, collapse = ", ")),
            call. = FALSE
        )
    }

    if (!is.character(x$calibration_status) || any(is.na(x$calibration_status)) || any(!x$calibration_status %in% pcr_profile_rules_calibration_statuses)) {
        stop(
            sprintf(
                "pcr_profile_rules column 'calibration_status' must contain only: %s",
                paste(pcr_profile_rules_calibration_statuses, collapse = ", ")
            ),
            call. = FALSE
        )
    }

    for (col in c("min_evidence_zone_a", "min_evidence_zone_b")) {
        if (!is.character(x[[col]]) || any(is.na(x[[col]])) || any(!x[[col]] %in% pcr_profile_rules_evidence_zones)) {
            stop(
                sprintf("pcr_profile_rules column '%s' must contain only: %s", col, paste(pcr_profile_rules_evidence_zones, collapse = ", ")),
                call. = FALSE
            )
        }
    }

    if (!is.character(x$rule_version) || any(is.na(x$rule_version)) || any(!nzchar(x$rule_version))) {
        stop("pcr_profile_rules column 'rule_version' must be non-missing, non-empty character values", call. = FALSE)
    }

    validated_hybrid <- x$profile_type == "hybrid" & x$calibration_status == "validated"
    if (any(validated_hybrid)) {
        if (!is.numeric(x$expected_log2_ratio) || any(!is.finite(x$expected_log2_ratio[validated_hybrid]))) {
            stop(
                "pcr_profile_rules requires a finite 'expected_log2_ratio' for every validated hybrid rule",
                call. = FALSE
            )
        }
        if (!is.numeric(x$max_abs_log2_deviation) || any(!is.finite(x$max_abs_log2_deviation[validated_hybrid]))) {
            stop(
                "pcr_profile_rules requires a finite 'max_abs_log2_deviation' for every validated hybrid rule",
                call. = FALSE
            )
        }
        if (any(x$max_abs_log2_deviation[validated_hybrid] < 0)) {
            stop("pcr_profile_rules column 'max_abs_log2_deviation' must be non-negative", call. = FALSE)
        }
    }

    pair_key <- paste(x$assay_id, pmin(x$target_a, x$target_b), pmax(x$target_a, x$target_b), sep = "\r")
    if (anyDuplicated(pair_key) > 0) {
        stop(
            "pcr_profile_rules must not define more than one rule for the same unordered target pair within the same assay_id",
            call. = FALSE
        )
    }

    invisible(x)
}

pcr_profile_rules <- function(dat) {
    x <- tibble::as_tibble(dat)

    id_cols <- c("assay_id", "profile_id", "target_a", "target_b", "profile_type", "calibration_status", "rule_version")
    for (col in intersect(id_cols, names(x))) {
        x[[col]] <- as.character(x[[col]])
    }

    if (!"calibration_status" %in% names(x)) {
        x$calibration_status <- "pending"
    }
    if (!"expected_log2_ratio" %in% names(x)) {
        x$expected_log2_ratio <- NA_real_
    }
    if (!"max_abs_log2_deviation" %in% names(x)) {
        x$max_abs_log2_deviation <- NA_real_
    }
    if (!"min_evidence_zone_a" %in% names(x)) {
        x$min_evidence_zone_a <- "above_confirmatory"
    }
    if (!"min_evidence_zone_b" %in% names(x)) {
        x$min_evidence_zone_b <- "above_confirmatory"
    }
    if (!"rule_version" %in% names(x)) {
        x$rule_version <- "1"
    }

    x$expected_log2_ratio <- as.numeric(x$expected_log2_ratio)
    x$max_abs_log2_deviation <- as.numeric(x$max_abs_log2_deviation)

    validate_pcr_profile_rules(x)

    class(x) <- c("pcr_profile_rules", class(x))
    x
}

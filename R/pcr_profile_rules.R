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

# Compatibility matrix: which calibration_status values are meaningful for each profile_type.
# hybrid rules describe a quantitative balance relationship, so they may still be `pending`
# calibration. mixed/forbidden rules are identity-based and never use balance calibration.
pcr_profile_rules_allowed_calibration <- list(
    hybrid = c("pending", "validated"),
    mixed = "not_applicable",
    forbidden = "not_applicable"
)

.pcr_check_calibration_compatibility <- function(profile_type, calibration_status) {
    allowed <- pcr_profile_rules_allowed_calibration[profile_type]
    bad <- !mapply(function(cs, allowed_values) cs %in% allowed_values, calibration_status, allowed)
    if (any(bad)) {
        stop(
            sprintf(
                "pcr_profile_rules has incompatible profile_type/calibration_status combinations: %s",
                paste(unique(paste0(profile_type[bad], "/", calibration_status[bad])), collapse = ", ")
            ),
            call. = FALSE
        )
    }
}

# Normalizes identifiers, enum columns, and defaults, and reports which optional
# columns were entirely absent from the caller-supplied table (rather than merely
# containing default-looking values), so validated hybrid rules can require them
# to have been explicitly supplied.
.pcr_profile_rules_normalize <- function(x) {
    id_cols <- c("assay_id", "profile_id", "target_a", "target_b")
    for (col in id_cols) {
        x[[col]] <- as.character(x[[col]])
    }

    x$profile_type <- .pcr_normalize_enum(x$profile_type)

    had_calibration_status <- "calibration_status" %in% names(x)
    had_min_evidence_zone_a <- "min_evidence_zone_a" %in% names(x)
    had_min_evidence_zone_b <- "min_evidence_zone_b" %in% names(x)
    had_rule_version <- "rule_version" %in% names(x)

    if (!had_calibration_status) {
        x$calibration_status <- ifelse(x$profile_type == "hybrid", "pending", "not_applicable")
    } else {
        x$calibration_status <- .pcr_normalize_enum(x$calibration_status)
    }

    if (!"expected_log2_ratio" %in% names(x)) {
        x$expected_log2_ratio <- NA_real_
    }
    if (!"max_abs_log2_deviation" %in% names(x)) {
        x$max_abs_log2_deviation <- NA_real_
    }
    if (!had_min_evidence_zone_a) {
        x$min_evidence_zone_a <- "above_confirmatory"
    } else {
        x$min_evidence_zone_a <- .pcr_normalize_enum(x$min_evidence_zone_a)
    }
    if (!had_min_evidence_zone_b) {
        x$min_evidence_zone_b <- "above_confirmatory"
    } else {
        x$min_evidence_zone_b <- .pcr_normalize_enum(x$min_evidence_zone_b)
    }
    if (!had_rule_version) {
        x$rule_version <- "1"
    } else {
        x$rule_version <- as.character(x$rule_version)
    }

    list(
        data = x,
        had_min_evidence_zone_a = had_min_evidence_zone_a,
        had_min_evidence_zone_b = had_min_evidence_zone_b,
        had_rule_version = had_rule_version
    )
}

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
#' `profile_type`. If `calibration_status` is absent, it defaults per row to
#' `"pending"` for `hybrid` rules and `"not_applicable"` for `mixed`/
#' `forbidden` rules. `min_evidence_zone_a`/`min_evidence_zone_b` default to
#' `"above_confirmatory"` and `rule_version` defaults to `"1"` **only** when
#' those columns are entirely absent; a validated hybrid rule requires all of
#' `expected_log2_ratio`, `max_abs_log2_deviation`, `min_evidence_zone_a`,
#' `min_evidence_zone_b`, and `rule_version` to have been explicitly supplied,
#' so scientifically consequential thresholds are never assigned silently.
#'
#' `profile_type` must be one of `"hybrid"`, `"mixed"`, or `"forbidden"`.
#' Allowed `calibration_status` values depend on `profile_type`: `hybrid`
#' allows `"pending"`/`"validated"`; `mixed` and `forbidden` allow only
#' `"not_applicable"`. `target_a` and `target_b` must differ, and the same
#' unordered target pair must not appear more than once within the same
#' `assay_id`. Identifier columns (`assay_id`, `profile_id`, `target_a`,
#' `target_b`) must not contain leading or trailing whitespace; enum columns
#' are trimmed and lower-cased before validation.
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
        .pcr_reject_untrimmed(x[[col]], paste0("pcr_profile_rules$", col))
    }

    if (any(x$target_a == x$target_b)) {
        stop("pcr_profile_rules requires target_a != target_b in every row", call. = FALSE)
    }

    normalized <- .pcr_profile_rules_normalize(x)
    x <- normalized$data

    if (any(is.na(x$profile_type)) || any(!x$profile_type %in% pcr_profile_rules_profile_types)) {
        stop(
            sprintf("pcr_profile_rules column 'profile_type' must contain only: %s", paste(pcr_profile_rules_profile_types, collapse = ", ")),
            call. = FALSE
        )
    }

    if (any(is.na(x$calibration_status)) || any(!x$calibration_status %in% pcr_profile_rules_calibration_statuses)) {
        stop(
            sprintf(
                "pcr_profile_rules column 'calibration_status' must contain only: %s",
                paste(pcr_profile_rules_calibration_statuses, collapse = ", ")
            ),
            call. = FALSE
        )
    }

    .pcr_check_calibration_compatibility(x$profile_type, x$calibration_status)

    for (col in c("min_evidence_zone_a", "min_evidence_zone_b")) {
        if (any(is.na(x[[col]])) || any(!x[[col]] %in% pcr_profile_rules_evidence_zones)) {
            stop(
                sprintf("pcr_profile_rules column '%s' must contain only: %s", col, paste(pcr_profile_rules_evidence_zones, collapse = ", ")),
                call. = FALSE
            )
        }
    }

    if (!is.character(x$rule_version) || any(is.na(x$rule_version)) || any(!nzchar(x$rule_version))) {
        stop("pcr_profile_rules column 'rule_version' must be non-missing, non-empty character values", call. = FALSE)
    }

    x$expected_log2_ratio <- .pcr_safe_numeric(x$expected_log2_ratio, "pcr_profile_rules$expected_log2_ratio")
    x$max_abs_log2_deviation <- .pcr_safe_numeric(x$max_abs_log2_deviation, "pcr_profile_rules$max_abs_log2_deviation")

    validated_hybrid <- x$profile_type == "hybrid" & x$calibration_status == "validated"
    if (any(validated_hybrid)) {
        if (any(!is.finite(x$expected_log2_ratio[validated_hybrid]))) {
            stop(
                "pcr_profile_rules requires a finite 'expected_log2_ratio' for every validated hybrid rule",
                call. = FALSE
            )
        }
        if (any(!is.finite(x$max_abs_log2_deviation[validated_hybrid]))) {
            stop(
                "pcr_profile_rules requires a finite 'max_abs_log2_deviation' for every validated hybrid rule",
                call. = FALSE
            )
        }
        if (any(x$max_abs_log2_deviation[validated_hybrid] < 0)) {
            stop("pcr_profile_rules column 'max_abs_log2_deviation' must be non-negative", call. = FALSE)
        }
        if (!normalized$had_min_evidence_zone_a || !normalized$had_min_evidence_zone_b) {
            stop(
                "pcr_profile_rules requires 'min_evidence_zone_a' and 'min_evidence_zone_b' to be explicitly supplied for every validated hybrid rule; they must not be silently defaulted",
                call. = FALSE
            )
        }
        if (!normalized$had_rule_version) {
            stop(
                "pcr_profile_rules requires 'rule_version' to be explicitly supplied for every validated hybrid rule; it must not be silently defaulted",
                call. = FALSE
            )
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

    id_cols <- c("assay_id", "profile_id", "target_a", "target_b")
    for (col in id_cols) {
        x[[col]] <- as.character(x[[col]])
    }

    # validate_pcr_profile_rules() is the single source of truth for normalization
    # (defaults, enum casing, safe numeric conversion): capture its returned value
    # rather than re-normalizing separately, or "had_*" tracking for explicit-field
    # requirements would be lost the moment a defaulted column already exists.
    x <- validate_pcr_profile_rules(x)

    class(x) <- c("pcr_profile_rules", class(x))
    x
}

pcr_profile_rules_empty <- function() {
    empty <- tibble::tibble(
        assay_id = character(0), profile_id = character(0), target_a = character(0), target_b = character(0),
        profile_type = character(0), calibration_status = character(0),
        expected_log2_ratio = numeric(0), max_abs_log2_deviation = numeric(0),
        min_evidence_zone_a = character(0), min_evidence_zone_b = character(0),
        rule_version = character(0)
    )
    class(empty) <- c("pcr_profile_rules", class(empty))
    empty
}

# Filters a profile-rules table to the single active assay represented in peak_calls
# and validates that every remaining rule refers to target IDs actually defined for
# that assay. Errors clearly instead of silently degrading to "no rules supplied".
.pcr_profile_rules_for_assay <- function(profile_rules, active_assay_id, known_target_ids) {
    if (is.null(profile_rules)) {
        return(NULL)
    }

    assay_rules <- profile_rules[profile_rules$assay_id == active_assay_id, , drop = FALSE]
    if (nrow(profile_rules) > 0L && nrow(assay_rules) == 0L) {
        stop(
            sprintf(
                "pcr_profile_rules contains no rules for assay_id '%s'; supply rules for this assay or omit profile_rules",
                active_assay_id
            ),
            call. = FALSE
        )
    }

    if (nrow(assay_rules) > 0L) {
        unknown_targets <- setdiff(c(assay_rules$target_a, assay_rules$target_b), known_target_ids)
        if (length(unknown_targets) > 0L) {
            stop(
                sprintf(
                    "pcr_profile_rules for assay_id '%s' refers to unknown target_id values: %s",
                    active_assay_id, paste(sort(unique(unknown_targets)), collapse = ", ")
                ),
                call. = FALSE
            )
        }
    }

    assay_rules
}


pcr_profile_evidence_required_cols <- c(
    "run_id", "plate_id", "well_id", "sample_id", "assay_id",
    "profile_id", "profile_type", "calibration_status", "rule_version",
    "target_a", "target_b",
    "target_a_peak_id", "target_b_peak_id",
    "target_a_size_bp", "target_b_size_bp",
    "target_a_concentration", "target_b_concentration",
    "target_a_evidence_zone", "target_b_evidence_zone",
    "observed_log2_ratio", "raw_balance_ratio", "fold_imbalance",
    "expected_log2_ratio", "max_abs_log2_deviation",
    "min_evidence_zone_a", "min_evidence_zone_b",
    "abs_log2_deviation", "balance_score",
    "balance_status", "strength_status",
    "dominant_target", "minor_target", "dominance_status",
    "profile_rule_status", "profile_structure_status",
    "interpretation_model_version"
)

pcr_profile_evidence_rule_statuses <- c("rule_missing", "calibration_pending", "calibration_validated", "forbidden_profile", "mixed_profile")
pcr_profile_evidence_structure_statuses <- c("distinct_physical_peaks", "duplicate_physical_peak")
pcr_profile_evidence_balance_statuses <- c("pass", "fail", "not_evaluable")
pcr_profile_evidence_strength_statuses <- c("pass", "fail")
pcr_profile_evidence_dominance_statuses <- c("target_a_dominant", "target_b_dominant", "equal", "not_evaluable")
pcr_profile_evidence_zones <- c("below_analytical", "analytical_to_confirmatory", "above_confirmatory")

#' Validate a canonical pairwise PCR profile-evidence table
#'
#' `validate_pcr_profile_evidence()` checks that a candidate table satisfies
#' the canonical `pcr_profile_evidence` schema produced by
#' [evaluate_pcr_profiles()], and is the fail-closed gate used by
#' [classify_pcr_samples()] before any externally supplied evidence can
#' contribute to a `hybrid_candidate` call.
#'
#' At minimum this checks: all canonical columns and types are present; one
#' row exists at most per interpreted-sample key (`run_id`, `plate_id`,
#' `well_id`, `sample_id`, `assay_id`); `target_a != target_b`;
#' `profile_rule_status`, `profile_structure_status`, `balance_status`,
#' `strength_status`, and `dominance_status` contain only allowed values;
#' `profile_structure_status` agrees with whether `target_a_peak_id` and
#' `target_b_peak_id` are identical; and, for `profile_rule_status ==
#' "calibration_validated"`, `strength_status` and `balance_status` are never
#' missing and `abs_log2_deviation`/`balance_score` are mathematically
#' coherent with `observed_log2_ratio`, `expected_log2_ratio`, and
#' `max_abs_log2_deviation` whenever the profile is evaluable.
#'
#' If `peak_calls` is supplied, every row is additionally checked against it:
#' the interpreted-sample key, both target IDs, and both representative peak
#' IDs must exist in `peak_calls`; the referenced peaks must be `matched` to
#' the stated target; and concentration, size, and evidence-zone values must
#' agree with the corresponding `peak_calls` row. A zero-row profile-evidence
#' table is always valid.
#'
#' @param x Candidate canonical `pcr_profile_evidence` table.
#' @param peak_calls Optional `pcr_peak_calls` object used for cross-object
#'   consistency checks.
#'
#' @return The validated input, invisibly.
#'
#' @seealso [evaluate_pcr_profiles()], [classify_pcr_samples()]
#' @export
validate_pcr_profile_evidence <- function(x, peak_calls = NULL) {
    if (!inherits(x, "data.frame")) {
        stop("pcr_profile_evidence input must be a data frame", call. = FALSE)
    }

    missing_cols <- setdiff(pcr_profile_evidence_required_cols, names(x))
    if (length(missing_cols) > 0) {
        stop(
            sprintf("pcr_profile_evidence is missing required columns: %s", paste(missing_cols, collapse = ", ")),
            call. = FALSE
        )
    }

    if (nrow(x) == 0L) {
        return(invisible(x))
    }

    key_cols <- .pcr_interpreted_sample_key_cols
    for (col in c(key_cols, "target_a", "target_b", "target_a_peak_id", "target_b_peak_id", "profile_rule_status", "profile_structure_status", "interpretation_model_version")) {
        if (!is.character(x[[col]]) || any(is.na(x[[col]])) || any(!nzchar(x[[col]]))) {
            stop(sprintf("pcr_profile_evidence column '%s' must be non-missing, non-empty character values", col), call. = FALSE)
        }
    }

    if (anyDuplicated(x[key_cols]) > 0) {
        stop("pcr_profile_evidence must contain at most one row per interpreted-sample key (run_id, plate_id, well_id, sample_id, assay_id)", call. = FALSE)
    }

    if (any(x$target_a == x$target_b)) {
        stop("pcr_profile_evidence requires target_a != target_b in every row", call. = FALSE)
    }

    if (any(!x$profile_rule_status %in% pcr_profile_evidence_rule_statuses)) {
        stop(sprintf("pcr_profile_evidence column 'profile_rule_status' must contain only: %s", paste(pcr_profile_evidence_rule_statuses, collapse = ", ")), call. = FALSE)
    }
    if (any(!x$profile_structure_status %in% pcr_profile_evidence_structure_statuses)) {
        stop(sprintf("pcr_profile_evidence column 'profile_structure_status' must contain only: %s", paste(pcr_profile_evidence_structure_statuses, collapse = ", ")), call. = FALSE)
    }

    duplicate_peak <- x$target_a_peak_id == x$target_b_peak_id
    structure_says_duplicate <- x$profile_structure_status == "duplicate_physical_peak"
    if (any(duplicate_peak != structure_says_duplicate)) {
        stop("pcr_profile_evidence 'profile_structure_status' is inconsistent with whether target_a_peak_id equals target_b_peak_id", call. = FALSE)
    }

    for (col in c("target_a_evidence_zone", "target_b_evidence_zone")) {
        if (!is.character(x[[col]]) || any(is.na(x[[col]])) || any(!x[[col]] %in% pcr_profile_evidence_zones)) {
            stop(sprintf("pcr_profile_evidence column '%s' must contain only: %s", col, paste(pcr_profile_evidence_zones, collapse = ", ")), call. = FALSE)
        }
    }

    # profile_id/profile_type/calibration_status/rule_version must be character, and must
    # agree with profile_rule_status: all NA when no rule applies, all populated and
    # mutually consistent with the specific rule outcome when one does. This prevents
    # malformed/forged evidence from carrying rule metadata that contradicts its own
    # profile_rule_status.
    for (col in c("profile_id", "profile_type", "calibration_status", "rule_version")) {
        if (!is.character(x[[col]])) {
            stop(sprintf("pcr_profile_evidence column '%s' must be a character vector", col), call. = FALSE)
        }
    }

    rule_missing <- x$profile_rule_status == "rule_missing"
    rule_metadata_populated <- !is.na(x$profile_id) | !is.na(x$profile_type) | !is.na(x$calibration_status) | !is.na(x$rule_version)
    rule_metadata_missing <- is.na(x$profile_id) | is.na(x$profile_type) | is.na(x$calibration_status) | is.na(x$rule_version)
    if (any(rule_missing & rule_metadata_populated)) {
        stop("pcr_profile_evidence requires profile_id/profile_type/calibration_status/rule_version to be NA whenever profile_rule_status is 'rule_missing'", call. = FALSE)
    }
    if (any(!rule_missing & rule_metadata_missing)) {
        stop("pcr_profile_evidence requires profile_id/profile_type/calibration_status/rule_version to be non-missing whenever profile_rule_status is not 'rule_missing'", call. = FALSE)
    }
    if (any(!rule_missing & !nzchar(x$rule_version))) {
        stop("pcr_profile_evidence column 'rule_version' must be non-empty whenever profile_rule_status is not 'rule_missing'", call. = FALSE)
    }
    if (any(!rule_missing & !nzchar(x$profile_id))) {
        stop("pcr_profile_evidence column 'profile_id' must be non-empty whenever profile_rule_status is not 'rule_missing'", call. = FALSE)
    }

    has_rule <- !rule_missing
    expected_profile_type <- dplyr::case_when(
        x$profile_rule_status == "forbidden_profile" ~ "forbidden",
        x$profile_rule_status == "mixed_profile" ~ "mixed",
        x$profile_rule_status %in% c("calibration_pending", "calibration_validated") ~ "hybrid",
        TRUE ~ NA_character_
    )
    if (any(has_rule & x$profile_type != expected_profile_type)) {
        stop("pcr_profile_evidence column 'profile_type' is inconsistent with profile_rule_status", call. = FALSE)
    }

    expected_calibration_status <- dplyr::case_when(
        x$profile_rule_status %in% c("forbidden_profile", "mixed_profile") ~ "not_applicable",
        x$profile_rule_status == "calibration_pending" ~ "pending",
        x$profile_rule_status == "calibration_validated" ~ "validated",
        TRUE ~ NA_character_
    )
    if (any(has_rule & x$calibration_status != expected_calibration_status)) {
        stop("pcr_profile_evidence column 'calibration_status' is inconsistent with profile_rule_status", call. = FALSE)
    }

    if (!is.character(x$dominance_status) || any(is.na(x$dominance_status)) || any(!x$dominance_status %in% pcr_profile_evidence_dominance_statuses)) {
        stop(sprintf("pcr_profile_evidence column 'dominance_status' must contain only: %s", paste(pcr_profile_evidence_dominance_statuses, collapse = ", ")), call. = FALSE)
    }

    non_missing_balance <- !is.na(x$balance_status)
    if (any(non_missing_balance) && any(!x$balance_status[non_missing_balance] %in% pcr_profile_evidence_balance_statuses)) {
        stop(sprintf("pcr_profile_evidence column 'balance_status' must be NA or one of: %s", paste(pcr_profile_evidence_balance_statuses, collapse = ", ")), call. = FALSE)
    }
    non_missing_strength <- !is.na(x$strength_status)
    if (any(non_missing_strength) && any(!x$strength_status[non_missing_strength] %in% pcr_profile_evidence_strength_statuses)) {
        stop(sprintf("pcr_profile_evidence column 'strength_status' must be NA or one of: %s", paste(pcr_profile_evidence_strength_statuses, collapse = ", ")), call. = FALSE)
    }

    # A validated hybrid rule must always resolve strength/balance explicitly.
    # This is a second, independent fail-closed check: hybrid gating in
    # pcr_sample_calls() also requires strength_status == "pass" directly, but
    # malformed/forged evidence must never even reach that stage looking valid.
    is_validated <- x$profile_rule_status == "calibration_validated"
    if (any(is_validated & is.na(x$strength_status))) {
        stop("pcr_profile_evidence requires a non-missing 'strength_status' whenever profile_rule_status is 'calibration_validated'", call. = FALSE)
    }
    if (any(is_validated & is.na(x$balance_status))) {
        stop("pcr_profile_evidence requires a non-missing 'balance_status' whenever profile_rule_status is 'calibration_validated'", call. = FALSE)
    }
    if (any(!is_validated & non_missing_strength)) {
        stop("pcr_profile_evidence must not set 'strength_status' unless profile_rule_status is 'calibration_validated'", call. = FALSE)
    }

    evaluated <- is_validated & !is.na(x$balance_status) & x$balance_status != "not_evaluable"
    if (any(evaluated)) {
        if (any(is.na(x$observed_log2_ratio[evaluated]) | is.na(x$expected_log2_ratio[evaluated]) | is.na(x$max_abs_log2_deviation[evaluated]) | is.na(x$abs_log2_deviation[evaluated]) | is.na(x$balance_score[evaluated]))) {
            stop("pcr_profile_evidence requires non-missing observed_log2_ratio/expected_log2_ratio/max_abs_log2_deviation/abs_log2_deviation/balance_score whenever balance_status is 'pass' or 'fail'", call. = FALSE)
        }
        recomputed <- abs(x$observed_log2_ratio[evaluated] - x$expected_log2_ratio[evaluated])
        if (any(!is.finite(recomputed)) || any(abs(recomputed - x$abs_log2_deviation[evaluated]) > 1e-8)) {
            stop("pcr_profile_evidence 'abs_log2_deviation' is not consistent with observed_log2_ratio and expected_log2_ratio", call. = FALSE)
        }
        expected_score <- 2^(-recomputed)
        if (any(abs(expected_score - x$balance_score[evaluated]) > 1e-8)) {
            stop("pcr_profile_evidence 'balance_score' is not consistent with abs_log2_deviation", call. = FALSE)
        }
        expected_status <- ifelse(recomputed <= x$max_abs_log2_deviation[evaluated], "pass", "fail")
        if (any(expected_status != x$balance_status[evaluated])) {
            stop("pcr_profile_evidence 'balance_status' is not consistent with abs_log2_deviation and max_abs_log2_deviation", call. = FALSE)
        }
    }

    if (!is.null(peak_calls)) {
        .pcr_validate_profile_evidence_against_peak_calls(x, peak_calls)
    }

    invisible(x)
}

.pcr_validate_profile_evidence_against_peak_calls <- function(x, peak_calls) {
    if (!inherits(peak_calls, "pcr_peak_calls")) {
        stop("peak_calls must be a pcr_peak_calls object", call. = FALSE)
    }

    key_cols <- .pcr_interpreted_sample_key_cols
    sample_keys <- unique(peak_calls[key_cols])

    for (i in seq_len(nrow(x))) {
        row <- x[i, ]
        key_match <- sample_keys$run_id == row$run_id & sample_keys$plate_id == row$plate_id &
            sample_keys$well_id == row$well_id & sample_keys$sample_id == row$sample_id &
            sample_keys$assay_id == row$assay_id
        if (!any(key_match)) {
            stop(
                sprintf("pcr_profile_evidence row %d refers to a sample/assay not present in peak_calls", i),
                call. = FALSE
            )
        }

        for (side in c("a", "b")) {
            target_id <- row[[paste0("target_", side)]]
            peak_id <- row[[paste0("target_", side, "_peak_id")]]
            concentration <- row[[paste0("target_", side, "_concentration")]]
            size_bp <- row[[paste0("target_", side, "_size_bp")]]
            evidence_zone <- row[[paste0("target_", side, "_evidence_zone")]]

            candidate <- peak_calls[
                peak_calls$run_id == row$run_id & peak_calls$plate_id == row$plate_id &
                    peak_calls$well_id == row$well_id & peak_calls$sample_id == row$sample_id &
                    peak_calls$assay_id == row$assay_id &
                    peak_calls$target_id == target_id & peak_calls$peak_id == peak_id,
            ]

            if (nrow(candidate) == 0L) {
                stop(
                    sprintf(
                        "pcr_profile_evidence row %d references peak_id '%s' for target '%s', which is not present in peak_calls for that sample/target",
                        i, peak_id, target_id
                    ),
                    call. = FALSE
                )
            }
            if (!any(candidate$matched)) {
                stop(
                    sprintf("pcr_profile_evidence row %d references a peak that is not matched to target '%s' in peak_calls", i, target_id),
                    call. = FALSE
                )
            }
            candidate <- candidate[candidate$matched, , drop = FALSE][1L, ]
            if (!isTRUE(all.equal(candidate$concentration, concentration)) ||
                !isTRUE(all.equal(candidate$size_bp, size_bp)) ||
                !identical(candidate$evidence_zone, evidence_zone)) {
                stop(
                    sprintf(
                        "pcr_profile_evidence row %d has concentration/size/evidence_zone inconsistent with the referenced peak_calls row for target '%s'",
                        i, target_id
                    ),
                    call. = FALSE
                )
            }
        }
    }

    invisible(x)
}

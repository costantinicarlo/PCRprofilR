.pcr_dual_target_call_state <- function(profile_rule_status, profile_structure_status, balance_status, strength_status) {
    dplyr::case_when(
        profile_rule_status == "rule_missing" ~ "dual_target_unresolved_review",
        profile_rule_status == "forbidden_profile" ~ "ambiguous_review",
        profile_rule_status == "mixed_profile" ~ "mixed_profile_candidate",
        # A duplicated physical peak affects structural/balance evaluability, not rule
        # existence, so it is checked as its own axis rather than as a rule status.
        profile_structure_status == "duplicate_physical_peak" ~ "dual_target_balance_review",
        profile_rule_status == "calibration_pending" ~ "dual_target_balance_review",
        profile_rule_status == "calibration_validated" & strength_status == "fail" ~ "dual_target_weak_review",
        profile_rule_status == "calibration_validated" & balance_status == "not_evaluable" ~ "dual_target_balance_review",
        profile_rule_status == "calibration_validated" & balance_status == "fail" ~ "dual_target_imbalanced_review",
        # Explicit, conjunctive requirement: NA/unknown strength_status (e.g. malformed or
        # forged evidence) never matches this branch and falls through to a review state.
        profile_rule_status == "calibration_validated" & strength_status == "pass" & balance_status == "pass" ~ "hybrid_candidate",
        TRUE ~ "dual_target_unresolved_review"
    )
}

pcr_sample_calls <- function(peak_calls, profile_rules = NULL, profile_evidence = NULL) {
    if (!inherits(peak_calls, "pcr_peak_calls")) {
        peak_calls <- pcr_peak_calls(peak_calls)
    }

    required_cols <- c("run_id", "plate_id", "well_id", "sample_id", "assay_id", "target_id", "biological_label", "matched", "within_window", "evidence_zone")
    missing_cols <- setdiff(required_cols, names(peak_calls))
    if (length(missing_cols) > 0) {
        stop(
            sprintf("pcr_sample_calls requires columns: %s", paste(required_cols, collapse = ", ")),
            call. = FALSE
        )
    }

    if (!"target_role" %in% names(peak_calls)) {
        peak_calls$target_role <- "optional"
    }

    if (!is.null(profile_rules) && !is.null(profile_evidence)) {
        stop(
            "pcr_sample_calls accepts either profile_rules (rules to compute evidence from) or profile_evidence (precomputed, validated evidence), not both",
            call. = FALSE
        )
    }

    if (is.null(profile_evidence)) {
        profile_evidence <- pcr_profile_evidence(peak_calls, profile_rules = profile_rules)
    } else if (!inherits(profile_evidence, "pcr_profile_evidence")) {
        stop("profile_evidence must be a pcr_profile_evidence object", call. = FALSE)
    }
    # Always validated, even for internally generated evidence and even when the object
    # already inherits the expected class: the class alone must never be trusted.
    validate_pcr_profile_evidence(profile_evidence, peak_calls = peak_calls)

    target_hits <- peak_calls |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id, .data$assay_id, .data$target_id) |>
        dplyr::summarise(
            target_matched = any(.data$matched),
            target_biological_label = dplyr::first(.data$biological_label),
            target_rule_group = dplyr::first(.data$rule_group),
            target_role = dplyr::first(.data$target_role),
            target_best_zone = dplyr::case_when(
                any(.data$within_window & .data$evidence_zone == "above_confirmatory") ~ "above_confirmatory",
                any(.data$within_window & .data$evidence_zone == "analytical_to_confirmatory") ~ "analytical_to_confirmatory",
                TRUE ~ "below_analytical"
            ),
            target_within_window_below = any(.data$within_window & .data$evidence_zone == "below_analytical"),
            .groups = "drop"
        )

    sample_summary <- target_hits |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id, .data$assay_id) |>
        dplyr::summarise(
            matched_target_count = sum(.data$target_matched),
            matched_targets = paste(.data$target_id[.data$target_matched], collapse = ";"),
            matched_rule_groups = paste(unique(.data$target_rule_group[.data$target_matched]), collapse = ";"),
            matched_label_count = dplyr::n_distinct(.data$target_biological_label[.data$target_matched]),
            required_target_count = sum(.data$target_role == "required"),
            required_target_matched_count = sum(.data$target_role == "required" & .data$target_matched),
            missing_required_target_count = sum(.data$target_role == "required" & !.data$target_matched),
            forbidden_target_count = sum(.data$target_role == "forbidden" & .data$target_matched),
            below_analytical_target_count = sum(.data$target_within_window_below),
            sample_threshold_zone = dplyr::case_when(
                any(.data$target_best_zone == "above_confirmatory") ~ "above_confirmatory",
                any(.data$target_best_zone == "analytical_to_confirmatory") ~ "analytical_to_confirmatory",
                TRUE ~ "below_analytical"
            ),
            rule_status = dplyr::case_when(
                sum(.data$target_role == "forbidden" & .data$target_matched) > 0 ~ "forbidden_matched",
                sum(.data$target_role == "required" & !.data$target_matched) > 0 & sum(.data$target_matched) > 0 ~ "missing_required_with_partial_match",
                TRUE ~ "compatible"
            ),
            call_state = dplyr::case_when(
                sum(.data$target_role == "forbidden" & .data$target_matched) > 0 ~ "ambiguous_review",
                sum(.data$target_role == "required" & !.data$target_matched) > 0 & sum(.data$target_matched) > 0 ~ "ambiguous_review",
                sum(.data$target_matched) > 2 & dplyr::n_distinct(.data$target_biological_label[.data$target_matched]) > 2 ~ "mixed_profile_candidate",
                # Pairwise profile evidence is only computed for exactly two matched targets
                # representing exactly two labels (see pcr_profile_evidence()); this predicate
                # must match exactly, or evidence and final call could disagree.
                sum(.data$target_matched) == 2 & dplyr::n_distinct(.data$target_biological_label[.data$target_matched]) == 2 ~ "__dual_target_pending__",
                sum(.data$target_matched) > 1 & dplyr::n_distinct(.data$target_biological_label[.data$target_matched]) > 1 ~ "ambiguous_review",
                any(.data$target_best_zone == "above_confirmatory") ~ "positive",
                any(.data$target_best_zone == "analytical_to_confirmatory") ~ "weak_positive",
                sum(.data$target_within_window_below) > 0 ~ "indeterminate_review",
                TRUE ~ "negative"
            ),
            call = dplyr::if_else(sum(.data$target_matched) > 0, "positive", "negative"),
            confidence = dplyr::if_else(sum(.data$target_matched) > 0, "baseline", "baseline"),
            .groups = "drop"
        )

    profile_tbl <- tibble::as_tibble(profile_evidence)
    join_keys <- .pcr_interpreted_sample_key_cols
    profile_fields <- intersect(c(join_keys, "profile_rule_status", "profile_structure_status", "balance_status", "strength_status"), names(profile_tbl))
    sample_summary <- dplyr::left_join(
        sample_summary,
        dplyr::select(profile_tbl, dplyr::all_of(profile_fields)),
        by = join_keys,
        relationship = "many-to-one"
    )

    sample_summary <- dplyr::mutate(
        sample_summary,
        call_state = dplyr::if_else(
            .data$call_state == "__dual_target_pending__",
            .pcr_dual_target_call_state(.data$profile_rule_status, .data$profile_structure_status, .data$balance_status, .data$strength_status),
            .data$call_state
        ),
        threshold_status = dplyr::if_else(.data$call_state %in% .pcr_terminal_call_states, .data$call_state, "review"),
        review_required = .data$call_state %in% .pcr_review_call_states,
        hybrid_candidate = .data$call_state == "hybrid_candidate",
        mixed_profile_candidate = .data$call_state == "mixed_profile_candidate"
    )

    sample_summary$matched_targets[sample_summary$matched_target_count == 0] <- ""
    sample_summary$matched_rule_groups[sample_summary$matched_target_count == 0] <- ""

    class(sample_summary) <- c("pcr_sample_calls", class(sample_summary))
    sample_summary
}


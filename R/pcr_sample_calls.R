pcr_sample_calls <- function(peak_calls) {
    if (!inherits(peak_calls, "pcr_peak_calls")) {
        peak_calls <- pcr_peak_calls(peak_calls)
    }

    required_cols <- c("run_id", "plate_id", "well_id", "sample_id", "target_id", "biological_label", "matched", "within_window", "evidence_zone")
    missing_cols <- setdiff(required_cols, names(peak_calls))
    if (length(missing_cols) > 0) {
        stop(
            sprintf("pcr_sample_calls requires columns: %s", paste(required_cols, collapse = ", ")),
            call. = FALSE
        )
    }

    target_hits <- peak_calls |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id, .data$target_id) |>
        dplyr::summarise(
            target_matched = any(.data$matched),
            target_biological_label = dplyr::first(.data$biological_label),
            target_best_zone = dplyr::case_when(
                any(.data$within_window & .data$evidence_zone == "above_confirmatory") ~ "above_confirmatory",
                any(.data$within_window & .data$evidence_zone == "analytical_to_confirmatory") ~ "analytical_to_confirmatory",
                TRUE ~ "below_analytical"
            ),
            target_within_window_below = any(.data$within_window & .data$evidence_zone == "below_analytical"),
            .groups = "drop"
        )

    sample_summary <- target_hits |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id) |>
        dplyr::summarise(
            matched_target_count = sum(.data$target_matched),
            matched_targets = paste(.data$target_id[.data$target_matched], collapse = ";"),
            matched_label_count = dplyr::n_distinct(.data$target_biological_label[.data$target_matched]),
            below_analytical_target_count = sum(.data$target_within_window_below),
            sample_threshold_zone = dplyr::case_when(
                any(.data$target_best_zone == "above_confirmatory") ~ "above_confirmatory",
                any(.data$target_best_zone == "analytical_to_confirmatory") ~ "analytical_to_confirmatory",
                TRUE ~ "below_analytical"
            ),
            call_state = dplyr::case_when(
                sum(.data$target_matched) > 2 & dplyr::n_distinct(.data$target_biological_label[.data$target_matched]) > 2 ~ "mixed_profile_candidate",
                sum(.data$target_matched) == 2 & dplyr::n_distinct(.data$target_biological_label[.data$target_matched]) == 2 ~ "hybrid_candidate",
                sum(.data$target_matched) > 1 ~ "ambiguous_review",
                any(.data$target_best_zone == "above_confirmatory") ~ "positive",
                any(.data$target_best_zone == "analytical_to_confirmatory") ~ "weak_positive",
                sum(.data$target_within_window_below) > 0 ~ "indeterminate_review",
                TRUE ~ "negative"
            ),
            call = dplyr::if_else(sum(.data$target_matched) > 0, "positive", "negative"),
            confidence = dplyr::if_else(sum(.data$target_matched) > 0, "baseline", "baseline"),
            .groups = "drop"
        ) |>
        dplyr::mutate(
            threshold_status = dplyr::if_else(.data$call_state %in% c("positive", "negative"), .data$call_state, "review"),
            review_required = .data$call_state %in% c("ambiguous_review", "weak_positive", "indeterminate_review", "hybrid_candidate", "mixed_profile_candidate"),
            hybrid_candidate = .data$call_state == "hybrid_candidate",
            mixed_profile_candidate = .data$call_state == "mixed_profile_candidate"
        )

    sample_summary$matched_targets[sample_summary$matched_target_count == 0] <- ""

    class(sample_summary) <- c("pcr_sample_calls", class(sample_summary))
    sample_summary
}

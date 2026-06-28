pcr_qc <- function(peaks, sample_calls = NULL) {
    if (!inherits(peaks, "pcr_peaks")) {
        peaks <- pcr_peaks(peaks)
    }

    peaks_tbl <- tibble::as_tibble(peaks)

    sample_base <- peaks_tbl |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id) |>
        dplyr::summarise(
            n_peaks = dplyr::n(),
            max_concentration = max(.data$concentration, na.rm = TRUE),
            .groups = "drop"
        )

    duplicate_tbl <- peaks_tbl |>
        dplyr::distinct(.data$run_id, .data$sample_id, .data$well_id) |>
        dplyr::group_by(.data$run_id, .data$sample_id) |>
        dplyr::summarise(n_wells = dplyr::n(), .groups = "drop") |>
        dplyr::mutate(duplicate_sample_id_in_run = .data$n_wells > 1) |>
        dplyr::select("run_id", "sample_id", "duplicate_sample_id_in_run")

    qc <- dplyr::left_join(sample_base, duplicate_tbl, by = c("run_id", "sample_id"))

    qc <- dplyr::mutate(
        qc,
        has_missing_well_id = is.na(.data$well_id) | !nzchar(.data$well_id),
        control_sample = grepl("^(CTR|CONTROL|NTC)$", .data$sample_id, ignore.case = TRUE),
        duplicate_sample_id_in_run = dplyr::coalesce(.data$duplicate_sample_id_in_run, FALSE)
    )

    if (!is.null(sample_calls)) {
        if (!inherits(sample_calls, "pcr_sample_calls")) {
            sample_calls <- pcr_sample_calls(sample_calls)
        }
        call_tbl <- tibble::as_tibble(sample_calls) |>
            dplyr::select("run_id", "plate_id", "well_id", "sample_id", "call", "call_state", "review_required", "hybrid_candidate", "mixed_profile_candidate")

        qc <- dplyr::left_join(qc, call_tbl, by = c("run_id", "plate_id", "well_id", "sample_id"))
        qc <- dplyr::mutate(
            qc,
            no_matched_targets = .data$call == "negative",
            weak_positive_state = .data$call_state == "weak_positive",
            ambiguous_call_state = .data$call_state == "ambiguous_review",
            indeterminate_call_state = .data$call_state == "indeterminate_review",
            contamination_candidate = (.data$control_sample & .data$call != "negative") |
                (.data$duplicate_sample_id_in_run & .data$call_state %in% c("hybrid_candidate", "mixed_profile_candidate", "ambiguous_review"))
        )
    } else {
        qc$call <- NA_character_
        qc$call_state <- NA_character_
        qc$review_required <- NA
        qc$hybrid_candidate <- NA
        qc$mixed_profile_candidate <- NA
        qc$no_matched_targets <- NA
        qc$weak_positive_state <- NA
        qc$ambiguous_call_state <- NA
        qc$indeterminate_call_state <- NA
        qc$contamination_candidate <- NA
    }

    qc <- dplyr::mutate(
        qc,
        qc_status = dplyr::case_when(
            .data$has_missing_well_id ~ "fail",
            .data$contamination_candidate ~ "review",
            .data$duplicate_sample_id_in_run ~ "review",
            TRUE ~ "pass"
        )
    )

    class(qc) <- c("pcr_qc", class(qc))
    qc
}

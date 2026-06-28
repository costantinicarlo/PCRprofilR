pcr_replicate_summary <- function(sample_calls, qc = NULL, replicate_keys = c("sample_id")) {
    if (!inherits(sample_calls, "pcr_sample_calls")) {
        sample_calls <- pcr_sample_calls(sample_calls)
    }

    calls_tbl <- tibble::as_tibble(sample_calls)

    if (!is.character(replicate_keys) || length(replicate_keys) == 0 || any(!nzchar(replicate_keys))) {
        stop("replicate_keys must be a non-empty character vector", call. = FALSE)
    }

    missing_keys <- setdiff(replicate_keys, names(calls_tbl))
    if (length(missing_keys) > 0) {
        stop(
            sprintf("pcr_replicate_summary missing replicate key columns: %s", paste(missing_keys, collapse = ", ")),
            call. = FALSE
        )
    }

    if (!is.null(qc)) {
        if (!inherits(qc, "pcr_qc")) {
            qc <- pcr_qc(qc)
        }

        qc_tbl <- tibble::as_tibble(qc)
        join_keys <- intersect(c("run_id", "plate_id", "well_id", "sample_id"), names(calls_tbl))

        qc_fields <- c(join_keys, "qc_status", "contamination_candidate")
        qc_fields <- intersect(qc_fields, names(qc_tbl))

        calls_tbl <- dplyr::left_join(
            calls_tbl,
            dplyr::select(qc_tbl, dplyr::all_of(qc_fields)),
            by = join_keys
        )
    }

    has_qc_status <- "qc_status" %in% names(calls_tbl)
    has_contamination <- "contamination_candidate" %in% names(calls_tbl)

    out <- calls_tbl |>
        dplyr::group_by(dplyr::across(dplyr::all_of(replicate_keys))) |>
        dplyr::summarise(
            n_replicates = dplyr::n(),
            positive_replicates = sum(.data$call == "positive", na.rm = TRUE),
            negative_replicates = sum(.data$call == "negative", na.rm = TRUE),
            review_replicates = sum(.data$review_required, na.rm = TRUE),
            unique_call_states = dplyr::n_distinct(.data$call_state),
            replicate_concordance = dplyr::if_else(dplyr::n_distinct(.data$call_state) == 1L, "concordant", "discordant"),
            consensus_call_state = dplyr::case_when(
                dplyr::n_distinct(.data$call_state) == 1L ~ dplyr::first(.data$call_state),
                any(.data$call_state %in% c("mixed_profile_candidate", "hybrid_candidate", "ambiguous_review")) ~ "review_discordant",
                any(.data$call_state == "positive") & all(.data$call_state %in% c("positive", "weak_positive")) ~ "positive_with_review",
                TRUE ~ "review_discordant"
            ),
            consensus_call = dplyr::if_else(sum(.data$call == "positive", na.rm = TRUE) > 0, "positive", "negative"),
            any_qc_fail = if (has_qc_status) any(.data$qc_status == "fail", na.rm = TRUE) else FALSE,
            any_contamination_candidate = if (has_contamination) any(.data$contamination_candidate, na.rm = TRUE) else FALSE,
            .groups = "drop"
        )

    class(out) <- c("pcr_replicate_calls", class(out))
    out
}

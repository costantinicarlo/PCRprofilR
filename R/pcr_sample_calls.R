pcr_sample_calls <- function(peak_calls) {
    if (!inherits(peak_calls, "pcr_peak_calls")) {
        peak_calls <- pcr_peak_calls(peak_calls)
    }

    required_cols <- c("run_id", "plate_id", "well_id", "sample_id", "target_id", "matched")
    missing_cols <- setdiff(required_cols, names(peak_calls))
    if (length(missing_cols) > 0) {
        stop(
            sprintf("pcr_sample_calls requires columns: %s", paste(required_cols, collapse = ", ")),
            call. = FALSE
        )
    }

    target_hits <- peak_calls |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id, .data$target_id) |>
        dplyr::summarise(target_matched = any(.data$matched), .groups = "drop")

    sample_summary <- target_hits |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id) |>
        dplyr::summarise(
            matched_target_count = sum(.data$target_matched),
            matched_targets = paste(.data$target_id[.data$target_matched], collapse = ";"),
            call = dplyr::if_else(sum(.data$target_matched) > 0, "positive", "negative"),
            confidence = dplyr::if_else(sum(.data$target_matched) > 0, "baseline", "baseline"),
            .groups = "drop"
        )

    sample_summary$matched_targets[sample_summary$matched_target_count == 0] <- ""

    class(sample_summary) <- c("pcr_sample_calls", class(sample_summary))
    sample_summary
}

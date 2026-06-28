#' @export
plot_pcr_evidence <- function(peak_calls, sample_calls = NULL, qc = NULL) {
    if (!inherits(peak_calls, "pcr_peak_calls")) {
        stop("plot_pcr_evidence requires a pcr_peak_calls object", call. = FALSE)
    }

    required_cols <- c("run_id", "plate_id", "well_id", "sample_id", "target_id", "size_bp", "concentration", "expected_size_bp", "evidence_zone", "matched")
    missing_cols <- setdiff(required_cols, names(peak_calls))
    if (length(missing_cols) > 0) {
        stop(
            sprintf("plot_pcr_evidence peak_calls missing columns: %s", paste(missing_cols, collapse = ", ")),
            call. = FALSE
        )
    }

    plot_tbl <- tibble::as_tibble(peak_calls)
    join_keys <- c("run_id", "plate_id", "well_id", "sample_id")

    if (!is.null(sample_calls)) {
        if (!inherits(sample_calls, "pcr_sample_calls")) {
            stop("sample_calls must be a pcr_sample_calls object", call. = FALSE)
        }
        sample_fields <- intersect(c(join_keys, "call", "call_state", "review_required", "rule_status"), names(sample_calls))
        plot_tbl <- dplyr::left_join(
            plot_tbl,
            dplyr::select(tibble::as_tibble(sample_calls), dplyr::all_of(sample_fields)),
            by = join_keys
        )
    }

    if (!is.null(qc)) {
        if (!inherits(qc, "pcr_qc")) {
            stop("qc must be a pcr_qc object", call. = FALSE)
        }
        qc_fields <- intersect(c(join_keys, "qc_status", "contamination_candidate", "control_role"), names(qc))
        plot_tbl <- dplyr::left_join(
            plot_tbl,
            dplyr::select(tibble::as_tibble(qc), dplyr::all_of(qc_fields)),
            by = join_keys
        )
    }

    target_tbl <- plot_tbl |>
        dplyr::distinct(.data$target_id, .data$expected_size_bp)

    ggplot2::ggplot(
        plot_tbl,
        ggplot2::aes(
            x = .data$size_bp,
            y = .data$concentration,
            color = .data$evidence_zone,
            shape = .data$matched
        )
    ) +
        ggplot2::geom_vline(
            data = target_tbl,
            ggplot2::aes(xintercept = .data$expected_size_bp),
            inherit.aes = FALSE,
            alpha = 0.25
        ) +
        ggplot2::geom_point(alpha = 0.75) +
        ggplot2::labs(
            x = "Fragment Size (bp)",
            y = "Conc. (ng/uL)",
            color = "Evidence zone",
            shape = "Matched"
        ) +
        ggplot2::theme_linedraw()
}

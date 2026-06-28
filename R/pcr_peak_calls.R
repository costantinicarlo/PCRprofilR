pcr_peak_calls <- function(peaks, assay) {
    if (!inherits(peaks, "pcr_peaks")) {
        peaks <- pcr_peaks(peaks)
    }
    if (!inherits(assay, "pcr_assay")) {
        assay <- pcr_assay(assay)
    }

    peak_tbl <- tibble::as_tibble(peaks)
    assay_tbl <- tibble::as_tibble(assay)

    peak_tbl$.__join_key <- 1L
    assay_tbl$.__join_key <- 1L

    out <- dplyr::left_join(peak_tbl, assay_tbl, by = ".__join_key", relationship = "many-to-many")
    out$.__join_key <- NULL

    out <- dplyr::mutate(
        out,
        size_delta_bp = .data$size_bp - .data$expected_size_bp,
        within_window = .data$size_bp >= .data$lower_size_bp & .data$size_bp <= .data$upper_size_bp,
        above_min_concentration = .data$concentration >= .data$min_concentration,
        above_confirm_concentration = .data$concentration >= .data$confirm_concentration,
        evidence_zone = dplyr::case_when(
            .data$above_confirm_concentration ~ "above_confirmatory",
            .data$above_min_concentration ~ "analytical_to_confirmatory",
            TRUE ~ "below_analytical"
        ),
        matched = .data$within_window & .data$above_min_concentration
    )

    class(out) <- c("pcr_peak_calls", class(out))
    out
}

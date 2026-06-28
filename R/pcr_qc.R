.normalize_pcr_control_role <- function(control_role, sample_id) {
    role <- rep(NA_character_, length(sample_id))
    if (!is.null(control_role)) {
        role <- tolower(trimws(as.character(control_role)))
        role[is.na(role)] <- ""
    }

    inferred <- rep("sample", length(sample_id))
    sample_id_chr <- as.character(sample_id)
    inferred[grepl("^(NTC|NO[_ -]?TEMPLATE)$", sample_id_chr, ignore.case = TRUE)] <- "no_template_control"
    inferred[grepl("^(BLANK|EMPTY)$", sample_id_chr, ignore.case = TRUE)] <- "blank"
    inferred[grepl("^(NEG|NEGATIVE|NEGATIVE[_ -]?CONTROL)$", sample_id_chr, ignore.case = TRUE)] <- "negative_control"
    inferred[grepl("^(CTR|CONTROL|POS|POSITIVE|POSITIVE[_ -]?CONTROL)$", sample_id_chr, ignore.case = TRUE)] <- "positive_control"

    aliases <- c(
        sample = "sample",
        unknown = "unknown",
        positive_control = "positive_control",
        positive = "positive_control",
        pos = "positive_control",
        pc = "positive_control",
        negative_control = "negative_control",
        negative = "negative_control",
        neg = "negative_control",
        nc = "negative_control",
        no_template_control = "no_template_control",
        ntc = "no_template_control",
        blank = "blank",
        empty = "blank"
    )

    out <- inferred
    explicit <- !is.na(role) & nzchar(role)
    mapped <- aliases[role[explicit]]
    if (any(is.na(mapped))) {
        bad <- unique(role[explicit][is.na(mapped)])
        stop(
            sprintf(
                "control_role values must be one of: %s; unknown values: %s",
                paste(sort(unique(names(aliases))), collapse = ", "),
                paste(bad, collapse = ", ")
            ),
            call. = FALSE
        )
    }
    out[explicit] <- unname(mapped)
    out
}

pcr_qc <- function(peaks, sample_calls = NULL) {
    if (!inherits(peaks, "pcr_peaks")) {
        peaks <- pcr_peaks(peaks)
    }

    peaks_tbl <- tibble::as_tibble(peaks)
    control_role <- if ("control_role" %in% names(peaks_tbl)) peaks_tbl$control_role else NULL
    peaks_tbl$control_role <- .normalize_pcr_control_role(control_role, peaks_tbl$sample_id)

    sample_base <- peaks_tbl |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id) |>
        dplyr::summarise(
            n_peaks = dplyr::n(),
            max_concentration = max(.data$concentration, na.rm = TRUE),
            control_role = dplyr::first(.data$control_role),
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
        control_sample = !.data$control_role %in% c("sample", "unknown"),
        positive_control = .data$control_role == "positive_control",
        negative_control = .data$control_role == "negative_control",
        no_template_control = .data$control_role == "no_template_control",
        blank_control = .data$control_role == "blank",
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
            positive_control_failed = .data$positive_control & .data$call == "negative",
            negative_control_failed = .data$negative_control & .data$call != "negative",
            no_template_control_failed = .data$no_template_control & .data$call != "negative",
            blank_control_failed = .data$blank_control & .data$n_peaks > 0,
            control_failure = .data$positive_control_failed | .data$negative_control_failed |
                .data$no_template_control_failed | .data$blank_control_failed,
            contamination_candidate = .data$negative_control_failed | .data$no_template_control_failed |
                .data$blank_control_failed |
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
        qc$positive_control_failed <- NA
        qc$negative_control_failed <- NA
        qc$no_template_control_failed <- NA
        qc$blank_control_failed <- NA
        qc$control_failure <- NA
        qc$contamination_candidate <- NA
    }

    qc <- dplyr::mutate(
        qc,
        qc_status = dplyr::case_when(
            .data$has_missing_well_id ~ "fail",
            .data$control_failure ~ "fail",
            .data$contamination_candidate ~ "review",
            .data$duplicate_sample_id_in_run ~ "review",
            TRUE ~ "pass"
        )
    )

    class(qc) <- c("pcr_qc", class(qc))
    qc
}

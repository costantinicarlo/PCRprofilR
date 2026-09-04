.read_pcr_table <- function(path) {
    if (!is.character(path) || length(path) != 1L || !nzchar(path)) {
        stop("path must be a non-empty character scalar", call. = FALSE)
    }
    if (!file.exists(path)) {
        stop(sprintf("file not found: %s", path), call. = FALSE)
    }

    ext <- tolower(tools::file_ext(path))
    sep <- if (ext %in% c("tsv", "txt")) "\t" else ","
    utils::read.table(path, header = TRUE, sep = sep, stringsAsFactors = FALSE, check.names = FALSE)
}

pcr_batch_run <- function(peaks_path, assay_path, output_dir, mapping = NULL, write_outputs = TRUE, profile_rules_path = NULL) {
    peaks_raw <- .read_pcr_table(peaks_path)
    assay_raw <- .read_pcr_table(assay_path)

    peaks_norm <- normalize_pcr_peaks(peaks_raw, mapping = mapping)
    peaks <- pcr_peaks(peaks_norm)
    assay <- pcr_assay(assay_raw)

    profile_rules <- NULL
    if (!is.null(profile_rules_path)) {
        profile_rules <- pcr_profile_rules(.read_pcr_table(profile_rules_path))
    }

    peak_calls <- pcr_peak_calls(peaks, assay)
    profile_evidence <- pcr_profile_evidence(peak_calls, profile_rules = profile_rules)
    sample_calls <- pcr_sample_calls(peak_calls, profile_evidence = profile_evidence)
    qc <- pcr_qc(peaks, sample_calls)

    outputs <- list(
        peaks = peaks,
        assay = assay,
        profile_rules = profile_rules,
        peak_calls = peak_calls,
        profile_evidence = profile_evidence,
        sample_calls = sample_calls,
        qc = qc,
        written_files = character(0)
    )

    if (isTRUE(write_outputs)) {
        if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
            stop("output_dir must be a non-empty character scalar", call. = FALSE)
        }

        # Route batch exports through the same canonical provenance/writing implementation
        # used by report_pcr_calls(), instead of a second, lower-provenance write.csv() path.
        artifacts <- pcr_export_artifacts(
            peak_calls = peak_calls,
            sample_calls = sample_calls,
            qc = qc,
            output_dir = output_dir,
            format = "csv",
            profile_evidence = profile_evidence,
            profile_rules = profile_rules,
            write_summary = TRUE
        )

        outputs$written_files <- artifacts$files
    }

    class(outputs) <- c("pcr_batch_run", class(outputs))
    outputs
}

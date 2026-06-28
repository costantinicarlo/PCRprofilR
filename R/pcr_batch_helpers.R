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

pcr_batch_run <- function(peaks_path, assay_path, output_dir, mapping = NULL, write_outputs = TRUE) {
    peaks_raw <- .read_pcr_table(peaks_path)
    assay_raw <- .read_pcr_table(assay_path)

    peaks_norm <- normalize_pcr_peaks(peaks_raw, mapping = mapping)
    peaks <- pcr_peaks(peaks_norm)
    assay <- pcr_assay(assay_raw)

    peak_calls <- pcr_peak_calls(peaks, assay)
    sample_calls <- pcr_sample_calls(peak_calls)
    qc <- pcr_qc(peaks, sample_calls)

    outputs <- list(
        peaks = peaks,
        assay = assay,
        peak_calls = peak_calls,
        sample_calls = sample_calls,
        qc = qc,
        written_files = character(0)
    )

    if (isTRUE(write_outputs)) {
        if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
            stop("output_dir must be a non-empty character scalar", call. = FALSE)
        }

        dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
        files <- c(
            peak_calls = file.path(output_dir, "peak_calls.csv"),
            sample_calls = file.path(output_dir, "sample_calls.csv"),
            qc = file.path(output_dir, "qc.csv")
        )

        utils::write.csv(tibble::as_tibble(peak_calls), files[["peak_calls"]], row.names = FALSE)
        utils::write.csv(tibble::as_tibble(sample_calls), files[["sample_calls"]], row.names = FALSE)
        utils::write.csv(tibble::as_tibble(qc), files[["qc"]], row.names = FALSE)

        outputs$written_files <- unname(files)
    }

    class(outputs) <- c("pcr_batch_run", class(outputs))
    outputs
}

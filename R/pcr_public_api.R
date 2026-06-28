#' @export
as_pcr_peaks <- function(dat, mapping = NULL, allow_qc_issues = FALSE) {
    if (inherits(dat, "pcr_peaks") && !isTRUE(allow_qc_issues)) {
        return(dat)
    }

    if (!inherits(dat, "data.frame")) {
        stop("as_pcr_peaks input must be a data frame", call. = FALSE)
    }

    if (all(pcr_peaks_required_cols %in% names(dat))) {
        return(pcr_peaks(dat, allow_qc_issues = allow_qc_issues))
    }

    normalize_pcr_peaks(dat, mapping = mapping, allow_qc_issues = allow_qc_issues)
}

#' @export
as_pcr_assay <- function(dat) {
    if (inherits(dat, "pcr_assay")) {
        return(dat)
    }

    pcr_assay(dat)
}

#' @export
detect_pcr_peaks <- function(peaks, assay) {
    pcr_peak_calls(as_pcr_peaks(peaks), as_pcr_assay(assay))
}

#' @export
classify_pcr_samples <- function(peak_calls) {
    pcr_sample_calls(peak_calls)
}

#' @export
qc_pcr_run <- function(peaks, sample_calls = NULL, allow_qc_issues = FALSE) {
    pcr_qc(as_pcr_peaks(peaks, allow_qc_issues = allow_qc_issues), sample_calls = sample_calls, allow_qc_issues = allow_qc_issues)
}

#' @export
summarize_pcr_replicates <- function(sample_calls, qc = NULL, replicate_keys = c("sample_id")) {
    pcr_replicate_summary(sample_calls, qc = qc, replicate_keys = replicate_keys)
}

#' @export
run_pcr_batch <- function(peaks_path, assay_path, output_dir, mapping = NULL, write_outputs = TRUE) {
    pcr_batch_run(
        peaks_path = peaks_path,
        assay_path = assay_path,
        output_dir = output_dir,
        mapping = mapping,
        write_outputs = write_outputs
    )
}

#' @export
report_pcr_calls <- function(peak_calls, sample_calls, qc, output_dir, format = c("csv", "tsv"), metadata = list(), write_summary = TRUE) {
    pcr_export_artifacts(
        peak_calls = peak_calls,
        sample_calls = sample_calls,
        qc = qc,
        output_dir = output_dir,
        format = format,
        metadata = metadata,
        write_summary = write_summary
    )
}

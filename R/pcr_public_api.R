#' Normalize peak data into the PCRprofilR peak schema
#'
#' `as_pcr_peaks()` is the entry point for turning raw instrument-like peak
#' tables into the canonical `pcr_peaks` object used by the deterministic
#' interpretation workflow.
#'
#' If `dat` already has the canonical peak columns, it is validated and returned
#' as a `pcr_peaks` object. Otherwise, source columns are normalized with
#' `normalize_pcr_peaks()`, using either the default legacy column names or an
#' explicit `mapping`.
#'
#' @param dat A data frame or existing `pcr_peaks` object. Raw data frames may
#'   use supported legacy column names such as `RunID`, `PlateID`, `WellID`,
#'   `SampleID`, `PeakID`, `Size`, `Conc`, `RawFile`, and `Instrument`.
#' @param mapping Optional named character vector mapping canonical column names
#'   to source column names.
#' @param allow_qc_issues Logical scalar. If `FALSE`, canonical validation is
#'   strict. If `TRUE`, selected QC-able issues, currently missing or malformed
#'   well identifiers, are allowed through for later QC review.
#'
#' @return A tibble-like `pcr_peaks` object.
#'
#' @seealso [validate_pcr_peaks()], [detect_pcr_peaks()],
#'   `vignette("PCRprofilR", package = "PCRprofilR")`
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

#' Normalize an assay specification into the PCRprofilR assay schema
#'
#' `as_pcr_assay()` turns a data frame of expected PCR targets into a canonical
#' `pcr_assay` object. The assay object defines expected fragment sizes,
#' accepted size windows, concentration thresholds, biological labels, rule
#' groups, and target roles.
#'
#' The optional `target_role` column may contain `required`, `optional`, or
#' `forbidden`. If it is omitted, targets are treated as `optional`.
#'
#' @param dat A data frame or existing `pcr_assay` object describing assay
#'   targets. Required columns are `assay_id`, `target_id`,
#'   `expected_size_bp`, `lower_size_bp`, `upper_size_bp`,
#'   `min_concentration`, `biological_label`, and `rule_group`.
#'   `confirm_concentration` is optional and defaults to `min_concentration`.
#'
#' @return A tibble-like `pcr_assay` object.
#'
#' @seealso [validate_pcr_assay()], [detect_pcr_peaks()],
#'   `vignette("PCRprofilR", package = "PCRprofilR")`
#' @export
as_pcr_assay <- function(dat) {
    if (inherits(dat, "pcr_assay")) {
        return(dat)
    }

    pcr_assay(dat)
}

#' Detect assay target evidence in observed PCR peaks
#'
#' `detect_pcr_peaks()` compares observed peaks with an assay specification and
#' returns a peak-level evidence table. Each observed peak is evaluated against
#' each assay target for size-window compatibility and concentration threshold
#' status.
#'
#' @param peaks A raw peak data frame or canonical `pcr_peaks` object.
#' @param assay A raw assay data frame or canonical `pcr_assay` object.
#'
#' @return A tibble-like `pcr_peak_calls` object containing observed peak
#'   fields, assay target fields, size deltas, threshold evidence zones, match
#'   flags, rule-group information, and target roles.
#'
#' @seealso [as_pcr_peaks()], [as_pcr_assay()], [classify_pcr_samples()]
#' @export
detect_pcr_peaks <- function(peaks, assay) {
    pcr_peak_calls(as_pcr_peaks(peaks), as_pcr_assay(assay))
}

#' Classify PCR samples from peak-level evidence
#'
#' `classify_pcr_samples()` summarizes peak-level evidence into deterministic
#' sample calls. It preserves reviewable states instead of forcing every sample
#' into a binary positive/negative interpretation.
#'
#' @param peak_calls A `pcr_peak_calls` object produced by
#'   [detect_pcr_peaks()].
#'
#' @return A tibble-like `pcr_sample_calls` object with one row per sample,
#'   including `call`, `call_state`, matched targets, threshold status,
#'   rule status, and review flags.
#'
#' @seealso [detect_pcr_peaks()], [qc_pcr_run()], [plot_pcr_evidence()]
#' @export
classify_pcr_samples <- function(peak_calls) {
    pcr_sample_calls(peak_calls)
}

#' Create quality-control flags for a PCR run
#'
#' `qc_pcr_run()` creates machine-readable QC output for peak data and, when
#' supplied, sample calls. QC output includes sample/control roles, pass/review/
#' fail status, duplicate sample identifiers, malformed well flags in the
#' review pathway, and contamination-candidate indicators.
#'
#' @param peaks A raw peak data frame or canonical `pcr_peaks` object.
#' @param sample_calls Optional `pcr_sample_calls` object produced by
#'   [classify_pcr_samples()].
#' @param allow_qc_issues Logical scalar. If `TRUE`, selected QC-able peak-table
#'   issues are retained so they can be represented in the QC table.
#'
#' @return A tibble-like `pcr_qc` object.
#'
#' @seealso [as_pcr_peaks()], [classify_pcr_samples()],
#'   [summarize_pcr_replicates()]
#' @export
qc_pcr_run <- function(peaks, sample_calls = NULL, allow_qc_issues = FALSE) {
    pcr_qc(as_pcr_peaks(peaks, allow_qc_issues = allow_qc_issues), sample_calls = sample_calls, allow_qc_issues = allow_qc_issues)
}

#' Summarize replicate PCR sample calls
#'
#' `summarize_pcr_replicates()` groups repeated PCR observations and reports
#' deterministic replicate agreement, discordance, consensus calls, and QC-aware
#' review state.
#'
#' @param sample_calls A `pcr_sample_calls` object produced by
#'   [classify_pcr_samples()].
#' @param qc Optional `pcr_qc` object produced by [qc_pcr_run()].
#' @param replicate_keys Character vector of column names used to group rows
#'   belonging to the same biological replicate set. The default groups by
#'   `sample_id`.
#'
#' @return A tibble-like `pcr_replicate_calls` object.
#'
#' @seealso [classify_pcr_samples()], [qc_pcr_run()], [report_pcr_calls()]
#' @export
summarize_pcr_replicates <- function(sample_calls, qc = NULL, replicate_keys = c("sample_id")) {
    pcr_replicate_summary(sample_calls, qc = qc, replicate_keys = replicate_keys)
}

#' Run the deterministic PCR workflow from input files
#'
#' `run_pcr_batch()` reads peak and assay files, normalizes them, computes peak
#' evidence, classifies samples, runs QC, and optionally writes reproducible
#' output artifacts. It is the file-based orchestration helper for scripted or
#' container workflows.
#'
#' @param peaks_path Path to a delimited peak input file.
#' @param assay_path Path to a delimited assay specification file.
#' @param output_dir Directory used for output artifacts when `write_outputs`
#'   is `TRUE`.
#' @param mapping Optional named character vector mapping canonical peak column
#'   names to source column names.
#' @param write_outputs Logical scalar controlling whether output files are
#'   written in addition to returning computed objects.
#'
#' @return A list containing canonical workflow outputs, including peaks, assay,
#'   peak calls, sample calls, QC, and exported file paths when requested.
#'
#' @seealso [as_pcr_peaks()], [detect_pcr_peaks()], [report_pcr_calls()]
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

#' Export PCR evidence, calls, QC, and provenance
#'
#' `report_pcr_calls()` writes the deterministic workflow outputs to files and
#' records provenance metadata. Use it when results should be stored as
#' auditable artifacts rather than copied manually from the R console.
#'
#' @param peak_calls A `pcr_peak_calls` object produced by [detect_pcr_peaks()].
#' @param sample_calls A `pcr_sample_calls` object produced by
#'   [classify_pcr_samples()].
#' @param qc A `pcr_qc` object produced by [qc_pcr_run()].
#' @param output_dir Directory where exported artifacts are written.
#' @param format Output table format, either `"csv"` or `"tsv"`.
#' @param metadata Named list of provenance fields to attach to exported
#'   artifacts.
#' @param write_summary Logical scalar controlling whether a plain-text summary
#'   report is written.
#'
#' @return A `pcr_export_artifacts` object describing written artifact paths.
#'
#' @seealso [run_pcr_batch()], [detect_pcr_peaks()], [classify_pcr_samples()],
#'   [qc_pcr_run()]
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

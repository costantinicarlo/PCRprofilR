\name{pcr_public_api}
\alias{as_pcr_peaks}
\alias{as_pcr_assay}
\alias{validate_pcr_peaks}
\alias{validate_pcr_assay}
\alias{detect_pcr_peaks}
\alias{classify_pcr_samples}
\alias{qc_pcr_run}
\alias{summarize_pcr_replicates}
\alias{run_pcr_batch}
\alias{report_pcr_calls}
\title{Curated helpers for PCR profile interpretation workflows}
\usage{
as_pcr_peaks(dat, mapping = NULL)

as_pcr_assay(dat)

validate_pcr_peaks(x)

validate_pcr_assay(x)

detect_pcr_peaks(peaks, assay)

classify_pcr_samples(peak_calls)

qc_pcr_run(peaks, sample_calls = NULL)

summarize_pcr_replicates(sample_calls, qc = NULL, replicate_keys = c("sample_id"))

run_pcr_batch(peaks_path, assay_path, output_dir, mapping = NULL, write_outputs = TRUE)

report_pcr_calls(
  peak_calls,
  sample_calls,
  qc,
  output_dir,
  format = c("csv", "tsv"),
  metadata = list(),
  write_summary = TRUE
)
}
\arguments{
\item{dat}{For \code{as_pcr_peaks()}, a data frame or \code{pcr_peaks} object to normalize into the canonical peak schema. For \code{as_pcr_assay()}, a data frame or \code{pcr_assay} object describing assay targets and thresholds.}

\item{x}{A candidate canonical table validated by \code{validate_pcr_peaks()} or \code{validate_pcr_assay()}.}

\item{mapping}{Optional named mapping used by \code{as_pcr_peaks()} to translate source column names into the canonical peak columns.}

\item{peaks}{Canonical or raw peak data passed to \code{detect_pcr_peaks()} or \code{qc_pcr_run()}.}

\item{assay}{Canonical or raw assay specification passed to \code{detect_pcr_peaks()}.}

\item{peak_calls}{Peak-level evidence table produced by \code{detect_pcr_peaks()}.}

\item{sample_calls}{Sample-level interpretation table produced by \code{classify_pcr_samples()}.}

\item{qc}{QC table produced by \code{qc_pcr_run()} or \code{NULL} when replicate summaries should be computed without QC state.}

\item{replicate_keys}{Character vector of column names used by \code{summarize_pcr_replicates()} to group replicate samples.}

\item{peaks_path}{Path to a delimited peak input file consumed by \code{run_pcr_batch()}.}

\item{assay_path}{Path to a delimited assay specification file consumed by \code{run_pcr_batch()}.}

\item{output_dir}{Directory where \code{run_pcr_batch()} or \code{report_pcr_calls()} writes exported artifacts.}

\item{write_outputs}{Logical flag controlling whether \code{run_pcr_batch()} writes output files in addition to returning computed objects.}

\item{format}{Output table format for \code{report_pcr_calls()}, either \code{"csv"} or \code{"tsv"}.}

\item{metadata}{Named list of provenance fields supplied to \code{report_pcr_calls()} for exported artifacts.}

\item{write_summary}{Logical flag controlling whether \code{report_pcr_calls()} writes a text summary report.}
}
\value{
These helpers return the canonical interpretation objects used by the package pipeline:
\describe{
\item{\code{as_pcr_peaks()}}{A \code{pcr_peaks} tibble-like object.}
\item{\code{as_pcr_assay()}}{A \code{pcr_assay} tibble-like object.}
\item{\code{validate_pcr_peaks()}}{The validated input, returned invisibly.}
\item{\code{validate_pcr_assay()}}{The validated input, returned invisibly.}
\item{\code{detect_pcr_peaks()}}{A \code{pcr_peak_calls} tibble-like object.}
\item{\code{classify_pcr_samples()}}{A \code{pcr_sample_calls} tibble-like object.}
\item{\code{qc_pcr_run()}}{A \code{pcr_qc} tibble-like object.}
\item{\code{summarize_pcr_replicates()}}{A \code{pcr_replicate_calls} tibble-like object.}
\item{\code{run_pcr_batch()}}{A list containing the canonical pipeline outputs and, optionally, exported files.}
\item{\code{report_pcr_calls()}}{A \code{pcr_export_artifacts} object describing written artifact paths.}
}
}
\description{
These functions provide the curated public interface for the package's canonical PCR profile interpretation workflow, from peak normalization and validation through evidence detection, sample calling, replicate summarization, QC evaluation, and export.
}
\details{
Use these helpers to compose the explicit interpretation layers introduced by the package internals: raw peaks are normalized with \code{as_pcr_peaks()}, canonical tables can be checked explicitly with \code{validate_pcr_peaks()} and \code{validate_pcr_assay()}, assay specifications are normalized with \code{as_pcr_assay()}, peak evidence is computed with \code{detect_pcr_peaks()}, sample calls are derived with \code{classify_pcr_samples()}, and QC/export helpers consume those classified outputs.
}

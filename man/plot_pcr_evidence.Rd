\name{plot_pcr_evidence}
\alias{plot_pcr_evidence}
\title{Plot classified PCR peak evidence}
\usage{
plot_pcr_evidence(peak_calls, sample_calls = NULL, qc = NULL)
}
\arguments{
\item{peak_calls}{A \code{pcr_peak_calls} object produced by \code{detect_pcr_peaks()}.}

\item{sample_calls}{Optional \code{pcr_sample_calls} object produced by \code{classify_pcr_samples()}. When supplied, sample-level call fields are joined into the plot data.}

\item{qc}{Optional \code{pcr_qc} object produced by \code{qc_pcr_run()}. When supplied, QC fields are joined into the plot data.}
}
\value{
A \pkg{ggplot2} plot object whose data are derived from classified PCR evidence objects.
}
\description{
Plots PCR fragment size and concentration using already-classified peak evidence. This helper consumes the canonical evidence, sample-call, and QC objects rather than recomputing positivity or threshold rules inside the plotting layer.
}

#' @export
#' @name PCRpositive
#' @title Select samples having fragments of specific size and concentration.
#' @param dat a data frame holding results of the PCR amplification and electrophoresis run.
#' @param target_size a numeric scalar of the diagnostic fragment size.
#' @param tolerance a numeric vector with the left and right tolerance values.
#' @param threshold a numeric scalar with the threshold concentration value.
#' @returns a character vector of the sample identifiers of positive amplifications.
#' @description
#' PCR diagnostic assays are based on the amplification of nucleic acid fragments obtained with allele-specific oligonucleotide primers.
#' The mix of amplicons resulting from PCR amplification are then run through a high-throughput device to obtain the fragments
#' concentration versus size profile in order to detect the occurrence of the diagnostic fragment(s) by capillary electrophoresis .
#' The function returns the samples in a PCR reaction that are considered positive for the outcome of interest, based on a window of possible
#' concentration and fragment size values specified by the three arguments \code{target_size}, \code{tolerance}, and \code{threshold}.
#' @details
#' The column names of the data frame containing the data to be classified must follow a specific format.
#' \describe{
#' \item{WellID}{the column with the PCR plate well identifiers. These are generally a combination of uppercase letters (A to H or A to P,
#' depending on the size of the PCR plate) followed by two numbers (01 to 12).}
#' \item{SampleID}{the column with the sample names. It is good practice to format each identifier as a string of no more than 10 ASCII characters or so.}
#' \item{Size}{the column with the fragments size, usually expressed in base pairs (bp).}
#' \item{Conc}{the column with the fragments concentration, usually expressed in ng/µL.}
#' }
#' @note
#' At present the target fragment size argument needs a single value, hence the function does not consider the case when there is more than one
#' diagnostic amplicon.
#' @family related functions
#' @examples
#' # load the data
#' data(mosquito)
#'
#' # detect samples with a target amplicon size of 390 ± 10 bp and 0.2 ng/uL concentration
#' PCRpositive(mosquito, 390, c(10, 10), 0.2)
#'
#' # the tolerance around the target size can be asymmetric
#' PCRpositive(mosquito, 390, c(0, 10), 0.2)
#'
#' # another target size will obviously return a different vector of samples
#' PCRpositive(mosquito, 315, c(0, 10), 0.2)
#'
PCRpositive <- function(dat, target_size, tolerance, threshold) {
  .assert_dat(dat)
  .assert_required_cols(dat, c("SampleID", "Size", "Conc"), "column names in input data frame must match 'SampleID', 'Size', and 'Conc'")
  .assert_positive_numeric_scalar(target_size, "target_size")
  .assert_tolerance(tolerance, "the tolerance argument must be a numeric vector of two values greater or equal to zero")
  .assert_nonnegative_numeric_scalar(threshold, "threshold")

  r <- c(target_size - tolerance[1L], target_size + tolerance[2L])

  if (!is.numeric(dat$Size)) {
    return(NULL)
  }

  valid_rows <-
    !is.na(dat$Size) &
    is.finite(dat$Size) &
    dat$Size > 0 &
    !is.na(dat$Conc) &
    is.finite(dat$Conc) &
    dat$Conc >= 0 &
    !is.na(dat$SampleID) &
    nzchar(as.character(dat$SampleID))

  dat <- dat[valid_rows, , drop = FALSE]

  if (nrow(dat) == 0L) {
    return(NULL)
  }

  legacy_well <- if ("WellID" %in% names(dat)) {
    as.character(dat$WellID)
  } else {
    sprintf("W%05d", seq_len(nrow(dat)))
  }

  peaks_dat <- data.frame(
    run_id = rep("legacy-run", nrow(dat)),
    plate_id = rep("legacy-plate", nrow(dat)),
    well_id = legacy_well,
    sample_id = as.character(dat$SampleID),
    peak_id = paste0("peak-", seq_len(nrow(dat))),
    size_bp = as.numeric(dat$Size),
    concentration = as.numeric(dat$Conc),
    raw_file = rep("in-memory", nrow(dat)),
    instrument = rep("legacy", nrow(dat)),
    stringsAsFactors = FALSE
  )

  assay_dat <- data.frame(
    assay_id = "legacy-assay",
    target_id = "legacy-target",
    expected_size_bp = target_size,
    lower_size_bp = r[1L],
    upper_size_bp = r[2L],
    min_concentration = threshold,
    biological_label = "positive",
    rule_group = "legacy",
    stringsAsFactors = FALSE
  )

  peaks <- pcr_peaks(peaks_dat)
  assay <- pcr_assay(assay_dat)
  peak_calls <- pcr_peak_calls(peaks, assay)
  sample_calls <- pcr_sample_calls(peak_calls)

  positives <- sample_calls$sample_id[sample_calls$call == "positive"] |>
    as.character() |>
    unique() |>
    sort()

  if (length(positives) == 0L) NULL else positives
}

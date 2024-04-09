#' @export
#' @name PCRoutcome
#' @title Classification of PCR samples based on diagnostic nucleic acid fragments.
#' @param dat a data frame holding results of a PCR amplification and electrophoresis run.
#' @param targets a named numeric vector of diagnostic fragment sizes.
#' @param tolerance a numeric vector with the left and right tolerance values.
#' @param threshold a numeric scalar with the threshold concentration value.
#' @returns A data frame with the PCR plate well identifier, the sample identifier, and the classification outcome.
#' @description
#' Takes an input data frame with the size/concentration profile of DNA/RNA fragments, and returns an output data frame of samples classified
#' based on the size of diagnostic fragments.
#' @details
#' The \code{targets} argument must be a named vector, where names correspond to the classification categories (e.g. species, clones, etc.).
#' Note that based on the specific combination of \code{targets}, \code{tolerance}, and \code{threshold} parameters, a sample can be classified
#' in more than a single category. This may have biological significance or not at all, and should be checked a posteriori.
#' Samples that cannot be assigned to a category return NA.
#' @family related functions
#' @importFrom rlang .data
#' @examples
#' # load the data
#' data(mosquito)
#'
#' # define a named vector of classification sizes (categories are species names in this case)
#' targets <-  c(arabiensis = 315, gambiae = 390, melas = 464)
#'
#' # classify samples with a tolerance of ±10 bp and 0.2 ng/uL concentration
#' head(PCRoutcome(mosquito, targets, c(10,10), 0.2), head = 10L)
#'
#' # the tolerance around the target size can be asymmetric
#' head(PCRoutcome(mosquito, targets, c(0,10), 0.2), head = 10L)
#'
PCRoutcome <- function(dat, targets, tolerance, threshold) {

  # check dat is a data frame
  stopifnot("the dat argument must be a data frame" = class(dat) %in% c("data.frame", "tbl", "tbl_df", "spec_tbl_df"))

  # check dat header names
  stopifnot("column names in input data frame must match 'WellID', 'SampleID', 'Size', and 'Conc'" = c("WellID", "SampleID", "Size", "Conc") %in% names(dat))

  # check targets is a named vector with positive numeric elements
  stopifnot("the targets argument must be a named numeric vector of positive values" = is.numeric(targets) & !is.null(attributes(targets)) & targets > 0)

  # check tolerance vector has two positive numeric elements
  stopifnot("the tolerance argument must be a numeric vector of two values greater or equal to zero" = is.numeric(tolerance) & length(tolerance) == 2 & tolerance[1L] >= 0 & tolerance[2L] >= 0)

  # check threshold vector has one positive numeric element
  stopifnot("the threshold argument must be a numeric scalar greater or equal to zero" = is.numeric(threshold) & length(threshold) == 1 & threshold >= 0)

  dplyr::left_join(
    x = dat %>%
      dplyr::select(.data$WellID, .data$SampleID) %>%
      unique(),
    y = lapply(targets,
               function(x) PCRpositive(dat, target_size = x, tolerance = tolerance, threshold = threshold)
    ) %>%
      tibble::enframe("Outcome", "SampleID") %>%
      tidyr::unnest(cols = .data$SampleID) %>%
      dplyr::relocate(.data$SampleID, .data$Outcome),
    by = "SampleID"
  )

}

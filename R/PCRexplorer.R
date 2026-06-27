#' @export
#' @name PCRexplorer
#' @title Visualisation of nucleic acid fragments size versus concentration profiles.
#' @param dat a data frame holding results of a PCR amplification and electrophoresis run.
#' @param targets a named numeric vector of diagnostic fragment sizes.
#' @param tolerance a numeric vector with the left and right tolerance values.
#' @param threshold a numeric scalar with the threshold concentration value.
#' @param logx logical operator to display fragments size values on logarithmic scale.
#' @param logy logical operator to display concentration values on logarithmic scale.
#' @param xlimits numeric vector restricting visualisation of fragments size range within min and max window.
#' @param join logical operator to show lines joining points from the same sample.
#' @param control string of the sample identifier name to show lines joining points of template samples.
#' @description
#' In order to make an informed choice for the tolerance and threshold settings, it is useful to visualise in a single plot the full range
#' of fragment sizes and concentrations returned by a PCR run, as well as their mutual relationships. For specific examples about how to
#' interpret and make use of this plot, see the package vignette.
#' @importFrom rlang .data
#' @examples
#' # load the data
#' data(mosquito)
#'
#' # parameter settings
#' targets <- c(arabiensis = 315, gambiae = 390, melas = 464)
#' tolerance <- c(0, 10)
#' threshold <- 0.05
#'
#' PCRexplorer(mosquito, targets, tolerance, threshold, logx = TRUE, logy = TRUE, join = TRUE, control = "CTR")
#'
PCRexplorer <- function(dat, targets, tolerance = NULL, threshold = NULL, logx = FALSE, logy = FALSE, xlimits = NULL, join = FALSE, control = NULL) {
  .assert_dat(dat)
  .assert_required_cols(dat, c("SampleID", "Size", "Conc"), "column names in input data frame must match 'SampleID', 'Size', and 'Conc'")

  # check targets is a vector with positive numeric elements
  stopifnot("the targets argument must be a numeric vector of positive values" = is.numeric(targets) & targets > 0)

  # check tolerance vector has two positive numeric elements
  if (!is.null(tolerance)) {
    .assert_tolerance(tolerance, "the tolerance argument must be a numeric vector of two values greater than or equal to zero")
  }

  # check threshold vector has one positive numeric element
  if (!is.null(threshold)) {
    .assert_nonnegative_numeric_scalar(threshold, "threshold")
  }

  # check that both the tolerance and threshold arguments are not NULL, if one of them is given
  if (!is.null(tolerance) || !is.null(threshold)) {
    stopifnot("the tolerance and threshold arguments must be both given" = !is.null(tolerance) & !is.null(threshold))
  }

  # check that logx, logy, and join are logical constants
  stopifnot("logx, logy, and join, must be logical constants" = is.logical(logx) & is.logical(logy) & is.logical(join))

  # check xlimits numeric vector has two ordered positive elements
  if (!is.null(xlimits)) {
    stopifnot("the xlimits argument must be a numeric vector of two ordered positive values" = is.numeric(xlimits) & length(xlimits) == 2 & xlimits[1L] >= 0 & xlimits[2L] > xlimits[1L])
  }

  # check that the control argument is an atomic string
  if (!is.null(control)) {
    stopifnot("the control argument must be an atomic string" = is.character(control) & length(control) == 1)
  }

  if (!is.null(tolerance) && !is.null(threshold)) {
    tiles <- data.frame(target = targets) %>%
      dplyr::mutate(
        xmin_ = .data$target - tolerance[1L],
        xmax_ = .data$target + tolerance[2L],
        ymin_ = threshold,
        ymax_ = max(dat$Conc, na.rm = TRUE)
      )
  }

  p <- ggplot2::ggplot(dat %>% dplyr::filter(!is.na(.data$Size))) +
    ggplot2::geom_vline(xintercept = targets, col = "blue") +
    ggplot2::labs(x = "Fragment Size (bp)", y = "Conc. (ng/uL)") +
    ggplot2::theme_linedraw()

  if (!is.null(tolerance) && !is.null(threshold)) {
    p <- p + ggplot2::geom_rect(
      data = tiles,
      ggplot2::aes(xmin = .data$xmin_, xmax = .data$xmax_, ymin = .data$ymin_, ymax = .data$ymax_), fill = "lightblue", alpha = .5
    )
  }

  p <- p + ggplot2::geom_point(ggplot2::aes(.data$Size, .data$Conc), size = 4, col = "red", alpha = .3)

  if (logx) p <- p + ggplot2::scale_x_log10()
  if (logy) p <- p + ggplot2::scale_y_log10()

  if (!is.null(xlimits)) p <- p + ggplot2::xlim(c(xlimits[1], xlimits[2]))

  if (join) p <- p + ggplot2::geom_line(ggplot2::aes(.data$Size, .data$Conc, group = .data$SampleID), col = "orange", lwd = .75, lty = 3)
  if (!is.null(control)) {
    p <- p + ggplot2::geom_line(
      data = dat %>% dplyr::filter(.data$SampleID == {{ control }}),
      ggplot2::aes(.data$Size, .data$Conc, group = .data$SampleID), lwd = .75, lty = 2
    )
  }

  return(p)
}

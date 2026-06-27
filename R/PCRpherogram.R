#' @export
#' @name PCRpherogram
#' @title Visualise amplification results as pherograms in a PCR plate layout.
#' @param dat a data frame holding results of the PCR amplification and electrophoresis run.
#' @param target_size a numeric scalar of the diagnostic fragment size.
#' @param tolerance a numeric vector with the left and right tolerance values.
#' @param threshold a numeric scalar with the threshold concentration value.
#' @description
#' The plot mimics a collection of electropherograms for each of the samples in a PCR microwell plate, where 'bands' are represented as vertical bars
#' whose color depends on the classification outcome: bars matching the classification criteria, shown in the plot title, are highlighted
#' in red, whereas 'parasite bands' are shown in blue (#F8766D and #619CFF, respectively, \pkg{ggplot2} default colors). The sample identifier name is shown
#' on the top left corner of each 'pherogram'.
#' @examples
#' # load the data
#' data(mosquito)
#'
#' PCRpherogram(mosquito, target_size = 390, tolerance = c(0, 10), threshold = 0.05)
#'
PCRpherogram <- function(dat, target_size, tolerance, threshold) {
  .assert_dat(dat)
  .assert_required_cols(dat, c("SampleID", "Size", "Conc"), "column names in input data frame must match 'SampleID', 'Size', and 'Conc'")
  .assert_positive_numeric_scalar(target_size, "target_size")
  .assert_tolerance(tolerance, "the tolerance argument must be a numeric vector of two values greater or equal to zero")
  .assert_nonnegative_numeric_scalar(threshold, "threshold")

  r <- c(target_size - tolerance[1L], target_size + tolerance[2L])

  plot_dat <- dplyr::mutate(
    dat,
    outcome = ifelse(dat$Conc >= threshold & inside.range(dat$Size, r), "a_positive", "b_negative"),
    rrow = stringr::str_extract(dat$WellID, "[A-Z]"),
    ccol = stringr::str_extract(dat$WellID, "[0-9]+"),
    alpha_col = (1 - ((max(dat$Conc, na.rm = TRUE) - dat$Conc) / 100))
  )

  ggplot2::ggplot(plot_dat) +
    ggplot2::geom_vline(ggplot2::aes(xintercept = target_size), alpha = .1) +
    ggplot2::geom_text(ggplot2::aes_string(label = "SampleID"),
      x = 0, y = 5,
      hjust = "left", vjust = "top", size = 3
    ) +
    ggplot2::geom_col(ggplot2::aes_string(x = "Size", y = "Conc", col = "outcome", alpha = "alpha_col"), show.legend = FALSE) +
    ggplot2::ggtitle(paste("Target Amplicon Size =", target_size, "bp *** Tolerance =", r[1L], "-", r[2L], " bp *** Threshold =", threshold, "ng/uL")) +
    ggplot2::scale_x_continuous(trans = "log2") +
    ggplot2::scale_y_continuous(trans = "sqrt") +
    ggplot2::labs(x = "Fragment Size (bp)", y = "Conc. (ng/uL)") +
    ggplot2::facet_grid(rrow ~ ccol) +
    ggplot2::theme_bw() +
    # remove gridlines and ticks with legends
    ggplot2::theme(
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      axis.ticks.x = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank()
    )
}

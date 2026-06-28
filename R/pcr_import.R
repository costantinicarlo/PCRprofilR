normalize_pcr_peaks <- function(dat, mapping = NULL, allow_qc_issues = FALSE) {
    if (!inherits(dat, "data.frame")) {
        stop("normalize_pcr_peaks input must be a data frame", call. = FALSE)
    }

    default_mapping <- c(
        run_id = "RunID",
        plate_id = "PlateID",
        well_id = "WellID",
        sample_id = "SampleID",
        peak_id = "PeakID",
        size_bp = "Size",
        concentration = "Conc",
        raw_file = "RawFile",
        instrument = "Instrument"
    )

    required <- names(default_mapping)

    if (is.null(mapping)) {
        mapping <- default_mapping
    } else {
        if (is.null(names(mapping)) || any(!nzchar(names(mapping)))) {
            stop("mapping must be a named character vector", call. = FALSE)
        }
        unknown <- setdiff(names(mapping), required)
        if (length(unknown) > 0) {
            stop(sprintf("mapping has unknown canonical columns: %s", paste(unknown, collapse = ", ")), call. = FALSE)
        }
        mapping <- utils::modifyList(as.list(default_mapping), as.list(mapping))
        mapping <- unlist(mapping, use.names = TRUE)
    }

    source_cols <- unname(mapping)
    missing_source <- setdiff(source_cols, names(dat))
    if (length(missing_source) > 0) {
        stop(
            sprintf("normalize_pcr_peaks missing source columns: %s", paste(missing_source, collapse = ", ")),
            call. = FALSE
        )
    }

    out <- tibble::tibble(
        run_id = dat[[mapping[["run_id"]]]],
        plate_id = dat[[mapping[["plate_id"]]]],
        well_id = dat[[mapping[["well_id"]]]],
        sample_id = dat[[mapping[["sample_id"]]]],
        peak_id = dat[[mapping[["peak_id"]]]],
        size_bp = dat[[mapping[["size_bp"]]]],
        concentration = dat[[mapping[["concentration"]]]],
        raw_file = dat[[mapping[["raw_file"]]]],
        instrument = dat[[mapping[["instrument"]]]]
    )

    pcr_peaks(out, allow_qc_issues = allow_qc_issues)
}

.with_provenance <- function(x, metadata = list()) {
    tbl <- tibble::as_tibble(x)

    run_ids <- if ("run_id" %in% names(tbl)) {
        paste(sort(unique(as.character(tbl$run_id))), collapse = ";")
    } else {
        ""
    }

    assay_ids <- if ("assay_id" %in% names(tbl)) {
        paste(sort(unique(as.character(tbl$assay_id))), collapse = ";")
    } else if (!is.null(metadata$assay_id)) {
        as.character(metadata$assay_id)
    } else {
        ""
    }

    tbl$provenance_timestamp_utc <- format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
    tbl$provenance_package_version <- as.character(utils::packageVersion("PCRprofilR"))
    tbl$provenance_run_ids <- run_ids
    tbl$provenance_assay_ids <- assay_ids

    tbl
}

.write_pcr_table <- function(x, path, format = "csv") {
    if (identical(format, "tsv")) {
        utils::write.table(x, file = path, sep = "\t", row.names = FALSE, quote = TRUE)
    } else {
        utils::write.csv(x, file = path, row.names = FALSE)
    }
}

pcr_export_artifacts <- function(peak_calls, sample_calls, qc, output_dir, format = c("csv", "tsv"), metadata = list(), write_summary = TRUE) {
    format <- match.arg(format)

    if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
        stop("output_dir must be a non-empty character scalar", call. = FALSE)
    }

    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    ext <- if (identical(format, "tsv")) "tsv" else "csv"

    peak_calls_out <- .with_provenance(peak_calls, metadata = metadata)
    sample_calls_out <- .with_provenance(sample_calls, metadata = metadata)
    qc_out <- .with_provenance(qc, metadata = metadata)

    files <- c(
        peak_calls = file.path(output_dir, paste0("peak_calls.", ext)),
        sample_calls = file.path(output_dir, paste0("sample_calls.", ext)),
        qc = file.path(output_dir, paste0("qc.", ext))
    )

    .write_pcr_table(peak_calls_out, files[["peak_calls"]], format = format)
    .write_pcr_table(sample_calls_out, files[["sample_calls"]], format = format)
    .write_pcr_table(qc_out, files[["qc"]], format = format)

    summary_file <- NA_character_
    if (isTRUE(write_summary)) {
        summary_file <- file.path(output_dir, "summary_report.txt")
        call_states <- table(sample_calls_out$call_state)
        qc_states <- table(qc_out$qc_status)

        summary_lines <- c(
            "PCRprofilR Summary Report",
            paste0("generated_utc: ", format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")),
            paste0("package_version: ", as.character(utils::packageVersion("PCRprofilR"))),
            "",
            "call_state_counts:",
            paste(utils::capture.output(print(call_states)), collapse = "\n"),
            "",
            "qc_status_counts:",
            paste(utils::capture.output(print(qc_states)), collapse = "\n")
        )
        writeLines(summary_lines, con = summary_file)
    }

    out <- list(
        files = unname(files),
        summary_file = summary_file,
        format = format
    )
    class(out) <- c("pcr_export_artifacts", class(out))
    out
}

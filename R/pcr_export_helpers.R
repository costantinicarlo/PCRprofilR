.pcr_reserved_provenance_cols <- c(
    "provenance_timestamp_utc",
    "provenance_package_version",
    "provenance_interpretation_model_version",
    "provenance_run_ids",
    "provenance_assay_ids",
    "provenance_source_revision"
)

.pcr_validate_export_metadata <- function(metadata) {
    if (length(metadata) == 0L) {
        return(invisible(metadata))
    }
    if (!is.list(metadata) || is.null(names(metadata)) || any(!nzchar(names(metadata)))) {
        stop("metadata must be a named list of scalar provenance fields", call. = FALSE)
    }
    user_cols <- paste0("provenance_user_", names(metadata))
    collisions <- intersect(user_cols, .pcr_reserved_provenance_cols)
    if (length(collisions) > 0) {
        stop(sprintf("metadata field names collide with reserved provenance columns: %s", paste(collisions, collapse = ", ")), call. = FALSE)
    }
    for (nm in names(metadata)) {
        val <- metadata[[nm]]
        if (!is.atomic(val) || length(val) != 1L) {
            stop(sprintf("metadata field '%s' must be a scalar atomic value or NA", nm), call. = FALSE)
        }
    }
    invisible(metadata)
}

.pcr_source_revision <- function(metadata) {
    if (!is.null(metadata$source_revision) && !is.na(metadata$source_revision)) {
        return(as.character(metadata$source_revision))
    }
    remote_sha <- tryCatch(
        utils::packageDescription("PCRprofilR", fields = "RemoteSha"),
        error = function(e) NA_character_,
        warning = function(w) NA_character_
    )
    if (is.null(remote_sha) || is.na(remote_sha) || !nzchar(remote_sha)) NA_character_ else as.character(remote_sha)
}

# Builds one shared provenance context per export operation, so every artifact in the
# same export receives identical timestamp/version/source-revision values rather than
# each table independently generating its own.
.pcr_build_export_provenance <- function(run_ids_source, metadata = list()) {
    .pcr_validate_export_metadata(metadata)

    run_ids <- if ("run_id" %in% names(run_ids_source)) {
        paste(sort(unique(as.character(run_ids_source$run_id))), collapse = ";")
    } else {
        ""
    }
    assay_ids <- if ("assay_id" %in% names(run_ids_source)) {
        paste(sort(unique(as.character(run_ids_source$assay_id))), collapse = ";")
    } else if (!is.null(metadata$assay_id)) {
        as.character(metadata$assay_id)
    } else {
        ""
    }

    list(
        timestamp_utc = format(as.POSIXct(Sys.time(), tz = "UTC"), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
        package_version = as.character(utils::packageVersion("PCRprofilR")),
        interpretation_model_version = .pcr_interpretation_model_version,
        run_ids = run_ids,
        assay_ids = assay_ids,
        source_revision = .pcr_source_revision(metadata),
        user_metadata = metadata
    )
}

.with_provenance <- function(x, provenance) {
    tbl <- tibble::as_tibble(x)

    tbl$provenance_timestamp_utc <- provenance$timestamp_utc
    tbl$provenance_package_version <- provenance$package_version
    tbl$provenance_interpretation_model_version <- provenance$interpretation_model_version
    tbl$provenance_run_ids <- provenance$run_ids
    tbl$provenance_assay_ids <- provenance$assay_ids
    tbl$provenance_source_revision <- if (is.na(provenance$source_revision)) NA_character_ else provenance$source_revision

    for (nm in names(provenance$user_metadata)) {
        tbl[[paste0("provenance_user_", nm)]] <- provenance$user_metadata[[nm]]
    }

    tbl
}

# Detects character values that begin (after leading whitespace) with a spreadsheet
# formula marker (=, +, -, @). Never mutates canonical values; only warns, so a
# reviewer knows to treat the export carefully if it will be opened in spreadsheet
# software. See OWASP "CSV Injection".
.pcr_warn_formula_like_values <- function(x, context) {
    char_cols <- names(x)[vapply(x, is.character, logical(1))]
    if (length(char_cols) == 0L) {
        return(invisible(NULL))
    }
    flagged <- character(0)
    for (col in char_cols) {
        vals <- x[[col]]
        hits <- !is.na(vals) & grepl("^\\s*[=+@-]", vals)
        if (any(hits)) {
            flagged <- c(flagged, sprintf("%s (%d value(s))", col, sum(hits)))
        }
    }
    if (length(flagged) > 0) {
        warning(
            sprintf(
                "%s contains values beginning with a spreadsheet formula marker (=, +, -, @) in: %s. Canonical values were not modified; treat this export cautiously if opened in spreadsheet software.",
                context, paste(flagged, collapse = "; ")
            ),
            call. = FALSE
        )
    }
    invisible(flagged)
}

.write_pcr_table <- function(x, path, format = "csv") {
    .pcr_warn_formula_like_values(x, basename(path))
    if (identical(format, "tsv")) {
        utils::write.table(x, file = path, sep = "\t", row.names = FALSE, quote = TRUE)
    } else {
        utils::write.csv(x, file = path, row.names = FALSE)
    }
}

pcr_export_artifacts <- function(peak_calls, sample_calls, qc, output_dir, format = c("csv", "tsv"), metadata = list(), write_summary = TRUE, profile_evidence = NULL, profile_rules = NULL) {
    format <- match.arg(format)

    if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
        stop("output_dir must be a non-empty character scalar", call. = FALSE)
    }

    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

    ext <- if (identical(format, "tsv")) "tsv" else "csv"

    provenance <- .pcr_build_export_provenance(tibble::as_tibble(peak_calls), metadata = metadata)

    peak_calls_out <- .with_provenance(peak_calls, provenance)
    sample_calls_out <- .with_provenance(sample_calls, provenance)
    qc_out <- .with_provenance(qc, provenance)

    files <- c(
        peak_calls = file.path(output_dir, paste0("peak_calls.", ext)),
        sample_calls = file.path(output_dir, paste0("sample_calls.", ext)),
        qc = file.path(output_dir, paste0("qc.", ext))
    )

    .write_pcr_table(peak_calls_out, files[["peak_calls"]], format = format)
    .write_pcr_table(sample_calls_out, files[["sample_calls"]], format = format)
    .write_pcr_table(qc_out, files[["qc"]], format = format)

    profile_evidence_out <- if (!is.null(profile_evidence)) {
        .with_provenance(profile_evidence, provenance)
    } else {
        .with_provenance(pcr_profile_evidence_empty(), provenance)
    }
    files <- c(files, profile_evidence = file.path(output_dir, paste0("profile_evidence.", ext)))
    .write_pcr_table(profile_evidence_out, files[["profile_evidence"]], format = format)

    # Absence of profile rules must be an explicit, machine-readable fact, not something
    # inferable only from a missing file: always write a (possibly zero-row) canonical
    # profile_rules artifact.
    profile_rules_supplied <- !is.null(profile_rules) && nrow(profile_rules) > 0L
    profile_rules_out <- if (profile_rules_supplied) {
        .with_provenance(profile_rules, provenance)
    } else {
        .with_provenance(pcr_profile_rules_empty(), provenance)
    }
    profile_rules_out$provenance_profile_rules_supplied <- profile_rules_supplied
    files <- c(files, profile_rules = file.path(output_dir, paste0("profile_rules.", ext)))
    .write_pcr_table(profile_rules_out, files[["profile_rules"]], format = format)

    summary_file <- NA_character_
    if (isTRUE(write_summary)) {
        summary_file <- file.path(output_dir, "summary_report.txt")
        call_states <- table(sample_calls_out$call_state)
        qc_states <- table(qc_out$qc_status)
        rule_versions <- if (profile_rules_supplied) paste(sort(unique(profile_rules$rule_version)), collapse = ";") else ""

        summary_lines <- c(
            "PCRprofilR Summary Report",
            paste0("generated_utc: ", provenance$timestamp_utc),
            paste0("package_version: ", provenance$package_version),
            paste0("interpretation_model_version: ", provenance$interpretation_model_version),
            paste0("profile_rules_supplied: ", profile_rules_supplied),
            paste0("profile_rule_versions: ", rule_versions),
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
        format = format,
        profile_rules_supplied = profile_rules_supplied
    )
    class(out) <- c("pcr_export_artifacts", class(out))
    out
}

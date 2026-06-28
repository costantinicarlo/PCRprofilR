test_that("pcr_export_artifacts writes peak, sample, and qc outputs with provenance", {
    peak_calls <- tibble::tibble(
        run_id = "run-1",
        assay_id = "assay-1",
        target_id = "target-a",
        sample_id = "S1",
        matched = TRUE
    )
    class(peak_calls) <- c("pcr_peak_calls", class(peak_calls))

    sample_calls <- tibble::tibble(
        run_id = "run-1",
        sample_id = "S1",
        call = "positive",
        call_state = "positive",
        review_required = FALSE
    )
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))

    qc <- tibble::tibble(
        run_id = "run-1",
        sample_id = "S1",
        qc_status = "pass",
        contamination_candidate = FALSE
    )
    class(qc) <- c("pcr_qc", class(qc))

    out_dir <- tempfile()
    out <- PCRprofilR:::pcr_export_artifacts(peak_calls, sample_calls, qc, out_dir, format = "csv")

    expect_s3_class(out, "pcr_export_artifacts")
    expect_length(out$files, 3)
    expect_true(all(file.exists(out$files)))
    expect_true(file.exists(out$summary_file))

    exported <- utils::read.csv(out$files[[1]], stringsAsFactors = FALSE)
    expect_true(all(c("provenance_timestamp_utc", "provenance_package_version", "provenance_run_ids", "provenance_assay_ids") %in% names(exported)))
    expect_identical(exported$provenance_run_ids[[1]], "run-1")
    expect_identical(exported$provenance_assay_ids[[1]], "assay-1")
})

test_that("pcr_export_artifacts supports TSV outputs", {
    peak_calls <- tibble::tibble(run_id = "run-1", assay_id = "assay-1", target_id = "target-a", sample_id = "S1", matched = TRUE)
    sample_calls <- tibble::tibble(run_id = "run-1", sample_id = "S1", call = "positive", call_state = "positive", review_required = FALSE)
    qc <- tibble::tibble(run_id = "run-1", sample_id = "S1", qc_status = "pass", contamination_candidate = FALSE)

    out_dir <- tempfile()
    out <- PCRprofilR:::pcr_export_artifacts(peak_calls, sample_calls, qc, out_dir, format = "tsv", write_summary = FALSE)

    expect_true(all(grepl("\\.tsv$", out$files)))
    expect_true(all(file.exists(out$files)))
    expect_true(is.na(out$summary_file))
})

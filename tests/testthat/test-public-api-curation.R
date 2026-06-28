test_that("curated public API exports are available", {
    exports <- getNamespaceExports("PCRprofilR")

    expect_true(all(c(
        "as_pcr_peaks",
        "as_pcr_assay",
        "validate_pcr_peaks",
        "validate_pcr_assay",
        "detect_pcr_peaks",
        "classify_pcr_samples",
        "qc_pcr_run",
        "summarize_pcr_replicates",
        "run_pcr_batch",
        "report_pcr_calls"
    ) %in% exports))
})

test_that("curated API functions compose into deterministic pipeline", {
    peaks_raw <- data.frame(
        RunID = c("run-1", "run-1"),
        PlateID = c("plate-1", "plate-1"),
        WellID = c("A01", "A02"),
        SampleID = c("S1", "S2"),
        PeakID = c("peak-1", "peak-2"),
        Size = c(390, 500),
        Conc = c(0.35, 0.01),
        RawFile = c("run.csv", "run.csv"),
        Instrument = c("bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    )

    assay <- as_pcr_assay(data.frame(
        assay_id = "assay-1",
        target_id = "target-a",
        expected_size_bp = 390,
        lower_size_bp = 380,
        upper_size_bp = 400,
        min_concentration = 0.2,
        confirm_concentration = 0.3,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    peaks <- as_pcr_peaks(peaks_raw)
    expect_s3_class(peaks, "pcr_peaks")

    peak_calls <- detect_pcr_peaks(peaks, assay)
    sample_calls <- classify_pcr_samples(peak_calls)
    qc <- qc_pcr_run(peaks, sample_calls)

    expect_s3_class(peak_calls, "pcr_peak_calls")
    expect_s3_class(sample_calls, "pcr_sample_calls")
    expect_s3_class(qc, "pcr_qc")

    replicate_summary <- summarize_pcr_replicates(sample_calls, qc = qc)
    expect_s3_class(replicate_summary, "pcr_replicate_calls")

    out_dir <- tempfile()
    export_out <- report_pcr_calls(peak_calls, sample_calls, qc, out_dir, write_summary = TRUE)
    expect_s3_class(export_out, "pcr_export_artifacts")
    expect_true(all(file.exists(export_out$files)))
})

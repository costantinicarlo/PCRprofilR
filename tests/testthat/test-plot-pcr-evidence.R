test_that("plot_pcr_evidence consumes classified evidence objects", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A01", "A02"),
        sample_id = c("S1", "S2"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(390, 500),
        concentration = c(0.35, 0.01),
        raw_file = c("run.csv", "run.csv"),
        instrument = c("bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    ))

    assay <- PCRprofilR:::pcr_assay(data.frame(
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

    peak_calls <- detect_pcr_peaks(peaks, assay)
    sample_calls <- classify_pcr_samples(peak_calls)
    qc <- qc_pcr_run(peaks, sample_calls)

    expect_no_warning(
        p <- plot_pcr_evidence(peak_calls, sample_calls = sample_calls, qc = qc)
    )

    expect_s3_class(p, "ggplot")
    expect_true(all(c("evidence_zone", "matched", "call_state", "qc_status") %in% names(p$data)))
    expect_identical(p$data$call_state[p$data$sample_id == "S1"][[1]], "positive")
})

test_that("plot_pcr_evidence validates classified object inputs", {
    expect_error(plot_pcr_evidence(data.frame()), "pcr_peak_calls")
})

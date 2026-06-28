test_that("three-zone evidence zones classify concentration boundaries", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1", "run-1"),
        plate_id = c("plate-1", "plate-1", "plate-1"),
        well_id = c("A01", "A02", "A03"),
        sample_id = c("S_below", "S_mid", "S_high"),
        peak_id = c("peak-1", "peak-2", "peak-3"),
        size_bp = c(390, 390, 390),
        concentration = c(0.19, 0.25, 0.3),
        raw_file = c("run.csv", "run.csv", "run.csv"),
        instrument = c("bioanalyzer", "bioanalyzer", "bioanalyzer"),
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

    out <- PCRprofilR:::pcr_peak_calls(peaks, assay)

    expect_identical(out$evidence_zone, c("below_analytical", "analytical_to_confirmatory", "above_confirmatory"))
})

test_that("sample calls include threshold-zone precedence", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A01", "A02"),
        sample_id = c("S_mid", "S_high"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(390, 390),
        concentration = c(0.25, 0.31),
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

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_equal(calls$sample_threshold_zone, c("analytical_to_confirmatory", "above_confirmatory"))
    expect_equal(calls$threshold_status, c("review", "positive"))
    expect_equal(calls$call, c("positive", "positive"))
})

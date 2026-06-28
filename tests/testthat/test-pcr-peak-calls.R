test_that("pcr_peak_calls returns evidence table with expected columns", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A01",
        sample_id = "S1",
        peak_id = "peak-1",
        size_bp = 390,
        concentration = 0.25,
        raw_file = "run.csv",
        instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    ))

    assay <- PCRprofilR:::pcr_assay(data.frame(
        assay_id = "assay-1",
        target_id = "target-a",
        expected_size_bp = 390,
        lower_size_bp = 380,
        upper_size_bp = 400,
        min_concentration = 0.2,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    out <- PCRprofilR:::pcr_peak_calls(peaks, assay)

    expect_s3_class(out, "pcr_peak_calls")
    expect_true(all(c("size_delta_bp", "within_window", "above_min_concentration", "above_confirm_concentration", "evidence_zone", "matched") %in% names(out)))
    expect_true(out$matched[[1]])
    expect_identical(out$evidence_zone[[1]], "above_confirmatory")
})

test_that("pcr_peak_calls keeps size and concentration boundaries inclusive", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A01", "A02"),
        sample_id = c("S_low", "S_high"),
        peak_id = c("peak-low", "peak-high"),
        size_bp = c(380, 400),
        concentration = c(0.2, 0.2),
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
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    out <- PCRprofilR:::pcr_peak_calls(peaks, assay)

    expect_true(all(out$within_window))
    expect_true(all(out$above_min_concentration))
    expect_true(all(out$matched))
})

test_that("pcr_peak_calls marks non-matching evidence correctly", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A03",
        sample_id = "S3",
        peak_id = "peak-3",
        size_bp = 500,
        concentration = 0.05,
        raw_file = "run.csv",
        instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    ))

    assay <- PCRprofilR:::pcr_assay(data.frame(
        assay_id = "assay-1",
        target_id = "target-a",
        expected_size_bp = 390,
        lower_size_bp = 380,
        upper_size_bp = 400,
        min_concentration = 0.2,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    out <- PCRprofilR:::pcr_peak_calls(peaks, assay)

    expect_false(out$within_window[[1]])
    expect_false(out$above_min_concentration[[1]])
    expect_false(out$matched[[1]])
    expect_identical(out$evidence_zone[[1]], "below_analytical")
})

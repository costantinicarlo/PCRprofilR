test_that("pcr_sample_calls assigns weak_positive for analytical-to-confirmatory evidence", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A01",
        sample_id = "S_weak",
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
        confirm_concentration = 0.3,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call_state[[1]], "weak_positive")
    expect_true(calls$review_required[[1]])
    expect_identical(calls$threshold_status[[1]], "review")
    expect_identical(calls$call[[1]], "positive")
})

test_that("pcr_sample_calls assigns positive for compatible multi-target same-label profiles", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A02", "A02"),
        sample_id = c("S_amb", "S_amb"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(315, 390),
        concentration = c(0.35, 0.35),
        raw_file = c("run.csv", "run.csv"),
        instrument = c("bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    ))

    assay <- PCRprofilR:::pcr_assay(data.frame(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("target-a", "target-b"),
        expected_size_bp = c(315, 390),
        lower_size_bp = c(305, 380),
        upper_size_bp = c(325, 400),
        min_concentration = c(0.2, 0.2),
        confirm_concentration = c(0.3, 0.3),
        biological_label = c("a", "a"),
        rule_group = c("species", "species"),
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call_state[[1]], "positive")
    expect_false(calls$review_required[[1]])
    expect_identical(calls$threshold_status[[1]], "positive")
    expect_identical(calls$rule_status[[1]], "compatible")
})

test_that("pcr_sample_calls assigns indeterminate_review for below-analytical in-window evidence", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A03",
        sample_id = "S_ind",
        peak_id = "peak-1",
        size_bp = 390,
        concentration = 0.1,
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
        confirm_concentration = 0.3,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call_state[[1]], "indeterminate_review")
    expect_true(calls$review_required[[1]])
    expect_identical(calls$threshold_status[[1]], "review")
    expect_identical(calls$call[[1]], "negative")
})

test_that("pcr_qc exposes state-specific review flags", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A01",
        sample_id = "S_weak",
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
        confirm_concentration = 0.3,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))
    qc <- PCRprofilR:::pcr_qc(peaks, calls)

    expect_true("weak_positive_state" %in% names(qc))
    expect_true("ambiguous_call_state" %in% names(qc))
    expect_true("indeterminate_call_state" %in% names(qc))
    expect_true(qc$weak_positive_state[[1]])
})

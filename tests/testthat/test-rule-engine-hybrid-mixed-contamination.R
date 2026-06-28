test_that("pcr_sample_calls assigns hybrid_candidate for two matched biological labels", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A01", "A01"),
        sample_id = c("S_hybrid", "S_hybrid"),
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
        biological_label = c("arabiensis", "gambiae"),
        rule_group = c("species", "species"),
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call_state[[1]], "hybrid_candidate")
    expect_true(calls$hybrid_candidate[[1]])
    expect_true(calls$review_required[[1]])
})

test_that("pcr_sample_calls assigns mixed_profile_candidate for three matched labels", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1", "run-1"),
        plate_id = c("plate-1", "plate-1", "plate-1"),
        well_id = c("A02", "A02", "A02"),
        sample_id = c("S_mixed", "S_mixed", "S_mixed"),
        peak_id = c("peak-1", "peak-2", "peak-3"),
        size_bp = c(315, 390, 464),
        concentration = c(0.35, 0.35, 0.35),
        raw_file = c("run.csv", "run.csv", "run.csv"),
        instrument = c("bioanalyzer", "bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    ))

    assay <- PCRprofilR:::pcr_assay(data.frame(
        assay_id = c("assay-1", "assay-1", "assay-1"),
        target_id = c("target-a", "target-b", "target-c"),
        expected_size_bp = c(315, 390, 464),
        lower_size_bp = c(305, 380, 454),
        upper_size_bp = c(325, 400, 474),
        min_concentration = c(0.2, 0.2, 0.2),
        confirm_concentration = c(0.3, 0.3, 0.3),
        biological_label = c("arabiensis", "gambiae", "melas"),
        rule_group = c("species", "species", "species"),
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call_state[[1]], "mixed_profile_candidate")
    expect_true(calls$mixed_profile_candidate[[1]])
    expect_true(calls$review_required[[1]])
})

test_that("pcr_qc does not flag a passing positive control as contamination", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A12",
        sample_id = "CTR",
        peak_id = "peak-1",
        size_bp = 390,
        concentration = 0.35,
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

    expect_identical(qc$control_role[[1]], "positive_control")
    expect_false(qc$positive_control_failed[[1]])
    expect_false(qc$contamination_candidate[[1]])
    expect_identical(qc$qc_status[[1]], "pass")
})

test_that("pcr_qc flags no-template control positives as contamination candidates", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A12",
        sample_id = "NTC",
        peak_id = "peak-1",
        size_bp = 390,
        concentration = 0.35,
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

    expect_identical(qc$control_role[[1]], "no_template_control")
    expect_true(qc$no_template_control_failed[[1]])
    expect_true(qc$contamination_candidate[[1]])
    expect_identical(qc$qc_status[[1]], "fail")
})

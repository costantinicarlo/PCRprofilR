test_that("pcr_sample_calls aggregates target matches to sample-level calls", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A01", "A01"),
        sample_id = c("S1", "S1"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(390, 700),
        concentration = c(0.30, 0.01),
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

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_s3_class(calls, "pcr_sample_calls")
    expect_equal(nrow(calls), 1)
    expect_identical(calls$call[[1]], "positive")
    expect_identical(calls$matched_target_count[[1]], 1L)
    expect_identical(calls$matched_targets[[1]], "target-a")
    expect_identical(calls$matched_rule_groups[[1]], "species")
    expect_identical(calls$rule_status[[1]], "compatible")
})

test_that("pcr_sample_calls returns negative when no targets match", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A02",
        sample_id = "S2",
        peak_id = "peak-1",
        size_bp = 700,
        concentration = 0.01,
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

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call[[1]], "negative")
    expect_identical(calls$matched_target_count[[1]], 0L)
    expect_identical(calls$matched_targets[[1]], "")
    expect_identical(calls$matched_rule_groups[[1]], "")
})

test_that("pcr_sample_calls supports multiple matched targets", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A03", "A03"),
        sample_id = c("S3", "S3"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(315, 390),
        concentration = c(0.3, 0.35),
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
        biological_label = c("arabiensis", "gambiae"),
        rule_group = c("species", "species"),
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call[[1]], "positive")
    expect_identical(calls$matched_target_count[[1]], 2L)
    expect_true(grepl("target-a", calls$matched_targets[[1]], fixed = TRUE))
    expect_true(grepl("target-b", calls$matched_targets[[1]], fixed = TRUE))
})

test_that("pcr_sample_calls marks forbidden target matches for review", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A04", "A04"),
        sample_id = c("S4", "S4"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(315, 390),
        concentration = c(0.3, 0.35),
        raw_file = c("run.csv", "run.csv"),
        instrument = c("bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    ))

    assay <- PCRprofilR:::pcr_assay(data.frame(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("expected-a", "forbidden-b"),
        expected_size_bp = c(315, 390),
        lower_size_bp = c(305, 380),
        upper_size_bp = c(325, 400),
        min_concentration = c(0.2, 0.2),
        biological_label = c("species-a", "species-a"),
        rule_group = c("species", "species"),
        target_role = c("required", "forbidden"),
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call_state[[1]], "ambiguous_review")
    expect_identical(calls$rule_status[[1]], "forbidden_matched")
    expect_equal(calls$forbidden_target_count[[1]], 1L)
    expect_true(calls$review_required[[1]])
})

test_that("pcr_sample_calls marks missing required targets when partial evidence exists", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A05",
        sample_id = "S5",
        peak_id = "peak-1",
        size_bp = 390,
        concentration = 0.35,
        raw_file = "run.csv",
        instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    ))

    assay <- PCRprofilR:::pcr_assay(data.frame(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("required-a", "optional-b"),
        expected_size_bp = c(315, 390),
        lower_size_bp = c(305, 380),
        upper_size_bp = c(325, 400),
        min_concentration = c(0.2, 0.2),
        biological_label = c("species-a", "species-a"),
        rule_group = c("species", "species"),
        target_role = c("required", "optional"),
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))

    expect_identical(calls$call_state[[1]], "ambiguous_review")
    expect_identical(calls$rule_status[[1]], "missing_required_with_partial_match")
    expect_equal(calls$required_target_count[[1]], 1L)
    expect_equal(calls$missing_required_target_count[[1]], 1L)
    expect_true(calls$review_required[[1]])
})

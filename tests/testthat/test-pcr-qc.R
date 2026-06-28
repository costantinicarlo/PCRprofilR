test_that("pcr_qc returns machine-readable QC flags", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A01", "A02"),
        sample_id = c("S1", "S2"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(390, 500),
        concentration = c(0.3, 0.05),
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

    sample_calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))
    qc <- PCRprofilR:::pcr_qc(peaks, sample_calls)

    expect_s3_class(qc, "pcr_qc")
    expect_true(all(c("has_missing_well_id", "duplicate_sample_id_in_run", "control_sample", "control_role", "positive_control", "negative_control", "no_template_control", "blank_control", "no_matched_targets", "weak_positive_state", "ambiguous_call_state", "indeterminate_call_state", "positive_control_failed", "negative_control_failed", "no_template_control_failed", "blank_control_failed", "control_failure", "contamination_candidate", "qc_status") %in% names(qc)))
})

test_that("pcr_qc flags duplicate sample IDs across wells", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c("A01", "A02"),
        sample_id = c("S1", "S1"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(390, 390),
        concentration = c(0.3, 0.31),
        raw_file = c("run.csv", "run.csv"),
        instrument = c("bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    ))

    qc <- PCRprofilR:::pcr_qc(peaks)

    expect_true(any(qc$duplicate_sample_id_in_run))
    expect_true(any(qc$qc_status == "review"))
})

test_that("pcr_qc identifies control samples", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A01",
        sample_id = "CTR",
        peak_id = "peak-1",
        size_bp = 390,
        concentration = 0.3,
        raw_file = "run.csv",
        instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    ))

    qc <- PCRprofilR:::pcr_qc(peaks)

    expect_true(qc$control_sample[[1]])
    expect_identical(qc$control_role[[1]], "positive_control")
})

test_that("pcr_qc honors explicit control roles", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = c("run-1", "run-1", "run-1"),
        plate_id = c("plate-1", "plate-1", "plate-1"),
        well_id = c("A01", "A02", "A03"),
        sample_id = c("PC", "water", "empty"),
        control_role = c("positive_control", "no_template_control", "blank"),
        peak_id = c("peak-1", "peak-2", "peak-3"),
        size_bp = c(390, 390, 500),
        concentration = c(0.3, 0.3, 0.05),
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
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    ))

    calls <- PCRprofilR:::pcr_sample_calls(PCRprofilR:::pcr_peak_calls(peaks, assay))
    qc <- PCRprofilR:::pcr_qc(peaks, calls)

    pc <- qc[qc$control_role == "positive_control", ]
    ntc <- qc[qc$control_role == "no_template_control", ]
    blank <- qc[qc$control_role == "blank", ]

    expect_false(pc$positive_control_failed[[1]])
    expect_false(pc$contamination_candidate[[1]])
    expect_identical(pc$qc_status[[1]], "pass")

    expect_true(ntc$no_template_control_failed[[1]])
    expect_true(ntc$contamination_candidate[[1]])
    expect_identical(ntc$qc_status[[1]], "fail")

    expect_true(blank$blank_control_failed[[1]])
    expect_true(blank$contamination_candidate[[1]])
    expect_identical(blank$qc_status[[1]], "fail")
})

test_that("pcr_qc rejects unknown explicit control roles", {
    peaks <- PCRprofilR:::pcr_peaks(data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A01",
        sample_id = "S1",
        control_role = "mystery",
        peak_id = "peak-1",
        size_bp = 390,
        concentration = 0.3,
        raw_file = "run.csv",
        instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    ))

    expect_error(PCRprofilR:::pcr_qc(peaks), "control_role values")
})

test_that("pcr_qc flags QC-able missing and malformed well identifiers", {
    dat <- data.frame(
        run_id = c("run-1", "run-1"),
        plate_id = c("plate-1", "plate-1"),
        well_id = c(NA_character_, "not-a-well"),
        sample_id = c("S1", "S2"),
        peak_id = c("peak-1", "peak-2"),
        size_bp = c(390, 391),
        concentration = c(0.3, 0.3),
        raw_file = c("run.csv", "run.csv"),
        instrument = c("bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    )

    expect_error(PCRprofilR:::pcr_qc(dat), "well_id")

    qc <- qc_pcr_run(dat, allow_qc_issues = TRUE)

    missing <- qc[is.na(qc$well_id), ]
    malformed <- qc[qc$well_id == "not-a-well", ]

    expect_true(missing$has_missing_well_id[[1]])
    expect_false(missing$malformed_well_id[[1]])
    expect_identical(missing$qc_status[[1]], "fail")

    expect_false(malformed$has_missing_well_id[[1]])
    expect_true(malformed$malformed_well_id[[1]])
    expect_identical(malformed$qc_status[[1]], "fail")
})

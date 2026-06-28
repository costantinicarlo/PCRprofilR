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
    expect_true(all(c("has_missing_well_id", "duplicate_sample_id_in_run", "control_sample", "no_matched_targets", "weak_positive_state", "ambiguous_call_state", "indeterminate_call_state", "contamination_candidate", "qc_status") %in% names(qc)))
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
})

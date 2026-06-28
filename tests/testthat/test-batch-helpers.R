test_that("pcr_batch_run orchestrates canonical pipeline and writes output files", {
    peaks_in <- data.frame(
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

    assay_in <- data.frame(
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
    )

    peaks_path <- tempfile(fileext = ".csv")
    assay_path <- tempfile(fileext = ".csv")
    out_dir <- tempfile()

    utils::write.csv(peaks_in, peaks_path, row.names = FALSE)
    utils::write.csv(assay_in, assay_path, row.names = FALSE)

    out <- PCRprofilR:::pcr_batch_run(peaks_path, assay_path, out_dir)

    expect_s3_class(out, "pcr_batch_run")
    expect_true(inherits(out$peak_calls, "pcr_peak_calls"))
    expect_true(inherits(out$sample_calls, "pcr_sample_calls"))
    expect_true(inherits(out$qc, "pcr_qc"))
    expect_length(out$written_files, 3)
    expect_true(all(file.exists(out$written_files)))
})

test_that("pcr_batch_run validates file paths", {
    expect_error(
        PCRprofilR:::pcr_batch_run("missing.csv", "missing_assay.csv", tempdir()),
        "file not found"
    )
})

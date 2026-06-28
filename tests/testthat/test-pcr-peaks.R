test_that("pcr_peaks constructor returns validated canonical object", {
    dat <- data.frame(
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
    )

    out <- PCRprofilR:::pcr_peaks(dat)

    expect_s3_class(out, "pcr_peaks")
    expect_equal(names(out), names(dat))
    expect_equal(out$size_bp, 390)
    expect_equal(out$concentration, 0.25)
})

test_that("pcr_peaks reports missing required columns", {
    dat <- data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A01",
        sample_id = "S1",
        peak_id = "peak-1",
        concentration = 0.25,
        raw_file = "run.csv",
        instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    )

    expect_error(PCRprofilR:::pcr_peaks(dat), "missing required columns: size_bp")
})

test_that("pcr_peaks validates numeric constraints", {
    dat <- data.frame(
        run_id = "run-1",
        plate_id = "plate-1",
        well_id = "A01",
        sample_id = "S1",
        peak_id = "peak-1",
        size_bp = -1,
        concentration = 0.25,
        raw_file = "run.csv",
        instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    )

    expect_error(PCRprofilR:::pcr_peaks(dat), "size_bp")

    dat$size_bp <- 390
    dat$concentration <- -0.1
    expect_error(PCRprofilR:::pcr_peaks(dat), "concentration")
})

test_that("pcr_peaks coerces factor identifiers to character", {
    dat <- data.frame(
        run_id = factor("run-1"),
        plate_id = factor("plate-1"),
        well_id = factor("A01"),
        sample_id = factor("S1"),
        peak_id = factor("peak-1"),
        size_bp = 390,
        concentration = 0.25,
        raw_file = factor("run.csv"),
        instrument = factor("bioanalyzer")
    )

    out <- PCRprofilR:::pcr_peaks(dat)

    expect_type(out$run_id, "character")
    expect_type(out$instrument, "character")
})

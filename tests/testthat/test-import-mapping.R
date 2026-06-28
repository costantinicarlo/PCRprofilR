test_that("normalize_pcr_peaks maps default source columns", {
    dat <- data.frame(
        RunID = "run-1",
        PlateID = "plate-1",
        WellID = "A01",
        SampleID = "S1",
        PeakID = "peak-1",
        Size = 390,
        Conc = 0.25,
        RawFile = "run.csv",
        Instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    )

    out <- PCRprofilR:::normalize_pcr_peaks(dat)

    expect_s3_class(out, "pcr_peaks")
    expect_named(
        out,
        c("run_id", "plate_id", "well_id", "sample_id", "peak_id", "size_bp", "concentration", "raw_file", "instrument")
    )
})

test_that("normalize_pcr_peaks supports custom source mapping", {
    dat <- data.frame(
        run = "run-2",
        plate = "plate-2",
        well = "B01",
        sample = "S2",
        peak = "peak-2",
        bp = 315,
        conc = 0.4,
        file = "custom.csv",
        machine = "fragment-analyzer",
        stringsAsFactors = FALSE
    )

    mapping <- c(
        run_id = "run",
        plate_id = "plate",
        well_id = "well",
        sample_id = "sample",
        peak_id = "peak",
        size_bp = "bp",
        concentration = "conc",
        raw_file = "file",
        instrument = "machine"
    )

    out <- PCRprofilR:::normalize_pcr_peaks(dat, mapping = mapping)

    expect_s3_class(out, "pcr_peaks")
    expect_identical(out$sample_id, "S2")
    expect_identical(out$size_bp, 315)
})

test_that("normalize_pcr_peaks validates mapping names and source columns", {
    dat <- data.frame(
        RunID = "run-1",
        PlateID = "plate-1",
        WellID = "A01",
        SampleID = "S1",
        PeakID = "peak-1",
        Size = 390,
        Conc = 0.25,
        RawFile = "run.csv",
        Instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    )

    expect_error(
        PCRprofilR:::normalize_pcr_peaks(dat, mapping = c(foo = "bar")),
        "unknown canonical columns"
    )

    expect_error(
        PCRprofilR:::normalize_pcr_peaks(dat, mapping = c(run_id = "NotThere")),
        "missing source columns"
    )
})

test_that("as_pcr_peaks review path allows QC-able well issues", {
    dat <- data.frame(
        RunID = "run-1",
        PlateID = "plate-1",
        WellID = "",
        SampleID = "S1",
        PeakID = "peak-1",
        Size = 390,
        Conc = 0.25,
        RawFile = "run.csv",
        Instrument = "bioanalyzer",
        stringsAsFactors = FALSE
    )

    expect_error(as_pcr_peaks(dat), "well_id")

    out <- as_pcr_peaks(dat, allow_qc_issues = TRUE)
    expect_s3_class(out, "pcr_peaks")
    expect_identical(out$well_id[[1]], "")
})

test_that("all exported functions reject non-data-frame dat argument consistently", {
    expect_error(PCRpositive(1, 390, c(10, 10), 0.2), "dat argument must be a data frame")
    expect_error(PCRoutcome(1, c(gambiae = 390), c(10, 10), 0.2), "dat argument must be a data frame")
    expect_error(PCRexplorer(1, c(gambiae = 390)), "dat argument must be a data frame")
    expect_error(PCRpherogram(1, 390, c(10, 10), 0.2), "dat argument must be a data frame")
})

test_that("required-column errors are explicit and stable", {
    dat <- data.frame(SampleID = "S1", Size = 390, Conc = 0.3)

    expect_error(
        PCRoutcome(dat, c(gambiae = 390), c(10, 10), 0.2),
        "WellID"
    )
})

test_that("targets, tolerance, and threshold validations return actionable errors", {
    dat <- data.frame(
        WellID = "A01",
        SampleID = "S1",
        Size = 390,
        Conc = 0.3,
        stringsAsFactors = FALSE
    )

    expect_error(
        PCRoutcome(dat, c(390), c(10, 10), 0.2),
        "named numeric vector"
    )

    expect_error(
        PCRpositive(dat[, c("SampleID", "Size", "Conc")], 390, c(-1, 10), 0.2),
        "tolerance"
    )

    expect_error(
        PCRpositive(dat[, c("SampleID", "Size", "Conc")], 390, c(10, 10), -0.1),
        "threshold"
    )
})

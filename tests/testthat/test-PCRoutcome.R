test_that("PCRoutcome baseline classification is stable on mosquito data", {
    data(mosquito)

    targets <- c(arabiensis = 315, gambiae = 390, melas = 464)
    out <- PCRoutcome(mosquito, targets, tolerance = c(10, 10), threshold = 0.2)

    expect_s3_class(out, "data.frame")
    expect_equal(nrow(out), 48)
    expect_equal(sum(is.na(out$Outcome)), 32)
    expect_equal(sum(out$Outcome == "gambiae", na.rm = TRUE), 15)
    expect_equal(sum(out$Outcome == "arabiensis", na.rm = TRUE), 1)
    expect_equal(sum(out$Outcome == "melas", na.rm = TRUE), 0)

    expect_identical(out$Outcome[out$SampleID == "SN20-02377"], "arabiensis")
    expect_true(is.na(out$Outcome[out$SampleID == "SN20-00548"]))
})

test_that("PCRoutcome supports samples with multiple target matches", {
    dat <- data.frame(
        WellID = c("A01", "A01", "A01"),
        SampleID = c("S1", "S1", "S1"),
        Size = c(315, 390, 700),
        Conc = c(0.30, 0.40, 0.10),
        stringsAsFactors = FALSE
    )

    targets <- c(arabiensis = 315, gambiae = 390)
    out <- PCRoutcome(dat, targets, tolerance = c(0, 0), threshold = 0.2)

    expect_equal(nrow(out), 2)
    expect_equal(sort(out$Outcome), c("arabiensis", "gambiae"))
    expect_true(all(out$SampleID == "S1"))
})

test_that("PCRoutcome keeps threshold and tolerance boundaries inclusive", {
    dat <- data.frame(
        WellID = c("A01", "A02", "A03", "A04"),
        SampleID = c("S_at_threshold", "S_below_threshold", "S_left_boundary", "S_right_boundary"),
        Size = c(390, 390, 380, 400),
        Conc = c(0.20, 0.1999, 0.25, 0.25),
        stringsAsFactors = FALSE
    )

    out <- PCRoutcome(
        dat,
        targets = c(gambiae = 390),
        tolerance = c(10, 10),
        threshold = 0.2
    )

    expect_identical(out$Outcome[out$SampleID == "S_at_threshold"], "gambiae")
    expect_true(is.na(out$Outcome[out$SampleID == "S_below_threshold"]))
    expect_identical(out$Outcome[out$SampleID == "S_left_boundary"], "gambiae")
    expect_identical(out$Outcome[out$SampleID == "S_right_boundary"], "gambiae")
})

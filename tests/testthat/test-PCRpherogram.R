test_that("PCRpherogram returns a ggplot object for baseline settings", {
    data(mosquito)

    p <- PCRpherogram(mosquito, target_size = 390, tolerance = c(0, 10), threshold = 0.05)

    expect_s3_class(p, "ggplot")
})

test_that("PCRpherogram requires required columns", {
    data(mosquito)

    dat <- mosquito[, c("SampleID", "Size", "Conc")]

    expect_error(
        PCRpherogram(dat, target_size = 390, tolerance = c(0, 10), threshold = 0.05)
    )
})

test_that("PCRpherogram validates target_size and threshold", {
    data(mosquito)

    expect_error(
        PCRpherogram(mosquito, target_size = -1, tolerance = c(0, 10), threshold = 0.05),
        "target_size"
    )

    expect_error(
        PCRpherogram(mosquito, target_size = 390, tolerance = c(0, 10), threshold = -0.01),
        "threshold"
    )
})

test_that("PCRexplorer returns a ggplot object for baseline settings", {
    data(mosquito)

    targets <- c(arabiensis = 315, gambiae = 390, melas = 464)
    p <- PCRexplorer(mosquito, targets, tolerance = c(0, 10), threshold = 0.05)

    expect_s3_class(p, "ggplot")
})

test_that("PCRexplorer supports optional display controls", {
    data(mosquito)

    targets <- c(arabiensis = 315, gambiae = 390, melas = 464)

    p <- PCRexplorer(
        mosquito,
        targets,
        tolerance = c(0, 10),
        threshold = 0.05,
        logx = TRUE,
        logy = TRUE,
        xlimits = c(200, 1000),
        join = TRUE,
        control = "CTR"
    )

    expect_s3_class(p, "ggplot")
})

test_that("PCRexplorer validates tolerance and threshold coupling", {
    data(mosquito)

    targets <- c(arabiensis = 315, gambiae = 390, melas = 464)

    expect_error(
        PCRexplorer(mosquito, targets, tolerance = c(0, 10), threshold = NULL),
        "must be both given"
    )

    expect_error(
        PCRexplorer(mosquito, targets, tolerance = NULL, threshold = 0.05),
        "must be both given"
    )
})

test_that("PCRexplorer validates xlimits", {
    data(mosquito)

    targets <- c(arabiensis = 315, gambiae = 390, melas = 464)

    expect_error(
        PCRexplorer(mosquito, targets, xlimits = c(500, 200)),
        "xlimits"
    )
})

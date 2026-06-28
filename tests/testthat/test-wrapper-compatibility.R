test_that("PCRpositive remains backward compatible after internal routing", {
    data(mosquito)

    out <- PCRpositive(mosquito, target_size = 390, tolerance = c(10, 10), threshold = 0.2)

    expect_type(out, "character")
    expect_equal(
        out,
        c(
            "CTR", "SN20-02321", "SN20-02323", "SN20-02359", "SN20-02363",
            "SN20-02372", "SN20-02373", "SN20-02374", "SN20-02375", "SN20-02376",
            "SN20-02378", "SN20-02381", "SN20-02384", "SN20-02401", "SN20-02402"
        )
    )
})

test_that("PCRoutcome remains backward compatible after internal routing", {
    data(mosquito)

    targets <- c(arabiensis = 315, gambiae = 390, melas = 464)
    out <- PCRoutcome(mosquito, targets, tolerance = c(10, 10), threshold = 0.2)

    expect_s3_class(out, "data.frame")
    expect_equal(nrow(out), 48)
    expect_equal(sum(is.na(out$Outcome)), 32)
    expect_equal(sum(out$Outcome == "gambiae", na.rm = TRUE), 15)
    expect_equal(sum(out$Outcome == "arabiensis", na.rm = TRUE), 1)
})

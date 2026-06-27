test_that("PCRpositive returns expected positives for baseline settings", {
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

test_that("PCRpositive supports asymmetric tolerance", {
    data(mosquito)

    out <- PCRpositive(mosquito, target_size = 315, tolerance = c(0, 10), threshold = 0.2)

    expect_equal(out, "SN20-02377")
})

test_that("PCRpositive returns NULL when no sample is positive", {
    data(mosquito)

    out <- PCRpositive(mosquito, target_size = 9999, tolerance = c(10, 10), threshold = 9999)

    expect_null(out)
})

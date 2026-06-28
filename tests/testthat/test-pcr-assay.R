test_that("pcr_assay constructor returns validated canonical object", {
    dat <- data.frame(
        assay_id = "assay-1",
        target_id = "target-a",
        expected_size_bp = 390,
        lower_size_bp = 380,
        upper_size_bp = 400,
        min_concentration = 0.2,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    )

    out <- PCRprofilR:::pcr_assay(dat)

    expect_s3_class(out, "pcr_assay")
    expect_equal(out$expected_size_bp, 390)
    expect_equal(out$min_concentration, 0.2)
    expect_equal(out$confirm_concentration, 0.2)
    expect_equal(out$target_role, "optional")
})

test_that("validate_pcr_assay accepts constructor-compatible optional confirm concentration", {
    dat <- data.frame(
        assay_id = "assay-1",
        target_id = "target-a",
        expected_size_bp = 390,
        lower_size_bp = 380,
        upper_size_bp = 400,
        min_concentration = 0.2,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    )

    expect_silent(validate_pcr_assay(dat))

    dat$confirm_concentration <- 0.3
    expect_silent(validate_pcr_assay(dat))

    dat$confirm_concentration <- 0.1
    expect_error(validate_pcr_assay(dat), "confirm_concentration")
})

test_that("pcr_assay reports missing required columns", {
    dat <- data.frame(
        assay_id = "assay-1",
        target_id = "target-a",
        expected_size_bp = 390,
        lower_size_bp = 380,
        upper_size_bp = 400,
        min_concentration = 0.2,
        biological_label = "gambiae",
        stringsAsFactors = FALSE
    )

    expect_error(PCRprofilR:::pcr_assay(dat), "missing required columns: rule_group")
})

test_that("pcr_assay enforces numeric and interval constraints", {
    dat <- data.frame(
        assay_id = "assay-1",
        target_id = "target-a",
        expected_size_bp = 390,
        lower_size_bp = 395,
        upper_size_bp = 400,
        min_concentration = 0.2,
        biological_label = "gambiae",
        rule_group = "species",
        stringsAsFactors = FALSE
    )

    expect_error(PCRprofilR:::pcr_assay(dat), "expected_size_bp")

    dat$expected_size_bp <- 390
    dat$lower_size_bp <- 380
    dat$min_concentration <- -0.1
    expect_error(PCRprofilR:::pcr_assay(dat), "min_concentration")

    dat$min_concentration <- 0.2
    dat$confirm_concentration <- 0.1
    expect_error(PCRprofilR:::pcr_assay(dat), "confirm_concentration")

    dat$confirm_concentration <- 0.3
    dat$target_role <- "unexpected"
    expect_error(PCRprofilR:::pcr_assay(dat), "target_role")
})

test_that("pcr_assay coerces factor identifiers to character", {
    dat <- data.frame(
        assay_id = factor("assay-1"),
        target_id = factor("target-a"),
        expected_size_bp = 390,
        lower_size_bp = 380,
        upper_size_bp = 400,
        min_concentration = 0.2,
        biological_label = factor("gambiae"),
        rule_group = factor("species")
    )

    out <- PCRprofilR:::pcr_assay(dat)

    expect_type(out$assay_id, "character")
    expect_type(out$rule_group, "character")
})

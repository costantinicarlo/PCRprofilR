test_that("as_pcr_profile_rules constructs successfully with a validated hybrid rule when all explicit parameters are supplied", {
    rules <- PCRprofilR:::pcr_profile_rules(data.frame(
        assay_id = "assay-1",
        profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae",
        target_b = "arabiensis",
        profile_type = "hybrid",
        calibration_status = "validated",
        expected_log2_ratio = 0,
        max_abs_log2_deviation = 1,
        min_evidence_zone_a = "above_confirmatory",
        min_evidence_zone_b = "above_confirmatory",
        rule_version = "1",
        stringsAsFactors = FALSE
    ))

    expect_s3_class(rules, "pcr_profile_rules")
    expect_identical(rules$calibration_status[[1]], "validated")
    expect_identical(rules$min_evidence_zone_a[[1]], "above_confirmatory")
    expect_identical(rules$rule_version[[1]], "1")
})

test_that("as_pcr_profile_rules constructs successfully with a minimal pending hybrid rule", {
    rules <- PCRprofilR:::pcr_profile_rules(data.frame(
        assay_id = "assay-1",
        profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae",
        target_b = "arabiensis",
        profile_type = "hybrid",
        stringsAsFactors = FALSE
    ))

    expect_s3_class(rules, "pcr_profile_rules")
    expect_identical(rules$calibration_status[[1]], "pending")
    expect_identical(rules$min_evidence_zone_a[[1]], "above_confirmatory")
    expect_identical(rules$rule_version[[1]], "1")
})

test_that("pcr_profile_rules rejects target_a == target_b", {
    expect_error(
        PCRprofilR:::pcr_profile_rules(data.frame(
            assay_id = "assay-1",
            profile_id = "p1",
            target_a = "gambiae",
            target_b = "gambiae",
            profile_type = "hybrid",
            stringsAsFactors = FALSE
        )),
        "target_a != target_b"
    )
})

test_that("pcr_profile_rules rejects duplicate unordered pair rules within an assay", {
    dup <- data.frame(
        assay_id = c("assay-1", "assay-1"),
        profile_id = c("p1", "p2"),
        target_a = c("gambiae", "arabiensis"),
        target_b = c("arabiensis", "gambiae"),
        profile_type = c("hybrid", "mixed"),
        stringsAsFactors = FALSE
    )
    expect_error(
        PCRprofilR:::pcr_profile_rules(dup),
        "unordered target pair"
    )
})

test_that("pcr_profile_rules rejects validated hybrid rule without expected ratio", {
    expect_error(
        PCRprofilR:::pcr_profile_rules(data.frame(
            assay_id = "assay-1",
            profile_id = "p1",
            target_a = "gambiae",
            target_b = "arabiensis",
            profile_type = "hybrid",
            calibration_status = "validated",
            max_abs_log2_deviation = 1,
            stringsAsFactors = FALSE
        )),
        "expected_log2_ratio"
    )
})

test_that("pcr_profile_rules rejects validated hybrid rule without tolerance", {
    expect_error(
        PCRprofilR:::pcr_profile_rules(data.frame(
            assay_id = "assay-1",
            profile_id = "p1",
            target_a = "gambiae",
            target_b = "arabiensis",
            profile_type = "hybrid",
            calibration_status = "validated",
            expected_log2_ratio = 0,
            stringsAsFactors = FALSE
        )),
        "max_abs_log2_deviation"
    )
})

test_that("pcr_profile_rules rejects negative tolerance", {
    expect_error(
        PCRprofilR:::pcr_profile_rules(data.frame(
            assay_id = "assay-1",
            profile_id = "p1",
            target_a = "gambiae",
            target_b = "arabiensis",
            profile_type = "hybrid",
            calibration_status = "validated",
            expected_log2_ratio = 0,
            max_abs_log2_deviation = -1,
            stringsAsFactors = FALSE
        )),
        "non-negative"
    )
})

test_that("pcr_profile_rules rejects invalid evidence zone values", {
    expect_error(
        PCRprofilR:::pcr_profile_rules(data.frame(
            assay_id = "assay-1",
            profile_id = "p1",
            target_a = "gambiae",
            target_b = "arabiensis",
            profile_type = "hybrid",
            min_evidence_zone_a = "not_a_zone",
            stringsAsFactors = FALSE
        )),
        "min_evidence_zone_a"
    )
})

test_that("validate_pcr_profile_rules accepts the documented minimal schema directly", {
    minimal <- data.frame(
        assay_id = "assay-1",
        profile_id = "p1",
        target_a = "gambiae",
        target_b = "arabiensis",
        profile_type = "mixed",
        stringsAsFactors = FALSE
    )

    expect_silent(PCRprofilR:::validate_pcr_profile_rules(minimal))
})

test_that("pcr_profile_rules rejects unknown profile_type and calibration_status", {
    expect_error(
        PCRprofilR:::pcr_profile_rules(data.frame(
            assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b",
            profile_type = "not_a_type", stringsAsFactors = FALSE
        )),
        "profile_type"
    )
    expect_error(
        PCRprofilR:::pcr_profile_rules(data.frame(
            assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b",
            profile_type = "hybrid", calibration_status = "not_a_status", stringsAsFactors = FALSE
        )),
        "calibration_status"
    )
})

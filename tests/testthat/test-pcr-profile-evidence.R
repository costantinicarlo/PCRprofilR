.pf_peaks <- function(...) PCRprofilR:::pcr_peaks(data.frame(..., stringsAsFactors = FALSE))
.pf_assay <- function(...) PCRprofilR:::pcr_assay(data.frame(..., stringsAsFactors = FALSE))
.pf_rules <- function(...) PCRprofilR:::pcr_profile_rules(data.frame(..., stringsAsFactors = FALSE))

.pf_two_target_assay <- function(confirm = 0.3) {
    .pf_assay(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("gambiae", "arabiensis"),
        expected_size_bp = c(390, 315),
        lower_size_bp = c(380, 305),
        upper_size_bp = c(400, 325),
        min_concentration = c(0.2, 0.2),
        confirm_concentration = c(confirm, confirm),
        biological_label = c("gambiae", "arabiensis"),
        rule_group = c("species", "species")
    )
}

test_that("representative peak selection picks the closest-to-expected size", {
    peaks <- .pf_peaks(
        run_id = rep("run-1", 3), plate_id = rep("plate-1", 3), well_id = rep("A01", 3),
        sample_id = rep("S1", 3), peak_id = c("peak-1", "peak-2", "peak-3"),
        size_bp = c(315, 388, 393), concentration = c(0.35, 0.4, 0.05),
        raw_file = rep("run.csv", 3), instrument = rep("bioanalyzer", 3)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    # gambiae sorts after arabiensis, so without a rule it becomes target_b.
    expect_identical(evidence$target_b_peak_id[[1]], "peak-2")
})

test_that("representative peak selection breaks equal size-distance ties on concentration", {
    peaks <- .pf_peaks(
        run_id = rep("run-1", 3), plate_id = rep("plate-1", 3), well_id = rep("A02", 3),
        sample_id = rep("S2", 3), peak_id = c("peak-1", "peak-2", "peak-3"),
        size_bp = c(315, 388, 392), concentration = c(0.35, 0.4, 0.9),
        raw_file = rep("run.csv", 3), instrument = rep("bioanalyzer", 3)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    # peak-2 and peak-3 are equidistant from 390bp; peak-3 has the higher concentration.
    expect_identical(evidence$target_b_peak_id[[1]], "peak-3")
})

test_that("representative peak selection resolves remaining ties deterministically by peak_id", {
    peaks <- .pf_peaks(
        run_id = rep("run-1", 3), plate_id = rep("plate-1", 3), well_id = rep("A03", 3),
        sample_id = rep("S3", 3), peak_id = c("peak-1", "peak-a", "peak-b"),
        size_bp = c(315, 388, 392), concentration = c(0.35, 0.4, 0.4),
        raw_file = rep("run.csv", 3), instrument = rep("bioanalyzer", 3)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    expect_identical(evidence$target_b_peak_id[[1]], "peak-a")
})

test_that("balance outcome does not influence representative peak selection", {
    # peak-2 is closest to the gambiae target but would produce a poor balance;
    # it must still be selected over a farther peak that would balance better.
    peaks <- .pf_peaks(
        run_id = rep("run-1", 3), plate_id = rep("plate-1", 3), well_id = rep("A04", 3),
        sample_id = rep("S4", 3), peak_id = c("peak-1", "peak-2", "peak-3"),
        size_bp = c(315, 390, 396), concentration = c(4, 0.25, 4),
        raw_file = rep("run.csv", 3), instrument = rep("bioanalyzer", 3)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    expect_identical(evidence$target_b_peak_id[[1]], "peak-2")
    expect_identical(evidence$balance_status[[1]], NA_character_)
})

test_that("no rule + duplicate physical peak resolves as unresolved review, not balance review", {
    overlap_assay <- .pf_assay(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("gambiae", "arabiensis"),
        expected_size_bp = c(390, 385),
        lower_size_bp = c(380, 375),
        upper_size_bp = c(400, 395),
        min_concentration = c(0.2, 0.2),
        confirm_concentration = c(0.3, 0.3),
        biological_label = c("gambiae", "arabiensis"),
        rule_group = c("species", "species")
    )
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A05", sample_id = "S5",
        peak_id = "peak-1", size_bp = 390, concentration = 0.5,
        raw_file = "run.csv", instrument = "bioanalyzer"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, overlap_assay)
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    # profile_rule_status describes the rule (there is none); profile_structure_status
    # is the separate, machine-readable record of the duplicated physical peak.
    expect_identical(evidence$profile_rule_status[[1]], "rule_missing")
    expect_identical(evidence$profile_structure_status[[1]], "duplicate_physical_peak")

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls)
    expect_identical(calls$call_state[[1]], "dual_target_unresolved_review")
})

test_that("recognised hybrid rule + duplicate physical peak resolves as balance review", {
    overlap_assay <- .pf_assay(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("gambiae", "arabiensis"),
        expected_size_bp = c(390, 385),
        lower_size_bp = c(380, 375),
        upper_size_bp = c(400, 395),
        min_concentration = c(0.2, 0.2),
        confirm_concentration = c(0.3, 0.3),
        biological_label = c("gambiae", "arabiensis"),
        rule_group = c("species", "species")
    )
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A05b", sample_id = "S5b",
        peak_id = "peak-1", size_bp = 390, concentration = 0.5,
        raw_file = "run.csv", instrument = "bioanalyzer"
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "validated", expected_log2_ratio = 0, max_abs_log2_deviation = 1,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory",
        rule_version = "1"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, overlap_assay)
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)

    expect_identical(evidence$profile_rule_status[[1]], "calibration_validated")
    expect_identical(evidence$profile_structure_status[[1]], "duplicate_physical_peak")
    expect_identical(evidence$balance_status[[1]], "not_evaluable")

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)
    expect_identical(calls$call_state[[1]], "dual_target_balance_review")
})


test_that("equal concentrations with expected log2 ratio 0 give a perfect balance score", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A06", sample_id = "S6",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "validated", expected_log2_ratio = 0, max_abs_log2_deviation = 1,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)

    expect_equal(evidence$observed_log2_ratio[[1]], 0)
    expect_equal(evidence$abs_log2_deviation[[1]], 0)
    expect_equal(evidence$balance_score[[1]], 1)
    expect_identical(evidence$balance_status[[1]], "pass")

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)
    expect_identical(calls$call_state[[1]], "hybrid_candidate")
    expect_true(calls$hybrid_candidate[[1]])
    expect_identical(calls$call[[1]], "positive")
})

test_that("a two-fold difference produces the expected log2 ratio magnitude", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A07", sample_id = "S7",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(2, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    expect_equal(abs(evidence$observed_log2_ratio[[1]]), 1)
    expect_equal(evidence$fold_imbalance[[1]], 2)
    expect_equal(evidence$raw_balance_ratio[[1]], 0.5)
})

test_that("an order-of-magnitude imbalance is represented correctly", {
    weak_assay <- .pf_assay(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("gambiae", "arabiensis"),
        expected_size_bp = c(390, 315),
        lower_size_bp = c(380, 305),
        upper_size_bp = c(400, 325),
        min_concentration = c(0.01, 0.01),
        confirm_concentration = c(0.3, 0.3),
        biological_label = c("gambiae", "arabiensis"),
        rule_group = c("species", "species")
    )
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A08", sample_id = "S8",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(8, 0.08),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "validated", expected_log2_ratio = 0, max_abs_log2_deviation = 0.5,
        min_evidence_zone_a = "analytical_to_confirmatory", min_evidence_zone_b = "analytical_to_confirmatory", rule_version = "1"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, weak_assay)
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)

    expect_equal(evidence$fold_imbalance[[1]], 100)
    expect_identical(evidence$balance_status[[1]], "fail")

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)
    expect_identical(calls$call_state[[1]], "dual_target_imbalanced_review")
    expect_identical(calls$call[[1]], "positive")
    expect_false(calls$hybrid_candidate[[1]])
})

test_that("a non-zero expected pair bias is handled correctly", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A09", sample_id = "S9",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(2, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "validated", expected_log2_ratio = 1, max_abs_log2_deviation = 0.25,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)

    expect_equal(evidence$abs_log2_deviation[[1]], 0)
    expect_identical(evidence$balance_status[[1]], "pass")

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)
    expect_identical(calls$call_state[[1]], "hybrid_candidate")
})

test_that("recognised pair with pending calibration produces dual_target_balance_review", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A10", sample_id = "S10",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "pending"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)

    # Raw diagnostics remain available even though calibration is pending.
    expect_equal(evidence$observed_log2_ratio[[1]], 0)
    expect_identical(evidence$profile_rule_status[[1]], "calibration_pending")

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)
    expect_identical(calls$call_state[[1]], "dual_target_balance_review")
    expect_false(calls$hybrid_candidate[[1]])
})

test_that("validated hybrid rule with a weak target produces dual_target_weak_review", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A11", sample_id = "S11",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(0.25, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "validated", expected_log2_ratio = 0, max_abs_log2_deviation = 5,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)

    expect_identical(calls$call_state[[1]], "dual_target_weak_review")
    expect_identical(calls$call[[1]], "positive")
})

test_that("forbidden pair produces ambiguous_review", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A12", sample_id = "S12",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "forbidden_pair",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "forbidden"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)

    expect_identical(calls$call_state[[1]], "ambiguous_review")
})

test_that("pair defined as mixed produces mixed_profile_candidate", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A13", sample_id = "S13",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "mixed_pair",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "mixed"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .pf_two_target_assay())
    calls <- PCRprofilR:::pcr_sample_calls(peak_calls, rules)

    expect_identical(calls$call_state[[1]], "mixed_profile_candidate")
    expect_true(calls$mixed_profile_candidate[[1]])
})

test_that("non-evaluable concentration does not receive a pseudocount", {
    target_x <- tibble::tibble(
        target_id = "gambiae", target_peak_id = "peak-1", target_size_bp = 390,
        target_concentration = 0, target_evidence_zone = "below_analytical"
    )
    target_y <- tibble::tibble(
        target_id = "arabiensis", target_peak_id = "peak-2", target_size_bp = 315,
        target_concentration = 4, target_evidence_zone = "above_confirmatory"
    )
    sample_key <- tibble::tibble(run_id = "run-1", plate_id = "plate-1", well_id = "A14", sample_id = "S14", assay_id = "assay-1")

    row <- PCRprofilR:::.pcr_profile_evidence_row(sample_key, target_x, target_y, NULL)

    expect_true(is.na(row$observed_log2_ratio))
    expect_identical(row$profile_rule_status[[1]], "rule_missing")
})

test_that("evaluate_pcr_profiles produces a pcr_profile_evidence object and integrates with classify_pcr_samples", {
    peaks <- .pf_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A15", sample_id = "S15",
        peak_id = c("peak-1", "peak-2"), size_bp = c(315, 390), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .pf_rules(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "validated", expected_log2_ratio = 0, max_abs_log2_deviation = 1,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1"
    )
    peak_calls <- PCRprofilR::detect_pcr_peaks(peaks, .pf_two_target_assay())
    profile_rules <- PCRprofilR::as_pcr_profile_rules(rules)
    profile_evidence <- PCRprofilR::evaluate_pcr_profiles(peak_calls, profile_rules)

    expect_s3_class(profile_evidence, "pcr_profile_evidence")

    calls <- PCRprofilR::classify_pcr_samples(peak_calls, profile_evidence = profile_evidence)
    expect_identical(calls$call_state[[1]], "hybrid_candidate")
})

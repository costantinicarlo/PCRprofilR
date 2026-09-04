.ah_peaks <- function(...) PCRprofilR:::pcr_peaks(data.frame(..., stringsAsFactors = FALSE))
.ah_assay <- function(...) PCRprofilR:::pcr_assay(data.frame(..., stringsAsFactors = FALSE))
.ah_rules <- function(...) PCRprofilR:::pcr_profile_rules(data.frame(..., stringsAsFactors = FALSE))

.ah_two_target_assay <- function() {
    .ah_assay(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("gambiae", "arabiensis"),
        expected_size_bp = c(390, 315),
        lower_size_bp = c(380, 305),
        upper_size_bp = c(400, 325),
        min_concentration = c(0.2, 0.2),
        confirm_concentration = c(0.3, 0.3),
        biological_label = c("gambiae", "arabiensis"),
        rule_group = c("species", "species")
    )
}

# --- 20.1 Assay identity -----------------------------------------------------

test_that("a single assay_id passes validation", {
    expect_s3_class(.ah_two_target_assay(), "pcr_assay")
})

test_that("multiple assay_id values are rejected", {
    expect_error(
        .ah_assay(
            assay_id = c("assay-1", "assay-2"),
            target_id = c("gambiae", "arabiensis"),
            expected_size_bp = c(390, 315),
            lower_size_bp = c(380, 305),
            upper_size_bp = c(400, 325),
            min_concentration = c(0.2, 0.2),
            biological_label = c("gambiae", "arabiensis"),
            rule_group = c("species", "species")
        ),
        "exactly one assay_id"
    )
})

test_that("duplicate target_id values within an assay are rejected", {
    expect_error(
        .ah_assay(
            assay_id = c("assay-1", "assay-1"),
            target_id = c("gambiae", "gambiae"),
            expected_size_bp = c(390, 390),
            lower_size_bp = c(380, 380),
            upper_size_bp = c(400, 400),
            min_concentration = c(0.2, 0.2),
            biological_label = c("gambiae", "gambiae"),
            rule_group = c("species", "species")
        ),
        "duplicate target_id"
    )
})

test_that("assay_id appears in pcr_sample_calls and profile joins use it", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = "peak-1", size_bp = 390, concentration = 0.35,
        raw_file = "run.csv", instrument = "bioanalyzer"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    calls <- PCRprofilR:::pcr_sample_calls(peak_calls)

    expect_true("assay_id" %in% names(calls))
    expect_identical(calls$assay_id[[1]], "assay-1")
})

test_that("no cross-assay hybrid can be manufactured: evaluate_pcr_profiles requires one assay_id", {
    peak_calls_multi <- tibble::tibble(
        run_id = c("run-1", "run-1"), plate_id = c("plate-1", "plate-1"), well_id = c("A01", "A01"),
        sample_id = c("S1", "S1"), assay_id = c("assay-1", "assay-2"),
        target_id = c("gambiae", "arabiensis"), peak_id = c("peak-1", "peak-2"),
        size_bp = c(390, 315), concentration = c(4, 4),
        size_delta_bp = c(0, 0), within_window = c(TRUE, TRUE), matched = c(TRUE, TRUE),
        evidence_zone = c("above_confirmatory", "above_confirmatory"),
        biological_label = c("gambiae", "arabiensis"), rule_group = c("species", "species")
    )
    class(peak_calls_multi) <- c("pcr_peak_calls", class(peak_calls_multi))

    expect_error(
        PCRprofilR:::pcr_profile_evidence(peak_calls_multi),
        "exactly one assay_id"
    )
})

# --- 20.2 Profile-evidence validation ---------------------------------------

test_that("a valid zero-row profile-evidence object passes validation", {
    expect_silent(PCRprofilR:::validate_pcr_profile_evidence(PCRprofilR:::pcr_profile_evidence_empty()))
})

test_that("missing canonical columns are rejected", {
    bad <- tibble::tibble(run_id = "run-1")
    expect_error(PCRprofilR:::validate_pcr_profile_evidence(bad), "missing required columns")
})

test_that("duplicate interpreted-sample keys are rejected", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)
    dup <- dplyr::bind_rows(evidence, evidence)

    expect_error(PCRprofilR:::validate_pcr_profile_evidence(dup), "at most one row per interpreted-sample key")
})

test_that("unknown enum values are rejected", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)
    evidence$profile_rule_status <- "not_a_status"

    expect_error(PCRprofilR:::validate_pcr_profile_evidence(evidence), "profile_rule_status")
})

test_that("calibration_validated with missing strength_status is rejected (fail-closed against forged evidence)", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .ah_rules(
        assay_id = "assay-1", profile_id = "p1", target_a = "gambiae", target_b = "arabiensis",
        profile_type = "hybrid", calibration_status = "validated",
        expected_log2_ratio = 0, max_abs_log2_deviation = 1,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)
    expect_identical(evidence$balance_status[[1]], "pass")

    forged <- evidence
    forged$strength_status <- NA_character_

    expect_error(PCRprofilR:::validate_pcr_profile_evidence(forged), "strength_status")
    expect_error(PCRprofilR:::pcr_sample_calls(peak_calls, profile_evidence = forged), "strength_status")
})

test_that("profile evidence referencing an unknown peak_id is rejected against peak_calls", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)
    evidence$target_a_peak_id <- "peak-does-not-exist"

    expect_error(PCRprofilR:::validate_pcr_profile_evidence(evidence, peak_calls = peak_calls), "not present in peak_calls")
})

test_that("profile evidence with altered concentration is rejected against peak_calls", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)
    evidence$target_a_concentration <- evidence$target_a_concentration + 100

    expect_error(PCRprofilR:::validate_pcr_profile_evidence(evidence, peak_calls = peak_calls), "inconsistent")
})

test_that("profile evidence for a sample absent from peak_calls is rejected", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)
    evidence$sample_id <- "S-other"

    expect_error(PCRprofilR:::validate_pcr_profile_evidence(evidence, peak_calls = peak_calls), "not present in peak_calls")
})

# --- 20.4 Structural cases ----------------------------------------------------

test_that("three matched targets with two labels do not produce ordinary pairwise evidence", {
    assay3 <- .ah_assay(
        assay_id = rep("assay-1", 3),
        target_id = c("gambiae", "gambiae_2", "arabiensis"),
        expected_size_bp = c(390, 392, 315),
        lower_size_bp = c(380, 382, 305),
        upper_size_bp = c(400, 402, 325),
        min_concentration = rep(0.2, 3),
        confirm_concentration = rep(0.3, 3),
        biological_label = c("gambiae", "gambiae", "arabiensis"),
        rule_group = rep("species", 3)
    )
    peaks <- .ah_peaks(
        run_id = rep("run-1", 3), plate_id = rep("plate-1", 3), well_id = rep("A01", 3), sample_id = rep("S1", 3),
        peak_id = c("peak-1", "peak-2", "peak-3"), size_bp = c(390, 392, 315), concentration = rep(4, 3),
        raw_file = rep("run.csv", 3), instrument = rep("bioanalyzer", 3)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, assay3)
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    expect_equal(nrow(evidence), 0L)

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls)
    expect_identical(calls$call_state[[1]], "ambiguous_review")
    expect_false(calls$hybrid_candidate[[1]])
})

test_that("two matched targets sharing one biological label are not treated as a hybrid", {
    assay_same_label <- .ah_assay(
        assay_id = c("assay-1", "assay-1"),
        target_id = c("gambiae", "gambiae_2"),
        expected_size_bp = c(390, 392),
        lower_size_bp = c(380, 382),
        upper_size_bp = c(400, 402),
        min_concentration = c(0.2, 0.2),
        confirm_concentration = c(0.3, 0.3),
        biological_label = c("gambiae", "gambiae"),
        rule_group = c("species", "species")
    )
    peaks <- .ah_peaks(
        run_id = c("run-1", "run-1"), plate_id = c("plate-1", "plate-1"), well_id = c("A01", "A01"), sample_id = c("S1", "S1"),
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 392), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, assay_same_label)
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)

    expect_equal(nrow(evidence), 0L)

    calls <- PCRprofilR:::pcr_sample_calls(peak_calls)
    expect_identical(calls$call_state[[1]], "positive")
    expect_false(calls$hybrid_candidate[[1]])
})

# --- 20.5 Rule contracts -------------------------------------------------------

test_that("hybrid + not_applicable is rejected", {
    expect_error(
        .ah_rules(assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b", profile_type = "hybrid", calibration_status = "not_applicable"),
        "incompatible profile_type/calibration_status"
    )
})

test_that("mixed + not_applicable is valid and mixed + pending/validated are rejected", {
    expect_s3_class(
        .ah_rules(assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b", profile_type = "mixed", calibration_status = "not_applicable"),
        "pcr_profile_rules"
    )
    expect_error(
        .ah_rules(assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b", profile_type = "mixed", calibration_status = "pending"),
        "incompatible profile_type/calibration_status"
    )
    expect_error(
        .ah_rules(assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b", profile_type = "mixed", calibration_status = "validated"),
        "incompatible profile_type/calibration_status"
    )
})

test_that("forbidden + not_applicable is valid and forbidden + pending/validated are rejected", {
    expect_s3_class(
        .ah_rules(assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b", profile_type = "forbidden", calibration_status = "not_applicable"),
        "pcr_profile_rules"
    )
    expect_error(
        .ah_rules(assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b", profile_type = "forbidden", calibration_status = "pending"),
        "incompatible profile_type/calibration_status"
    )
})

test_that("calibration_status defaults are type-aware when the column is entirely absent", {
    rules <- .ah_rules(
        assay_id = c("assay-1", "assay-1"), profile_id = c("p1", "p2"),
        target_a = c("a", "c"), target_b = c("b", "d"),
        profile_type = c("mixed", "forbidden")
    )
    expect_identical(rules$calibration_status, c("not_applicable", "not_applicable"))
})

test_that("validated hybrid rule missing min_evidence_zone_a/b entirely is rejected", {
    expect_error(
        .ah_rules(
            assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b",
            profile_type = "hybrid", calibration_status = "validated",
            expected_log2_ratio = 0, max_abs_log2_deviation = 1
        ),
        "min_evidence_zone_a"
    )
})

test_that("validated hybrid rule missing rule_version entirely is rejected", {
    expect_error(
        .ah_rules(
            assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b",
            profile_type = "hybrid", calibration_status = "validated",
            expected_log2_ratio = 0, max_abs_log2_deviation = 1,
            min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory"
        ),
        "rule_version"
    )
})

test_that("rules referring to unknown assay targets are rejected", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    rules <- .ah_rules(
        assay_id = "assay-1", profile_id = "p1", target_a = "gambiae", target_b = "unknown-target",
        profile_type = "mixed", calibration_status = "not_applicable"
    )

    expect_error(PCRprofilR:::pcr_profile_evidence(peak_calls, rules), "unknown target_id")
})

test_that("non-empty rules with no active-assay match produce an actionable error", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    rules <- .ah_rules(
        assay_id = "some-other-assay", profile_id = "p1", target_a = "x", target_b = "y",
        profile_type = "mixed", calibration_status = "not_applicable"
    )

    expect_error(PCRprofilR:::pcr_profile_evidence(peak_calls, rules), "no rules for assay_id")
})

# --- 20.6 Numeric input --------------------------------------------------------

test_that("factor-valued numeric rule columns are converted safely, not via level codes", {
    dat <- data.frame(
        assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b",
        profile_type = "hybrid", calibration_status = "validated",
        expected_log2_ratio = factor("0.5"), max_abs_log2_deviation = factor("1.0"),
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1",
        stringsAsFactors = FALSE
    )
    rules <- PCRprofilR:::pcr_profile_rules(dat)
    expect_equal(rules$expected_log2_ratio, 0.5)
    expect_equal(rules$max_abs_log2_deviation, 1.0)
})

test_that("malformed character numeric rule values are rejected clearly", {
    dat <- data.frame(
        assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b",
        profile_type = "hybrid", calibration_status = "validated",
        expected_log2_ratio = "not-a-number", max_abs_log2_deviation = "1",
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1",
        stringsAsFactors = FALSE
    )
    expect_error(PCRprofilR:::pcr_profile_rules(dat), "cannot be parsed as numeric")
})

test_that("Inf, -Inf, and NaN rule values are rejected for validated hybrid rules", {
    base <- list(
        assay_id = "assay-1", profile_id = "p1", target_a = "a", target_b = "b",
        profile_type = "hybrid", calibration_status = "validated",
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1"
    )
    expect_error(PCRprofilR:::pcr_profile_rules(c(base, list(expected_log2_ratio = Inf, max_abs_log2_deviation = 1))), "finite")
    expect_error(PCRprofilR:::pcr_profile_rules(c(base, list(expected_log2_ratio = -Inf, max_abs_log2_deviation = 1))), "finite")
    expect_error(PCRprofilR:::pcr_profile_rules(c(base, list(expected_log2_ratio = NaN, max_abs_log2_deviation = 1))), "finite")
})

# --- 20.7 Dominance -------------------------------------------------------------

test_that("dominance is A, B, equal, or not_evaluable as appropriate", {
    peaks_a_dominant <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "SA",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(8, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls_a <- PCRprofilR:::pcr_peak_calls(peaks_a_dominant, .ah_two_target_assay())
    evidence_a <- PCRprofilR:::pcr_profile_evidence(peak_calls_a)
    expect_identical(evidence_a$dominance_status[[1]], "target_b_dominant") # gambiae sorts to target_b without a rule
    expect_identical(evidence_a$dominant_target[[1]], "gambiae")

    peaks_equal <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A02", sample_id = "SE",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls_e <- PCRprofilR:::pcr_peak_calls(peaks_equal, .ah_two_target_assay())
    evidence_e <- PCRprofilR:::pcr_profile_evidence(peak_calls_e)
    expect_identical(evidence_e$dominance_status[[1]], "equal")
    expect_true(is.na(evidence_e$dominant_target[[1]]))
    expect_true(is.na(evidence_e$minor_target[[1]]))
})

# --- 20.8 Exports and provenance -----------------------------------------------

test_that("canonical profile rules are exported and absence is explicit", {
    peak_calls <- tibble::tibble(
        run_id = "run-1", assay_id = "assay-1", target_id = "target-a", sample_id = "S1", matched = TRUE
    )
    class(peak_calls) <- c("pcr_peak_calls", class(peak_calls))
    sample_calls <- tibble::tibble(run_id = "run-1", sample_id = "S1", call = "positive", call_state = "positive", review_required = FALSE)
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))
    qc <- tibble::tibble(run_id = "run-1", sample_id = "S1", qc_status = "pass", contamination_candidate = FALSE)
    class(qc) <- c("pcr_qc", class(qc))

    out_dir <- tempfile()
    out <- PCRprofilR:::pcr_export_artifacts(peak_calls, sample_calls, qc, out_dir, format = "csv")

    rules_file <- out$files[grepl("profile_rules", out$files)]
    expect_length(rules_file, 1)
    expect_true(file.exists(rules_file))
    expect_false(out$profile_rules_supplied)

    summary_txt <- readLines(out$summary_file)
    expect_true(any(grepl("profile_rules_supplied: FALSE", summary_txt)))
    expect_true(any(grepl("interpretation_model_version:", summary_txt)))
})

test_that("named user metadata are preserved with a provenance_user_ prefix", {
    peak_calls <- tibble::tibble(run_id = "run-1", assay_id = "assay-1", target_id = "target-a", sample_id = "S1", matched = TRUE)
    class(peak_calls) <- c("pcr_peak_calls", class(peak_calls))
    sample_calls <- tibble::tibble(run_id = "run-1", sample_id = "S1", call = "positive", call_state = "positive", review_required = FALSE)
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))
    qc <- tibble::tibble(run_id = "run-1", sample_id = "S1", qc_status = "pass", contamination_candidate = FALSE)
    class(qc) <- c("pcr_qc", class(qc))

    out_dir <- tempfile()
    out <- PCRprofilR:::pcr_export_artifacts(
        peak_calls, sample_calls, qc, out_dir,
        format = "csv", metadata = list(operator = "jdoe", batch_note = "test")
    )
    exported <- utils::read.csv(out$files[[1]], stringsAsFactors = FALSE)
    expect_identical(exported$provenance_user_operator[[1]], "jdoe")
    expect_identical(exported$provenance_user_batch_note[[1]], "test")
})

test_that("metadata must be scalar atomic values", {
    peak_calls <- tibble::tibble(run_id = "run-1", assay_id = "assay-1", target_id = "target-a", sample_id = "S1", matched = TRUE)
    class(peak_calls) <- c("pcr_peak_calls", class(peak_calls))
    sample_calls <- tibble::tibble(run_id = "run-1", sample_id = "S1", call = "positive", call_state = "positive", review_required = FALSE)
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))
    qc <- tibble::tibble(run_id = "run-1", sample_id = "S1", qc_status = "pass", contamination_candidate = FALSE)
    class(qc) <- c("pcr_qc", class(qc))

    expect_error(
        PCRprofilR:::pcr_export_artifacts(peak_calls, sample_calls, qc, tempfile(), metadata = list(bad = c(1, 2))),
        "scalar atomic value"
    )
})

test_that("formula-like exported values trigger a warning without mutating canonical data", {
    peak_calls <- tibble::tibble(
        run_id = "run-1", assay_id = "assay-1", target_id = "target-a",
        sample_id = "=cmd|'/c calc'!A1", matched = TRUE
    )
    class(peak_calls) <- c("pcr_peak_calls", class(peak_calls))
    sample_calls <- tibble::tibble(run_id = "run-1", sample_id = "=cmd|'/c calc'!A1", call = "positive", call_state = "positive", review_required = FALSE)
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))
    qc <- tibble::tibble(run_id = "run-1", sample_id = "=cmd|'/c calc'!A1", qc_status = "pass", contamination_candidate = FALSE)
    class(qc) <- c("pcr_qc", class(qc))

    out_dir <- tempfile()
    expect_warning(
        out <- PCRprofilR:::pcr_export_artifacts(peak_calls, sample_calls, qc, out_dir, format = "csv"),
        "formula marker"
    )
    exported <- utils::read.csv(out$files[[1]], stringsAsFactors = FALSE)
    expect_identical(exported$sample_id[[1]], "=cmd|'/c calc'!A1")
})

test_that("batch mode works with a real profile_rules_path and writes profile_rules.csv", {
    peaks_in <- data.frame(
        RunID = c("run-1", "run-1"), PlateID = c("plate-1", "plate-1"), WellID = c("A01", "A01"),
        SampleID = c("S1", "S1"), PeakID = c("peak-1", "peak-2"), Size = c(390, 315), Conc = c(4, 4),
        RawFile = c("run.csv", "run.csv"), Instrument = c("bioanalyzer", "bioanalyzer"),
        stringsAsFactors = FALSE
    )
    assay_in <- data.frame(
        assay_id = c("assay-1", "assay-1"), target_id = c("gambiae", "arabiensis"),
        expected_size_bp = c(390, 315), lower_size_bp = c(380, 305), upper_size_bp = c(400, 325),
        min_concentration = c(0.2, 0.2), confirm_concentration = c(0.3, 0.3),
        biological_label = c("gambiae", "arabiensis"), rule_group = c("species", "species"),
        stringsAsFactors = FALSE
    )
    rules_in <- data.frame(
        assay_id = "assay-1", profile_id = "gambiae_arabiensis_hybrid",
        target_a = "gambiae", target_b = "arabiensis", profile_type = "hybrid",
        calibration_status = "validated", expected_log2_ratio = 0, max_abs_log2_deviation = 1,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1",
        stringsAsFactors = FALSE
    )

    peaks_path <- tempfile(fileext = ".csv")
    assay_path <- tempfile(fileext = ".csv")
    rules_path <- tempfile(fileext = ".csv")
    out_dir <- tempfile()

    utils::write.csv(peaks_in, peaks_path, row.names = FALSE)
    utils::write.csv(assay_in, assay_path, row.names = FALSE)
    utils::write.csv(rules_in, rules_path, row.names = FALSE)

    out <- PCRprofilR:::pcr_batch_run(peaks_path, assay_path, out_dir, profile_rules_path = rules_path)

    expect_s3_class(out$profile_rules, "pcr_profile_rules")
    expect_identical(out$sample_calls$call_state[[1]], "hybrid_candidate")
    rules_file <- out$written_files[grepl("profile_rules", out$written_files)]
    expect_length(rules_file, 1)
    expect_true(file.exists(rules_file))
})

# --- PR #5 review follow-ups ---------------------------------------------------

test_that("rule metadata inconsistent with profile_rule_status is rejected", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A01", sample_id = "S1",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls)
    expect_identical(evidence$profile_rule_status[[1]], "rule_missing")

    # rule_missing rows must carry NA rule metadata.
    forged_populated <- evidence
    forged_populated$profile_type <- "hybrid"
    expect_error(PCRprofilR:::validate_pcr_profile_evidence(forged_populated), "profile_id/profile_type/calibration_status/rule_version")

    # A row claiming a rule applies must have fully populated, non-empty rule metadata.
    rules <- .ah_rules(assay_id = "assay-1", profile_id = "p1", target_a = "gambiae", target_b = "arabiensis", profile_type = "mixed", calibration_status = "not_applicable")
    evidence_mixed <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)
    expect_identical(evidence_mixed$profile_rule_status[[1]], "mixed_profile")

    forged_missing <- evidence_mixed
    forged_missing$rule_version <- NA_character_
    expect_error(PCRprofilR:::validate_pcr_profile_evidence(forged_missing), "non-missing")

    # profile_type must agree with profile_rule_status (mixed_profile -> "mixed").
    forged_type <- evidence_mixed
    forged_type$profile_type <- "forbidden"
    expect_error(PCRprofilR:::validate_pcr_profile_evidence(forged_type), "profile_type.*inconsistent")

    # calibration_status must agree with profile_rule_status (mixed_profile -> "not_applicable").
    forged_calibration <- evidence_mixed
    forged_calibration$calibration_status <- "validated"
    expect_error(PCRprofilR:::validate_pcr_profile_evidence(forged_calibration), "calibration_status.*inconsistent")
})

test_that("balance_score inconsistent with abs_log2_deviation is rejected", {
    peaks <- .ah_peaks(
        run_id = "run-1", plate_id = "plate-1", well_id = "A02", sample_id = "S2",
        peak_id = c("peak-1", "peak-2"), size_bp = c(390, 315), concentration = c(4, 4),
        raw_file = rep("run.csv", 2), instrument = rep("bioanalyzer", 2)
    )
    rules <- .ah_rules(
        assay_id = "assay-1", profile_id = "p1", target_a = "gambiae", target_b = "arabiensis",
        profile_type = "hybrid", calibration_status = "validated",
        expected_log2_ratio = 0, max_abs_log2_deviation = 1,
        min_evidence_zone_a = "above_confirmatory", min_evidence_zone_b = "above_confirmatory", rule_version = "1"
    )
    peak_calls <- PCRprofilR:::pcr_peak_calls(peaks, .ah_two_target_assay())
    evidence <- PCRprofilR:::pcr_profile_evidence(peak_calls, rules)
    expect_identical(evidence$balance_status[[1]], "pass")

    forged_score <- evidence
    forged_score$balance_score <- forged_score$balance_score + 10
    expect_error(PCRprofilR:::validate_pcr_profile_evidence(forged_score), "balance_score")

    forged_na_score <- evidence
    forged_na_score$balance_score <- NA_real_
    expect_error(PCRprofilR:::validate_pcr_profile_evidence(forged_na_score), "non-missing")
})

test_that("pcr_export_artifacts rejects non-data-frame profile_rules/profile_evidence with a clear error", {
    peak_calls <- tibble::tibble(run_id = "run-1", assay_id = "assay-1", target_id = "target-a", sample_id = "S1", matched = TRUE)
    class(peak_calls) <- c("pcr_peak_calls", class(peak_calls))
    sample_calls <- tibble::tibble(run_id = "run-1", sample_id = "S1", call = "positive", call_state = "positive", review_required = FALSE)
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))
    qc <- tibble::tibble(run_id = "run-1", sample_id = "S1", qc_status = "pass", contamination_candidate = FALSE)
    class(qc) <- c("pcr_qc", class(qc))

    expect_error(
        PCRprofilR:::pcr_export_artifacts(peak_calls, sample_calls, qc, tempfile(), profile_rules = list()),
        "profile_rules must be a data frame"
    )
    expect_error(
        PCRprofilR:::pcr_export_artifacts(peak_calls, sample_calls, qc, tempfile(), profile_evidence = list()),
        "profile_evidence must be a data frame"
    )
})


test_that("pcr_replicate_summary returns concordant replicate summary", {
    sample_calls <- tibble::tibble(
        run_id = c("run-1", "run-2"),
        plate_id = c("plate-1", "plate-2"),
        well_id = c("A01", "A01"),
        sample_id = c("S1", "S1"),
        matched_target_count = c(1L, 1L),
        matched_targets = c("target-a", "target-a"),
        matched_label_count = c(1L, 1L),
        below_analytical_target_count = c(0L, 0L),
        sample_threshold_zone = c("above_confirmatory", "above_confirmatory"),
        call_state = c("positive", "positive"),
        call = c("positive", "positive"),
        confidence = c("baseline", "baseline"),
        threshold_status = c("positive", "positive"),
        review_required = c(FALSE, FALSE),
        hybrid_candidate = c(FALSE, FALSE),
        mixed_profile_candidate = c(FALSE, FALSE)
    )
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))

    out <- PCRprofilR:::pcr_replicate_summary(sample_calls)

    expect_s3_class(out, "pcr_replicate_calls")
    expect_equal(out$n_replicates[[1]], 2L)
    expect_identical(out$replicate_concordance[[1]], "concordant")
    expect_identical(out$consensus_call_state[[1]], "positive")
})

test_that("pcr_replicate_summary marks discordant replicate states", {
    sample_calls <- tibble::tibble(
        run_id = c("run-1", "run-2"),
        plate_id = c("plate-1", "plate-2"),
        well_id = c("A01", "A01"),
        sample_id = c("S2", "S2"),
        matched_target_count = c(1L, 0L),
        matched_targets = c("target-a", ""),
        matched_label_count = c(1L, 0L),
        below_analytical_target_count = c(0L, 1L),
        sample_threshold_zone = c("analytical_to_confirmatory", "below_analytical"),
        call_state = c("weak_positive", "indeterminate_review"),
        call = c("positive", "negative"),
        confidence = c("baseline", "baseline"),
        threshold_status = c("review", "review"),
        review_required = c(TRUE, TRUE),
        hybrid_candidate = c(FALSE, FALSE),
        mixed_profile_candidate = c(FALSE, FALSE)
    )
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))

    out <- PCRprofilR:::pcr_replicate_summary(sample_calls)

    expect_identical(out$replicate_concordance[[1]], "discordant")
    expect_identical(out$consensus_call_state[[1]], "review_discordant")
    expect_identical(out$consensus_call[[1]], "positive")
})

test_that("pcr_replicate_summary carries QC rollups when provided", {
    sample_calls <- tibble::tibble(
        run_id = c("run-1", "run-2"),
        plate_id = c("plate-1", "plate-2"),
        well_id = c("A01", "A01"),
        sample_id = c("S3", "S3"),
        matched_target_count = c(1L, 1L),
        matched_targets = c("target-a", "target-a"),
        matched_label_count = c(1L, 1L),
        below_analytical_target_count = c(0L, 0L),
        sample_threshold_zone = c("above_confirmatory", "above_confirmatory"),
        call_state = c("positive", "positive"),
        call = c("positive", "positive"),
        confidence = c("baseline", "baseline"),
        threshold_status = c("positive", "positive"),
        review_required = c(FALSE, FALSE),
        hybrid_candidate = c(FALSE, FALSE),
        mixed_profile_candidate = c(FALSE, FALSE)
    )
    class(sample_calls) <- c("pcr_sample_calls", class(sample_calls))

    qc <- tibble::tibble(
        run_id = c("run-1", "run-2"),
        plate_id = c("plate-1", "plate-2"),
        well_id = c("A01", "A01"),
        sample_id = c("S3", "S3"),
        qc_status = c("pass", "review"),
        contamination_candidate = c(FALSE, TRUE)
    )
    class(qc) <- c("pcr_qc", class(qc))

    out <- PCRprofilR:::pcr_replicate_summary(sample_calls, qc = qc)

    expect_false(out$any_qc_fail[[1]])
    expect_true(out$any_contamination_candidate[[1]])
})

.pcr_evidence_zone_rank <- c(
    below_analytical = 0L,
    analytical_to_confirmatory = 1L,
    above_confirmatory = 2L
)

.pcr_representative_target_peaks <- function(peak_calls) {
    matched <- dplyr::filter(peak_calls, .data$matched)

    matched |>
        dplyr::mutate(.abs_size_delta = abs(.data$size_delta_bp)) |>
        dplyr::arrange(.data$.abs_size_delta, dplyr::desc(.data$concentration), .data$peak_id) |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id, .data$assay_id, .data$target_id) |>
        dplyr::slice(1L) |>
        dplyr::ungroup() |>
        dplyr::select(
            "run_id", "plate_id", "well_id", "sample_id", "assay_id", "target_id",
            "biological_label", "rule_group",
            target_peak_id = "peak_id",
            target_size_bp = "size_bp",
            target_concentration = "concentration",
            target_evidence_zone = "evidence_zone"
        )
}

.pcr_profile_rule_lookup <- function(profile_rules, assay_id, target_x, target_y) {
    if (is.null(profile_rules) || nrow(profile_rules) == 0L) {
        return(NULL)
    }
    hit <- profile_rules[
        profile_rules$assay_id == assay_id &
            ((profile_rules$target_a == target_x & profile_rules$target_b == target_y) |
                (profile_rules$target_a == target_y & profile_rules$target_b == target_x)),
        ,
        drop = FALSE
    ]
    if (nrow(hit) == 0L) {
        return(NULL)
    }
    hit[1L, , drop = FALSE]
}

.pcr_profile_evidence_row <- function(sample_key, target_x, target_y, profile_rules) {
    rule <- .pcr_profile_rule_lookup(profile_rules, sample_key$assay_id, target_x$target_id, target_y$target_id)

    if (!is.null(rule)) {
        if (identical(rule$target_a, target_x$target_id)) {
            ta <- target_x
            tb <- target_y
        } else {
            ta <- target_y
            tb <- target_x
        }
    } else {
        ordered <- sort(c(target_x$target_id, target_y$target_id))
        ta <- if (identical(target_x$target_id, ordered[1L])) target_x else target_y
        tb <- if (identical(target_x$target_id, ordered[1L])) target_y else target_x
    }

    # Structural evaluability (does the profile rest on two distinct physical peaks?) is a
    # separate machine-readable axis from profile_rule_status (does a pairwise rule exist,
    # and what is its calibration state?). Conflating the two previously let a duplicated
    # physical peak silently masquerade as a rule status.
    duplicate_peak <- identical(ta$target_peak_id, tb$target_peak_id)
    profile_structure_status <- if (duplicate_peak) "duplicate_physical_peak" else "distinct_physical_peaks"

    profile_rule_status <- if (is.null(rule)) {
        "rule_missing"
    } else if (identical(rule$profile_type, "forbidden")) {
        "forbidden_profile"
    } else if (identical(rule$profile_type, "mixed")) {
        "mixed_profile"
    } else if (identical(rule$profile_type, "hybrid") && identical(rule$calibration_status, "pending")) {
        "calibration_pending"
    } else if (identical(rule$profile_type, "hybrid") && identical(rule$calibration_status, "validated")) {
        "calibration_validated"
    } else {
        "rule_missing"
    }

    ca <- ta$target_concentration
    cb <- tb$target_concentration
    evaluable <- !duplicate_peak &&
        is.finite(ca) && is.finite(cb) && !is.na(ca) && !is.na(cb) && ca > 0 && cb > 0

    observed_log2_ratio <- NA_real_
    raw_balance_ratio <- NA_real_
    fold_imbalance <- NA_real_
    dominant_target <- NA_character_
    minor_target <- NA_character_
    dominance_status <- "not_evaluable"

    if (evaluable) {
        observed_log2_ratio <- log2(ca / cb)
        raw_balance_ratio <- min(ca, cb) / max(ca, cb)
        fold_imbalance <- max(ca, cb) / min(ca, cb)
        if (ca > cb) {
            dominant_target <- ta$target_id
            minor_target <- tb$target_id
            dominance_status <- "target_a_dominant"
        } else if (cb > ca) {
            dominant_target <- tb$target_id
            minor_target <- ta$target_id
            dominance_status <- "target_b_dominant"
        } else {
            dominance_status <- "equal"
        }
    }

    expected_log2_ratio <- NA_real_
    max_abs_log2_deviation <- NA_real_
    min_evidence_zone_a <- NA_character_
    min_evidence_zone_b <- NA_character_
    abs_log2_deviation <- NA_real_
    balance_score <- NA_real_
    balance_status <- NA_character_
    strength_status <- NA_character_

    if (!is.null(rule) && identical(rule$profile_type, "hybrid")) {
        expected_log2_ratio <- rule$expected_log2_ratio
        max_abs_log2_deviation <- rule$max_abs_log2_deviation
        min_evidence_zone_a <- rule$min_evidence_zone_a
        min_evidence_zone_b <- rule$min_evidence_zone_b
    }

    if (identical(profile_rule_status, "calibration_validated")) {
        strength_status <- if (
            .pcr_evidence_zone_rank[[ta$target_evidence_zone]] >= .pcr_evidence_zone_rank[[rule$min_evidence_zone_a]] &&
                .pcr_evidence_zone_rank[[tb$target_evidence_zone]] >= .pcr_evidence_zone_rank[[rule$min_evidence_zone_b]]
        ) {
            "pass"
        } else {
            "fail"
        }

        if (evaluable) {
            abs_log2_deviation <- abs(observed_log2_ratio - expected_log2_ratio)
            balance_score <- 2^(-abs_log2_deviation)
            balance_status <- if (abs_log2_deviation <= max_abs_log2_deviation) "pass" else "fail"
        } else {
            balance_status <- "not_evaluable"
        }
    }

    tibble::tibble(
        run_id = sample_key$run_id,
        plate_id = sample_key$plate_id,
        well_id = sample_key$well_id,
        sample_id = sample_key$sample_id,
        assay_id = sample_key$assay_id,
        profile_id = if (is.null(rule)) NA_character_ else rule$profile_id,
        profile_type = if (is.null(rule)) NA_character_ else rule$profile_type,
        calibration_status = if (is.null(rule)) NA_character_ else rule$calibration_status,
        rule_version = if (is.null(rule)) NA_character_ else rule$rule_version,
        target_a = ta$target_id,
        target_b = tb$target_id,
        target_a_peak_id = ta$target_peak_id,
        target_b_peak_id = tb$target_peak_id,
        target_a_size_bp = ta$target_size_bp,
        target_b_size_bp = tb$target_size_bp,
        target_a_concentration = ca,
        target_b_concentration = cb,
        target_a_evidence_zone = ta$target_evidence_zone,
        target_b_evidence_zone = tb$target_evidence_zone,
        observed_log2_ratio = observed_log2_ratio,
        raw_balance_ratio = raw_balance_ratio,
        fold_imbalance = fold_imbalance,
        expected_log2_ratio = expected_log2_ratio,
        max_abs_log2_deviation = max_abs_log2_deviation,
        min_evidence_zone_a = min_evidence_zone_a,
        min_evidence_zone_b = min_evidence_zone_b,
        abs_log2_deviation = abs_log2_deviation,
        balance_score = balance_score,
        balance_status = balance_status,
        strength_status = strength_status,
        dominant_target = dominant_target,
        minor_target = minor_target,
        dominance_status = dominance_status,
        profile_rule_status = profile_rule_status,
        profile_structure_status = profile_structure_status,
        interpretation_model_version = .pcr_interpretation_model_version
    )
}

pcr_profile_evidence_empty <- function() {
    empty <- tibble::tibble(
        run_id = character(0), plate_id = character(0), well_id = character(0), sample_id = character(0),
        assay_id = character(0), profile_id = character(0), profile_type = character(0),
        calibration_status = character(0), rule_version = character(0),
        target_a = character(0), target_b = character(0),
        target_a_peak_id = character(0), target_b_peak_id = character(0),
        target_a_size_bp = numeric(0), target_b_size_bp = numeric(0),
        target_a_concentration = numeric(0), target_b_concentration = numeric(0),
        target_a_evidence_zone = character(0), target_b_evidence_zone = character(0),
        observed_log2_ratio = numeric(0), raw_balance_ratio = numeric(0), fold_imbalance = numeric(0),
        expected_log2_ratio = numeric(0), max_abs_log2_deviation = numeric(0),
        min_evidence_zone_a = character(0), min_evidence_zone_b = character(0),
        abs_log2_deviation = numeric(0), balance_score = numeric(0),
        balance_status = character(0), strength_status = character(0),
        dominant_target = character(0), minor_target = character(0), dominance_status = character(0),
        profile_rule_status = character(0), profile_structure_status = character(0),
        interpretation_model_version = character(0)
    )
    class(empty) <- c("pcr_profile_evidence", class(empty))
    empty
}

pcr_profile_evidence <- function(peak_calls, profile_rules = NULL) {
    if (!inherits(peak_calls, "pcr_peak_calls")) {
        stop("pcr_profile_evidence requires a pcr_peak_calls object", call. = FALSE)
    }
    if (!is.null(profile_rules) && !inherits(profile_rules, "pcr_profile_rules")) {
        profile_rules <- pcr_profile_rules(profile_rules)
    }

    active_assay_ids <- unique(peak_calls$assay_id)
    if (length(active_assay_ids) != 1L) {
        stop("pcr_profile_evidence requires peak_calls to represent exactly one assay_id", call. = FALSE)
    }
    profile_rules <- .pcr_profile_rules_for_assay(profile_rules, active_assay_ids, unique(peak_calls$target_id))

    representative <- .pcr_representative_target_peaks(peak_calls)

    # Pairwise profile evidence is evaluable only for exactly two matched targets
    # representing exactly two distinct biological labels; this must match the
    # predicate used by pcr_sample_calls() so evidence and final call never disagree.
    dual_target_samples <- representative |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id, .data$assay_id) |>
        dplyr::filter(dplyr::n() == 2L & dplyr::n_distinct(.data$biological_label) == 2L) |>
        dplyr::ungroup()

    if (nrow(dual_target_samples) == 0L) {
        return(pcr_profile_evidence_empty())
    }

    sample_groups <- dual_target_samples |>
        dplyr::group_by(.data$run_id, .data$plate_id, .data$well_id, .data$sample_id, .data$assay_id) |>
        dplyr::group_split()

    rows <- lapply(sample_groups, function(grp) {
        sample_key <- grp[1L, c("run_id", "plate_id", "well_id", "sample_id", "assay_id")]
        target_x <- grp[1L, , drop = FALSE]
        target_y <- grp[2L, , drop = FALSE]
        .pcr_profile_evidence_row(sample_key, target_x, target_y, profile_rules)
    })

    out <- dplyr::bind_rows(rows)
    class(out) <- c("pcr_profile_evidence", class(out))
    out
}


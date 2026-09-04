.pcr_interpretation_model_version <- "pairwise-profile-balance-v1"

# Canonical grouping key for one interpreted sample within one assay context.
.pcr_interpreted_sample_key_cols <- c("run_id", "plate_id", "well_id", "sample_id", "assay_id")

# Centralised call_state registries so a new state cannot be added in one
# downstream layer (sample calls, QC, replicates, plotting) while being
# silently omitted from another.
.pcr_dual_target_call_states <- c(
    "dual_target_unresolved_review",
    "dual_target_weak_review",
    "dual_target_imbalanced_review",
    "dual_target_balance_review",
    "hybrid_candidate"
)

.pcr_multi_target_call_states <- c("mixed_profile_candidate", "ambiguous_review", .pcr_dual_target_call_states)

.pcr_review_call_states <- c("weak_positive", "indeterminate_review", .pcr_multi_target_call_states)

.pcr_terminal_call_states <- c("positive", "negative")

# Values that make an already-detected sample relevant for contamination review (never a negative call).
.pcr_contamination_relevant_call_states <- .pcr_multi_target_call_states

#' Safely convert a scientific parameter column to numeric
#'
#' Rejects the classic `as.numeric(factor)` pitfall (silently returning
#' internal level codes) by converting factors through `as.character()`
#' first. Character values that cannot be parsed as numeric are reported
#' explicitly rather than silently becoming `NA`.
#'
#' @param x A numeric, character, or factor vector.
#' @param colname Column name used in error messages.
#'
#' @return A numeric vector.
#' @noRd
.pcr_safe_numeric <- function(x, colname) {
    if (is.numeric(x)) {
        return(x)
    }
    if (is.factor(x)) {
        x <- as.character(x)
    }
    if (is.logical(x) && all(is.na(x))) {
        return(as.numeric(x))
    }
    if (!is.character(x)) {
        stop(sprintf("column '%s' must be numeric or character-numeric", colname), call. = FALSE)
    }
    out <- suppressWarnings(as.numeric(x))
    bad <- !is.na(x) & is.na(out)
    if (any(bad)) {
        stop(
            sprintf(
                "column '%s' contains values that cannot be parsed as numeric: %s",
                colname, paste(unique(x[bad]), collapse = ", ")
            ),
            call. = FALSE
        )
    }
    out
}

.pcr_reject_untrimmed <- function(x, colname) {
    if (any(!is.na(x) & trimws(x) != x)) {
        stop(sprintf("column '%s' must not contain leading or trailing whitespace", colname), call. = FALSE)
    }
    x
}

.pcr_normalize_enum <- function(x) {
    trimws(tolower(as.character(x)))
}

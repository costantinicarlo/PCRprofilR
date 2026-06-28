## ----knitr-setup, include = FALSE---------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.dim = c(6, 4)
)


## ----setup--------------------------------------------------------------------
library(PCRprofilR)


## ----load-data----------------------------------------------------------------
data(mosquito)

head(mosquito[, c("WellID", "SampleID", "Type", "Size", "Conc")], 8)


## ----count-usable-peaks-------------------------------------------------------
usable_peak_rows <- with(
  mosquito,
  !is.na(Size) &
    is.finite(Size) &
    Size > 0 &
    !is.na(Conc) &
    is.finite(Conc) &
    Conc >= 0 &
    !is.na(WellID) &
    nzchar(as.character(WellID)) &
    !is.na(SampleID) &
    nzchar(as.character(SampleID))
)

table(usable_peak_rows)


## ----prepare-peaks------------------------------------------------------------
peaks_input <- transform(
  mosquito,
  RunID = "run-1",
  PlateID = "plate-1",
  PeakID = paste0("peak-", seq_len(nrow(mosquito))),
  RawFile = "mosquito.csv",
  Instrument = "labchip"
)

peaks_input <- peaks_input[usable_peak_rows, ]

peaks <- as_pcr_peaks(peaks_input)

head(peaks)


## ----assay--------------------------------------------------------------------
assay <- as_pcr_assay(data.frame(
  assay_id = c("species-assay", "species-assay", "species-assay"),
  target_id = c("arabiensis", "gambiae", "melas"),
  expected_size_bp = c(315, 390, 464),
  lower_size_bp = c(315, 390, 464),
  upper_size_bp = c(325, 400, 474),
  min_concentration = c(0.05, 0.05, 0.05),
  confirm_concentration = c(0.2, 0.2, 0.2),
  biological_label = c("arabiensis", "gambiae", "melas"),
  rule_group = c("species", "species", "species"),
  target_role = c("optional", "optional", "optional"),
  stringsAsFactors = FALSE
))

assay


## ----peak-calls---------------------------------------------------------------
peak_calls <- detect_pcr_peaks(peaks, assay)

head(
  peak_calls[peak_calls$matched, c(
    "sample_id",
    "target_id",
    "size_bp",
    "expected_size_bp",
    "size_delta_bp",
    "concentration",
    "evidence_zone",
    "matched"
  )]
)


## ----sample-calls-------------------------------------------------------------
sample_calls <- classify_pcr_samples(peak_calls)

head(sample_calls[, c(
  "well_id",
  "sample_id",
  "call",
  "call_state",
  "matched_targets",
  "rule_status",
  "review_required"
)])


## ----call-state-counts--------------------------------------------------------
table(sample_calls$call_state)


## ----qc-----------------------------------------------------------------------
qc <- qc_pcr_run(peaks, sample_calls)

head(qc[, c(
  "well_id",
  "sample_id",
  "control_role",
  "qc_status",
  "contamination_candidate",
  "duplicate_sample_id_in_run"
)])


## ----qc-counts----------------------------------------------------------------
table(qc$qc_status)


## ----classified-plot----------------------------------------------------------
plot_pcr_evidence(peak_calls, sample_calls = sample_calls, qc = qc)


## ----replicate-summary--------------------------------------------------------
replicate_summary <- summarize_pcr_replicates(sample_calls, qc = qc)

head(replicate_summary)


## ----export, eval = FALSE-----------------------------------------------------
# report_out <- report_pcr_calls(
#   peak_calls = peak_calls,
#   sample_calls = sample_calls,
#   qc = qc,
#   output_dir = "pcr-results",
#   format = "csv",
#   write_summary = TRUE
# )


## ----batch, eval = FALSE------------------------------------------------------
# batch_out <- run_pcr_batch(
#   peaks_path = "peaks.csv",
#   assay_path = "assay.csv",
#   output_dir = "pcr-results"
# )


## ----legacy-explorer----------------------------------------------------------
targets <- c(arabiensis = 315, gambiae = 390, melas = 464)

PCRexplorer(
  mosquito,
  targets,
  tolerance = c(0, 10),
  threshold = 0.05,
  xlimits = c(300, 500),
  logy = TRUE,
  join = TRUE,
  control = "CTR"
)


## ----minimal-script, eval = FALSE---------------------------------------------
# library(PCRprofilR)
# 
# data(mosquito)
# 
# peaks_input <- transform(
#   mosquito,
#   RunID = "run-1",
#   PlateID = "plate-1",
#   PeakID = paste0("peak-", seq_len(nrow(mosquito))),
#   RawFile = "mosquito.csv",
#   Instrument = "labchip"
# )
# 
# usable_peak_rows <- with(
#   peaks_input,
#   !is.na(Size) &
#     is.finite(Size) &
#     Size > 0 &
#     !is.na(Conc) &
#     is.finite(Conc) &
#     Conc >= 0 &
#     !is.na(WellID) &
#     nzchar(as.character(WellID)) &
#     !is.na(SampleID) &
#     nzchar(as.character(SampleID))
# )
# 
# peaks <- as_pcr_peaks(peaks_input[usable_peak_rows, ])
# 
# assay <- as_pcr_assay(data.frame(
#   assay_id = c("species-assay", "species-assay", "species-assay"),
#   target_id = c("arabiensis", "gambiae", "melas"),
#   expected_size_bp = c(315, 390, 464),
#   lower_size_bp = c(315, 390, 464),
#   upper_size_bp = c(325, 400, 474),
#   min_concentration = c(0.05, 0.05, 0.05),
#   confirm_concentration = c(0.2, 0.2, 0.2),
#   biological_label = c("arabiensis", "gambiae", "melas"),
#   rule_group = c("species", "species", "species"),
#   target_role = c("optional", "optional", "optional"),
#   stringsAsFactors = FALSE
# ))
# 
# peak_calls <- detect_pcr_peaks(peaks, assay)
# sample_calls <- classify_pcr_samples(peak_calls)
# qc <- qc_pcr_run(peaks, sample_calls)
# replicate_summary <- summarize_pcr_replicates(sample_calls, qc = qc)


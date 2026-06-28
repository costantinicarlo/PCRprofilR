library(PCRprofilR)

data(mosquito)

# Build canonical-like input from legacy columns for a reproducible example.
peaks_input <- transform(
    mosquito,
    RunID = "run-1",
    PlateID = "plate-1",
    PeakID = paste0("peak-", seq_len(nrow(mosquito))),
    RawFile = "mosquito.csv",
    Instrument = "labchip"
)

peaks_input <- subset(
    peaks_input,
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

peaks <- as_pcr_peaks(peaks_input)

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
    stringsAsFactors = FALSE
))

peak_calls <- detect_pcr_peaks(peaks, assay)
sample_calls <- classify_pcr_samples(peak_calls)
qc <- qc_pcr_run(peaks, sample_calls)

head(sample_calls[, c("sample_id", "call", "call_state", "threshold_status")])
head(qc[, c("sample_id", "qc_status", "contamination_candidate")])

plot_pcr_evidence(peak_calls, sample_calls, qc)

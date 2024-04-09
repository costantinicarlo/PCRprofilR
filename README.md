# Introduction

Electrophoresis devices based on microfluidics technology can simplify and scale up the analysis of nucleic acids in biomolecular applications. Following a run and using specialised software, one can generally retrieve from these devices a text output file (usually in CSV format) containing the fragment size and concentration of the amplicons resulting from PCR amplification of each sample. The functions in the `PCRprofilR` package provide a simple way to visualise and automate the retrieval of the information in this output file for downstream applications. One of these applications is the programmatic classification of DNA/RNA samples returning amplicons that are diagnostic based on their fragment size. This insures the transparency and reproducibility of results of analyses based on this classification.

# Installation

`PCRprofilR` functions depend on the `tidyverse`, therefore packages `magrittr`, `tibble`, `tidyr`, `dplyr`, and `ggplot2` should be installed in your system.

`PCRprofilR` is not on CRAN, so to install it from GitHub use the commands:

`install.packages("devtools") # if you have not installed "devtools" package`

`devtools::install_github("carlocostantini/PCRprofilR")`

or

`install.packages("githubinstall") # if you have not installed "githubinstall" package`

`githubinstall::githubinstall("PCRprofilR")`

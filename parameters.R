#parameters.r

# Definitions
nThreads <- FALSE

template = "MSC"
gsr_bool = TRUE
method_variance <- "non-negative"
method_FC <- "VB1"
# Important switch for the BBM library and prior to use
bold_scaling <- "sd" # "mean"

# parse gsr_bool to name
if (gsr_bool == TRUE) {
  gsr = "GSR"
} else {
  gsr = "noGSR"
}

# bold_scaling suffix -- appended (in setup.R) to dir_output and used in
# scripts for local ./output paths so runs with different BOLD scaling do
# not overwrite each other's outputs. Matches the prior-file naming in 01.
bold_suffix <- if (bold_scaling == "mean") "" else "_sd"

# define subjects and sessions
subjects <- sprintf("MSC%02d", 1:10 )
sessions <- sprintf("func%02d", 1:10 )

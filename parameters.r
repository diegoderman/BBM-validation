#parameters.r

# Definitions
nThreads <- FALSE

template = "MSC"
gsr_bool = TRUE
method_variance = "non-negative"
method_variance <- "non-negative"
method_FC <- "VB1"

# parse gsr_bool to name
if (gsr_bool == TRUE) {
  gsr = "GSR"
} else {
  gsr = "noGSR"
}

# define subjects and sessions
subjects <- sprintf("MSC%02d", 1:10 )
sessions <- sprintf("func%02d", 1:10 )

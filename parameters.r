#parameters.r

template = "MSC"
gsr_bool = FALSE
method_variance = "non-negative"
method_variance <- "non-negative"
method_FC <- "VB1"

# parse gsr_bool to name
if (gsr_bool == TRUE) {
  gsr = "GSR"
} else {
  gsr = "noGSR"
}
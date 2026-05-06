# fit a single session of MSC data to the MSC GSR priors.

# Definitions
subid <- "MSC01"
sesid <- "func01"

method_variance <- "non-negative"
method_FC <- "VB1"
nThreads <- FALSE

# source setup script, which loads libraries and paths
source("./setup.R")

# load prior
prior_msc <- readRDS(file.path(dir_priors, "MSC", "prior_combined_MSC_noGSR.rds"))

# load preprocessed bold timeseries
cifti_fname <- file.path(dir_msc, paste0("sub-", subid, "/processed_restingstate_timecourses/ses-", sesid, "/cifti"),
                         paste0("sub-", subid, "_ses-", sesid, "_task-rest_bold_32k_fsLR.dtseries.nii"))
bold_cifti <- read_cifti(cifti_fname)

# plot mean time series of bold
msc01_bbm <- fit_BBM(
  BOLD = bold_cifti,
  prior = prior_msc,
  var_method = method_variance,
  TR = TR_MSC,
  drop_first = 5,
  GSR = FALSE,
  scrub = FALSE,
  usePar = nThreads)


plot(msc01_bbm, idx = 6)

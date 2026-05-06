# fit a single session of MSC data to the MSC GSR priors.

# Definitions
subid <- "MSC01"
sesid <- "func01"

nThreads <- FALSE

# source setup script, which loads libraries and paths
source("./setup.R")

source("./parameters.r")

# load prior
prior_msc <- readRDS(file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, ".rds")))

# load preprocessed bold timeseries
cifti_fname <- file.path(dir_msc, paste0("sub-", subid, "/processed_restingstate_timecourses/ses-", sesid, "/cifti"),
                         paste0("sub-", subid, "_ses-", sesid, "_task-rest_bold_32k_fsLR.dtseries.nii"))
bold_cifti <- read_cifti(cifti_fname)

# plot mean time series of bold
msc01_bbm <- fit_BBM(
  BOLD = bold_cifti,
  prior = prior_msc,
  var_method = method_variance,
  method_FC = method_FC,
  TR = TR_MSC,
  drop_first = 5,
  GSR = FALSE,
  scrub = FALSE,
  usePar = nThreads)

# save model fit
rds_fname <- file.path(dir_output, paste0("fit_BBM_", subid, "_", sesid, "_", method_variance, "_", method_FC, "_", gsr, ".rds"))


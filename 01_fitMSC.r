# fit a single session of MSC data to the MSC GSR priors.

# source setup script, which loads libraries and paths
source("./setup.R")

# all definitions in parameters
source("./parameters.r")

# load prior
prior_msc <- readRDS(file.path(dir_priors, template, paste0("prior_combined_", template, "_", gsr, ".rds")))

# for subjects and sessions
for (subid in subjects) {
  for (sesid in sessions) {
    print(paste("Processing subject", subid, "session", sesid))

    # Define output dir
    dir_output_sub <- file.path(dir_output, "fit_BBM-rds", paste0("sub-", subid))

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
    rds_fname <- file.path(dir_output_sub, paste0("fit_BBM_", subid, "_", sesid, "_", method_variance, "_", method_FC, "_", gsr, ".rds"))
    saveRDS(msc01_bbm, rds_fname)

  }
}